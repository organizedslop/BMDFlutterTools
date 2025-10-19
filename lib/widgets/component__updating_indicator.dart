import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:flutter/material.dart";

/// Small, reusable inline progress + label row that picks up text styles
/// from the current Theme via [BuildContext].
class UpdatingIndicator extends StatelessWidget {
  const UpdatingIndicator({
    super.key,
    this.label = "Updating…",
    this.size = 12,
    this.strokeWidth = 2,
    this.color,
    this.textStyle,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  /// The label shown to the right of the spinner.
  final String label;

  /// The width/height of the spinner.
  final double size;

  /// The spinner stroke width.
  final double strokeWidth;

  /// Optional override for the spinner color; defaults to BeColorSwatch.darkGray.
  final Color? color;

  /// Optional override for the text style; if null, uses Theme.of(context).textTheme.bodyMedium
  /// with BeColorSwatch.darkGray applied.
  final TextStyle? textStyle;

  /// How to align the row horizontally.
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final spinnerColor = color ?? BeColorSwatch.darkGray;
    final style = (textStyle ?? Theme.of(context).textTheme.bodySmall)?.copyWith(
      color: BeColorSwatch.darkGray,
      fontWeight: FontWeight.bold,
    );

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: spinnerColor,
            strokeWidth: strokeWidth,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: style),
      ],
    );
  }
}