import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tree.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/plantation_actions.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/feedback.dart';
import 'tree_details_screen.dart';
import 'tree_form_screen.dart';

/// Tree navigation and actions shared by several screens.
abstract final class TreeActions {
  static Future<void> openAddForm(BuildContext context) {
    return Navigator.of(context)
        .push(MaterialPageRoute<bool>(builder: (_) => const TreeFormScreen()));
  }

  static Future<void> openEditForm(BuildContext context, Tree tree) {
    return Navigator.of(context).push(
      MaterialPageRoute<bool>(builder: (_) => TreeFormScreen(existing: tree)),
    );
  }

  static Future<void> openDetails(BuildContext context, String treeId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TreeDetailsScreen(treeId: treeId),
      ),
    );
  }

  /// Asks for confirmation, then deletes the tree with its tasks and
  /// watering history. Returns true when the tree was deleted.
  static Future<bool> delete(BuildContext context, Tree tree) async {
    final confirmed = await AppFeedback.confirm(
      context,
      title: 'Delete "${tree.name}"?',
      message:
          'This permanently removes the tree, its watering history and '
          'its maintenance tasks. This cannot be undone.',
      confirmLabel: 'Delete tree',
    );
    if (!confirmed || !context.mounted) return false;
    final actions = PlantationActions(
      context.read<TreeProvider>(),
      context.read<MaintenanceProvider>(),
    );
    try {
      await actions.deleteTree(tree.id);
      if (context.mounted) {
        AppFeedback.success(context, '"${tree.name}" deleted');
      }
      return true;
    } catch (error) {
      if (context.mounted) {
        AppFeedback.error(context, 'Could not delete tree: $error');
      }
      return false;
    }
  }
}
