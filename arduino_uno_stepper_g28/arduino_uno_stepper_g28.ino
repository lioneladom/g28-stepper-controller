#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <AFMotor.h>
#include <SoftwareSerial.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
AF_Stepper motor(200, 1);

// Bluetooth module on pins 9 (RX) and 10 (TX) at 9600 baud
SoftwareSerial BTSerial(9, 10); 

const int potPin = A0;
const int dirButtonPin = 2;   
const int stopButtonPin = 13; 

// Operating Modes
#define MODE_VELOCITY 1
#define MODE_POSITION 2

int currentOperatingMode = MODE_VELOCITY;

bool directionForward = true;
bool emergencyStopped = false;

int lastDirButtonState = HIGH;
int lastStopButtonState = HIGH;
int lastMappedSpeed = -1;
bool directionChanged = true;

// Velocity Control & Noise Filter
int btSpeed = -1; 
bool useBtSpeed = false;
int lastPotRawSpeed = -1;
int filteredPotValue = 0;

// Position Controller Tracking (200 steps/rev -> 1.8 degrees/step)
long currentPositionSteps = 0; 
long targetPositionSteps = 0;
bool positionMoveActive = false;

unsigned long lastStatusBroadcastTime = 0;

int getAngleDegrees() {
  long angle = (currentPositionSteps * 360) / 200;
  angle = angle % 360;
  if (angle < 0) angle += 360;
  return (int)angle;
}

void sendStatusTelemetry(int currentSpeed) {
  BTSerial.print("<STATUS,");
  BTSerial.print(emergencyStopped ? 0 : currentSpeed);
  BTSerial.print(",");
  BTSerial.print(directionForward ? 1 : 0);
  BTSerial.print(",");
  BTSerial.print(emergencyStopped ? 1 : 0);
  BTSerial.print(",");
  BTSerial.print(getAngleDegrees());
  BTSerial.print(",");
  BTSerial.print(currentOperatingMode);
  BTSerial.println(">");
}

void updateLcdDisplay(int speed) {
  if (emergencyStopped) {
    lcd.setCursor(0, 0);
    lcd.print("                "); 
    lcd.setCursor(0, 1);
    lcd.print(" EMERGENCY STOP ");
    return;
  }

  if (currentOperatingMode == MODE_VELOCITY) {
    lcd.setCursor(0, 0);
    lcd.print("Speed: ");
    lcd.print(speed);
    lcd.print(" RPM   ");

    lcd.setCursor(0, 1);
    lcd.print("Mode: ");
    lcd.print(directionForward ? "Forward " : "Reverse ");
  } 
  else if (currentOperatingMode == MODE_POSITION) {
    lcd.setCursor(0, 0);
    lcd.print("Pos: ");
    lcd.print(getAngleDegrees());
    lcd.print((char)223); // Degree symbol
    lcd.print(" Target ");

    lcd.setCursor(0, 1);
    lcd.print("Mode: Angle GO  ");
  }
}

void setup() {
  Wire.begin();
  lcd.init();                      
  lcd.backlight();
  
  pinMode(dirButtonPin, INPUT_PULLUP);  
  pinMode(stopButtonPin, INPUT_PULLUP); 
  
  BTSerial.begin(9600);
  
  lcd.setCursor(0, 0);
  lcd.print("Speed: 0 RPM    ");
  lcd.setCursor(0, 1);
  lcd.print("Mode: Forward   ");

  filteredPotValue = analogRead(potPin);
}

