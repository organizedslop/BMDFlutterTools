/*
 * List Action Item
 *
 * Created by:  Blake Davis
 * Description: List item that displays a widget as a label, and executes an action when tapped
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/utilities/utilities__theme.dart";

import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: List Action Item
 * ------------------------------------------------------------------------------------------------------------------ */
class ListActionItem extends StatefulWidget {

    final dynamic label;

    final EdgeInsets padding;

    final Function action;


    ListActionItem({ super.key,
            required this.label,
            required this.action,
                     this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 8) });


    @override
    State<ListActionItem> createState() => _ListActionItemState();
}




/* ======================================================================================================================
 * MARK: List Action Item
 * ------------------------------------------------------------------------------------------------------------------ */
class _ListActionItemState extends State<ListActionItem> {

    bool loading = false;

    late final dynamic label;

    late final EdgeInsets padding;

    late final Function action;



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        label   = widget.label;
        padding = widget.padding;
        action  = widget.action;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        // Use the label's type to determine how to represent it.
        Widget labelAsWidget;


        // If the label is already a Widget, use it as-is.
        if (label is Widget) {
            labelAsWidget = label;

        // If the label is a String, create a Text Widget.
        } else if (label is String) {
            labelAsWidget = Text(label, style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent)));

        } else {

            // If the label has a .toString() method, use it to create a Text Widget.
            try {
                labelAsWidget = Text(label.toString(), style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent)));

            // Default to an "empty" Widget.
            } on NoSuchMethodError {
                labelAsWidget = const SizedBox.shrink();
            }
        }


        return InkWell(
            onTap: () async {
                setState(() { loading = true; });

                await action();

                setState(() { loading = false; });
            },
            splashFactory: NoSplash.splashFactory,
            child:         Padding(
                padding: padding,
                child:   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize:      MainAxisSize.max,
                    spacing:           8,
                    children: [
                        loading ? SizedBox(
                            height: Theme.of(context).textTheme.headlineMedium?.fontSize ?? 20,
                            width:  Theme.of(context).textTheme.headlineMedium?.fontSize ?? 20,
                            child:  Center(child: CircularProgressIndicator(color: BeColorSwatch.gray))
                        ) : null,
                        labelAsWidget
                    ].nonNulls.toList()
                )
            )
        );
    }
}




