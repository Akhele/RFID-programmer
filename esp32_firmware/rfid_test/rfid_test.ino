/*
 * Simple RFID Test Sketch
 * Use this to verify your RFID-RC522 module is working
 */

#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN 5
#define RST_PIN 22

MFRC522 mfrc522(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(115200);
  Serial.println("\n=== RFID-RC522 Test ===");
  
  SPI.begin();
  mfrc522.PCD_Init();
  
  Serial.println("\nChecking RFID module...");
  mfrc522.PCD_DumpVersionToSerial();
  
  byte version = mfrc522.PCD_ReadRegister(mfrc522.VersionReg);
  Serial.print("Firmware Version: 0x");
  Serial.print(version, HEX);
  
  if (version == 0x91 || version == 0x92) {
    Serial.println(" ✓ VALID - Module is working!");
  } else if (version == 0x00 || version == 0xFF) {
    Serial.println(" ✗ ERROR - No communication with RFID module!");
    Serial.println("\nTroubleshooting:");
    Serial.println("1. Check wiring (especially SPI pins)");
    Serial.println("2. Verify 3.3V power (NOT 5V!)");
    Serial.println("3. Check jumper wire connections");
  } else {
    Serial.println(" ? UNKNOWN - Check connections");
  }
  
  Serial.println("\n=== Wiring Guide ===");
  Serial.println("RFID-RC522 -> ESP32");
  Serial.println("SDA (SS)   -> GPIO 5");
  Serial.println("SCK        -> GPIO 18");
  Serial.println("MOSI       -> GPIO 23");
  Serial.println("MISO       -> GPIO 19");
  Serial.println("RST        -> GPIO 22");
  Serial.println("3.3V       -> 3.3V");
  Serial.println("GND        -> GND");
  Serial.println("\n===================\n");
  Serial.println("Place a card near the reader...\n");
}

void loop() {
  // Look for new cards
  if (!mfrc522.PICC_IsNewCardPresent()) {
    delay(100);
    return;
  }
  
  // Select one of the cards
  if (!mfrc522.PICC_ReadCardSerial()) {
    delay(100);
    return;
  }
  
  // Show UID
  Serial.println("==================");
  Serial.println("✓ CARD DETECTED!");
  Serial.println("==================");
  Serial.print("UID: ");
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    if (mfrc522.uid.uidByte[i] < 0x10) Serial.print("0");
    Serial.print(mfrc522.uid.uidByte[i], HEX);
    if (i < mfrc522.uid.size - 1) Serial.print(":");
  }
  Serial.println();
  
  Serial.print("Card Type: ");
  MFRC522::PICC_Type piccType = mfrc522.PICC_GetType(mfrc522.uid.sak);
  Serial.println(mfrc522.PICC_GetTypeName(piccType));
  
  Serial.println("==================\n");
  
  delay(2000);
  mfrc522.PICC_HaltA();
}


