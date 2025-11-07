# ESP32 RFID Firmware

## Overview
This firmware enables ESP32 to interface with RFID-RC522 module and communicate via Bluetooth Low Energy (BLE).

## Libraries Required
- **MFRC522** by GithubCommunity
- **ESP32 BLE Arduino** (included with ESP32 board package)

## Installation

### 1. Install Libraries
Open Arduino IDE:
1. Go to **Sketch → Include Library → Manage Libraries**
2. Search for "MFRC522"
3. Install "MFRC522 by GithubCommunity"

### 2. Configure Board
1. **Tools → Board** → Select your ESP32 board
2. **Tools → Port** → Select correct COM port
3. Recommended settings:
   - Upload Speed: 921600
   - CPU Frequency: 240MHz
   - Flash Size: 4MB

### 3. Upload
1. Connect ESP32 via USB
2. Click **Upload** button
3. Open **Serial Monitor** (115200 baud)
4. Verify output: "BLE service started"

## Pin Configuration

```
RFID-RC522    →    ESP32
---------          ------
SDA/SS       →    GPIO 5
SCK          →    GPIO 18
MOSI         →    GPIO 23
MISO         →    GPIO 19
RST          →    GPIO 22
3.3V         →    3.3V
GND          →    GND
```

## Communication Protocol

### Commands (App → ESP32)

| Command | Description | Response |
|---------|-------------|----------|
| `SCAN` | Check for card presence | `UID:...` or `NO_CARD` |
| `READ` | Read all card sectors | `UID:...`, `DATA:...`, `READ_COMPLETE` |
| `WRITE:sector:block:hexdata` | Write data to card | `OK:...` or `ERROR:...` |
| `FORMAT` | Format card (erase all data) | `OK:...` |
| `AUTH:sector:keyType:key` | Custom authentication | `OK:...` |

### Responses (ESP32 → App)

| Response | Description |
|----------|-------------|
| `OK:message` | Operation successful |
| `ERROR:message` | Operation failed |
| `NO_CARD` | No card detected |
| `UID:hexstring` | Card UID |
| `DATA:block:hexdata` | Block data |
| `READ_COMPLETE` | Read operation finished |

## Examples

### Reading a Card
```
App → ESP32: READ
ESP32 → App: UID:04A1B2C3D4E5F6
ESP32 → App: DATA:4:00000000000000000000000000000000
ESP32 → App: DATA:5:48656C6C6F20576F726C642100000000
ESP32 → App: ...
ESP32 → App: READ_COMPLETE
ESP32 → App: OK:Card read successfully
```

### Writing to Card
```
App → ESP32: WRITE:1:0:48656C6C6F20576F726C642100000000
ESP32 → App: OK:Data written to block 4
```

## Troubleshooting

### "BLE service not starting"
- Check board selection
- Ensure ESP32 has BLE support
- Try different ESP32 board

### "RFID reader not found"
- Verify wiring connections
- Use 3.3V (NOT 5V)
- Check SPI pins

### "Authentication failed"
- Card may have custom keys
- Try with new/blank card
- Check default key in code

## Customization

### Change BLE Device Name
```cpp
BLEDevice::init("ESP32-RFID");  // Change name here
```

### Modify Default RFID Key
```cpp
for (byte i = 0; i < 6; i++) {
  key.keyByte[i] = 0xFF;  // Change key bytes here
}
```

### Add Custom Commands
Add to `processCommand()` function:
```cpp
else if (command == "MYCMD") {
  handleMyCommand();
}
```

## Serial Monitor Output

Expected output on startup:
```
ESP32 RFID Programmer Starting...
MFRC522 Software Version: 0x92 = v2.0
BLE service started. Waiting for connections...
TX: OK:System ready
Device connected
RX: READ
TX: UID:04A1B2C3D4E5F6
...
```

## Performance Notes

- BLE range: ~10-30 meters (open space)
- Card read time: ~500-1000ms
- Card write time: ~100-200ms per block
- Maximum BLE packet: 512 bytes (chunked automatically)

## Security Considerations

⚠️ **Important**: This firmware uses default RFID keys (FFFFFFFFFFFF). For production use:
1. Change default keys
2. Implement proper authentication
3. Encrypt BLE communication
4. Add access control

## License
MIT License

