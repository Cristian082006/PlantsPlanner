import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps [child] with a subtle backdrop of green leaf silhouettes — decorative
/// only (never intercepts touches), low-opacity so text stays fully legible.
class PlantsBackdrop extends StatelessWidget {
  final Widget child;

  const PlantsBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColors.bg),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LeafBackdropPainter(
                accent: AppColors.accent,
                accent2: AppColors.accent2,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _LeafBackdropPainter extends CustomPainter {
  final Color accent;
  final Color accent2;

  _LeafBackdropPainter({required this.accent, required this.accent2});

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Color color,
    double opacity,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final path = Path();
    // Simple leaf silhouette: two symmetric cubic-bezier lobes meeting at a
    // tip, wide in the middle, like a monstera/philodendron leaf.
    path.moveTo(0, -size);
    path.cubicTo(size * 0.75, -size * 0.6, size * 0.7, size * 0.35, 0, size);
    path.cubicTo(-size * 0.7, size * 0.35, -size * 0.75, -size * 0.6, 0, -size);
    path.close();
    canvas.drawPath(path, paint);

    final veinPaint = Paint()
      ..color = color.withValues(alpha: opacity * 1.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.035;
    canvas.drawLine(Offset(0, -size * 0.85), Offset(0, size * 0.85), veinPaint);
    for (var i = 1; i <= 3; i++) {
      final t = i / 4;
      final y = -size * 0.85 + t * size * 1.7;
      final w = size * 0.5 * (1 - (t - 0.5).abs() * 1.6).clamp(0.0, 1.0);
      canvas.drawLine(Offset(0, y), Offset(w, y + size * 0.15), veinPaint);
      canvas.drawLine(Offset(0, y), Offset(-w, y + size * 0.15), veinPaint);
    }

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed, hand-placed cluster so the motif reads as a deliberate corner
    // decoration rather than a busy repeating wallpaper.
    _drawLeaf(
      canvas,
      Offset(size.width * 0.08, size.height * 0.06),
      size.width * 0.30,
      -0.5,
      accent,
      0.07,
    );
    _drawLeaf(
      canvas,
      Offset(size.width * 0.28, size.height * 0.03),
      size.width * 0.22,
      0.35,
      accent2,
      0.06,
    );
    _drawLeaf(
      canvas,
      Offset(size.width * 0.92, size.height * 0.92),
      size.width * 0.34,
      2.6,
      accent,
      0.07,
    );
    _drawLeaf(
      canvas,
      Offset(size.width * 0.72, size.height * 0.97),
      size.width * 0.24,
      3.4,
      accent2,
      0.06,
    );
    _drawLeaf(
      canvas,
      Offset(size.width * 1.0, size.height * 0.55),
      size.width * 0.20,
      1.9,
      accent,
      0.05,
    );
  }

  @override
  bool shouldRepaint(covariant _LeafBackdropPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.accent2 != accent2;
}
