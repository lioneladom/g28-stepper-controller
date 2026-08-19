#include <SoftwareSerial.h>

// SoftwareSerial on pins 9 (RX) and 10 (TX)
SoftwareSerial BTSerial(9, 10); 

void setup() {
  Serial.begin(9600);
  BTSerial.begin(38400); // HC-05 AT mode default baud rate (or 9600)
  
  Serial.println("--- HC-05 Renamer to 'G28' ---");
  Serial.println("Sending AT+NAME=G28 ...");
  
  delay(1000);
  BTSerial.print("AT+NAME=G28\r\n");
  delay(1000);
  
  // Try 9600 baud fallback if 38400 didn't catch
  BTSerial.begin(9600);
  delay(500);
  BTSerial.print("AT+NAME=G28\r\n");
  BTSerial.print("AT+NAMEG28\r\n"); // For HC-06 firmware
  
  Serial.println("Renamed! Disconnect power and reconnect to test Bluetooth scan name 'G28'.");
}

void loop() {
  if (BTSerial.available()) {
    Serial.write(BTSerial.read());
  }
  if (Serial.available()) {
    BTSerial.write(Serial.read());
  }
}