void loop() {
  bool stateNeedsBroadcast = false;

  // 1. Process Bluetooth incoming commands
  if (BTSerial.available() > 0) {
    char cmd = BTSerial.peek();
    
    if (cmd == 'M' || cmd == 'm') {
      BTSerial.read(); // consume 'M'
      int modeVal = BTSerial.parseInt();
      if (modeVal == 1 || modeVal == 2) {
        currentOperatingMode = modeVal;
        positionMoveActive = false;
        motor.release();
        updateLcdDisplay(0);
        stateNeedsBroadcast = true;
      }
    }
    else if (cmd == 'F' || cmd == 'f') {
      BTSerial.read();
      directionForward = true;
      directionChanged = true;
      positionMoveActive = false;
      stateNeedsBroadcast = true;
    } 
    else if (cmd == 'R' || cmd == 'r') {
      BTSerial.read();
      directionForward = false;
      directionChanged = true;
      positionMoveActive = false;
      stateNeedsBroadcast = true;
    } 
    else if (cmd == 'S' || cmd == 's') {
      BTSerial.read();
      emergencyStopped = !emergencyStopped;
      positionMoveActive = false;
      motor.release();
      updateLcdDisplay(0);
      stateNeedsBroadcast = true;
    }
    else if (cmd == 'V' || cmd == 'v') {
      BTSerial.read(); // consume 'V'
      int val = BTSerial.parseInt(); // read target speed (0 - 80 RPM)
      btSpeed = constrain(val, 0, 80);
      useBtSpeed = true;
      stateNeedsBroadcast = true;
    }
    else if (cmd == 'G' || cmd == 'g') {
      BTSerial.read(); // consume 'G'
      int degrees = BTSerial.parseInt(); // Target angle movement (e.g., G90 or G-45)
      long stepsToMove = (degrees * 200L) / 360L;
      targetPositionSteps = currentPositionSteps + stepsToMove;
      positionMoveActive = true;
      currentOperatingMode = MODE_POSITION;
      stateNeedsBroadcast = true;
    }
    else if (cmd == 'Z' || cmd == 'z') {
      BTSerial.read(); // consume 'Z'
      currentPositionSteps = 0; // Tare / Set current position as 0 degrees origin
      targetPositionSteps = 0;
      positionMoveActive = false;
      updateLcdDisplay(0);
      stateNeedsBroadcast = true;
    }
    else {
      BTSerial.read(); // clear unknown byte
    }
  }

  // 2. Check Emergency Stop Button (Physical Pin 13)
  int stopState = digitalRead(stopButtonPin);
  if (stopState == LOW && lastStopButtonState == HIGH) {
    emergencyStopped = !emergencyStopped; 
    positionMoveActive = false;
    motor.release();
    updateLcdDisplay(0);
    stateNeedsBroadcast = true;
    delay(200); 
  }
  lastStopButtonState = stopState;

  // 3. Handle Emergency Stop Condition
  if (emergencyStopped) {
    motor.release();
    positionMoveActive = false;
    updateLcdDisplay(0);
    
    if (stateNeedsBroadcast || millis() - lastStatusBroadcastTime > 500) {
      sendStatusTelemetry(0);
      lastStatusBroadcastTime = millis();
    }
    return; 
  }

  // 4. Handle Hardware Pin 2 Direction Button (Only active in Velocity Mode)
  int dirState = digitalRead(dirButtonPin);
  if (dirState == LOW && lastDirButtonState == HIGH && currentOperatingMode == MODE_VELOCITY) {
    directionForward = !directionForward;
    directionChanged = true;
    stateNeedsBroadcast = true;
    delay(200);
  }
  lastDirButtonState = dirState;

  // 5. Read hardware potentiometer (Only active in Velocity Mode)
  int rawPot = analogRead(potPin);
  filteredPotValue = (filteredPotValue * 4 + rawPot) / 5;
  int potSpeed = map(filteredPotValue, 0, 1023, 0, 80);
  if (potSpeed < 3) potSpeed = 0;

  if (currentOperatingMode == MODE_VELOCITY) {
    if (lastPotRawSpeed != -1 && abs(potSpeed - lastPotRawSpeed) >= 5) {
      useBtSpeed = false;
    }
  }
  lastPotRawSpeed = potSpeed;

  // 6. MODE 2: POSITION CONTROLLER EXECUTION
  if (currentOperatingMode == MODE_POSITION) {
    if (positionMoveActive) {
      if (currentPositionSteps != targetPositionSteps) {
        int moveSpeed = (btSpeed > 0) ? btSpeed : 45; // Default position move speed 45 RPM
        motor.setSpeed(moveSpeed);

        if (targetPositionSteps > currentPositionSteps) {
          directionForward = true;
          motor.step(1, FORWARD, SINGLE);
          currentPositionSteps++;
        } else {
          directionForward = false;
          motor.step(1, BACKWARD, SINGLE);
          currentPositionSteps--;
        }

        updateLcdDisplay(moveSpeed);

        if (millis() - lastStatusBroadcastTime > 200) {
          sendStatusTelemetry(moveSpeed);
          lastStatusBroadcastTime = millis();
        }
        return; // Complete position stepping
      } else {
        // Reached target angle!
        positionMoveActive = false;
        motor.release();
        updateLcdDisplay(0);
        stateNeedsBroadcast = true;
      }
    } else {
      motor.release();
    }

    if (stateNeedsBroadcast || millis() - lastStatusBroadcastTime > 500) {
      sendStatusTelemetry(0);
      lastStatusBroadcastTime = millis();
    }
    return;
  }

  // 7. MODE 1: VELOCITY CONTROLLER EXECUTION
  int motorSpeed = useBtSpeed ? btSpeed : potSpeed;

  if (motorSpeed != lastMappedSpeed || directionChanged) {
    updateLcdDisplay(motorSpeed);
    lastMappedSpeed = motorSpeed;
    directionChanged = false;
    stateNeedsBroadcast = true;
  }

  if (stateNeedsBroadcast || millis() - lastStatusBroadcastTime > 500) {
    sendStatusTelemetry(motorSpeed);
    lastStatusBroadcastTime = millis();
  }

  if (motorSpeed > 0) {
    motor.setSpeed(motorSpeed);
    if (directionForward) {
      motor.step(2, FORWARD, SINGLE);
      currentPositionSteps += 2;
    } else {
      motor.step(2, BACKWARD, SINGLE);
      currentPositionSteps -= 2;
    }
  } else {
    motor.release();
  }
}
