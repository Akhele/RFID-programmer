# RFID Card Not Detected - Troubleshooting Guide

## 🔍 Quick Checks

### 1. Verify RFID-RC522 Wiring

**Double-check all connections:**

```
RFID-RC522  →  ESP32
──────────     ─────
SDA (SS)    →  GPIO 5
SCK         →  GPIO 18
MOSI        →  GPIO 23
MISO        →  GPIO 19
RST         →  GPIO 22
3.3V        →  3.3V  ⚠️ IMPORTANT: NOT 5V!
GND         →  GND
```

**Common Mistakes:**
- ❌ Using 5V instead of 3.3V (will damage reader)
- ❌ Loose jumper wires
- ❌ Wrong GPIO pins
- ❌ Swapped MOSI/MISO

---

## 🧪 Test 1: Check Serial Monitor

Open Serial Monitor (115200 baud) and look for:

### ✅ Good Output:
```
ESP32 RFID Programmer Starting...
MFRC522 Software Version: 0x92 = v2.0
BLE service started. Waiting for connections...
```

### ❌ Bad Output (RFID not connected):
```
ESP32 RFID Programmer Starting...
MFRC522 Software Version: 0x00 = (unknown)
```

**If you see 0x00:**
- RFID module is not connected properly
- Check wiring, especially SPI pins (MOSI, MISO, SCK, SS)
- Check power (3.3V and GND)

---

## 🧪 Test 2: Check RFID Module Power

1. **Verify voltage**: Use multimeter to check 3.3V on VCC pin
2. **Check LED**: Some RFID modules have an LED that lights up when powered
3. **Try different power source**: Some ESP32s have weak 3.3V output

**Power Solutions:**
- Add 100nF capacitor between 3.3V and GND (close to RFID module)
- Use external 3.3V power supply
- Try USB 3.0 port (more stable power)

---

## 🧪 Test 3: Test Card Placement

### Correct Card Position:
- Place card **flat** on the RFID antenna
- Card should be within **0-5cm** of antenna
- Try moving card **slowly** across antenna surface
- **Don't move** card while reading

### Card Types:
✅ **Supported:**
- MIFARE Classic 1K (most common white cards)
- MIFARE Classic 4K
- Hotel key cards
- Building access cards

❌ **Not Supported:**
- NFC-only cards
- EMV credit/debit cards
- Apple Pay/Google Pay
- Some newer secure cards

---

## 🧪 Test 4: Use Arduino Test Sketch

To isolate the issue, test with a simple RFID sketch:

### Upload This Test Code:

```cpp
#include <SPI.h>
#include <MFRC522.h>

#define SS_PIN 5
#define RST_PIN 22

MFRC522 mfrc522(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(115200);
  SPI.begin();
  mfrc522.PCD_Init();
  
  Serial.println("RFID Test - Place card near reader...");
  mfrc522.PCD_DumpVersionToSerial();
}

void loop() {
  // Look for new cards
  if (!mfrc522.PICC_IsNewCardPresent()) {
    delay(50);
    return;
  }
  
  // Select one of the cards
  if (!mfrc522.PICC_ReadCardSerial()) {
    delay(50);
    return;
  }
  
  // Show UID
  Serial.print("Card UID: ");
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    Serial.print(mfrc522.uid.uidByte[i] < 0x10 ? " 0" : " ");
    Serial.print(mfrc522.uid.uidByte[i], HEX);
  }
  Serial.println();
  
  delay(1000);
  mfrc522.PICC_HaltA();
}
```

**Expected Output:**
```
RFID Test - Place card near reader...
MFRC522 Software Version: 0x92 = v2.0
Card UID: 04 A1 B2 C3
```

---

## 🔧 Common Issues & Solutions

### Issue 1: "MFRC522 Software Version: 0x00"

**Problem**: RFID module not communicating

**Solutions:**
1. Check SPI wiring (MOSI, MISO, SCK, SS)
2. Try different jumper wires
3. Check for bent/damaged RFID pins
4. Verify 3.3V power (NOT 5V!)

### Issue 2: "NO_CARD" in App

**Problem**: Card not detected but module works

**Solutions:**
1. Place card directly on antenna (flat)
2. Try different card (some cards are incompatible)
3. Check if card is MIFARE Classic 1K
4. Antenna might be damaged

