/**
 * esp32_stepper_controller.ino
 * NEMA17 Stepper — ESP32 BLE Gateway
 *
 * Hardware:
 *   ESP32 Dev Module
 *   LCD 16x2 via I2C (address 0x27)
 *   Potentiometer  pin 34  (12-bit ADC, centre ~2048 = idle)
 *   E-Stop button  pin 26  (INPUT_PULLUP, LOW = pressed, toggles latch)
 *   Reset button   pin 27  (INPUT_PULLUP, LOW = pressed, reboots ESP32)
 *   UART2 TX pin 17 -> Arduino A0 (RX)
 *   UART2 RX pin 16 <- Arduino A1 (TX)
 *
 *   The power switch is wired between the battery, the motor driver, and
 *   the breadboard + rail only. The ESP32 has no connection to it.
 *
 * Control priority (highest first):
 *   1. E-Stop latch  -- motor off, cleared by pressing E-Stop again
 *   2. App (BLE)     -- when connected and app has sent a run/goto command
 *   3. Potentiometer -- always available as manual fallback
 *
 * Command protocol (ESP32 -> Arduino, 9600 baud):
 *   <STOP>
 *   <RUN,F,{rpm}>  or  <RUN,B,{rpm}>
 *   <GOTO,{degrees},{rpm}>
 *
 * Telemetry (Arduino -> ESP32):
 *   POS:{degrees}\n   every 200 ms
 */

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ---------------------------------------------------------------------------
// Pin definitions
// ---------------------------------------------------------------------------
#define POT_PIN    34
#define BTN_ESTOP  26
#define BTN_RESET  27
#define RXD2       16
#define TXD2       17

// ---------------------------------------------------------------------------
// BLE UUIDs
// ---------------------------------------------------------------------------
#define SERVICE_UUID      "12345678-0000-1000-8000-00805f9b34fb"
#define SPEED_CHAR_UUID   "12345678-0001-1000-8000-00805f9b34fb"
#define DIR_CHAR_UUID     "12345678-0002-1000-8000-00805f9b34fb"
#define TARGET_CHAR_UUID  "12345678-0003-1000-8000-00805f9b34fb"
#define STATUS_CHAR_UUID  "12345678-0004-1000-8000-00805f9b34fb"

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
#define MAX_RPM        80
#define POT_CENTER     2048
#define POT_DEADZONE   150
#define POT_SMOOTH_N   8
#define DEBOUNCE_MS    60UL
#define LCD_UPDATE_MS  200UL
#define BLE_NOTIFY_MS  500UL

// ---------------------------------------------------------------------------
// Types  -- all structs/enums declared BEFORE any function definition
// so the Arduino IDE prototype generator does not create forward declarations
// that reference undefined types.
// ---------------------------------------------------------------------------

enum SysMode {
  SYS_ESTOP,
  SYS_APP,
  SYS_POT
};

struct PotCmd {
  bool running;
  bool forward;
  int  rpm;
};

// ---------------------------------------------------------------------------
// Hardware objects
// ---------------------------------------------------------------------------
LiquidCrystal_I2C lcd(0x27, 16, 2);

// ---------------------------------------------------------------------------
// BLE objects
// ---------------------------------------------------------------------------
BLEServer*          pServer     = nullptr;
BLECharacteristic*  pStatusChar = nullptr;
bool                bleConnected = false;

// ---------------------------------------------------------------------------
// App (BLE) state  -- volatile because written from BLE callback tasks
// ---------------------------------------------------------------------------
volatile int  appRPM          = 0;
volatile bool appForward      = true;
volatile bool appRunning      = false;
volatile bool velCmdPending   = false;
volatile bool gotoCmdPending  = false;
volatile int  appTargetDeg    = 0;

// ---------------------------------------------------------------------------
// Potentiometer smoothing
// ---------------------------------------------------------------------------
int potSamples[POT_SMOOTH_N];
int potIdx = 0;

// ---------------------------------------------------------------------------
// System state
// ---------------------------------------------------------------------------
SysMode sysMode     = SYS_POT;
SysMode prevSysMode = SYS_POT;

bool          eStopLatched = false;
unsigned long lastEStopMs  = 0;
unsigned long lastResetMs  = 0;

long reportedPosition = 0;

// Display cache (used for LCD and BLE notification)
bool dispRunning = false;
bool dispForward = true;
int  dispRPM     = 0;

// Command deduplication (only send to Arduino when state changes)
int  lastSentRPM     = -1;
bool lastSentForward = true;
bool lastSentStop    = false;

unsigned long lastLcdMs    = 0;
unsigned long lastNotifyMs = 0;

// ---------------------------------------------------------------------------
// Potentiometer functions
// ---------------------------------------------------------------------------

void initPot() {
  int v = analogRead(POT_PIN);
  for (int i = 0; i < POT_SMOOTH_N; i++) potSamples[i] = v;
  potIdx = 0;
}

