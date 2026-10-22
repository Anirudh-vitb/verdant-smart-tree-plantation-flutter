import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_environment.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/plantation_actions.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feedback.dart';
import '../../widgets/section_header.dart';
import '../../widgets/statistic_card.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/tree_card.dart';
import '../../widgets/tree_illustration.dart';
import '../maintenance/task_actions.dart';
import '../trees/record_watering_sheet.dart';
import '../trees/tree_actions.dart';
import 'health_summary_card.dart';

/// Home screen: summary numbers, health chart, quick actions and lists.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenTab});

  /// Switches the main navigation to another tab (1 = Trees, 2 = Maintenance).
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final treeProvider = context.watch<TreeProvider>();
    final maintenance = context.watch<MaintenanceProvider>();
    final now = DateTime.now();
    final stats = DashboardStats.compute(
      trees: treeProvider.trees,
      tasks: maintenance.tasks,
      waterings: treeProvider.waterings,
      now: now,
    );
    final upcomingWatering = maintenance.upcomingWatering();
    final recentTrees = treeProvider.recentTrees();
    final warnings = [
      context.watch<AppEnvironment>().storageWarning,
      treeProvider.loadWarning,
      if (maintenance.skippedOnLoad > 0)
        '${maintenance.skippedOnLoad} saved task(s) were damaged and could not be loaded.',
    ].whereType<String>().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.forest, color: AppColors.forest),
            SizedBox(width: AppSpacing.sm),
            Text('Verdant'),
          ],
        ),
        actions: [_DashboardMenu(now: now)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          for (final warning in warnings) _WarningBanner(message: warning),
          _WelcomeBanner(stats: stats, now: now),
          const SizedBox(height: AppSpacing.md),
          _StatsGrid(stats: stats, onOpenTab: onOpenTab),
          const SizedBox(height: AppSpacing.md),
          HealthSummaryCard(stats: stats),
          const SectionHeader(title: 'Quick actions'),
          Row(
            children: [
              _QuickAction(
                icon: Icons.add_circle_outline,
                label: 'Add tree',
                color: AppColors.forest,
                background: AppColors.leafSoft,
                onTap: () => TreeActions.openAddForm(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickAction(
                icon: Icons.water_drop_outlined,
                label: 'Record watering',
                color: AppColors.water,
                background: AppColors.waterBg,
                onTap: () => showRecordWateringSheet(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickAction(
                icon: Icons.handyman_outlined,
                label: 'Maintenance',
                color: AppColors.attentionFg,
                background: AppColors.attentionBg,
                onTap: () => onOpenTab(2),
              ),
            ],
          ),
          SectionHeader(
            title: 'Upcoming watering',
            actionLabel: 'View all',
            onAction: () => onOpenTab(2),
          ),
          if (upcomingWatering.isEmpty)
            Card(
              child: EmptyState(
                compact: true,
                icon: Icons.water_drop_outlined,
                title: 'No watering scheduled',
                message: 'Plan regular watering so young saplings survive.',
                actionLabel: 'Schedule watering',
                onAction: () => TaskActions.openForm(context),
              ),
            )
          else
            for (final task in upcomingWatering)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TaskTile(
                  task: task,
                  now: now,
                  treeName: task.treeId == null
                      ? null
                      : treeProvider.treeById(task.treeId!)?.name,
                  onTap: () => TaskActions.openForm(context, task: task),
                  onToggleComplete: (done) =>
                      TaskActions.setCompleted(context, task, done),
                  onDelete: () => TaskActions.delete(context, task),
                ),
              ),
          SectionHeader(
            title: 'Recently added trees',
            actionLabel: 'See all',
            onAction: () => onOpenTab(1),
          ),
          if (recentTrees.isEmpty)
            Card(
              child: EmptyState(
                compact: true,
                icon: Icons.park_outlined,
                title: 'No trees yet',
                message: 'Start by adding the first tree you planted.',
                actionLabel: 'Add a tree',
                onAction: () => TreeActions.openAddForm(context),
              ),
            )
          else
            for (final tree in recentTrees)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TreeCard(
                  tree: tree,
                  lastWatered: treeProvider.lastWatered(tree.id),
                  onTap: () => TreeActions.openDetails(context, tree.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.stats, required this.now});

  final DashboardStats stats;
  final DateTime now;

  String get _greeting {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _summary {
    if (stats.totalTrees == 0) {
      return 'Your plantation is empty. Add your first tree to begin.';
    }
    if (stats.requiringAttention == 0 && stats.overdueTasks == 0) {
      return 'All ${stats.totalTrees} trees are healthy and nothing is overdue.';
    }
    final parts = [
      if (stats.requiringAttention > 0)
        '${stats.requiringAttention} tree${stats.requiringAttention == 1 ? ' needs' : 's need'} attention',
      if (stats.overdueTasks > 0)
        '${stats.overdueTasks} task${stats.overdueTasks == 1 ? ' is' : 's are'} overdue',
    ];
    return '${parts.join(' and ')}.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(AppSpacing.radius + 4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.date(now).toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$_greeting!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Smart Tree Plantation Management',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB7E4C7),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const TreeIllustration(size: 88),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.onOpenTab});

  final DashboardStats stats;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatisticCard(
        label: 'Trees planted',
        value: stats.totalTrees,
        icon: Icons.park_outlined,
        color: AppColors.forest,
        background: AppColors.leafSoft,
        caption: '${stats.wateringsThisWeek} waterings this week',
        onTap: () => onOpenTab(1),
      ),
      StatisticCard(
        label: 'Healthy trees',
        value: stats.healthy,
        icon: Icons.check_circle_outline,
        color: AppColors.healthyFg,
        background: AppColors.healthyBg,
        caption: '${stats.healthyPercent}% of all trees',
      ),
      StatisticCard(
        label: 'Need attention',
        value: stats.requiringAttention,
        icon: Icons.warning_amber_rounded,
        color: AppColors.attentionFg,
        background: AppColors.attentionBg,
        caption: '${stats.critical} critical',
      ),
      StatisticCard(
        label: 'Pending tasks',
        value: stats.pendingTasks,
        icon: Icons.pending_actions,
        color: stats.overdueTasks > 0 ? AppColors.criticalFg : AppColors.forest,
        background: stats.overdueTasks > 0
            ? AppColors.criticalBg
            : AppColors.leafSoft,
        caption: stats.overdueTasks > 0
            ? '${stats.overdueTasks} overdue'
            : 'None overdue',
        onTap: () => onOpenTab(2),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        const gap = AppSpacing.sm;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.sm,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: background,
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.attentionBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.attentionFg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.attentionFg),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MenuAction { removeSamples, restoreSamples, about }

class _DashboardMenu extends StatelessWidget {
  const _DashboardMenu({required this.now});

  final DateTime now;

  Future<void> _handle(BuildContext context, _MenuAction action) async {
    final actions = PlantationActions(
      context.read<TreeProvider>(),
      context.read<MaintenanceProvider>(),
    );
    switch (action) {
      case _MenuAction.removeSamples:
        final confirmed = await AppFeedback.confirm(
          context,
          title: 'Remove sample data?',
          message:
              'All records marked "Sample" will be deleted, including any '
              'tasks or watering you added to sample trees. Your own trees '
              'and their records are kept.',
          confirmLabel: 'Remove',
        );
        if (!confirmed || !context.mounted) return;
        try {
          await actions.removeDemoData();
          if (context.mounted) {
            AppFeedback.success(context, 'Sample data removed');
          }
        } catch (error) {
          if (context.mounted) {
            AppFeedback.error(context, 'Could not remove sample data: $error');
          }
        }
      case _MenuAction.restoreSamples:
        try {
          await actions.restoreDemoData(now);
          if (context.mounted) {
            AppFeedback.success(context, 'Sample data loaded');
          }
        } catch (error) {
          if (context.mounted) {
            AppFeedback.error(context, 'Could not load sample data: $error');
          }
        }
      case _MenuAction.about:
        showAboutDialog(
          context: context,
          applicationName: 'Verdant',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(
            Icons.forest,
            color: AppColors.forest,
            size: 40,
          ),
          children: const [
            Text(
              'Smart Tree Plantation Management System. Track planted trees, '
              'their health, watering and maintenance. All data is stored on '
              'this device and works offline.',
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDemo =
        context.select<TreeProvider, bool>((p) => p.hasDemoData) ||
        context.select<MaintenanceProvider, bool>((p) => p.hasDemoData);
    return PopupMenuButton<_MenuAction>(
      tooltip: 'More options',
      onSelected: (action) => _handle(context, action),
      itemBuilder: (context) => [
        if (hasDemo)
          const PopupMenuItem(
            value: _MenuAction.removeSamples,
            child: ListTile(
              leading: Icon(Icons.cleaning_services_outlined),
              title: Text('Remove sample data'),
            ),
          )
        else
          const PopupMenuItem(
            value: _MenuAction.restoreSamples,
            child: ListTile(
              leading: Icon(Icons.dataset_outlined),
              title: Text('Load sample data'),
            ),
          ),
        const PopupMenuItem(
          value: _MenuAction.about,
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
          ),
        ),
      ],
    );
  }
}
