import 'package:material_ui/material_ui.dart';
import '../constants/app_colors.dart';

class BrandLogo extends StatelessWidget {
  final bool darkBackground;
  final bool showTagline;
  final double size;

  const BrandLogo({
    super.key,
    this.darkBackground = false,
    this.showTagline = true,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = darkBackground
        ? AppColors.textLight
        : AppColors.primary;

    final accentColor = darkBackground
        ? AppColors.accent
        : AppColors.chartGreen;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: darkBackground
                ? AppColors.accent
                : AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          child: CustomPaint(
            painter: _BrandIconPainter(
              color: darkBackground
                  ? AppColors.primary
                  : AppColors.accent,
            ),
          ),
        ),

        SizedBox(width: size * 0.22),

        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: size * 0.46,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sakay',
                      style: TextStyle(color: mainColor),
                    ),
                    TextSpan(
                      text: 'Sense',
                      style: TextStyle(color: accentColor),
                    ),
                  ],
                ),
              ),

              if (showTagline) ...[
                const SizedBox(height: 4),
                Text(
                  'Smarter counting. Better journeys.',
                  style: TextStyle(
                    fontSize: size * 0.21,
                    fontWeight: FontWeight.w400,
                    color: darkBackground
                        ? AppColors.sidebarText
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandIconPainter extends CustomPainter {
  final Color color;

  const _BrandIconPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    canvas.scale(
      size.width / 64,
      size.height / 64,
    );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Detection brackets
    final brackets = Path()
      ..moveTo(12, 23)
      ..lineTo(12, 12)
      ..lineTo(23, 12)
      ..moveTo(41, 12)
      ..lineTo(52, 12)
      ..lineTo(52, 23)
      ..moveTo(12, 41)
      ..lineTo(12, 52)
      ..lineTo(23, 52)
      ..moveTo(41, 52)
      ..lineTo(52, 52)
      ..lineTo(52, 41);

    canvas.drawPath(brackets, paint);

    // Vehicle body
    final vehicle = RRect.fromRectAndRadius(
      const Rect.fromLTWH(20, 19, 24, 27),
      const Radius.circular(5),
    );

    canvas.drawRRect(vehicle, paint);

    // Windshield
    canvas.drawLine(
      const Offset(20, 33),
      const Offset(44, 33),
      paint,
    );

    // Upper vehicle detail
    canvas.drawLine(
      const Offset(26, 24),
      const Offset(38, 24),
      paint,
    );

    // Vehicle wheels
    canvas.drawLine(
      const Offset(25, 46),
      const Offset(25, 49),
      paint,
    );

    canvas.drawLine(
      const Offset(39, 46),
      const Offset(39, 49),
      paint,
    );

    // Headlights
    final lightPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      const Offset(26, 39),
      1.8,
      lightPaint,
    );

    canvas.drawCircle(
      const Offset(38, 39),
      1.8,
      lightPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _BrandIconPainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}