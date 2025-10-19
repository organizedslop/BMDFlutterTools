import 'package:bmd_flutter_tools/theme/blurred_ink_splash.dart';
import 'package:flutter/material.dart';

class BlurredSplashFactory extends InteractiveInkFeatureFactory {

    const BlurredSplashFactory({this.blurSigma = 12.0});

    final double blurSigma;

    @override
    InteractiveInkFeature create({
        required MaterialInkController controller,
        required RenderBox referenceBox,
        required Offset position,
        required Color color,
        required TextDirection textDirection,
        bool containedInkWell = false,
        RectCallback? rectCallback,
        BorderRadius? borderRadius,
        ShapeBorder? customBorder,
        double? radius,
        VoidCallback? onRemoved,
    }) {

        return BlurredInkSplash(
        blurSigma:    blurSigma,
        color:        color,
        controller:   controller,
        customBorder: customBorder,
        onRemoved:    onRemoved,
        radius:       radius ?? 30,
        referenceBox: referenceBox,
        position:     position,
        );
    }
}
