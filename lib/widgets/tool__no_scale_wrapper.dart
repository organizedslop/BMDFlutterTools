import "package:flutter/material.dart";




class NoScale extends StatelessWidget {

    final Widget child;

    const NoScale({super.key, required this.child});


    @override
    Widget build(BuildContext context) {
        return MediaQuery(
            data:  MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child,
        );
    }
}