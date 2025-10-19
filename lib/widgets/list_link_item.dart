/*
 * List Link Item
 *
 * Created by:  Blake Davis
 * Description: List Link item
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/utilities/utilities__theme.dart";

import "package:flutter/material.dart";

import "package:flutter_sficon/flutter_sficon.dart";




/* ======================================================================================================================
 * MARK: List Link Item
 * ------------------------------------------------------------------------------------------------------------------ */
class ListLinkItem extends StatelessWidget {

    final bool      primaryLabelOnTop;

    final dynamic   primaryLabel,
                    secondaryLabel;

    final EdgeInsets
                    padding;

    final Function  action;


    ListLinkItem({  super.key,
            required this.primaryLabel,
                     this.secondaryLabel,
                     this.primaryLabelOnTop = false,
            required this.action,
                     this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 4) });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        dynamic labelTop    = primaryLabelOnTop ? primaryLabel   : secondaryLabel;
        dynamic labelBottom = primaryLabelOnTop ? secondaryLabel : primaryLabel;

        // Use the labels' types to determine how to represent them.
        Map<dynamic, Widget> contentAsWidget = {};

        // Iterate over the labels...
        for (var item in [labelTop, labelBottom]) {

            // Skip the label if it is null.
            if (item == null) {
                continue;

            // If the label/value is already a Widget, add it to the Map as-is.
            } else if (item is Widget) {
                contentAsWidget[item] = item;

            // If the label/value is a String, create a Text Widget and add it to the Map.
            } else if (item is String) {
                contentAsWidget[item] = (item == primaryLabel) ? Text(item,               style: beTextTheme.headingPrimary) :
                                                                 Text(item.toUpperCase(), style: beTextTheme.captionPrimary);
            } else {
                // If the label/value has a .toString() method, use it to create a Text Widget and add it to the Map.
                try {
                    contentAsWidget[item] = (item == primaryLabel) ? Text(item.toString(),               style: beTextTheme.headingPrimary) :
                                                                     Text(item.toString().toUpperCase(), style: beTextTheme.captionPrimary);
                // Default to an "empty" Widget.
                } on NoSuchMethodError {
                    contentAsWidget[item] = const SizedBox.shrink();
                }
            }
        }


        return InkWell(
            onTap:         (){ action(); },
            splashFactory: NoSplash.splashFactory,
            child:         Padding(
                padding: padding,
                child:   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize:      MainAxisSize.max,
                    children:          [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment:  MainAxisAlignment.center,
                            mainAxisSize:       MainAxisSize.min,
                            children:           [
                                contentAsWidget[labelTop]    ?? const SizedBox.shrink(),
                                contentAsWidget[labelBottom] ?? const SizedBox.shrink()
                            ]
                        ),
                        SFIcon(SFIcons.sf_chevron_right,
                            fontSize:   beTextTheme.headingSecondary.fontSize,
                            fontWeight: FontWeight.w500,
                            color:      beColorScheme.text.accent
                        )
                    ]
                )
            )
        );
    }
}




