class RfidCard {
  final String uid;
  final Map<int, String> blocks;
  final DateTime readTime;

  RfidCard({
    required this.uid,
    required this.blocks,
    DateTime? readTime,
  }) : readTime = readTime ?? DateTime.now();

  String getFormattedUid() {
    return uid.toUpperCase().replaceAllMapped(
      RegExp(r'.{2}'),
      (match) => '${match.group(0)} ',
    ).trim();
  }

  String? getBlockData(int blockNumber) {
    return blocks[blockNumber];
  }

  String getFormattedBlockData(int blockNumber) {
    final data = blocks[blockNumber];
    if (data == null) return 'Not read';
    
    return data.toUpperCase().replaceAllMapped(
      RegExp(r'.{2}'),
      (match) => '${match.group(0)} ',
    ).trim();
  }

  // Convert hex string to ASCII (if printable)
  String hexToAscii(String hex) {
    final buffer = StringBuffer();
    for (int i = 0; i < hex.length; i += 2) {
      final hexByte = hex.substring(i, i + 2);
      final byte = int.parse(hexByte, radix: 16);
      if (byte >= 32 && byte <= 126) {
        buffer.write(String.fromCharCode(byte));
      } else {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'blocks': blocks,
      'readTime': readTime.toIso8601String(),
    };
  }

  factory RfidCard.fromJson(Map<String, dynamic> json) {
    return RfidCard(
      uid: json['uid'] as String,
      blocks: Map<int, String>.from(json['blocks']),
      readTime: DateTime.parse(json['readTime'] as String),
    );
  }
}

