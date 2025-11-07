import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import 'bluetooth_scan_screen.dart';
import 'rfid_operations_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Programmer'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Consumer<BleService>(
        builder: (context, bluetoothService, child) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    bluetoothService.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    size: 100,
                    color: bluetoothService.isConnected
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    bluetoothService.statusMessage,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (bluetoothService.isConnected) ...[
                    Text(
                      'Connected to: ${bluetoothService.connectedDevice?.platformName}',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RfidOperationsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.credit_card),
                      label: const Text('RFID Operations'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await bluetoothService.disconnect();
                      },
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: const Text('Disconnect'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: bluetoothService.isScanning
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BluetoothScanScreen(),
                                ),
                              );
                            },
                      icon: const Icon(Icons.bluetooth_searching),
                      label: Text(
                        bluetoothService.isScanning
                            ? 'Scanning...'
                            : 'Scan for Devices',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  _buildInfoCard(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Setup Instructions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Upload firmware to ESP32\n'
              '2. Connect RFID-RC522 module\n'
              '3. Power on ESP32\n'
              '4. Scan and connect to ESP32-RFID\n'
              '5. Start reading/writing cards',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

