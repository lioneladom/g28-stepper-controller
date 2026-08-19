/**
 * arduino_uno_stepper_controller.ino
 * NEMA17 Stepper Controller — Standalone Arduino Uno
 *
 * Hardware:
 *   - Arduino Uno
 *   - Adafruit Motor Shield v1 (L293D)
 *   - NEMA 17 stepper (200 steps/rev) wired to Port 1 (M1 & M2)
 *   - HC-05 Bluetooth: RX via divider to Uno A1(TX), TX directly to Uno A0(RX)
 *   - LCD 16x2 I2C (Address 0x27): SDA to A4, SCL to A5
 *   - Potentiometer: Wiper to A2
 *   - E-Stop Button: D2 to GND (INPUT_PULLUP)
 *
 * Control Priority:
 *   1. E-Stop latch (halts motor immediately)
 *   2. App (HC-05) overrides Potentiometer when running
 *   3. Potentiometer (manual fallback)
 */

#include <AFMotor.h>
#include <SoftwareSerial.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// ── Hardware Pins ─────────────────────────────────────────────────────────────
#define PIN_BT_RX    A0
#define PIN_BT_TX    A1
#define PIN_POT      A2
#define PIN_ESTOP    2

// ── Objects ───────────────────────────────────────────────────────────────────
SoftwareSerial BT_Serial(PIN_BT_RX, PIN_BT_TX);
AF_Stepper     motor(200, 1);
LiquidCrystal_I2C lcd(0x27, 16, 2);

// ── Constants ─────────────────────────────────────────────────────────────────
const int MAX_RPM        = 80;
const int STEPS_PER_REV  = 200;
const int POT_CENTER     = 512;
const int POT_DEADZONE   = 30;
const int POT_SMOOTH_N   = 8;
const unsigned long DEBOUNCE_MS        = 60UL;
const unsigned long LCD_UPDATE_MS      = 200UL;
const unsigned long REPORT_INTERVAL_MS = 200UL;

// ── System State ──────────────────────────────────────────────────────────────
enum SysMode { SYS_POT, SYS_APP, SYS_ESTOP };
SysMode sysMode = SYS_POT;

bool eStopLatched = false;
unsigned long lastEStopMs = 0;

// ── Motor state ───────────────────────────────────────────────────────────────
enum MotorMode { MODE_STOPPED, MODE_VELOCITY, MODE_POSITION };
MotorMode motorMode = MODE_STOPPED;
uint8_t   motorDir  = FORWARD;

long currentSteps = 0;
long targetSteps  = 0;
unsigned long stepIntervalUs = 0;
unsigned long lastStepUs     = 0;
unsigned long lastReportMs   = 0;
unsigned long lastLcdMs      = 0;

// App Commands
bool appRunning = false;
int  appRPM = 0;
bool appForward = true;

// ── Potentiometer ─────────────────────────────────────────────────────────────
int potSamples[POT_SMOOTH_N];
int potIdx = 0;

void initPot() {
  int v = analogRead(PIN_POT);
  for (int i = 0; i < POT_SMOOTH_N; i++) potSamples[i] = v;
}

int readSmoothedPot() {
  potSamples[potIdx] = analogRead(PIN_POT);
  potIdx = (potIdx + 1) % POT_SMOOTH_N;
  long sum = 0;
  for (int i = 0; i < POT_SMOOTH_N; i++) sum += potSamples[i];
  return (int)(sum / POT_SMOOTH_N);
}

// ── Bluetooth Parser ──────────────────────────────────────────────────────────
String rxBuf = "";

void parseCommand(String& raw) {
  raw.trim();
  int len = raw.length();
  if (len < 3) return;
  if (raw.charAt(0) != '<' || raw.charAt(len - 1) != '>') return;

  String body = raw.substring(1, len - 1);

  if (body == "STOP") {
    appRunning = false;
    appRPM = 0;
    return;
  }

  if (body.startsWith("RUN,")) {
    String params = body.substring(4);
    int c = params.indexOf(',');
    if (c < 1) return;
    appForward = (params.substring(0, c) == "F");
    appRPM     = params.substring(c + 1).toInt();
    appRunning = (appRPM > 0);
    
    if (appRunning) {
      motorRunVelocity(appForward ? FORWARD : BACKWARD, appRPM);
      sysMode = SYS_APP;
    }
    return;
  }

  if (body.startsWith("GOTO,")) {
    String params = body.substring(5);
    int c = params.indexOf(',');
    if (c < 1) return;
    int deg = params.substring(0, c).toInt();
    int rpm = params.substring(c + 1).toInt();
    
    appRunning = true;
    sysMode = SYS_APP;
    motorGoto(deg, rpm);
    return;
  }
}

// ── Motor Helpers ─────────────────────────────────────────────────────────────
long degreesToSteps(int deg) {
  return (long)deg * 10L / 18L;
}
int stepsToDegrees(long steps) {
  return (int)(steps * 18L / 10L);
}
unsigned long rpmToIntervalUs(int rpm) {
  if (rpm <= 0) return 0;
  rpm = constrain(rpm, 1, MAX_RPM);
  return 60000000UL / ((unsigned long)rpm * (unsigned long)STEPS_PER_REV);
}

void motorStop() {
  motorMode = MODE_STOPPED;
  stepIntervalUs = 0;
  motor.release();
}

