import 'package:flutter/material.dart';

class GoogleIcon extends StatelessWidget {
  final double size;

  const GoogleIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: GoogleIconPainter()),
    );
  }
}

class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Google "G" background (white circle)
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    // Google "G" colored parts
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width * 0.4;

    // Blue part (right side)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -1.57, // -90 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Green part (bottom right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      0, // 0 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Yellow part (bottom left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      1.57, // 90 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Red part (top left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      3.14, // 180 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // White inner circle to create the "G" shape
    paint.color = Colors.white;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.6, paint);

    // Blue inner rectangle (right part of "G")
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        centerX,
        centerY - radius * 0.2,
        radius * 0.6,
        radius * 0.4,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