int readSmoothedPot() {
  potSamples[potIdx] = analogRead(POT_PIN);
  potIdx = (potIdx + 1) % POT_SMOOTH_N;
  long sum = 0;
  for (int i = 0; i < POT_SMOOTH_N; i++) sum += potSamples[i];
  return (int)(sum / POT_SMOOTH_N);
}

PotCmd interpretPot(int val) {
  PotCmd c;
  c.running = false;
  c.forward = true;
  c.rpm     = 0;

  if (val > POT_CENTER + POT_DEADZONE) {
    c.running = true;
    c.forward = true;
    c.rpm     = map(val, POT_CENTER + POT_DEADZONE, 4095, 0, MAX_RPM);
  } else if (val < POT_CENTER - POT_DEADZONE) {
    c.running = true;
    c.forward = false;
    c.rpm     = map(val, POT_CENTER - POT_DEADZONE, 0, 0, MAX_RPM);
  }

  c.rpm = constrain(c.rpm, 0, MAX_RPM);
  return c;
}

// ---------------------------------------------------------------------------
// Arduino command helpers
// ---------------------------------------------------------------------------

void sendStop() {
  if (!lastSentStop) {
    Serial2.print("<STOP>\n");
    lastSentStop = true;
    lastSentRPM  = 0;
  }
}

void sendRun(bool fwd, int rpm, bool force) {
  rpm = constrain(rpm, 1, MAX_RPM);
  bool changed = (rpm != lastSentRPM) || (fwd != lastSentForward) || lastSentStop;
  if (force || changed) {
    Serial2.print("<RUN,");
    Serial2.print(fwd ? "F" : "B");
    Serial2.print(",");
    Serial2.print(rpm);
    Serial2.print(">\n");
    lastSentRPM     = rpm;
    lastSentForward = fwd;
    lastSentStop    = false;
  }
}

void sendGoto(int deg, int rpm) {
  rpm = constrain(rpm, 5, MAX_RPM);
  Serial2.print("<GOTO,");
  Serial2.print(deg);
  Serial2.print(",");
  Serial2.print(rpm);
  Serial2.print(">\n");
  lastSentStop = false;
  lastSentRPM  = rpm;
}

// ---------------------------------------------------------------------------
// LCD helper
// ---------------------------------------------------------------------------

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

  switch (sysMode) {
    case SYS_ESTOP:
      row0 = "!!! E-STOP !!!";
      row1 = "Motor LOCKED";
      break;

    case SYS_APP:
      if (!bleConnected) {
        row0 = "APP: No BLE";
      } else if (dispRunning) {
        row0 = "APP " + String(dispForward ? "FWD " : "REV ") + String(dispRPM) + "RPM";
      } else {
        row0 = "APP: IDLE";
      }
      row1 = "Pos:" + String(reportedPosition) + "deg";
      break;

    case SYS_POT:
      row0 = dispRunning
        ? "POT " + String(dispForward ? "FWD " : "REV ") + String(dispRPM) + "RPM"
        : "POT: IDLE";
      row1 = "Pos:" + String(reportedPosition) + "deg";
      break;
  }

  lcdRow(0, row0);
  lcdRow(1, row1);
}

// ---------------------------------------------------------------------------
// BLE Callbacks
// ---------------------------------------------------------------------------

class ServerCB : public BLEServerCallbacks {
  void onConnect(BLEServer*) {
    bleConnected = true;
  }
  void onDisconnect(BLEServer*) {
    bleConnected   = false;
    appRunning     = false;
    velCmdPending  = true;
    gotoCmdPending = false;
    BLEDevice::startAdvertising();
  }
};

class SpeedCB : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) {
    String v = c->getValue();
    if (v.length() > 0) {
      int pct        = constrain((uint8_t)v[0], 0, 100);
      appRPM         = map(pct, 0, 100, 0, MAX_RPM);
      appRunning     = (appRPM > 0);
      gotoCmdPending = false;
      velCmdPending  = true;
    }
  }
};

class DirCB : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) {
    String v = c->getValue();
    if (v.length() > 0) {
      uint8_t val = (uint8_t)v[0];
      if (val == 99) {
        lcdRow(0, "REBOOTING...");
        lcdRow(1, "Please wait...");
        delay(800);
        ESP.restart();
      } else {
        appForward    = (val == 0);
        velCmdPending = true;
      }
    }
  }
};

class TargetCB : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) {
    String v = c->getValue();
    if (v.length() >= 2) {
      int16_t deg    = (uint8_t)v[0] | ((uint8_t)v[1] << 8);
      appTargetDeg   = (int)deg;
      if (appRPM <= 0) appRPM = 40;
      appRunning     = true;
      gotoCmdPending = true;
      velCmdPending  = false;
    }
  }
};

// ---------------------------------------------------------------------------
// Setup
// ---------------------------------------------------------------------------

