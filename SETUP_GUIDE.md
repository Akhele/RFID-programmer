# RFID Programmer - Complete Setup Guide

## 📋 Table of Contents
1. [Hardware Requirements](#hardware-requirements)
2. [Software Requirements](#software-requirements)
3. [Hardware Assembly](#hardware-assembly)
4. [ESP32 Firmware Setup](#esp32-firmware-setup)
5. [Flutter App Setup](#flutter-app-setup)
6. [Testing & Usage](#testing--usage)
7. [Troubleshooting](#troubleshooting)

---

## 🔧 Hardware Requirements

### Components Needed
- **ESP32 Development Board** (any variant with BLE support)
- **RFID-RC522 Module**
- **MIFARE Classic 1K Cards** (or compatible RFID cards)
- **Jumper Wires** (Female-to-Female or Male-to-Female)
- **USB Cable** (for ESP32 programming)
- **Power Supply** (USB or external 3.3V/5V)

### Optional Components
- Breadboard for prototyping
- LED and resistor for status indication
- Buzzer for audio feedback

---

## 💻 Software Requirements

### For ESP32 Development
1. **Arduino IDE** (v1.8.19 or v2.x)
   - Download from: https://www.arduino.cc/en/software

2. **ESP32 Board Support**
   - In Arduino IDE: File → Preferences
   - Add to "Additional Board Manager URLs":
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Go to: Tools → Board → Boards Manager
   - Search "ESP32" and install "ESP32 by Espressif Systems"

3. **Required Arduino Libraries**
   - **MFRC522** by GithubCommunity (v1.4.10 or later)
     - Install via: Sketch → Include Library → Manage Libraries
     - Search "MFRC522" and install

### For Flutter App Development
1. **Flutter SDK** (3.0.0 or later)
   - Download from: https://flutter.dev/docs/get-started/install

2. **Android Studio** or **Xcode** (for iOS)
   - Android Studio: https://developer.android.com/studio
   - Xcode: Available on Mac App Store

3. **Physical Device** (Recommended for Bluetooth testing)
   - Android 5.0+ (API 21+)
   - iOS 12.0+

---

## 🔌 Hardware Assembly

### RFID-RC522 to ESP32 Wiring

Connect the RFID-RC522 module to ESP32 as follows:

| RFID-RC522 Pin | ESP32 Pin | Description |
|----------------|-----------|-------------|
| SDA (SS)       | GPIO 5    | Chip Select |
| SCK            | GPIO 18   | SPI Clock   |
| MOSI           | GPIO 23   | Master Out  |
| MISO           | GPIO 19   | Master In   |
| IRQ            | -         | Not used    |
| GND            | GND       | Ground      |
| RST            | GPIO 22   | Reset       |
| 3.3V           | 3.3V      | Power       |

### Wiring Diagram

```
ESP32                    RFID-RC522
-----                    ----------
GPIO 5  ────────────────→ SDA/SS
GPIO 18 ────────────────→ SCK
GPIO 23 ────────────────→ MOSI
GPIO 19 ────────────────→ MISO
GPIO 22 ────────────────→ RST
3.3V    ────────────────→ 3.3V
GND     ────────────────→ GND
```

### ⚠️ Important Notes
- Use **3.3V** power supply for RFID-RC522 (NOT 5V!)
- Ensure good connections (poor connections cause intermittent issues)
- Keep wires short to minimize interference
- Double-check connections before powering on

---

## 🔧 ESP32 Firmware Setup

### Step 1: Open Arduino IDE

1. Launch Arduino IDE
2. Open the firmware file:
   - File → Open
   - Navigate to: `esp32_firmware/rfid_programmer.ino`

### Step 2: Configure Board Settings

1. Go to: **Tools → Board**
2. Select your ESP32 board (e.g., "ESP32 Dev Module")
3. Configure the following settings:
   ```
   Board: "ESP32 Dev Module"
   Upload Speed: "921600"
   CPU Frequency: "240MHz (WiFi/BT)"
   Flash Frequency: "80MHz"
   Flash Mode: "QIO"
   Flash Size: "4MB (32Mb)"
   Partition Scheme: "Default 4MB with spiffs"
   Core Debug Level: "None"
   Port: [Select your COM/Serial port]
   ```

### Step 3: Verify Libraries

1. Go to: **Sketch → Include Library → Manage Libraries**
2. Verify installed:
   - ✅ MFRC522 (by GithubCommunity)
3. ESP32 BLE libraries are included with the board package

### Step 4: Upload Firmware

1. Connect ESP32 to computer via USB
2. Select correct port: **Tools → Port → [Your ESP32 Port]**
3. Click **Upload** button (→) or Sketch → Upload
4. Wait for upload to complete
5. Open **Serial Monitor** (Tools → Serial Monitor)
6. Set baud rate to **115200**
7. Press ESP32 reset button

### Expected Output
```
ESP32 RFID Programmer Starting...
MFRC522 Software Version: 0x92 = v2.0
BLE service started. Waiting for connections...
TX: OK:System ready
```

### Troubleshooting Upload Issues

**Issue: "Failed to connect"**
- Hold the BOOT button while uploading
- Check USB cable (use data cable, not charge-only)
- Try different USB port
- Lower upload speed (115200 instead of 921600)

**Issue: "Port not found"**
- Install CH340/CP2102 USB drivers
- Check device manager (Windows) or ls /dev/tty* (Mac/Linux)

---

## 📱 Flutter App Setup

### Step 1: Verify Flutter Installation

```bash
flutter doctor
```

Ensure all required components are installed.

### Step 2: Install Dependencies

Navigate to project directory:
```bash
cd RFID-programmer
flutter pub get
```

### Step 3: Platform-Specific Setup

#### Android Setup

1. **Enable Developer Mode** on your Android device:
   - Settings → About Phone
   - Tap "Build Number" 7 times

2. **Enable USB Debugging**:
   - Settings → Developer Options
   - Enable "USB Debugging"

3. **Connect Device** and verify:
   ```bash
   flutter devices
   ```

#### iOS Setup (Mac only)

1. **Open Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Set Team**:
   - Select project in navigator
   - Under "Signing & Capabilities"
   - Select your development team

3. **Connect Device** and verify:
   ```bash
   flutter devices
   ```

### Step 4: Run the App

```bash
flutter run
```

Or use your IDE:
- **VS Code**: Press F5
- **Android Studio**: Click Run button

---

## 🎯 Testing & Usage

### Initial Connection Test

1. **Power on ESP32**
   - Ensure firmware is uploaded
   - Check Serial Monitor for "BLE service started"

2. **Open Flutter App**
   - Grant Bluetooth permissions when prompted
   - Grant Location permissions (required for BLE on Android)

3. **Scan for Devices**
   - Tap "Scan for Devices"
   - Look for "ESP32-RFID" in the list
   - Note the signal strength (RSSI)

4. **Connect to ESP32**
   - Tap "Connect" button
   - Wait for "Connected" message
   - Status should show "Connected to ESP32-RFID"

### Reading RFID Cards

1. **Navigate to RFID Operations**
   - From home screen, tap "RFID Operations"

2. **Read a Card**
   - Place RFID card on reader
   - Tap "Read Card" button
   - Wait for card data to appear

3. **View Card Data**
   - Card UID displayed at top
   - Expand blocks to see hex and ASCII data
   - Block numbers indicate sector/block position

### Writing to RFID Cards

1. **Read Card First**
   - Must read card before writing

2. **Tap "Write" Button**
   - Opens write screen

3. **Enter Data**
   - **Text Mode**: Enter up to 16 characters
   - **Hex Mode**: Enter 32 hex characters (16 bytes)

4. **Select Sector and Block**
   - Sector: 1-15 (sector 0 contains manufacturer data)
   - Block: 0-2 (block 3 is reserved for keys)

5. **Write to Card**
   - Place card on reader
   - Tap "Write to Card"
   - Wait for confirmation

### Formatting Cards

1. **From RFID Operations Screen**
   - Tap "Format" button
   - Confirm action

2. **Place Card on Reader**
   - All data blocks will be erased
   - Sector 0 (manufacturer block) is preserved
   - Process takes a few seconds

---

## 🔍 Troubleshooting

### Bluetooth Issues

**App can't find ESP32**
- ✅ Ensure ESP32 is powered on
- ✅ Check Serial Monitor for "BLE service started"
- ✅ Grant all Bluetooth permissions
- ✅ Enable Location services (Android)
- ✅ Close and reopen app
- ✅ Try restarting ESP32

**Connection drops frequently**
- ✅ Move devices closer (within 10m)
- ✅ Remove obstacles between devices
- ✅ Check ESP32 power supply (USB cable quality)
- ✅ Reduce WiFi interference

### RFID Reading Issues

**"No card detected" error**
- ✅ Check RFID wiring connections
- ✅ Use 3.3V (NOT 5V) power
- ✅ Place card flat on reader
- ✅ Try different card position
- ✅ Check card compatibility (MIFARE Classic 1K)

**"Authentication failed" error**
- ✅ Card may have custom keys
- ✅ Try formatting with default reader
- ✅ Use new/blank card

**Intermittent reads**
- ✅ Check SPI connections
- ✅ Shorten jumper wires
- ✅ Add 100nF capacitor between 3.3V and GND
- ✅ Improve power supply

### App Issues

**Permissions denied**
- ✅ Go to App Settings
- ✅ Manually grant Bluetooth permissions
- ✅ Manually grant Location permissions (Android)

**App crashes on startup**
- ✅ Run: `flutter clean && flutter pub get`
- ✅ Reinstall app
- ✅ Check logs: `flutter logs`

---

## 📊 MIFARE Classic 1K Card Structure

### Memory Layout

- **Total Size**: 1KB (1024 bytes)
- **Sectors**: 16 (numbered 0-15)
- **Blocks per Sector**: 4 (numbered 0-3)
- **Bytes per Block**: 16

### Block Types

1. **Data Blocks** (Blocks 0-2 in each sector)
   - Can store any data
   - 16 bytes each

2. **Sector Trailer** (Block 3 in each sector)
   - Contains Key A, Access Bits, Key B
   - Cannot be overwritten without correct keys
   - Protected for card security

3. **Manufacturer Block** (Sector 0, Block 0)
   - Contains UID and manufacturer data
   - Read-only, cannot be modified

### Example Card Layout

```
Sector 0:
  Block 0: [UID + Manufacturer Data] (READ-ONLY)
  Block 1: [User Data]
  Block 2: [User Data]
  Block 3: [Keys & Access Bits] (PROTECTED)

Sector 1-15:
  Block 0: [User Data]
  Block 1: [User Data]
  Block 2: [User Data]
  Block 3: [Keys & Access Bits] (PROTECTED)
```

---

## 🔐 Security Notes

1. **Default Keys**: FFFFFFFFFFFF (not secure for production)
2. **Change Keys**: Use RFID tools to set custom keys
3. **Access Control**: Configure access bits for protection
4. **Physical Security**: RFID cards can be cloned
5. **Use Cases**: Best for non-critical applications

---

## 🚀 Advanced Features

### Custom Authentication Keys

Modify the firmware to use custom keys:

```cpp
// In rfid_programmer.ino
MFRC522::MIFARE_Key customKey;
customKey.keyByte[0] = 0xAB;
customKey.keyByte[1] = 0xCD;
// ... set all 6 bytes
```

### Extended Command Set

Add custom commands by modifying `processCommand()` function:

```cpp
else if (command == "CUSTOM") {
  handleCustomCommand();
}
```

---

## 📞 Support & Resources

### Documentation
- MFRC522 Datasheet: [NXP Official Site]
- ESP32 Reference: [Espressif Documentation]
- Flutter Blue Plus: [pub.dev/packages/flutter_blue_plus]

### Common Issues
- Check GitHub Issues for known problems
- ESP32 forum: esp32.com
- Flutter community: flutter.dev/community

---

## 📝 License

MIT License - See LICENSE file for details

---

## ✨ Features Summary

✅ Bluetooth LE connectivity
✅ RFID card reading (all sectors)
✅ RFID card writing (text/hex modes)
✅ Card formatting
✅ UID extraction
✅ Hex and ASCII data display
✅ Real-time response logging
✅ Material Design 3 UI
✅ Cross-platform (Android/iOS)

---

**Enjoy your RFID programming!** 🎉

