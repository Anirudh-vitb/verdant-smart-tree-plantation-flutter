import 'package:flutter/material.dart';

/// The kind of maintenance work a task represents.
enum TaskType {
  watering('Watering', Icons.water_drop_outlined),
  fertilizing('Fertilizing', Icons.compost_outlined),
  pruning('Pruning', Icons.content_cut),
  inspection('Health Inspection', Icons.health_and_safety_outlined),
  general('General Maintenance', Icons.handyman_outlined);

  const TaskType(this.label, this.icon);

  final String label;
  final IconData icon;

  static TaskType fromName(String name) => TaskType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => throw FormatException('Unknown task type "$name"'),
  );
}

/// A scheduled piece of plantation maintenance, optionally linked to a tree.
class MaintenanceTask {
  const MaintenanceTask({
    required this.id,
    required this.title,
    required this.type,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.treeId,
    this.notes = '',
    this.isCompleted = false,
    this.completedAt,
    this.isDemo = false,
  });

  final String id;
  final String title;
  final TaskType type;

  /// Null when the task applies to the whole plantation.
  final String? treeId;
  final DateTime dueDate;
  final String notes;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDemo;

  /// A pending task whose due day is before today.
  bool isOverdue(DateTime now) {
    if (isCompleted) return false;
    final today = DateTime(now.year, now.month, now.day);
    return dueDate.isBefore(today);
  }

  MaintenanceTask copyWith({
    String? title,
    TaskType? type,
    String? treeId,
    bool clearTree = false,
    DateTime? dueDate,
    String? notes,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) {
    return MaintenanceTask(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      treeId: clearTree ? null : treeId ?? this.treeId,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDemo: isDemo,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'treeId': treeId,
    'dueDate': dueDate.toIso8601String(),
    'notes': notes,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDemo': isDemo,
  };

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    final completedAt = json['completedAt'] as String?;
    return MaintenanceTask(
      id: json['id'] as String,
      title: json['title'] as String,
      type: TaskType.fromName(json['type'] as String),
      treeId: json['treeId'] as String?,
      dueDate: DateTime.parse(json['dueDate'] as String),
      notes: json['notes'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDemo: json['isDemo'] as bool? ?? false,
    );
  }
}
