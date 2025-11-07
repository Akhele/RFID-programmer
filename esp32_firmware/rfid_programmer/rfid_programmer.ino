/*
 * ESP32 RFID Programmer Firmware
 * 
 * This firmware allows ESP32 to communicate with RFID-RC522 module
 * and expose functionality via Bluetooth Low Energy (BLE)
 * 
 * Hardware connections:
 * RFID-RC522 to ESP32:
 * - SDA/SS  → GPIO 5
 * - SCK     → GPIO 18
 * - MOSI    → GPIO 23
 * - MISO    → GPIO 19
 * - RST     → GPIO 22
 * - 3.3V    → 3.3V
 * - GND     → GND
 */

#include <SPI.h>
#include <MFRC522.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// RFID Pin definitions
#define SS_PIN    5
#define RST_PIN   22

// BLE UUIDs (Nordic UART Service)
#define SERVICE_UUID           "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID_RX "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID_TX "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

// RFID objects
MFRC522 mfrc522(SS_PIN, RST_PIN);
MFRC522::MIFARE_Key key;

// BLE objects
BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Command buffer
String commandBuffer = "";

// Forward declarations
void sendResponse(String message);
void processCommand(String command);
void handleScan();
void handleRead();
void handleWrite(String command);
void handleFormat();
void handleAuth(String command);

// BLE Server callbacks
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Device connected");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Device disconnected");
    }
};

// BLE Receive callbacks
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = String(pCharacteristic->getValue().c_str());

      if (rxValue.length() > 0) {
        for (int i = 0; i < rxValue.length(); i++) {
          char c = rxValue[i];
          if (c == '\n') {
            processCommand(commandBuffer);
            commandBuffer = "";
          } else {
            commandBuffer += c;
          }
        }
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 RFID Programmer Starting...");

  // Initialize SPI bus
  SPI.begin();
  
  // Initialize RFID reader
  mfrc522.PCD_Init();
  delay(4);
  mfrc522.PCD_DumpVersionToSerial();
  
  // Prepare the default key (FFFFFFFFFFFF)
  for (byte i = 0; i < 6; i++) {
    key.keyByte[i] = 0xFF;
  }

  // Initialize BLE
  BLEDevice::init("ESP32-RFID");
  
  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create BLE Characteristics
  pTxCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID_TX,
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
  pTxCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
                                           CHARACTERISTIC_UUID_RX,
                                           BLECharacteristic::PROPERTY_WRITE
                                         );
  pRxCharacteristic->setCallbacks(new MyCallbacks());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE service started. Waiting for connections...");
  sendResponse("OK:System ready");
}

void loop() {
  // Handle BLE connection state
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Start advertising");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
  
  delay(10);
}

void sendResponse(String message) {
  if (deviceConnected) {
    pTxCharacteristic->setValue(message.c_str());
    pTxCharacteristic->notify();
  }
  Serial.println("TX: " + message);
}

void processCommand(String command) {
  Serial.println("RX: " + command);
  command.trim();
  
  if (command == "SCAN") {
    handleScan();
  } else if (command == "READ") {
    handleRead();
  } else if (command.startsWith("WRITE:")) {
    handleWrite(command);
  } else if (command == "FORMAT") {
    handleFormat();
  } else if (command.startsWith("AUTH:")) {
    handleAuth(command);
  } else {
    sendResponse("ERROR:Unknown command");
  }
}

