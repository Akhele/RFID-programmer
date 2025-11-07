# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Hardware Setup (2 minutes)

Connect RFID-RC522 to ESP32:

```
RFID-RC522  →  ESP32
----------     -----
SDA/SS      →  GPIO 5
SCK         →  GPIO 18
MOSI        →  GPIO 23
MISO        →  GPIO 19
RST         →  GPIO 22
3.3V        →  3.3V (NOT 5V!)
GND         →  GND
```

### Step 2: Upload ESP32 Firmware (2 minutes)

1. Open `esp32_firmware/rfid_programmer.ino` in Arduino IDE
2. Install MFRC522 library: **Sketch → Include Library → Manage Libraries** → Search "MFRC522"
3. Select your ESP32 board: **Tools → Board → ESP32 Dev Module**
4. Select port: **Tools → Port → [Your ESP32 Port]**
5. Click **Upload** button
6. Open **Serial Monitor** (115200 baud) to verify: "BLE service started"

### Step 3: Run Flutter App (1 minute)

```bash
cd RFID-programmer
flutter pub get
flutter run
```

### Step 4: Connect & Use

1. **In the app:**
   - Tap "Scan for Devices"
   - Find "ESP32-RFID" and tap "Connect"
   
2. **Read a card:**
   - Tap "RFID Operations"
   - Place card on reader
   - Tap "Read Card"
   
3. **Write to card:**
   - After reading, tap "Write"
   - Enter text or hex data
   - Tap "Write to Card"

## ✅ Checklist

- [ ] RFID-RC522 connected to 3.3V (NOT 5V)
- [ ] All 7 wires connected correctly
- [ ] MFRC522 library installed in Arduino IDE
- [ ] ESP32 firmware uploaded successfully
- [ ] Serial Monitor shows "BLE service started"
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Bluetooth permissions granted on phone
- [ ] ESP32-RFID appears in device list

## ⚠️ Common Issues

| Issue | Solution |
|-------|----------|
| "No card detected" | Check wiring, use 3.3V, place card flat |
| ESP32 not found | Check Serial Monitor, restart ESP32 |
| Can't connect | Grant Bluetooth & Location permissions |
| Upload failed | Hold BOOT button during upload |

## 📚 Need More Help?

- Full setup: See `SETUP_GUIDE.md`
- ESP32 firmware: See `esp32_firmware/README.md`
- Troubleshooting: See `SETUP_GUIDE.md` → Troubleshooting section

## 🎯 Test Cards

The firmware works with:
- ✅ MIFARE Classic 1K (most common)
- ✅ MIFARE Classic 4K
- ⚠️ MIFARE Ultralight (limited support)
- ❌ MIFARE DESFire (not supported)

Enjoy! 🎉

