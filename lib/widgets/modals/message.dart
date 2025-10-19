/*
 * Message Modal
 *
 * Created by:  Blake Davis
 * Description: A widget which displays a modal with plain-text messages
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/utilities/theme_utilities.dart";

import "package:flutter/material.dart";




/* =====================================================================================================================
 * MARK: Message Modal
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
class MessageModal extends StatelessWidget {

    final String body;
    final String title;


    MessageModal({ super.key,
                    this.title = "",
                    this.body  = ""  });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Dialog(
            child: Padding(
                padding: EdgeInsets.all(24),
                child:   Column(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                        Text(title, style: beTextTheme.headingTertiary),
                        const SizedBox(height: 8),
                        Text(body, style: beTextTheme.bodyPrimary)
                    ]
                )
            )
        );
    }
}