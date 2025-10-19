/*
 * List Value Item
 *
 * Created by:  Blake Davis
 * Description: List item that displays a justified label and value
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/utilities/utilities__theme.dart";

import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: List Value Item
 * ------------------------------------------------------------------------------------------------------------------ */
class ListValueItem extends StatelessWidget {

    final bool      elliptValue,
                    wrapValue;

    final dynamic   label,
                    value;

    final int? labelFlex, valueFlex;

    final EdgeInsets
                    padding;

    final Function? action;


    ListValueItem({ super.key,
                     this.label       = "",
            required this.value,
                     this.action,
                     this.wrapValue   = true,
                     this.elliptValue = false,
                     this.padding     = const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                     this.labelFlex,
                     this.valueFlex   });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        // Use the label and value's types to determine how to represent them.
        Map<dynamic, Widget> contentAsWidget = {};


        // Iterate over the label and value...
        for (var item in [label, value]) {

            // If the label/value is already a Widget, add it to the Map as-is.
            if (item is Widget) {
                contentAsWidget[item] = item;

            // If the label/value is a String, create a Text Widget and add it to the Map.
            } else if (item is String) {

                // Use the theme accent color for the value, if it is tappable.
                contentAsWidget[item] = Text(item,
                                             overflow: elliptValue ? TextOverflow.ellipsis : null,
                                             softWrap: wrapValue,
                                             style: ((item == value && action != null)  ? beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent)) :
                                                                                          beTextTheme.bodyPrimary));
            } else {
                // If the label/value has a .toString() method, use it to create a Text Widget and add it to the Map.
                try {

                    // Use the theme accent color for the value, if it is tappable.
                    contentAsWidget[item] = Text(item.toString(),
                                                 overflow: elliptValue ? TextOverflow.ellipsis : null,
                                                 softWrap: wrapValue,
                                                 style: ((item == value && action != null)  ? beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent)) :
                                                                                              beTextTheme.bodyPrimary));
                // Default to an "empty" Widget.
                } on NoSuchMethodError {
                    contentAsWidget[item] = const SizedBox.shrink();
                }
            }
        }


        Padding styledContent = Padding(padding: padding,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize:      MainAxisSize.max,
                children:          [

                    // Label
                    Flexible(
                        flex:  labelFlex ?? 0,
                        fit:   FlexFit.loose,
                        child: Column(
                            children: [
                                contentAsWidget[label] ?? const SizedBox.shrink()
                            ]
                        )
                    ),

                    // Spacer
                    const SizedBox(width: 8),

                    // Value
                    Flexible(
                        flex:  valueFlex ?? 0,
                        fit:   FlexFit.loose,
                        child: Column(
                            children: [
                                contentAsWidget[value] ?? const SizedBox.shrink()
                            ]
                        )
                    )
                ]
            )
        );


        // If an action is provided, wrap the output in a GestureDetector.
        if (action != null) {
            return GestureDetector(
                onTap: (){ action!(); },
                child: styledContent
            );

        } else {
            return styledContent;
        }
    }
}




