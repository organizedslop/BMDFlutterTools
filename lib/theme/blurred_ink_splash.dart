import 'dart:ui';
import 'package:flutter/material.dart';

class BlurredInkSplash extends InteractiveInkFeature {
  final Paint _paint;

  BlurredInkSplash({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Color color,
    required Offset position,
    required double radius,
    required ShapeBorder? customBorder,
    required double blurSigma,
    VoidCallback? onRemoved,
  })  : _paint = Paint()..color = color,
        super(
          controller: controller,
          referenceBox: referenceBox,
          color: color,
          onRemoved: onRemoved,
        ) {
    _radius = radius;
    _position = position;
    _blurSigma = blurSigma;
    _customBorder = customBorder;
    controller.addInkFeature(this);
    _radiusController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync:    controller.vsync,
    )
      ..addListener(controller.markNeedsPaint)
      ..forward();
  }

  late final double _radius;
  late final Offset _position;
  late final double _blurSigma;
  late final ShapeBorder? _customBorder;
  late final AnimationController _radiusController;

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final Paint paint = Paint()..color = _paint.color;

    // Apply the blur filter to the paint object
    if (_blurSigma > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, _blurSigma);
    }

    final double splashRadius = _radiusController.value * _radius;
    final Path? clippedPath = _customBorder?.getOuterPath(
      Offset.zero & referenceBox.size,
    );

    canvas.transform(transform.storage);

    if (clippedPath != null) {
      canvas.clipPath(clippedPath);
    }

    canvas.drawCircle(_position, splashRadius, paint);
  }

  @override
  void confirm() {
    _radiusController.reverse()..whenComplete(dispose);
  }

  @override
  void cancel() {
    _radiusController.reverse()..whenComplete(dispose);
  }

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }
}
