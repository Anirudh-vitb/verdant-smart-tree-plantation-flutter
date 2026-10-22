import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/maintenance_task.dart';
import '../../providers/maintenance_provider.dart';
import '../../widgets/feedback.dart';
import 'task_form_screen.dart';

/// Task actions shared by the maintenance list, dashboard and tree details.
abstract final class TaskActions {
  static Future<void> openForm(
    BuildContext context, {
    MaintenanceTask? task,
    String? treeId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => TaskFormScreen(existing: task, initialTreeId: treeId),
      ),
    );
  }

  static Future<void> setCompleted(
    BuildContext context,
    MaintenanceTask task,
    bool completed,
  ) async {
    final provider = context.read<MaintenanceProvider>();
    try {
      await provider.setCompleted(task.id, completed);
      if (!context.mounted) return;
      AppFeedback.success(
        context,
        completed
            ? '"${task.title}" marked as completed'
            : '"${task.title}" moved back to pending',
      );
    } catch (error) {
      if (context.mounted) {
        AppFeedback.error(context, 'Could not update task: $error');
      }
    }
  }

  static Future<void> delete(BuildContext context, MaintenanceTask task) async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Delete task?',
      message: '"${task.title}" will be permanently removed.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<MaintenanceProvider>().deleteTask(task.id);
      if (context.mounted) AppFeedback.success(context, 'Task deleted');
    } catch (error) {
      if (context.mounted) {
        AppFeedback.error(context, 'Could not delete task: $error');
      }
    }
  }
}
