import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/tree.dart';
import 'health_status_badge.dart';

/// List item summarising a tree.
class TreeCard extends StatelessWidget {
  const TreeCard({
    super.key,
    required this.tree,
    required this.onTap,
    this.lastWatered,
  });

  final Tree tree;
  final DateTime? lastWatered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textMuted,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'tree-avatar-${tree.id}',
                child: TreeAvatar(health: tree.health),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            tree.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (tree.isDemo) const _DemoTag(),
                      ],
                    ),
                    Text(
                      tree.species,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _IconLine(
                      icon: Icons.place_outlined,
                      text: tree.location,
                      style: muted,
                    ),
                    const SizedBox(height: 2),
                    _IconLine(
                      icon: Icons.event_outlined,
                      text: 'Planted ${Formatters.date(tree.plantedOn)}',
                      style: muted,
                    ),
                    if (lastWatered != null) ...[
                      const SizedBox(height: 2),
                      _IconLine(
                        icon: Icons.water_drop_outlined,
                        text:
                            'Watered ${Formatters.relativeDay(lastWatered!).toLowerCase()}',
                        style: muted,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    HealthStatusBadge(status: tree.health, compact: true),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded tree icon tinted by health status.
class TreeAvatar extends StatelessWidget {
  const TreeAvatar({super.key, required this.health, this.size = 52});

  final HealthStatus health;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: health.background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.park_rounded,
        color: health.foreground,
        size: size * 0.55,
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text, this.style});

  final IconData icon;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _DemoTag extends StatelessWidget {
  const _DemoTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Sample',
        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
    );
  }
}
