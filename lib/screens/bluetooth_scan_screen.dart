import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  @override
  void initState() {
    super.initState();
    // Start scanning when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bluetoothService = Provider.of<BleService>(context, listen: false);
      bluetoothService.startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Devices'),
        actions: [
          Consumer<BleService>(
            builder: (context, bluetoothService, child) {
              return IconButton(
                icon: Icon(
                  bluetoothService.isScanning ? Icons.stop : Icons.refresh,
                ),
                onPressed: bluetoothService.isScanning
                    ? () => bluetoothService.stopScan()
                    : () => bluetoothService.startScan(),
              );
            },
          ),
        ],
      ),
      body: Consumer<BleService>(
        builder: (context, bluetoothService, child) {
          if (bluetoothService.isScanning) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning for devices...'),
                ],
              ),
            );
          }

          if (bluetoothService.scanResults.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No devices found'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => bluetoothService.startScan(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Scan Again'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: bluetoothService.scanResults.length,
            itemBuilder: (context, index) {
              final result = bluetoothService.scanResults[index];
              return _buildDeviceCard(context, result, bluetoothService);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    fbp.ScanResult result,
    BleService bluetoothService,
  ) {
    final device = result.device;
    final rssi = result.rssi;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth,
              color: _getRssiColor(rssi),
            ),
            Text(
              '$rssi dBm',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
        title: Text(
          device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(device.remoteId.toString()),
        trailing: ElevatedButton(
          onPressed: () async {
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Connecting...'),
                      ],
                    ),
                  ),
                ),
              ),
            );

            // Try to connect
            final success = await bluetoothService.connectToDevice(device);

            if (context.mounted) {
              // Close loading dialog
              Navigator.pop(context);

              if (success) {
                // Go back to home screen
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Connected to ${device.platformName}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to connect'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Connect'),
        ),
      ),
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }
}

