# RFID Programmer

A Flutter application for reading and programming RFID cards using ESP32 and RFID-RC522 module via Bluetooth.

## Features

- 📱 Bluetooth connectivity with ESP32
- 🔍 Scan and detect RFID cards
- 📖 Read RFID card data
- ✍️ Write data to RFID cards
- 🔄 Format RFID cards
- 📊 Display card UID and data blocks

## Hardware Requirements

- ESP32 development board
- RFID-RC522 module
- RFID cards (MIFARE Classic 1K recommended)
- Connecting wires

## ESP32 Wiring

Connect RFID-RC522 to ESP32:
- SDA/SS  → GPIO 5
- SCK     → GPIO 18
- MOSI    → GPIO 23
- MISO    → GPIO 19
- IRQ     → Not connected
- GND     → GND
- RST     → GPIO 22
- 3.3V    → 3.3V

## Setup

### Flutter App

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

### ESP32 Firmware

1. Open `esp32_firmware/rfid_programmer.ino` in Arduino IDE
2. Install required libraries:
   - MFRC522 by GithubCommunity
   - ESP32 BLE Arduino (included in ESP32 board package)
3. Select your ESP32 board and port
4. Upload the firmware

## Usage

1. Upload firmware to ESP32
2. Power on the ESP32
3. Open the Flutter app
4. Grant Bluetooth permissions
5. Scan for devices and connect to "ESP32-RFID"
6. Use the app to read/write RFID cards

## Communication Protocol

Commands sent from app to ESP32:
- `READ` - Read RFID card
- `WRITE:sector:block:data` - Write data to card
- `FORMAT` - Format card with default keys
- `SCAN` - Check for card presence

ESP32 responses:
- `OK:message` - Success
- `ERROR:message` - Error occurred
- `UID:xxxxxxxxxxxx` - Card UID
- `DATA:block:hexdata` - Block data
- `NO_CARD` - No card detected

## License

MIT License