void setup() {
  Serial.begin(115200);
  Serial2.begin(9600, SERIAL_8N1, RXD2, TXD2);
  Serial2.setTimeout(10);

  pinMode(BTN_ESTOP, INPUT_PULLUP);
  pinMode(BTN_RESET, INPUT_PULLUP);

  Wire.begin();
  lcd.init();
  lcd.backlight();
  lcdRow(0, "System Starting");
  lcdRow(1, "Please wait...");

  initPot();

  BLEDevice::init("NEMA17-Controller");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCB());

  BLEService* svc = pServer->createService(SERVICE_UUID);

  BLECharacteristic* spd = svc->createCharacteristic(SPEED_CHAR_UUID,  BLECharacteristic::PROPERTY_WRITE);
  BLECharacteristic* dir = svc->createCharacteristic(DIR_CHAR_UUID,    BLECharacteristic::PROPERTY_WRITE);
  BLECharacteristic* tgt = svc->createCharacteristic(TARGET_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);

  spd->setCallbacks(new SpeedCB());
  dir->setCallbacks(new DirCB());
  tgt->setCallbacks(new TargetCB());

  pStatusChar = svc->createCharacteristic(STATUS_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pStatusChar->addDescriptor(new BLE2902());

  svc->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();

  delay(1000);
  lcd.clear();
}

// ---------------------------------------------------------------------------
// Loop
// ---------------------------------------------------------------------------

void loop() {
  unsigned long now = millis();

  // 1. Read position from Arduino
  while (Serial2.available()) {
    String line = Serial2.readStringUntil('\n');
    line.trim();
    if (line.startsWith("POS:")) {
      reportedPosition = line.substring(4).toInt();
    }
  }

  // 2. E-Stop button (debounced, toggles latch)
  if (digitalRead(BTN_ESTOP) == LOW && (now - lastEStopMs) > DEBOUNCE_MS) {
    lastEStopMs  = now;
    eStopLatched = !eStopLatched;
    lastSentStop = false;
    lastSentRPM  = -1;
  }

  // 3. Reset button (debounced, reboots ESP32)
  if (digitalRead(BTN_RESET) == LOW && (now - lastResetMs) > DEBOUNCE_MS) {
    lastResetMs = now;
    Serial2.print("<STOP>\n");
    delay(50);
    lcdRow(0, "SYSTEM REBOOTING");
    lcdRow(1, "Please wait...");
    delay(1200);
    ESP.restart();
  }

  // 4. Determine system mode
  prevSysMode = sysMode;

  if (eStopLatched) {
    sysMode = SYS_ESTOP;
  } else {
    sysMode = (bleConnected && appRunning) ? SYS_APP : SYS_POT;
  }

  bool modeChanged = (sysMode != prevSysMode);

  // 5. Execute mode
  dispRunning = false;
  dispForward = true;
  dispRPM     = 0;

  switch (sysMode) {

    case SYS_ESTOP:
      sendStop();
      break;

    case SYS_APP:
      if (gotoCmdPending) {
        int rpm = appRPM > 0 ? (int)appRPM : 40;
        sendGoto(appTargetDeg, rpm);
        gotoCmdPending = false;
        dispRunning    = true;
        dispForward    = (appTargetDeg >= (int)reportedPosition);
        dispRPM        = rpm;

      } else if (velCmdPending) {
        if (appRunning && appRPM > 0) {
          sendRun(appForward, appRPM, false);
          dispRunning = true;
          dispForward = appForward;
          dispRPM     = appRPM;
        } else {
          sendStop();
        }
        velCmdPending = false;

      } else {
        // No new command - update display from current app state.
        // Auto-clear appRunning when GOTO completes.
        if (appRunning && abs(reportedPosition - (long)appTargetDeg) <= 2) {
          appRunning = false;
        }
        dispRunning = appRunning && (appRPM > 0);
        dispForward = appForward;
        dispRPM     = dispRunning ? (int)appRPM : 0;
      }
      break;

    case SYS_POT: {
      int    potVal = readSmoothedPot();
      PotCmd pc     = interpretPot(potVal);

      if (pc.running) {
        sendRun(pc.forward, pc.rpm, modeChanged);
      } else {
        sendStop();
      }
      dispRunning = pc.running;
      dispForward = pc.forward;
      dispRPM     = pc.rpm;
      break;
    }
  }

  // 6. LCD
  updateLCD();

  // 7. BLE notification
  if (bleConnected && (now - lastNotifyMs) >= BLE_NOTIFY_MS) {
    lastNotifyMs = now;
    int speedPct = map(dispRPM, 0, MAX_RPM, 0, 100);
    String json = "{\"position\":"  + String(reportedPosition) +
                  ",\"speed\":"     + String(speedPct) +
                  ",\"running\":"   + String(dispRunning ? "true" : "false") +
                  ",\"battery\":85}";
    pStatusChar->setValue(json.c_str());
    pStatusChar->notify();
  }

  delay(20);
}
