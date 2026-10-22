/// Health condition of a planted tree.
enum HealthStatus {
  healthy('Healthy'),
  needsAttention('Needs Attention'),
  critical('Critical');

  const HealthStatus(this.label);

  final String label;

  /// Parses the stored name, throwing [FormatException] for unknown values.
  static HealthStatus fromName(String name) => HealthStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => throw FormatException('Unknown health status "$name"'),
  );
}

/// A single tree planted as part of the plantation drive.
class Tree {
  const Tree({
    required this.id,
    required this.name,
    required this.species,
    required this.plantedOn,
    required this.location,
    required this.health,
    required this.createdAt,
    required this.updatedAt,
    this.scientificName,
    this.notes = '',
    this.isDemo = false,
  });

  final String id;
  final String name;
  final String species;
  final String? scientificName;
  final DateTime plantedOn;
  final String location;
  final HealthStatus health;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// True for records created by the first-run sample data.
  final bool isDemo;

  /// Whole days since planting (never negative).
  int ageInDays(DateTime now) {
    final days = now.difference(plantedOn).inDays;
    return days < 0 ? 0 : days;
  }

  Tree copyWith({
    String? name,
    String? species,
    String? scientificName,
    bool clearScientificName = false,
    DateTime? plantedOn,
    String? location,
    HealthStatus? health,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Tree(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      scientificName: clearScientificName
          ? null
          : scientificName ?? this.scientificName,
      plantedOn: plantedOn ?? this.plantedOn,
      location: location ?? this.location,
      health: health ?? this.health,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDemo: isDemo,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'species': species,
    'scientificName': scientificName,
    'plantedOn': plantedOn.toIso8601String(),
    'location': location,
    'health': health.name,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDemo': isDemo,
  };

  /// Builds a tree from stored JSON. Throws [FormatException] or [TypeError]
  /// when the data is malformed so the storage layer can skip the record.
  factory Tree.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    if (id.isEmpty || name.trim().isEmpty) {
      throw const FormatException('Tree is missing an id or name');
    }
    return Tree(
      id: id,
      name: name,
      species: json['species'] as String,
      scientificName: json['scientificName'] as String?,
      plantedOn: DateTime.parse(json['plantedOn'] as String),
      location: json['location'] as String,
      health: HealthStatus.fromName(json['health'] as String),
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDemo: json['isDemo'] as bool? ?? false,
    );
  }
}