### Issue 3: Intermittent Detection

**Problem**: Sometimes works, sometimes doesn't

**Solutions:**
1. **Add capacitor**: 100nF between 3.3V and GND
2. **Shorten wires**: Use shorter jumper wires
3. **Secure connections**: Check for loose wires
4. **Better power**: Use powered USB hub
5. **Check interference**: Move away from WiFi routers

### Issue 4: Card Works but Data Corrupt

**Problem**: UID shown but garbled data

**Solutions:**
1. Lower SPI speed (rare issue)
2. Check signal integrity
3. Use shielded wires for long connections
4. Ground ESP32 properly

---

## 🎯 Step-by-Step Debug Process

### Step 1: Verify RFID Module
```
1. Upload test sketch above
2. Open Serial Monitor
3. Check version output
4. Place card and watch for UID
```

### Step 2: Check Wiring One-by-One
```
Pin by pin verification:
□ 3.3V → RFID VCC (measure with multimeter)
□ GND  → RFID GND
□ GPIO 5  → RFID SDA
□ GPIO 18 → RFID SCK
□ GPIO 23 → RFID MOSI
□ GPIO 19 → RFID MISO
□ GPIO 22 → RFID RST
```

### Step 3: Test Card
```
□ Try with different card
□ Check if card is MIFARE Classic
□ Test card on phone (NFC capable phones)
□ Verify card isn't password protected
```

### Step 4: Power Issues
```
□ Measure 3.3V output
□ Add decoupling capacitor
□ Try different USB port/cable
□ Use external power supply
```

---

## 📊 Voltage Requirements

| Component | Voltage | Current |
|-----------|---------|---------|
| ESP32 | 3.3V / 5V | 80-260mA |
| RFID-RC522 | 3.3V only | 13-26mA |
| **Total** | - | ~100-300mA |

**Important**: 
- RFID-RC522 **MUST** use 3.3V (5V will damage it!)
- Peak current during card read can spike
- USB 2.0 provides 500mA max (sufficient)
- USB 3.0 provides 900mA max (better)

---

## 🛠️ Hardware Checklist

### RFID Module Check:
- [ ] Module has no visible damage
- [ ] All pins intact
- [ ] Antenna coil intact
- [ ] No burn marks or corrosion

### ESP32 Check:
- [ ] Blue LED lights up when powered
- [ ] Serial Monitor working
- [ ] Can upload sketches
- [ ] 3.3V pin provides proper voltage

### Wiring Check:
- [ ] All 7 wires connected
- [ ] No loose connections
- [ ] Wires not too long (< 20cm ideal)
- [ ] Using 3.3V (NOT 5V)

### Card Check:
- [ ] Card is MIFARE Classic 1K/4K
- [ ] Card not damaged or demagnetized
- [ ] Try multiple cards
- [ ] Card has data (blank cards work too)

---

## 🎓 Advanced Debugging

### Check SPI Communication:

Add this to test sketch after `mfrc522.PCD_Init()`:

```cpp
byte v = mfrc522.PCD_ReadRegister(mfrc522.VersionReg);
Serial.print("Firmware Version: 0x");
Serial.print(v, HEX);
if (v == 0x91 || v == 0x92) {
  Serial.println(" - VALID");
} else if (v == 0x00 || v == 0xFF) {
  Serial.println(" - NO COMMUNICATION!");
} else {
  Serial.println(" - UNKNOWN");
}
```

### Measure Signal with Oscilloscope:
- SCK should show clock pulses
- MOSI should show data when transmitting
- MISO should show data when receiving

---

## 📞 Still Not Working?

If nothing helps:

1. **Test with known-good hardware**: Borrow working RFID module or ESP32
2. **Try different RFID module**: Your module might be defective
3. **Check ESP32 variant**: Make sure it's ESP32 (not ESP32-S2 or ESP32-C3)
4. **Inspect solder joints**: If module is DIY/custom

---

## ✅ Success Indicators

### You'll know it's working when:

**Serial Monitor shows:**
```
MFRC522 Software Version: 0x92 = v2.0
```

**When card is placed:**
```
RX: SCAN
TX: UID:04A1B2C3D4
TX: OK:Card detected
```

**In Flutter app:**
- "Card detected" message
- UID displayed
- Block data visible

---

Good luck! 🚀


