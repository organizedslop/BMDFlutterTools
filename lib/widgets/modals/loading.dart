/*
 * Loading Modal
 *
 * Created by:  Blake Davis
 * Description: A widget which displays a modal loading indicator and plain-text messages
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";

import "package:flutter/material.dart";
import "package:flutter_sficon/flutter_sficon.dart";




/* ======================================================================================================================
 * MARK: Loading Modal
 * ------------------------------------------------------------------------------------------------------------------ */
class LoadingModal extends StatelessWidget {

    final bool cancellable;

    final String text;

    final Function? cancelAction;


    LoadingModal({ super.key,
                    this.text         = "",
                    this.cancellable  = false,
                    this.cancelAction });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Dialog(
            child: Padding(
                padding: EdgeInsets.only(top: 24, right: 24, bottom: 14, left: 24),
                child:   Column(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                        const CircularProgressIndicator(),

                        const SizedBox(height: 8),

                        Text(text, style: beTextTheme.headingTertiary),

                        cancellable ? Padding(
                            padding: EdgeInsets.only(top: 16),
                            child:   InkWell(
                                onTap: () {
                                    if (cancelAction != null) {
                                        cancelAction!();
                                    }
                                    // Dismiss the modal
                                    appRouter.pop();
                                },
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize:      MainAxisSize.min,
                                    spacing:  3,
                                    children: [
                                        SFIcon(SFIcons.sf_xmark, fontSize: 12, fontWeight: FontWeight.bold, color: BeColorSwatch.gray),
                                        Text("Cancel", style: TextStyle(fontSize: Theme.of(context).textTheme.bodySmall!.fontSize, fontWeight: FontWeight.bold, color: BeColorSwatch.gray))
                                    ]
                                )
                            )
                        ) : const SizedBox(height: 10)
                    ]
                )
            )
        );
    }
}