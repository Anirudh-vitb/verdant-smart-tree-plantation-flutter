import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/maintenance_task.dart';

/// Card for a maintenance task with a completion checkbox and actions menu.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onTap,
    this.treeName,
    this.onDelete,
    this.now,
  });

  final MaintenanceTask task;

  /// Name of the linked tree, or null for plantation-wide tasks.
  final String? treeName;
  final ValueChanged<bool> onToggleComplete;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = task.isOverdue(now ?? DateTime.now());
    final dueColor = overdue ? AppColors.criticalFg : AppColors.textMuted;
    final dueText = task.isCompleted && task.completedAt != null
        ? 'Completed ${Formatters.date(task.completedAt!)}'
        : overdue
        ? 'Overdue · due ${Formatters.date(task.dueDate)}'
        : 'Due ${Formatters.relativeDay(task.dueDate, now: now).toLowerCase()} · ${Formatters.date(task.dueDate)}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            4,
            AppSpacing.sm,
            0,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (value) => onToggleComplete(value ?? false),
                semanticLabel: task.isCompleted
                    ? 'Mark ${task.title} as pending'
                    : 'Mark ${task.title} as completed',
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: task.type == TaskType.watering
                      ? AppColors.waterBg
                      : AppColors.leafSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  task.type.icon,
                  size: 20,
                  color: task.type == TaskType.watering
                      ? AppColors.water
                      : AppColors.forest,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${task.type.label} · ${treeName ?? 'Whole plantation'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: dueColor,
                        fontWeight: overdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Task actions',
                onSelected: (value) {
                  if (value == 'edit') onTap();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onDelete != null)
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
