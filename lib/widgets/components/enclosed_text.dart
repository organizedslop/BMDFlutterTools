/*
 * Enclosed Text
 *
 * Created by:  Blake Davis
 * Description: A widget for displaying text enclosed in a stadium
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: Enclosed Text
 * ------------------------------------------------------------------------------------------------------------------ */
class EnclosedText extends StatelessWidget {

    final Color?     backgroundColor;

    final String     text;

    final TextStyle  defaultStyle = beTextTheme.captionPrimary.merge(TextStyle(color: beColorScheme.text.inverse, height:0));

    final TextStyle? style;


    EnclosedText(this.text, { super.key,
                               this.backgroundColor,
                               this.style
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: backgroundColor),
            child:      Padding(
                padding: EdgeInsets.only(right: 3, bottom: 1.5, left: 3),
                child:   Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style:    defaultStyle.merge(style)
                )
            )
        );
    }
}