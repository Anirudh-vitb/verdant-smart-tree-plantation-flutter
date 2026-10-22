/// A log entry stating that a tree was watered at a given time.
///
/// This only records the activity; it does not control any physical device.
class WateringRecord {
  const WateringRecord({
    required this.id,
    required this.treeId,
    required this.wateredAt,
    this.quantityLitres,
    this.durationMinutes,
    this.notes = '',
    this.isDemo = false,
  });

  final String id;
  final String treeId;
  final DateTime wateredAt;
  final double? quantityLitres;
  final int? durationMinutes;
  final String notes;
  final bool isDemo;

  /// Short description such as "10 L · 15 min".
  String get amountSummary {
    final parts = <String>[
      if (quantityLitres != null) '${_trim(quantityLitres!)} L',
      if (durationMinutes != null) '$durationMinutes min',
    ];
    return parts.join(' · ');
  }

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'treeId': treeId,
    'wateredAt': wateredAt.toIso8601String(),
    'quantityLitres': quantityLitres,
    'durationMinutes': durationMinutes,
    'notes': notes,
    'isDemo': isDemo,
  };

  factory WateringRecord.fromJson(Map<String, dynamic> json) {
    return WateringRecord(
      id: json['id'] as String,
      treeId: json['treeId'] as String,
      wateredAt: DateTime.parse(json['wateredAt'] as String),
      quantityLitres: (json['quantityLitres'] as num?)?.toDouble(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      notes: json['notes'] as String? ?? '',
      isDemo: json['isDemo'] as bool? ?? false,
    );
  }
}
