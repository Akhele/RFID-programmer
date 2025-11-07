import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rfid_card.dart';
import '../services/bluetooth_service.dart';
import '../services/rfid_service.dart';
import 'write_card_screen.dart';

class RfidOperationsScreen extends StatefulWidget {
  const RfidOperationsScreen({super.key});

  @override
  State<RfidOperationsScreen> createState() => _RfidOperationsScreenState();
}

class _RfidOperationsScreenState extends State<RfidOperationsScreen> {
  late RfidService _rfidService;
  RfidCard? _currentCard;
  bool _isReading = false;
  String _statusMessage = 'Ready';
  final List<String> _responseLog = [];

  @override
  void initState() {
    super.initState();
    final bluetoothService = Provider.of<BleService>(context, listen: false);
    _rfidService = RfidService(bluetoothService);
    
    // Listen to responses
    _rfidService.responseStream.listen((response) {
      setState(() {
        _responseLog.insert(0, '${DateTime.now().toString().substring(11, 19)}: $response');
        if (_responseLog.length > 50) {
          _responseLog.removeLast();
        }
        
        if (response.startsWith('OK:')) {
          _statusMessage = response.substring(3);
        } else if (response.startsWith('ERROR:')) {
          _statusMessage = response.substring(6);
        } else if (response == 'NO_CARD') {
          _statusMessage = 'No card detected';
        }
      });
    });
    
    // Listen to card data
    _rfidService.cardStream.listen((card) {
      setState(() {
        _currentCard = card;
        _isReading = false;
        _statusMessage = 'Card read successfully';
      });
    });
  }

  @override
  void dispose() {
    _rfidService.dispose();
    super.dispose();
  }

  Future<void> _readCard() async {
    setState(() {
      _isReading = true;
      _statusMessage = 'Reading card...';
      _currentCard = null;
    });

    try {
      await _rfidService.readCard();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isReading = false;
      });
    }
  }

  Future<void> _scanCard() async {
    setState(() {
      _statusMessage = 'Scanning for card...';
    });

    try {
      await _rfidService.scanForCard();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _formatCard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Format Card'),
        content: const Text(
          'This will reset all data blocks to default values. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Format'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _statusMessage = 'Formatting card...';
      });

      try {
        await _rfidService.formatCard();
      } catch (e) {
        setState(() {
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Operations'),
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                if (_isReading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _currentCard != null ? Icons.check_circle : Icons.info_outline,
                    color: _currentCard != null ? Colors.green : null,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isReading ? null : _scanCard,
                  icon: const Icon(Icons.search),
                  label: const Text('Scan'),
                ),
                ElevatedButton.icon(
                  onPressed: _isReading ? null : _readCard,
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Read Card'),
                ),
                ElevatedButton.icon(
                  onPressed: _currentCard == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WriteCardScreen(
                                rfidService: _rfidService,
                                currentCard: _currentCard,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.edit),
                  label: const Text('Write'),
                ),
                OutlinedButton.icon(
                  onPressed: _isReading ? null : _formatCard,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Format'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Card Data Display
          Expanded(
            child: _currentCard == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No card data',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Place a card near the reader and tap "Read Card"',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _buildCardData(),
          ),
          
          // Response Log
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text(
                        'Response Log',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          setState(() {
                            _responseLog.clear();
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _responseLog.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _responseLog[index],
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardData() {
    if (_currentCard == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Card UID',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentCard!.getFormattedUid(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Data Blocks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._currentCard!.blocks.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(
                'Block ${entry.key}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hex:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentCard!.getFormattedBlockData(entry.key),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ASCII:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentCard!.hexToAscii(entry.value),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

