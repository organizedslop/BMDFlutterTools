/*
 * Counter Field
 *
 * Created by:  Blake Davis
 * Description: A widget which displays a numeric value with increment and decrement buttons
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:flutter/material.dart";
import "package:flutter_sficon/flutter_sficon.dart";




/* ======================================================================================================================
 * MARK: Counter
 * ------------------------------------------------------------------------------------------------------------------ */
class CounterField extends StatefulWidget {

    final Function? onChange;

    final int   currentValue,
                defaultValue;

    final int?  maximumValue,
                minimumValue;


    const CounterField({ super.key,
                          this.currentValue  = 0,
                          this.maximumValue,
                          this.minimumValue,
                          this.defaultValue  = 0,
                          this.onChange           });


    @override
    State<CounterField> createState() => _CounterFieldState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _CounterFieldState extends State<CounterField> {

    int? maximumValue,
         minimumValue;

    late int currentValue;


    get value { return currentValue; }



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        currentValue = widget.currentValue;
        maximumValue = widget.maximumValue;
        minimumValue = widget.minimumValue;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Container(
            alignment:  AlignmentDirectional.center,
            decoration: BoxDecoration(border: Border.all(color: beColorScheme.text.tertiary, width: 1.5), borderRadius: BorderRadius.circular(6), color: beColorScheme.background.primary),
            padding:    EdgeInsets.all(4),
            child:      Row(
                spacing:  8,
                children: [

                    InkWell(
                        onTap: () {
                            setState(() {
                                if (minimumValue == null || currentValue > minimumValue!) {
                                    currentValue -= 1;

                                    if (widget.onChange != null) {
                                        widget.onChange!(value);
                                    }
                                } else {
                                    logPrint("ℹ️  Minimum value (${minimumValue}) reached.");
                                }
                            });
                        },
                        child: SFIcon(SFIcons.sf_minus,
                            color:      (currentValue > (minimumValue ?? double.negativeInfinity) ? beColorScheme.text.accent : beColorScheme.text.tertiary),
                            fontSize:   beTextTheme.bodySecondary.fontSize,
                            fontWeight: FontWeight.bold),
                    ),

                    Text(currentValue.toString()),

                    InkWell(
                        onTap: () {
                            setState(() {
                                if (maximumValue == null || currentValue < maximumValue!) {
                                    currentValue += 1;

                                    if (widget.onChange != null) {
                                        widget.onChange!(value);
                                    }
                                } else {
                                    logPrint("ℹ️  Maximum value (${maximumValue}) reached.");
                                }
                            });
                        },
                        child: SFIcon(SFIcons.sf_plus,
                            color:      (currentValue < (maximumValue ?? double.infinity) ? beColorScheme.text.accent : beColorScheme.text.tertiary),
                            fontSize:   beTextTheme.bodySecondary.fontSize,
                            fontWeight: FontWeight.bold),
                    ),
                ]
            )
        );
    }
}