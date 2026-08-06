import 'package:flutter/material.dart';
import '../services/app_tab_controller.dart';
import '../theme/app_theme.dart';

/// One stop of the guided tour: switches to [tabIndex] and, if [targetKey]
/// resolves to a mounted widget, draws a spotlight cutout around it. When
/// the target isn't found (e.g. an empty-state screen that hasn't built the
/// widget yet), the step still shows its description centered, un-spotlit,
/// rather than failing.
class CoachMarkStep {
  final int tabIndex;
  final GlobalKey? targetKey;
  final String title;
  final String description;
  final BoxShape shape;

  const CoachMarkStep({
    required this.tabIndex,
    this.targetKey,
    required this.title,
    required this.description,
    this.shape = BoxShape.rectangle,
  });
}

class CoachMarkOverlay extends StatefulWidget {
  final List<CoachMarkStep> steps;
  final VoidCallback onFinished;

  const CoachMarkOverlay({
    super.key,
    required this.steps,
    required this.onFinished,
  });

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  int _index = 0;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyStep());
  }

  void _applyStep() {
    final step = widget.steps[_index];
    AppTabController.instance.tabIndex.value = step.tabIndex;
    // The freshly-selected tab needs a frame to build/lay out before its
    // target's RenderBox has a valid size and position to measure.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final box =
        widget.steps[_index].targetKey?.currentContext?.findRenderObject()
            as RenderBox?;
    Rect? rect;
    if (box != null && box.attached && box.hasSize) {
      rect = box.localToGlobal(Offset.zero) & box.size;
    }
    setState(() => _targetRect = rect);
  }

  void _next() {
    if (_index == widget.steps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() {
      _index++;
      _targetRect = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyStep());
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final screenSize = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        // Absorbs every tap so the dimmed (but still technically live) UI
        // underneath can't be triggered mid-tour — advancing only happens
        // through the card's own buttons.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      rect: _targetRect,
                      shape: step.shape,
                    ),
                  ),
                ),
              ),
              _DescriptionCard(
                step: step,
                index: _index,
                total: widget.steps.length,
                targetRect: _targetRect,
                screenSize: screenSize,
                onNext: _next,
                onSkip: widget.onFinished,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? rect;
  final BoxShape shape;

  const _SpotlightPainter({required this.rect, required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xcc0b0f14),
    );

    final target = rect;
    if (target != null) {
      final hole = target.inflate(10);
      final holePaint = Paint()..blendMode = BlendMode.clear;
      final borderPaint = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      if (shape == BoxShape.circle) {
        final radius = hole.longestSide / 2;
        canvas.drawCircle(hole.center, radius, holePaint);
        canvas.drawCircle(hole.center, radius, borderPaint);
      } else {
        final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(16));
        canvas.drawRRect(rrect, holePaint);
        canvas.drawRRect(rrect, borderPaint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.shape != shape;
}

class _DescriptionCard extends StatelessWidget {
  final CoachMarkStep step;
  final int index;
  final int total;
  final Rect? targetRect;
  final Size screenSize;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _DescriptionCard({
    required this.step,
    required this.index,
    required this.total,
    required this.targetRect,
    required this.screenSize,
    required this.onNext,
    required this.onSkip,
  });

  bool get _isLast => index == total - 1;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < total; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: i == index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == index
                          ? AppColors.accent
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: onSkip,
                child: Text(
                  'Sari peste',
                  style: TextStyle(fontSize: 13, color: AppColors.neutral400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            step.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            step.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.neutral400,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: Text(_isLast ? 'Am înțeles' : 'Înainte'),
            ),
          ),
        ],
      ),
    );

    // No measured target (welcome step, or a widget that isn't built in the
    // current app state) — just center the card.
    final rect = targetRect;
    if (rect == null) {
      return Center(child: card);
    }

    // Prefer the side of the target with more room, so the card never
    // overlaps the very thing it's explaining.
    final spaceAbove = rect.top;
    final spaceBelow = screenSize.height - rect.bottom;
    final placeBelow = spaceBelow >= spaceAbove;

    return Positioned(
      left: 0,
      right: 0,
      top: placeBelow ? rect.bottom + 24 : null,
      bottom: placeBelow ? null : screenSize.height - rect.top + 24,
      child: card,
    );
  }
}
