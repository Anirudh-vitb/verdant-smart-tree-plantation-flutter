import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/tree.dart';
import '../../models/watering_record.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/health_status_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/tree_card.dart';
import '../maintenance/task_actions.dart';
import 'record_watering_sheet.dart';
import 'tree_actions.dart';

/// Full information about one tree, its watering and maintenance history.
class TreeDetailsScreen extends StatelessWidget {
  const TreeDetailsScreen({super.key, required this.treeId});

  final String treeId;

  @override
  Widget build(BuildContext context) {
    final treeProvider = context.watch<TreeProvider>();
    final tree = treeProvider.treeById(treeId);

    // The tree may have been deleted while this screen was open.
    if (tree == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.park_outlined,
          title: 'Tree not found',
          message: 'This tree has been deleted.',
        ),
      );
    }

    final waterings = treeProvider.wateringsFor(tree.id);
    final tasks = context.watch<MaintenanceProvider>().tasksForTree(tree.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(tree.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Edit tree',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => TreeActions.openEditForm(context, tree),
          ),
          IconButton(
            tooltip: 'Delete tree',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final deleted = await TreeActions.delete(context, tree);
              if (deleted && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-water-${tree.id}',
        backgroundColor: AppColors.water,
        onPressed: () => showRecordWateringSheet(context, treeId: tree.id),
        icon: const Icon(Icons.water_drop),
        label: const Text('Record watering'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          96,
        ),
        children: [
          _HeaderCard(tree: tree),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            tree: tree,
            lastWatered: waterings.isEmpty ? null : waterings.first.wateredAt,
          ),
          if (tree.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(tree.notes),
                  ],
                ),
              ),
            ),
          ],
          SectionHeader(
            title: 'Maintenance (${tasks.length})',
            actionLabel: 'Schedule task',
            onAction: () => TaskActions.openForm(context, treeId: tree.id),
          ),
          if (tasks.isEmpty)
            const Card(
              child: EmptyState(
                compact: true,
                icon: Icons.event_available_outlined,
                title: 'No maintenance scheduled',
                message: 'Schedule pruning, fertilizing or an inspection for this tree.',
              ),
            )
          else
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TaskTile(
                  task: task,
                  treeName: tree.name,
                  onTap: () => TaskActions.openForm(context, task: task),
                  onToggleComplete: (done) =>
                      TaskActions.setCompleted(context, task, done),
                  onDelete: () => TaskActions.delete(context, task),
                ),
              ),
          SectionHeader(title: 'Watering history (${waterings.length})'),
          if (waterings.isEmpty)
            const Card(
              child: EmptyState(
                compact: true,
                icon: Icons.water_drop_outlined,
                title: 'Not watered yet',
                message: 'Use "Record watering" to log each watering.',
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < waterings.length; i++) ...[
                    if (i > 0) const Divider(indent: 64),
                    _WateringTile(record: waterings[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.tree});

  final Tree tree;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Hero(
              tag: 'tree-avatar-${tree.id}',
              child: TreeAvatar(health: tree.health, size: 72),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tree.name, style: theme.textTheme.titleLarge),
                  Text(tree.species, style: theme.textTheme.bodyLarge),
                  if (tree.scientificName != null &&
                      tree.scientificName != tree.species)
                    Text(
                      tree.scientificName!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMuted,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      HealthStatusBadge(status: tree.health),
                      if (tree.isDemo)
                        const Chip(
                          label: Text('Sample record'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.tree, required this.lastWatered});

  final Tree tree;
  final DateTime? lastWatered;

  @override
  Widget build(BuildContext context) {
    final age = tree.ageInDays(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Planted on',
              value: '${Formatters.date(tree.plantedOn)} · ${_ageText(age)}',
            ),
            _InfoRow(
              icon: Icons.place_outlined,
              label: 'Location',
              value: tree.location,
            ),
            _InfoRow(
              icon: Icons.water_drop_outlined,
              label: 'Last watered',
              value: lastWatered == null
                  ? 'Not recorded yet'
                  : Formatters.dateTime(lastWatered!),
            ),
            _InfoRow(
              icon: Icons.update,
              label: 'Last updated',
              value: Formatters.dateTime(tree.updatedAt),
            ),
          ],
        ),
      ),
    );
  }
}

String _ageText(int days) => switch (days) {
  0 => 'planted today',
  1 => '1 day ago',
  _ => '$days days ago',
};

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.forest),
      title: Text(label, style: const TextStyle(color: AppColors.textMuted)),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _WateringTile extends StatelessWidget {
  const _WateringTile({required this.record});

  final WateringRecord record;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (record.amountSummary.isNotEmpty) record.amountSummary,
      if (record.notes.isNotEmpty) record.notes,
    ].join(' · ');
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.waterBg,
        child: Icon(Icons.water_drop, color: AppColors.water, size: 20),
      ),
      title: Text(Formatters.dateTime(record.wateredAt)),
      subtitle: details.isEmpty ? null : Text(details),
      trailing: Text(
        Formatters.relativeDay(record.wateredAt),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}
