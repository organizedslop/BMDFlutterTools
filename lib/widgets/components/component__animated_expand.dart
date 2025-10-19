import "package:flutter/material.dart";

/// A reusable animated expand/collapse wrapper that uses a SizeTransition
/// via AnimatedSwitcher. Keeps animation settings consistent across the app.
class AnimatedExpand extends StatelessWidget {
  final Widget child;
  final bool expanded;
  final Duration duration;
  final Curve expandCurve;
  final Curve collapseCurve;
  final Object? childKey;
  final double axisAlignment;

  const AnimatedExpand({
    super.key,
    required this.child,
    required this.expanded,
    this.duration = const Duration(milliseconds: 200),
    this.expandCurve = Curves.easeOut,
    this.collapseCurve = Curves.easeIn,
    this.childKey,
    this.axisAlignment = -1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: expandCurve,
      switchOutCurve: collapseCurve,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: axisAlignment,
        child: child,
      ),
      child: expanded
          ? KeyedSubtree(
              key: ValueKey<Object?>(childKey ?? true),
              child: child,
            )
          : const SizedBox.shrink(key: ValueKey<bool>(false)),
    );
  }
}
