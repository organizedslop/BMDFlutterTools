/*
 * Plain Button
 *
 * Created by:  Blake Davis
 * Description: A button widget with simple formatting options
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: Plain Button
 * ------------------------------------------------------------------------------------------------------------------ */
class PlainButton extends StatelessWidget {

    final Function onTap;

    final dynamic  label;

    final Color?   backgroundColor,
                   tappedBackgroundColor,
                   textColor;


    const PlainButton({
                super.key,
        required this.onTap,
        required this.label,
                 this.backgroundColor        = BeColorSwatch.blue,
                 this.tappedBackgroundColor  = BeColorSwatch.gray,
                 this.textColor              = BeColorSwatch.white
    });



    Widget labelAsWidget(dynamic label) {

        // If the label is a Widget, return it as-is
        if (label is Widget) {
            return label;

        } else {
            String labelAsString = "";

            // If the label is a String, return it in a Text widget
            if (label is String) {
                labelAsString = label;

            // Otherwise, try various methods to represent the label as a String
            } else {
                if (label.containsKey("toJson")) {
                    try {
                        labelAsString = label.toJson();

                    } catch(error) {
                        labelAsString = "[Error]";
                    }
                } else {
                    try {
                        labelAsString = json.encode(label);

                    } catch(error) {
                        if (label.containsKey("toString")) {
                            labelAsString = label.toString();
                        } else {
                            labelAsString = "[Error]";
                        }
                    }
                }
            }

            return Text(
                labelAsString,
                style: TextStyle(
                    color:      textColor,
                    fontFamily: "lato",
                    fontSize:   14,
                    fontWeight: FontWeight.bold
                )
            );
        }
    }


    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Container(
            clipBehavior: Clip.hardEdge,
            decoration:   BoxDecoration(borderRadius: BorderRadius.circular(fullRadius)),
            child:        Material(
                color: backgroundColor,
                child: InkWell(
                    highlightColor: tappedBackgroundColor,
                    onTap:          () { onTap(); },
                    splashFactory:  NoSplash.splashFactory,
                    child:          Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child:   labelAsWidget(label)
                    )
                )
            )
        );
    }
}
