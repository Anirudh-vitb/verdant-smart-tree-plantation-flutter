import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Simple vector tree drawn in code, so the app needs no image assets.
class TreeIllustration extends StatelessWidget {
  const TreeIllustration({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _TreePainter()),
    );
  }
}

class _TreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.93),
        width: w * 0.7,
        height: h * 0.1,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    // Trunk.
    final trunk = Path()
      ..moveTo(w * 0.46, h * 0.92)
      ..lineTo(w * 0.47, h * 0.55)
      ..lineTo(w * 0.53, h * 0.55)
      ..lineTo(w * 0.54, h * 0.92)
      ..close();
    canvas.drawPath(trunk, Paint()..color = const Color(0xFF8B5E3C));

    // Canopy made of overlapping circles in two greens.
    final dark = Paint()..color = AppColors.leaf;
    final light = Paint()..color = const Color(0xFF95D5B2);
    canvas.drawCircle(Offset(w * 0.34, h * 0.48), w * 0.2, dark);
    canvas.drawCircle(Offset(w * 0.66, h * 0.48), w * 0.2, dark);
    canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.25, dark);
    canvas.drawCircle(Offset(w * 0.44, h * 0.27), w * 0.11, light);
    canvas.drawCircle(Offset(w * 0.62, h * 0.4), w * 0.08, light);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
