import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/tree.dart';

/// Colour and icon for each health status, used by badges, filters and charts.
extension HealthStatusStyle on HealthStatus {
  Color get foreground => switch (this) {
    HealthStatus.healthy => AppColors.healthyFg,
    HealthStatus.needsAttention => AppColors.attentionFg,
    HealthStatus.critical => AppColors.criticalFg,
  };

  Color get background => switch (this) {
    HealthStatus.healthy => AppColors.healthyBg,
    HealthStatus.needsAttention => AppColors.attentionBg,
    HealthStatus.critical => AppColors.criticalBg,
  };

  /// Stronger tone for chart segments.
  Color get chartColor => switch (this) {
    HealthStatus.healthy => AppColors.leaf,
    HealthStatus.needsAttention => const Color(0xFFE9A23B),
    HealthStatus.critical => const Color(0xFFD64545),
  };

  IconData get icon => switch (this) {
    HealthStatus.healthy => Icons.check_circle_outline,
    HealthStatus.needsAttention => Icons.error_outline,
    HealthStatus.critical => Icons.warning_amber_rounded,
  };
}

class HealthStatusBadge extends StatelessWidget {
  const HealthStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final HealthStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Health status: ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: status.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status.icon,
              size: compact ? 14 : 16,
              color: status.foreground,
            ),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: status.foreground,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
