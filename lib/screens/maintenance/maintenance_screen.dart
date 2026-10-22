import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_tile.dart';
import 'task_actions.dart';

enum TaskFilter { pending, completed }

/// Pending and completed maintenance tasks.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  TaskFilter _filter = TaskFilter.pending;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaintenanceProvider>();
    final trees = context.watch<TreeProvider>();
    final pending = provider.pendingTasks;
    final completed = provider.completedTasks;
    final tasks = _filter == TaskFilter.pending ? pending : completed;
    final now = DateTime.now();
    final overdue = pending.where((t) => t.isOverdue(now)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-maintenance',
        onPressed: () => TaskActions.openForm(context),
        icon: const Icon(Icons.add_task),
        label: const Text('New task'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<TaskFilter>(
                segments: [
                  ButtonSegment(
                    value: TaskFilter.pending,
                    icon: const Icon(Icons.pending_actions),
                    label: Text('Pending (${pending.length})'),
                  ),
                  ButtonSegment(
                    value: TaskFilter.completed,
                    icon: const Icon(Icons.task_alt),
                    label: Text('Completed (${completed.length})'),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (value) =>
                    setState(() => _filter = value.first),
              ),
            ),
          ),
          if (_filter == TaskFilter.pending && overdue > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.criticalBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.criticalFg),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '$overdue task${overdue == 1 ? ' is' : 's are'} overdue',
                      style: const TextStyle(
                        color: AppColors.criticalFg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: tasks.isEmpty
                ? _emptyState(context)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      96,
                    ),
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskTile(
                        key: ValueKey(task.id),
                        task: task,
                        now: now,
                        treeName: task.treeId == null
                            ? null
                            : trees.treeById(task.treeId!)?.name,
                        onTap: () => TaskActions.openForm(context, task: task),
                        onToggleComplete: (done) =>
                            TaskActions.setCompleted(context, task, done),
                        onDelete: () => TaskActions.delete(context, task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    if (_filter == TaskFilter.completed) {
      return const EmptyState(
        icon: Icons.task_alt,
        title: 'No completed tasks',
        message: 'Tick a pending task once the work is done and it will appear here.',
      );
    }
    return EmptyState(
      icon: Icons.event_available_outlined,
      title: 'All caught up',
      message:
          'No pending maintenance. Schedule watering, pruning or inspections.',
      actionLabel: 'Schedule a task',
      onAction: () => TaskActions.openForm(context),
    );
  }
}
