/*
 * License User Field
 *
 * Created by:  Blake Davis
 * Description: A widget managing the assigned user and owner for licenses
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/data/model/data__software_license.dart";

import "package:flutter/material.dart";

import "package:flutter_riverpod/flutter_riverpod.dart";




/* ======================================================================================================================
 * MARK: License User Field
 * ------------------------------------------------------------------------------------------------------------------ */

class LicenseUserField extends ConsumerStatefulWidget {

    final SoftwareLicenseData license;

    final Map<int, TextEditingController> textEditingControllers;


    LicenseUserField({ super.key,
               required this.license,
               required this.textEditingControllers });


    @override
    ConsumerState<LicenseUserField> createState() => _LicenseUserFieldState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _LicenseUserFieldState extends ConsumerState<LicenseUserField> {


    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        try {
            final currentLicense = widget.license;

            // Create TextEditingController if necessary
            widget.textEditingControllers.putIfAbsent(widget.license.id, () => TextEditingController(text: widget.license.id.toString()));

        } catch(error) {
            return;
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return TextFormField(
            controller:    widget.textEditingControllers[widget.license.id],
            decoration:    null,
            keyboardType:  TextInputType.text,
            onChanged:     (text) {
                setState(() {
                    // Set the field's value
                    String currentValue = text;
                });
            }
        );
    }
}