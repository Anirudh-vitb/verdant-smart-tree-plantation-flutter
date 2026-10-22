import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_stats.dart';
import '../../models/tree.dart';
import '../../widgets/health_status_badge.dart';

/// Stacked bar showing the share of trees in each health status.
class HealthSummaryCard extends StatelessWidget {
  const HealthSummaryCard({super.key, required this.stats});

  final DashboardStats stats;

  int _count(HealthStatus status) => switch (status) {
    HealthStatus.healthy => stats.healthy,
    HealthStatus.needsAttention => stats.needsAttention,
    HealthStatus.critical => stats.critical,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = stats.totalTrees;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Tree health',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  total == 0
                      ? 'No trees yet'
                      : '${stats.healthyPercent}% healthy',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.forest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: total == 0
                  ? 'No tree health data'
                  : HealthStatus.values
                        .map((s) => '${s.label}: ${_count(s)}')
                        .join(', '),
              excludeSemantics: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 14,
                  child: total == 0
                      ? Container(color: AppColors.outline)
                      : LayoutBuilder(
                          builder: (context, constraints) => Row(
                            children: [
                              for (final status in HealthStatus.values)
                                if (_count(status) > 0)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOut,
                                    width:
                                        constraints.maxWidth *
                                        _count(status) /
                                        total,
                                    color: status.chartColor,
                                  ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                for (final status in HealthStatus.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: status.chartColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${status.label} · ${_count(status)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
