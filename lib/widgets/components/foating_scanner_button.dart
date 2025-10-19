/*
 *  Floating Scanner Button
 *
 * Created by:  Blake Davis
 * Description: A floating button widget that opens the scanner
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:bmd_flutter_tools/widgets/utilities/no_scale_wrapper.dart";
import "package:flutter/material.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";




/* =====================================================================================================================
 * MARK: Floating Scanner Button
 * ------------------------------------------------------------------------------------------------------------------ */
 class FloatingScannerButton extends StatelessWidget {

    const FloatingScannerButton({ super.key });

    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Container(
            decoration: hardEdgeDecoration.copyWith(borderRadius: BorderRadius.circular(fullRadius)),
            child: Container(
                foregroundDecoration: fullRadiusBeveledDecoration,
                child: FloatingActionButton(
                    backgroundColor: BeColorSwatch.red.color,
                    foregroundColor: BeColorSwatch.white.color,
                    key:             const Key("scanner_floating_action_button"),
                    onPressed:       () { context.pushNamed("scanner"); },
                    shape:           const CircleBorder(),
                    splashColor:     BeColorSwatch.white.color.withAlpha(60),
                    child:           const NoScale(child: SFIcon(SFIcons.sf_qrcode))
                )
            )
        );
    }
}