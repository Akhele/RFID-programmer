import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rfid_card.dart';
import '../services/rfid_service.dart';

class WriteCardScreen extends StatefulWidget {
  final RfidService rfidService;
  final RfidCard? currentCard;

  const WriteCardScreen({
    super.key,
    required this.rfidService,
    this.currentCard,
  });

  @override
  State<WriteCardScreen> createState() => _WriteCardScreenState();
}

class _WriteCardScreenState extends State<WriteCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sectorController = TextEditingController(text: '1');
  final _blockController = TextEditingController(text: '0');
  final _hexDataController = TextEditingController();
  final _textDataController = TextEditingController();
  
  bool _isWriting = false;
  bool _useTextMode = true;
  String _statusMessage = '';

  @override
  void dispose() {
    _sectorController.dispose();
    _blockController.dispose();
    _hexDataController.dispose();
    _textDataController.dispose();
    super.dispose();
  }

  Future<void> _writeData() async {
    if (!_formKey.currentState!.validate()) return;

    final sector = int.parse(_sectorController.text);
    final block = int.parse(_blockController.text);

    setState(() {
      _isWriting = true;
      _statusMessage = 'Writing to card...';
    });

    try {
      if (_useTextMode) {
        await widget.rfidService.writeTextToCard(
          sector: sector,
          block: block,
          text: _textDataController.text,
        );
      } else {
        await widget.rfidService.writeToCard(
          sector: sector,
          block: block,
          data: _hexDataController.text,
        );
      }

      await widget.rfidService.waitForResponse(
        startsWith: 'OK',
      );

      setState(() {
        _statusMessage = 'Write successful!';
        _isWriting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data written successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Write failed: $e';
        _isWriting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Write failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write to Card'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.currentCard != null)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Card UID',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.currentCard!.getFormattedUid(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Mode selector
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Text Mode'),
                  icon: Icon(Icons.text_fields),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Hex Mode'),
                  icon: Icon(Icons.code),
                ),
              ],
              selected: {_useTextMode},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _useTextMode = newSelection.first;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Sector and Block inputs
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sectorController,
                    decoration: const InputDecoration(
                      labelText: 'Sector',
                      border: OutlineInputBorder(),
                      helperText: 'Range: 0-15',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final sector = int.tryParse(value);
                      if (sector == null || sector < 0 || sector > 15) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _blockController,
                    decoration: const InputDecoration(
                      labelText: 'Block',
                      border: OutlineInputBorder(),
                      helperText: 'Range: 0-3',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final block = int.tryParse(value);
                      if (block == null || block < 0 || block > 3) {
                        return 'Invalid';
                      }
                      // Block 3 is sector trailer (contains keys)
                      if (block == 3) {
                        return 'Block 3 reserved';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Data input
            if (_useTextMode)
              TextFormField(
                controller: _textDataController,
                decoration: const InputDecoration(
                  labelText: 'Text Data',
                  border: OutlineInputBorder(),
                  helperText: 'Max 16 characters',
                  hintText: 'Enter text to write...',
                ),
                maxLength: 16,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              )
            else
              TextFormField(
                controller: _hexDataController,
                decoration: const InputDecoration(
                  labelText: 'Hex Data',
                  border: OutlineInputBorder(),
                  helperText: 'Exactly 32 hex characters (16 bytes)',
                  hintText: 'FFFFFFFFFFFFFFFFFFFFFFFFFFFF',
                ),
                maxLength: 32,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter hex data';
                  }
                  if (value.length != 32) {
                    return 'Must be exactly 32 hex characters';
                  }
                  return null;
                },
              ),
            
            const SizedBox(height: 24),
            
            // Write button
            ElevatedButton.icon(
              onPressed: _isWriting ? null : _writeData,
              icon: _isWriting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isWriting ? 'Writing...' : 'Write to Card'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: _statusMessage.startsWith('Write successful')
                    ? Colors.green[100]
                    : Colors.orange[100],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Info card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Important Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Each sector has 4 blocks (0-3)\n'
                      '• Block 3 contains keys (cannot be written)\n'
                      '• Blocks 0-2 can store data (16 bytes each)\n'
                      '• Text mode pads data automatically\n'
                      '• Hex mode requires exactly 32 characters',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