void motorRunVelocity(uint8_t dir, int rpm) {
  rpm = constrain(rpm, 1, MAX_RPM);
  motorDir = dir;
  stepIntervalUs = rpmToIntervalUs(rpm);
  motorMode = MODE_VELOCITY;
}

void motorGoto(int degrees, int rpm) {
  rpm = constrain(rpm, 5, MAX_RPM);
  targetSteps = degreesToSteps(degrees);
  stepIntervalUs = rpmToIntervalUs(rpm);
  motorMode = MODE_POSITION;
}

// ── LCD ───────────────────────────────────────────────────────────────────────
void lcdRow(int row, const String& text) {
  String line = text;
  while (line.length() < 16) line += ' ';
  lcd.setCursor(0, row);
  lcd.print(line.substring(0, 16));
}

void updateLCD() {
  if (millis() - lastLcdMs < LCD_UPDATE_MS) return;
  lastLcdMs = millis();

  String row0, row1;
  int deg = stepsToDegrees(currentSteps);

  if (eStopLatched) {
    row0 = "!!! E-STOP !!!";
    row1 = "Motor LOCKED";
  } else if (sysMode == SYS_APP) {
    if (motorMode != MODE_STOPPED) {
      row0 = "APP " + String((motorDir == FORWARD) ? "FWD " : "REV ") + String(60000000UL / (stepIntervalUs * STEPS_PER_REV)) + "RPM";
    } else {
      row0 = "APP: IDLE";
    }
    row1 = "Pos:" + String(deg) + "deg";
  } else {
    if (motorMode != MODE_STOPPED) {
      row0 = "POT " + String((motorDir == FORWARD) ? "FWD " : "REV ") + String(60000000UL / (stepIntervalUs * STEPS_PER_REV)) + "RPM";
    } else {
      row0 = "POT: IDLE";
    }
    row1 = "Pos:" + String(deg) + "deg";
  }

  lcdRow(0, row0);
  lcdRow(1, row1);
}

// ── Setup ─────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(9600);
  BT_Serial.begin(9600);
  rxBuf.reserve(64);

  pinMode(PIN_ESTOP, INPUT_PULLUP);
  
  Wire.begin();
  lcd.init();
  lcd.backlight();
  lcdRow(0, "System Starting");
  lcdRow(1, "Please wait...");

  initPot();
  motor.release();
  
  delay(1000);
  lcd.clear();
}

// ── Main Loop ─────────────────────────────────────────────────────────────────
void loop() {
  unsigned long nowUs = micros();
  unsigned long nowMs = millis();

  // 1. E-Stop Button
  if (digitalRead(PIN_ESTOP) == LOW && (nowMs - lastEStopMs) > DEBOUNCE_MS) {
    lastEStopMs = nowMs;
    eStopLatched = !eStopLatched;
    if (eStopLatched) {
      motorStop();
      appRunning = false;
    }
  }

  // 2. Bluetooth Receive
  while (BT_Serial.available()) {
    char c = (char)BT_Serial.read();
    if (c == '\n') {
      parseCommand(rxBuf);
      rxBuf = "";
    } else if (c != '\r' && rxBuf.length() < 63) {
      rxBuf += c;
    }
  }

  // 3. Logic & State Management
  if (eStopLatched) {
    sysMode = SYS_ESTOP;
    motorStop();
  } else if (appRunning) {
    sysMode = SYS_APP;
    // (Movement handled by parseCommand and motor step logic)
  } else {
    sysMode = SYS_POT;
    int potVal = readSmoothedPot();
    
    if (potVal > POT_CENTER + POT_DEADZONE) {
      int rpm = map(potVal, POT_CENTER + POT_DEADZONE, 1023, 1, MAX_RPM);
      motorRunVelocity(FORWARD, rpm);
    } else if (potVal < POT_CENTER - POT_DEADZONE) {
      int rpm = map(potVal, POT_CENTER - POT_DEADZONE, 0, 1, MAX_RPM);
      motorRunVelocity(BACKWARD, rpm);
    } else {
      motorStop();
    }
  }

  // 4. Motor Step (Non-blocking)
  switch (motorMode) {
    case MODE_VELOCITY:
      if (stepIntervalUs > 0 && (nowUs - lastStepUs) >= stepIntervalUs) {
        lastStepUs = nowUs;
        motor.onestep(motorDir, SINGLE);
        currentSteps += (motorDir == FORWARD) ? 1 : -1;
      }
      break;

    case MODE_POSITION:
      if (currentSteps == targetSteps) {
        motorStop();
        appRunning = false; // Auto-idle when GOTO finishes
      } else if (stepIntervalUs > 0 && (nowUs - lastStepUs) >= stepIntervalUs) {
        lastStepUs = nowUs;
        uint8_t dir = (targetSteps > currentSteps) ? FORWARD : BACKWARD;
        motor.onestep(dir, SINGLE);
        currentSteps += (dir == FORWARD) ? 1 : -1;
      }
      break;

    case MODE_STOPPED:
    default:
      break;
  }

  // 5. Telemetry via Bluetooth
  if (nowMs - lastReportMs >= REPORT_INTERVAL_MS) {
    lastReportMs = nowMs;
    BT_Serial.print("POS:");
    BT_Serial.println(stepsToDegrees(currentSteps));
  }

  // 6. LCD Update
  updateLCD();
}