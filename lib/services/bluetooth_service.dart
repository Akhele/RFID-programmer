import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

class BleService extends ChangeNotifier {
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _rxCharacteristic;
  fbp.BluetoothCharacteristic? _txCharacteristic;
  
  bool _isScanning = false;
  bool _isConnected = false;
  String _statusMessage = 'Disconnected';
  
  final List<fbp.ScanResult> _scanResults = [];
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionStateSubscription;
  
  // ESP32 BLE Service and Characteristic UUIDs
  // These are standard UUIDs for Nordic UART Service (NUS)
  static const String serviceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String rxCharacteristicUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // Write to ESP32
  static const String txCharacteristicUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // Read from ESP32
  
  // Getters
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;
  List<fbp.ScanResult> get scanResults => _scanResults;
  
  BleService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    // Check if Bluetooth is available
    if (await fbp.FlutterBluePlus.isSupported == false) {
      _statusMessage = 'Bluetooth not supported';
      notifyListeners();
      return;
    }
    
    // Listen to Bluetooth adapter state
    fbp.FlutterBluePlus.adapterState.listen((state) {
      if (state != fbp.BluetoothAdapterState.on) {
        _statusMessage = 'Bluetooth is off';
      } else if (!_isConnected) {
        _statusMessage = 'Ready to scan';
      }
      notifyListeners();
    });
  }
  
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      
      return statuses.values.every((status) => status.isGranted);
    }
    return true;
  }
  
  Future<void> startScan() async {
    if (_isScanning) return;
    
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      _statusMessage = 'Bluetooth permissions not granted';
      notifyListeners();
      return;
    }
    
    _scanResults.clear();
    _isScanning = true;
    _statusMessage = 'Scanning...';
    notifyListeners();
    
    try {
      await fbp.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
        androidUsesFineLocation: true,
      );
      
      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        _scanResults.clear();
        for (var result in results) {
          if (result.device.platformName.isNotEmpty) {
            _scanResults.add(result);
          }
        }
        notifyListeners();
      });
      
      // Stop scanning after timeout
      await Future.delayed(const Duration(seconds: 8));
      await stopScan();
    } catch (e) {
      _statusMessage = 'Scan error: $e';
      _isScanning = false;
      notifyListeners();
    }
  }
  
  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _isScanning = false;
    _statusMessage = _isConnected ? 'Connected' : 'Scan completed';
    notifyListeners();
  }
  
  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      _statusMessage = 'Connecting to ${device.platformName}...';
      notifyListeners();
      
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      
      // Listen to connection state changes
      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == fbp.BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });
      
      _statusMessage = 'Discovering services...';
      notifyListeners();
      
      // Discover services
      List<fbp.BluetoothService> services = await device.discoverServices();
      
      // Find the UART service
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == rxCharacteristicUuid.toLowerCase()) {
              _rxCharacteristic = characteristic;
            } else if (characteristic.uuid.toString().toLowerCase() == txCharacteristicUuid.toLowerCase()) {
              _txCharacteristic = characteristic;
              // Enable notifications
              await characteristic.setNotifyValue(true);
            }
          }
        }
      }
      
      if (_rxCharacteristic == null || _txCharacteristic == null) {
        throw Exception('UART service not found on device');
      }
      
      _isConnected = true;
      _statusMessage = 'Connected to ${device.platformName}';
      notifyListeners();
      
      return true;
    } catch (e) {
      _statusMessage = 'Connection failed: $e';
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _handleDisconnection();
    }
  }
  
  void _handleDisconnection() {
    _connectedDevice = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _isConnected = false;
    _statusMessage = 'Disconnected';
    _connectionStateSubscription?.cancel();
    notifyListeners();
  }
  
  Future<void> sendCommand(String command) async {
    if (!_isConnected || _rxCharacteristic == null) {
      throw Exception('Not connected to device');
    }
    
    try {
      final data = '$command\n'.codeUnits;
      await _rxCharacteristic!.write(data, withoutResponse: false);
    } catch (e) {
      throw Exception('Failed to send command: $e');
    }
  }
  
  Stream<String> receiveData() {
    if (!_isConnected || _txCharacteristic == null) {
      return Stream.error('Not connected to device');
    }
    
    return _txCharacteristic!.lastValueStream.map((value) {
      return String.fromCharCodes(value).trim();
    });
  }
  
  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    disconnect();
    super.dispose();
  }
}

