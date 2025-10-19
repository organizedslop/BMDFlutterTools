import "package:flutter/material.dart";

/// ShapeBorder that renders a gradient stroke following a rounded rectangle.
class GradientBorderShape extends ShapeBorder {
  final BorderRadiusGeometry borderRadius;
  final double borderWidth;
  final Gradient gradient;

  const GradientBorderShape({
    required this.borderRadius,
    required this.borderWidth,
    required this.gradient,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  ShapeBorder scale(double t) => GradientBorderShape(
        borderRadius:
            BorderRadiusGeometry.lerp(BorderRadius.zero, borderRadius, t) ??
                borderRadius,
        borderWidth: borderWidth * t,
        gradient: gradient,
      );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final RRect outer = borderRadius.resolve(textDirection).toRRect(rect);
    final RRect inner = outer.deflate(borderWidth);
    return Path()..addRRect(inner);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final RRect outer = borderRadius.resolve(textDirection).toRRect(rect);
    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(outer.deflate(borderWidth / 2), paint);
  }

  @override
  void paintInterior(Canvas canvas, Rect rect, Paint paint,
      {TextDirection? textDirection}) {}
}
