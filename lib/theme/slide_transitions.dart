import "package:flutter/material.dart";

// Push ➜  slide from the right
// Pop  ➜  slide to the left
class SlideTransitionsBuilder extends PageTransitionsBuilder {

    const SlideTransitionsBuilder();

    static final _inCurve  = Curves.easeOutCubic;
    static final _outCurve = Curves.easeInCubic;

    static final _incoming = Tween(begin: const Offset(1, 0), end: Offset.zero)
        .chain(CurveTween(curve: _inCurve));

    static final _outgoing = Tween(begin: Offset.zero, end: const Offset(-1, 0))
        .chain(CurveTween(curve: _outCurve));

    @override
    Widget buildTransitions<T>( PageRoute<T>      route,
                                BuildContext      context,
                                Animation<double> animation,
                                Animation<double> secondaryAnimation,
                                Widget            child                 ) {
        return SlideTransition(
            position: secondaryAnimation.drive(_outgoing),  // Page below the top one
            child: SlideTransition(
                position: animation.drive(_incoming),       // Top page
                child:    child,
            ),
        );
    }
}