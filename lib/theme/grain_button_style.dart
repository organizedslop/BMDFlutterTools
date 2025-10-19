import "package:bmd_flutter_tools/theme/app_styles.dart";
import 'package:bmd_flutter_tools/theme/blurred_splash_factory.dart';
import 'package:bmd_flutter_tools/utilities/utilities__theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' show DecorationImagePainter;

class GrainButtonDecoration extends Decoration {
  final Gradient gradient;
  final BorderRadiusGeometry borderRadius;
  final List<DecorationImage> overlayImages;

  const GrainButtonDecoration({
    required this.gradient,
    required this.borderRadius,
    this.overlayImages = const <DecorationImage>[],
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _GrainButtonDecorationPainter(this, onChanged);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GrainButtonDecoration &&
        other.gradient == gradient &&
        other.borderRadius == borderRadius &&
        listEquals(other.overlayImages, overlayImages);
  }

  @override
  int get hashCode => Object.hash(
        gradient,
        borderRadius,
        Object.hashAll(overlayImages),
      );
}

class _GrainButtonDecorationPainter extends BoxPainter {
  _GrainButtonDecorationPainter(this.decoration, VoidCallback? onChanged)
      : _imagePainters = [
          for (final DecorationImage image in decoration.overlayImages)
            image.createPainter(() {
              if (onChanged != null) {
                onChanged();
              }
            }),
        ],
        super(onChanged);

  final GrainButtonDecoration decoration;
  final List<DecorationImagePainter> _imagePainters;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size? size = configuration.size;
    if (size == null) {
      return;
    }

    final Rect rect = offset & size;
    final BorderRadius resolvedRadius =
        decoration.borderRadius.resolve(configuration.textDirection);
    final RRect rrect = resolvedRadius.toRRect(rect);

    final Paint paint = Paint()
      ..shader = decoration.gradient.createShader(rect);
    canvas.drawRRect(rrect, paint);

    final Path clipPath = Path()..addRRect(rrect);
    for (final DecorationImagePainter painter in _imagePainters) {
      painter.paint(canvas, rect, clipPath, configuration);
    }
  }

  @override
  void dispose() {
    for (final DecorationImagePainter painter in _imagePainters) {
      painter.dispose();
    }
    super.dispose();
  }
}

final DecorationImage buttonNoiseHighlightImage = DecorationImage(
  image: const AssetImage("assets/images/texture__button_noise_highlight.png"),
  repeat: ImageRepeat.repeat,
  filterQuality: FilterQuality.medium,
  opacity: 0.5,
  scale: 0.5,
);

final DecorationImage buttonNoiseShadowImage = DecorationImage(
  image: const AssetImage("assets/images/texture__button_noise_shadow.png"),
  repeat: ImageRepeat.repeat,
  filterQuality: FilterQuality.medium,
  opacity: 0.8,
  scale: 0.5,
);

ButtonStyle grainButtonStyle({
  required List<Color> colors,
  required BorderRadius borderRadius,
  EdgeInsetsGeometry? padding,
  TextStyle? textStyle,
}) {
  final EdgeInsetsGeometry effectivePadding = padding ??
      EdgeInsets.symmetric(
        horizontal: beTextTheme.headingPrimary.fontSize! * 0.8,
        vertical: beTextTheme.headingPrimary.fontSize! * 0.4,
      );

  final TextStyle? effectiveTextStyle =
      textStyle; //beTextTheme.bodyPrimary.merge(const TextStyle(color: BeColorSwatch.white));

  return ButtonStyle(
    animationDuration: buttonOverlayFadeDuration,
    padding: WidgetStateProperty.all(effectivePadding),
    textStyle: (effectiveTextStyle != null)
        ? WidgetStateProperty.all(effectiveTextStyle)
        : null,
    backgroundColor: WidgetStateProperty.all(Colors.transparent),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: borderRadius),
    ),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return BeColorSwatch.white.withOpacity(0.16);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return BeColorSwatch.white.withOpacity(0.08);
      }
      return Colors.transparent;
    }),
    splashFactory: BlurredSplashFactory(),
    backgroundBuilder: (context, states, child) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Ink(
          // Draw the gradient and grain on the Material itself so ink splashes render above them.
          decoration: GrainButtonDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: borderRadius,
            overlayImages: <DecorationImage>[
              buttonNoiseHighlightImage,
              buttonNoiseShadowImage,
            ],
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    },
  );
}
