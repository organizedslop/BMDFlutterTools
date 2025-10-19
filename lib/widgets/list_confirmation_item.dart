/*
 * List Confirmation Item
 *
 * Created by:  Blake Davis
 * Description: A widget that displays a row of text buttons with user-defined actions
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/utilities/utilities__theme.dart";

import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: List Confirmation Item
 * ------------------------------------------------------------------------------------------------------------------ */
class ListConfirmationItem extends StatelessWidget {

    final Map<dynamic, Function> buttons;

    final EdgeInsets padding;


    ListConfirmationItem({ super.key,
                   required this.buttons,
                            this.padding = const EdgeInsets.only(top: 12, right: 0, bottom: 15, left: 0) });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return IntrinsicHeight(
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment:  MainAxisAlignment.spaceEvenly,
                mainAxisSize:       MainAxisSize.max,
                children: () {
                    List<Widget> output = [];

                    for (var index = 0; index < buttons.length; index++) {
                        output.add(
                            Expanded(child:
                                InkWell(
                                    onTap:         () { buttons.values.toList()[index](); },
                                    splashFactory: NoSplash.splashFactory,
                                    child:         Padding(
                                        padding: padding,
                                        child:   Container(
                                            alignment:   AlignmentDirectional.center,
                                            constraints: BoxConstraints.expand(),
                                            child:       buttons.keys.toList()[index]
                                        )
                                    )
                                )
                            )
                        );
                        if (index != buttons.length-1) {
                            output.add(VerticalDivider(color: BeColorSwatch.lighterGray, thickness: 1, width: double.minPositive));
                        }
                    }
                    return output;
                }()
            )
        );
    }
}