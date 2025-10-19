/*
 * List Info Item
 *
 * Created by:  Blake Davis
 * Description: List item that displays a widget as a label
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/utilities/utilities__theme.dart";

import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: List Info Item
 * ------------------------------------------------------------------------------------------------------------------ */
class ListInfoItem extends StatelessWidget {

    final dynamic  label;

    final EdgeInsets padding;


    ListInfoItem({ super.key,
            required this.label,
                     this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 8) });




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
            labelAsWidget = Text(label, style: beTextTheme.bodyPrimary);

        } else {

            // If the label has a .toString() method, use it to create a Text Widget.
            try {
                labelAsWidget = Text(label.toString(), style: beTextTheme.bodyPrimary);

            // Default to an "empty" Widget.
            } on NoSuchMethodError {
                labelAsWidget = const SizedBox.shrink();
            }
        }


        return Padding(
            padding: padding,
            child:   Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:      MainAxisSize.max,
                children:          [labelAsWidget]
            )
        );
    }
}




