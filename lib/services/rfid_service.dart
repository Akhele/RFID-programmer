import 'dart:async';
import '../models/rfid_card.dart';
import 'bluetooth_service.dart';

class RfidService {
  final BleService _bluetoothService;
  StreamSubscription? _dataSubscription;
  
  final _responseController = StreamController<String>.broadcast();
  final _cardController = StreamController<RfidCard>.broadcast();
  
  String _currentUid = '';
  final Map<int, String> _currentBlocks = {};
  
  RfidService(this._bluetoothService) {
    _setupDataListener();
  }
  
  void _setupDataListener() {
    _dataSubscription = _bluetoothService.receiveData().listen(
      _handleResponse,
      onError: (error) {
        _responseController.addError(error);
      },
    );
  }
  
  void _handleResponse(String response) {
    _responseController.add(response);
    
    // Parse specific response types
    if (response.startsWith('UID:')) {
      _currentUid = response.substring(4);
    } else if (response.startsWith('DATA:')) {
      // Format: DATA:blockNumber:hexdata
      final parts = response.substring(5).split(':');
      if (parts.length >= 2) {
        final blockNumber = int.tryParse(parts[0]);
        final data = parts[1];
        if (blockNumber != null) {
          _currentBlocks[blockNumber] = data;
        }
      }
    } else if (response.startsWith('READ_COMPLETE')) {
      // Emit complete card data
      if (_currentUid.isNotEmpty) {
        _cardController.add(RfidCard(
          uid: _currentUid,
          blocks: Map.from(_currentBlocks),
        ));
      }
    }
  }
  
  Stream<String> get responseStream => _responseController.stream;
  Stream<RfidCard> get cardStream => _cardController.stream;
  
  Future<void> scanForCard() async {
    _currentUid = '';
    _currentBlocks.clear();
    await _bluetoothService.sendCommand('SCAN');
  }
  
  Future<void> readCard() async {
    _currentUid = '';
    _currentBlocks.clear();
    await _bluetoothService.sendCommand('READ');
  }
  
  Future<void> writeToCard({
    required int sector,
    required int block,
    required String data,
  }) async {
    // Validate data (must be 32 hex characters for 16 bytes)
    if (data.length != 32) {
      throw ArgumentError('Data must be exactly 32 hex characters (16 bytes)');
    }
    
    if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(data)) {
      throw ArgumentError('Data must contain only hex characters');
    }
    
    await _bluetoothService.sendCommand('WRITE:$sector:$block:$data');
  }
  
  Future<void> writeTextToCard({
    required int sector,
    required int block,
    required String text,
  }) async {
    // Convert text to hex, pad to 16 bytes
    String hexData = '';
    for (int i = 0; i < text.length && i < 16; i++) {
      hexData += text.codeUnitAt(i).toRadixString(16).padLeft(2, '0');
    }
    
    // Pad with zeros to make 32 characters (16 bytes)
    hexData = hexData.padRight(32, '0');
    
    await writeToCard(sector: sector, block: block, data: hexData);
  }
  
  Future<void> formatCard() async {
    await _bluetoothService.sendCommand('FORMAT');
  }
  
  Future<void> authenticate({
    required int sector,
    String keyType = 'A',
    String? key,
  }) async {
    // Default key is FFFFFFFFFFFF for MIFARE Classic cards
    final authKey = key ?? 'FFFFFFFFFFFF';
    await _bluetoothService.sendCommand('AUTH:$sector:$keyType:$authKey');
  }
  
  Future<String> waitForResponse({
    Duration timeout = const Duration(seconds: 5),
    String? startsWith,
  }) async {
    final completer = Completer<String>();
    late StreamSubscription subscription;
    
    subscription = responseStream.listen((response) {
      if (startsWith == null || response.startsWith(startsWith)) {
        if (!completer.isCompleted) {
          completer.complete(response);
          subscription.cancel();
        }
      }
    });
    
    // Set timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(TimeoutException('No response received'));
      }
    });
    
    return completer.future;
  }
  
  void dispose() {
    _dataSubscription?.cancel();
    _responseController.close();
    _cardController.close();
  }
}