void handleScan() {
  // Check if card is present
  if (!mfrc522.PICC_IsNewCardPresent()) {
    sendResponse("NO_CARD");
    return;
  }
  
  if (!mfrc522.PICC_ReadCardSerial()) {
    sendResponse("ERROR:Failed to read card serial");
    return;
  }
  
  // Get UID
  String uid = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    uid += String(mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
    uid += String(mfrc522.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  
  sendResponse("UID:" + uid);
  sendResponse("OK:Card detected");
  
  mfrc522.PICC_HaltA();
}

void handleRead() {
  // Check if card is present
  if (!mfrc522.PICC_IsNewCardPresent()) {
    sendResponse("NO_CARD");
    return;
  }
  
  if (!mfrc522.PICC_ReadCardSerial()) {
    sendResponse("ERROR:Failed to read card serial");
    return;
  }
  
  // Send UID
  String uid = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    uid += String(mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
    uid += String(mfrc522.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  sendResponse("UID:" + uid);
  
  // Read all sectors (0-15 for MIFARE Classic 1K)
  for (byte sector = 0; sector < 16; sector++) {
    // Read blocks in this sector (4 blocks per sector)
    for (byte blockOffset = 0; blockOffset < 4; blockOffset++) {
      byte blockAddr = sector * 4 + blockOffset;
      
      // Authenticate
      MFRC522::StatusCode status = mfrc522.PCD_Authenticate(
        MFRC522::PICC_CMD_MF_AUTH_KEY_A, 
        blockAddr, 
        &key, 
        &(mfrc522.uid)
      );
      
      if (status != MFRC522::STATUS_OK) {
        continue; // Skip blocks that can't be authenticated
      }
      
      // Read block
      byte buffer[18];
      byte size = sizeof(buffer);
      status = mfrc522.MIFARE_Read(blockAddr, buffer, &size);
      
      if (status == MFRC522::STATUS_OK) {
        String data = "DATA:" + String(blockAddr) + ":";
        for (byte i = 0; i < 16; i++) {
          if (buffer[i] < 0x10) data += "0";
          data += String(buffer[i], HEX);
        }
        data.toUpperCase();
        sendResponse(data);
      }
    }
  }
  
  sendResponse("READ_COMPLETE");
  sendResponse("OK:Card read successfully");
  
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

void handleWrite(String command) {
  // Parse command: WRITE:sector:block:hexdata
  int firstColon = command.indexOf(':', 6);
  int secondColon = command.indexOf(':', firstColon + 1);
  int thirdColon = command.indexOf(':', secondColon + 1);
  
  if (firstColon == -1 || secondColon == -1 || thirdColon == -1) {
    sendResponse("ERROR:Invalid write command format");
    return;
  }
  
  int sector = command.substring(6, firstColon).toInt();
  int blockOffset = command.substring(firstColon + 1, secondColon).toInt();
  String hexData = command.substring(secondColon + 1);
  hexData.trim();
  
  // Validate
  if (sector < 0 || sector > 15) {
    sendResponse("ERROR:Invalid sector");
    return;
  }
  
  if (blockOffset < 0 || blockOffset > 2) {
    sendResponse("ERROR:Invalid block (use 0-2, block 3 is reserved)");
    return;
  }
  
  if (hexData.length() != 32) {
    sendResponse("ERROR:Data must be 32 hex characters");
    return;
  }
  
  // Check if card is present
  if (!mfrc522.PICC_IsNewCardPresent()) {
    sendResponse("NO_CARD");
    return;
  }
  
  if (!mfrc522.PICC_ReadCardSerial()) {
    sendResponse("ERROR:Failed to read card serial");
    return;
  }
  
  byte blockAddr = sector * 4 + blockOffset;
  
  // Authenticate
  MFRC522::StatusCode status = mfrc522.PCD_Authenticate(
    MFRC522::PICC_CMD_MF_AUTH_KEY_A,
    blockAddr,
    &key,
    &(mfrc522.uid)
  );
  
  if (status != MFRC522::STATUS_OK) {
    sendResponse("ERROR:Authentication failed");
    mfrc522.PICC_HaltA();
    return;
  }
  
  // Convert hex string to byte array
  byte dataBlock[16];
  for (int i = 0; i < 16; i++) {
    String byteString = hexData.substring(i * 2, i * 2 + 2);
    dataBlock[i] = (byte)strtol(byteString.c_str(), NULL, 16);
  }
  
  // Write to card
  status = mfrc522.MIFARE_Write(blockAddr, dataBlock, 16);
  
  if (status != MFRC522::STATUS_OK) {
    sendResponse("ERROR:Write failed - " + String(mfrc522.GetStatusCodeName(status)));
  } else {
    sendResponse("OK:Data written to block " + String(blockAddr));
  }
  
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

void handleFormat() {
  // Check if card is present
  if (!mfrc522.PICC_IsNewCardPresent()) {
    sendResponse("NO_CARD");
    return;
  }
  
  if (!mfrc522.PICC_ReadCardSerial()) {
    sendResponse("ERROR:Failed to read card serial");
    return;
  }
  
  sendResponse("OK:Formatting card...");
  
  // Format all data blocks (not sector trailers)
  byte emptyBlock[16] = {0};
  int blocksFormatted = 0;
  
  for (byte sector = 1; sector < 16; sector++) { // Skip sector 0 (manufacturer block)
    for (byte blockOffset = 0; blockOffset < 3; blockOffset++) { // Skip trailer block
      byte blockAddr = sector * 4 + blockOffset;
      
      // Authenticate
      MFRC522::StatusCode status = mfrc522.PCD_Authenticate(
        MFRC522::PICC_CMD_MF_AUTH_KEY_A,
        blockAddr,
        &key,
        &(mfrc522.uid)
      );
      
      if (status != MFRC522::STATUS_OK) {
        continue;
      }
      
      // Write empty block
      status = mfrc522.MIFARE_Write(blockAddr, emptyBlock, 16);
      if (status == MFRC522::STATUS_OK) {
        blocksFormatted++;
      }
    }
  }
  
  sendResponse("OK:Formatted " + String(blocksFormatted) + " blocks");
  
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

void handleAuth(String command) {
  // Parse command: AUTH:sector:keyType:key
  // This is for future advanced functionality
  sendResponse("OK:Using default authentication");
}

