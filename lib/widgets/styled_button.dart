/*
 * Styled Button
 *
 * Created by:  Blake Davis
 * Description: A button widget pre-styled to fit the app's aesthetic
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: Styled Button
 * ------------------------------------------------------------------------------------------------------------------ */
class StyledButton extends StatelessWidget {

    final Color? backgroundColor;

    final EdgeInsets padding;

    final void Function() onPressed;

    final Widget label;


    const StyledButton({
                 this.backgroundColor,
        required this.label,
        required this.onPressed,
                      padding,

    })  :  this.padding = padding ?? const EdgeInsets.all(0);




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return FilledButton(
            style:      ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(backgroundColor ?? Theme.of(context).colorScheme.primary)
            ),
            onPressed:  onPressed,
            child:      Padding(padding: padding, child: label)
        );
    }
}