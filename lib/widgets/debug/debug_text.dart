/*
 * Debug Text
 *
 * Created by:  Blake Davis
 * Description: A widget for displaying debug text
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/components/enclosed_text.dart";

import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: Debug Text
 * ------------------------------------------------------------------------------------------------------------------ */
class DebugText extends StatelessWidget {

    final String     text;

    final TextStyle  defaultStyle = beTextTheme.captionPrimary.merge(TextStyle(color: beColorScheme.text.inverse, height:0));

    final TextStyle? style;


    DebugText(this.text, { super.key,
                            this.style  });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return EnclosedText(
            text,
            backgroundColor: beColorScheme.text.debug,
            style:           defaultStyle.merge(style)
        );
    }
}