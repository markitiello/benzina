import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Il logo: monogramma "B" con una goccia al posto dell'apice, su un
/// riquadro arrotondato. Disegnato in una griglia 64×64 come nel mockup.
class BenzinaLogo extends StatelessWidget {
  const BenzinaLogo({
    super.key,
    required this.size,
    required this.background,
    required this.foreground,
    this.shadow,
  });

  final double size;
  final Color background;
  final Color foreground;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo Benzina',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: shadow,
        ),
        alignment: Alignment.center,
        child: SizedBox.square(
          dimension: size * 2 / 3,
          child: CustomPaint(
            painter: _MonogramPainter(
              color: foreground,
              textStyle: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonogramPainter extends CustomPainter {
  _MonogramPainter({required this.color, required this.textStyle});

  final Color color;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 64;
    canvas.save();
    canvas.scale(unit);

    final text = TextPainter(
      text: TextSpan(
        text: 'B',
        style: textStyle.copyWith(fontSize: 56, color: color, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = text.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    text.paint(canvas, Offset(27 - text.width / 2, 53 - baseline));

    final drop = Path()
      ..moveTo(51, 8)
      ..cubicTo(51, 8, 44, 16.5, 44, 21)
      ..arcToPoint(
        const Offset(58, 21),
        radius: const Radius.circular(7),
        clockwise: false,
      )
      ..cubicTo(58, 16.5, 51, 8, 51, 8)
      ..close();
    canvas.drawPath(drop, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MonogramPainter old) =>
      old.color != color || old.textStyle != textStyle;
}
