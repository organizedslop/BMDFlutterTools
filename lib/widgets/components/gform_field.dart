/*
 * Gravity Forms Field
 *
 * Created by:  Blake Davis
 * Description: A widget for rendering Gravity Forms fields
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "dart:ui";

import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__address.dart";
import "package:bmd_flutter_tools/data/model/data__gfield.dart";
import "package:bmd_flutter_tools/data/model/data__name.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";
import "package:bmd_flutter_tools/widgets/components/enclosed__text.dart";

import "package:flutter/foundation.dart";

import "package:flutter/material.dart";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:flutter_sficon/flutter_sficon.dart";

import "package:html/parser.dart";

import "package:string_validator/string_validator.dart";

import "package:syncfusion_flutter_signaturepad/signaturepad.dart";




/* ======================================================================================================================
 * Field formatting
 * ------------------------------------------------------------------------------------------------------------------ */
final gfieldDropDownIcon      = const Padding(padding: EdgeInsets.only(top: 2), child: SFIcon(SFIcons.sf_chevron_down, color: BeColorSwatch.blue, fontSize: 16, fontWeight: FontWeight.bold));
final gfieldHintStyle         = TextStyle(color: beColorScheme.text.tertiary, fontWeight: FontWeight.normal);
final gfieldHorizontalPadding = const EdgeInsets.symmetric(horizontal: 10);
final gfieldRoundedBorder     = OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: beColorScheme.text.quaternary, width: 2.5));
final gfieldVerticalPadding   = const EdgeInsets.only(top: 8, bottom: 16);




final BoxDecoration gfieldBoxDecoration = BoxDecoration(
    border:       Border.fromBorderSide(gfieldRoundedBorder.borderSide),
    borderRadius: gfieldRoundedBorder.borderRadius,
);




final InputDecoration gfieldInputDecoration = InputDecoration(
    enabledBorder:  gfieldRoundedBorder,
    fillColor:      BeColorSwatch.offWhite,
    filled:         true,
    focusedBorder:  gfieldRoundedBorder,
    border:         gfieldRoundedBorder,
    contentPadding: gfieldHorizontalPadding
);




Widget formFieldLabel({ required String labelText,
                              int    fieldId    = 0,
                              bool   isRequired = false,
                              bool   isValid    = true   }) {

    // Don't add padding to the field if the label text is an empty string
    if (labelText == "") {
        return const SizedBox.shrink();

    } else {
        return Padding(
            padding: EdgeInsets.only(left: 6),
            child:   Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                    Text(labelText, style: beTextTheme.bodyPrimary.merge(TextStyle(color: isValid ? null : BeColorSwatch.red, fontWeight: FontWeight.bold))),

                    isRequired ? Text("* ", style: beTextTheme.headingSecondary.merge(TextStyle(color: BeColorSwatch.red, height: 0.75))) : null,

                    // Text(" ${fieldId.toString()}", style: beTextTheme.captionSecondary.merge(TextStyle(color: BeColorSwatch.magenta)))
                ].nonNulls.toList()
            )
        );
    }
}




/* ======================================================================================================================
 * MARK: Gravity Forms Field
 * ------------------------------------------------------------------------------------------------------------------ */
class GFormField extends ConsumerStatefulWidget {

    final GFieldData gfield;

    final Map<String, TextEditingController> textEditingControllers;

    bool onPage,
         passwordVisible,
         showDescription,
         showTitle;

    Function? nextPage,
              previousPage;

    Function refreshForm;




    GFormField({
                super.key,
        required this.gfield,
                      passwordVisible,
                      onPage,
                 this.nextPage,
                 this.previousPage,
                      refreshForm,
                      showDescription,
                      showTitle,
        required this.textEditingControllers

    })  :  this.onPage          = onPage          ?? true,
           this.passwordVisible = passwordVisible ?? false,
           this.refreshForm     = refreshForm     ?? (() { }),
           this.showDescription = showDescription ?? true,
           this.showTitle       = showTitle       ?? true;


    @override
    ConsumerState<GFormField> createState() => GFormFieldState();
}








/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class GFormFieldState extends ConsumerState<GFormField> {

    final GlobalKey<SfSignaturePadState> signatureGlobalKey = GlobalKey();

    final Map<String, dynamic> emailDefaultValue    = { "email":    "",  "email_confirmation":    "" };
    final Map<String, dynamic> passwordDefaultValue = { "password": "",  "password_confirmation": "" };

    TextStyle validationMessageStyle = TextStyle(color: BeColorSwatch.red, fontWeight: FontWeight.bold);

    bool refresh = false;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        try {
            if ((widget.gfield.inputs?.length ?? 0) > 1) {

                // Handle normal multi-input fields
                if (widget.gfield.type == "address" || widget.gfield.type == "name") {

                    Map<String, dynamic> currentValueAsJson = json.decode(widget.gfield.value ?? (widget.gfield.type == "address" ? '{"city":"","country":"","state":"","street":"","street_2":"","zip":""}' : '{"prefix":"","first":"","middle":"","last":"","suffix":""}'));

                    // Create controllers for each subfield if they exist
                    for (var fieldName in currentValueAsJson.keys) {
                        widget.textEditingControllers.putIfAbsent(fieldName, () => TextEditingController(text: currentValueAsJson[fieldName] ?? ""));
                    }

                // Handle "single-input" fields that require confirmation
                } else {
                    String fieldName = widget.gfield.type;
                    Map<String, String> defaultValue = { fieldName: "", "${fieldName}_confirmation": "" };
                    Map<String, String> currentValueAsJson = (widget.gfield.value != null) ? json.decode(widget.gfield.value!) : defaultValue;

                    // Create controllers for each subfield if they exist
                    widget.textEditingControllers.putIfAbsent(fieldName, () => TextEditingController(text: currentValueAsJson[fieldName] ?? ""));
                    widget.textEditingControllers.putIfAbsent("${fieldName}_confirmation", () => TextEditingController(text: currentValueAsJson["${fieldName}_confirmation"] ?? ""));
                }

            // Handle single-input fields
            } else {
                String fieldName = widget.gfield.label;

                String currentValueAsString = widget.gfield.value ?? "";

                widget.textEditingControllers.putIfAbsent(fieldName, () => TextEditingController(text: currentValueAsString));
            }

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
     * MARK: GField Description Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Widget formFieldDescription({ required String descriptionText,
                                        int    fieldId          = 0,
                                        bool   isRequired       = false }) {

        // Don't add padding to the field if the label text is an empty string
        if (descriptionText == "") {
            return const SizedBox.shrink();

        } else {
            return Padding(
                padding: EdgeInsets.only(left: 6, bottom: 8),
                child:   Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                        RichText(
                            text: TextSpan(
                                style:    beTextTheme.headingPrimary.merge(TextStyle(fontSize: 28)),
                                children: [
                                    TextSpan(text: descriptionText),

                                    isRequired ? TextSpan(text: " *", style: beTextTheme.headingPrimary.merge(TextStyle(color: beColorScheme.text.accent2, height: 0.75))) : null,

                                    ref.read(isDebuggingProvider) ? TextSpan(text: " ${fieldId.toString()}", style: beTextTheme.captionSecondary.merge(TextStyle(color: BeColorSwatch.magenta))) : null

                                ].nonNulls.toList()
                            )
                        )
                    ].nonNulls.toList()
                )
            );
        }
    }











    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Get Signature as Byte Data
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<ByteData?> _getSignatureAsByteData() async {

        final data      = await signatureGlobalKey.currentState!.toImage(pixelRatio: 3.0);
        ByteData? bytes = await data.toByteData(format: ImageByteFormat.png);

        return bytes;
    }








    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        bool isValid = !(ref.read(gformValidationMessageProvider)[widget.gfield.formId]?? {}).containsKey(widget.gfield.id.toString());


        // Return an empty widget for hidden fields
        if (widget.gfield.visibility != "visible" || !widget.onPage) { return const SizedBox.shrink(); }

        // The field's validation message widget
        final gfieldValidationMessage = Consumer( builder: (context, ref, child) {
            final String? validationMessage = ref.watch(gformValidationMessageProvider)[widget.gfield.formId]?[widget.gfield.id.toString()];

            // Return an empty widget if there is no message
            if (validationMessage == null || validationMessage.isEmpty) { return const SizedBox.shrink(); }

            return Padding(
                padding: EdgeInsets.only(bottom: 10),
                child:   Text(validationMessage, style: validationMessageStyle)
            );
        });

        // Determine the field's type and return the appropriate widgets
        switch (widget.gfield.type) {

            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Address Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "address":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                      fieldId:          widget.gfield.id,
                                                      isRequired:       widget.gfield.isRequired),

                                // Field label
                                // !widget.showTitle ? null :
                                //     formFieldLabel(labelText:  widget.gfield.label,
                                //                 fieldId:    widget.gfield.id,
                                //                 isRequired: widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Street address label
                                formFieldLabel(labelText:  "Street Address",
                                            fieldId:    widget.gfield.id,
                                            isRequired: widget.gfield.isRequired),

                                // Street address field
                                TextFormField(
                                    controller: widget.textEditingControllers["street"],
                                    decoration: InputDecoration(
                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                        hintText:      "123 Main St",
                                        hintStyle:     gfieldHintStyle
                                    ),
                                    keyboardType: TextInputType.streetAddress,
                                    onChanged:    (text) {
                                        setState(() {
                                            // Get the fields's existing value
                                            AddressData currentValue = AddressData.fromJson(widget.gfield.value, source: LocationEncoding.database);

                                            // Set the field's value
                                            currentValue.street = text;
                                            widget.gfield.value = json.encode(currentValue.toJson(destination: LocationEncoding.database));

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    },
                                ),

                                const SizedBox(height: 10),

                                // Street address line 2 label
                                formFieldLabel(labelText: "",
                                            fieldId:   widget.gfield.id),

                                // Street address line 2 field
                                TextFormField(
                                    controller: widget.textEditingControllers["street_2"],
                                    decoration: InputDecoration(
                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                        hintText:      "Building A, Unit 1",
                                        hintStyle:     gfieldHintStyle
                                    ),
                                    keyboardType: TextInputType.streetAddress,
                                    onChanged:    (text) {
                                        setState(() {
                                            // Get the fields's existing value
                                            AddressData currentValue = AddressData.fromJson(widget.gfield.value, source: LocationEncoding.database);

                                            // Set the field's value
                                            currentValue.street2 = text;
                                            widget.gfield.value = json.encode(currentValue.toJson(destination: LocationEncoding.database));

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    },
                                ),

                                const SizedBox(height: 10),

                                Row(
                                    children: [
                                        // City
                                        Expanded(child:
                                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                                formFieldLabel(labelText:  "City",
                                                            fieldId:    widget.gfield.id,
                                                            isRequired: widget.gfield.isRequired),

                                                TextFormField(
                                                    controller: widget.textEditingControllers["city"],
                                                    decoration: InputDecoration(
                                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                                        hintText:      "Austin",
                                                        hintStyle:     gfieldHintStyle
                                                    ),
                                                    keyboardType: TextInputType.name,
                                                    onChanged:    (text) {
                                                        setState(() {
                                                            // Get the fields's existing value
                                                            AddressData currentValue = AddressData.fromJson(widget.gfield.value, source: LocationEncoding.database);

                                                            // Set the field's value
                                                            currentValue.city = text;
                                                            widget.gfield.value = json.encode(currentValue.toJson(destination: LocationEncoding.database));

                                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                                            widget.refreshForm();
                                                        });
                                                    },
                                                )
                                            ])
                                        ),

                                        const SizedBox(width: 10),

                                        // State
                                        Expanded(child:
                                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                                formFieldLabel(labelText:  "State",
                                                            fieldId:    widget.gfield.id,
                                                            isRequired: widget.gfield.isRequired),

                                                TextFormField(
                                                    controller: widget.textEditingControllers["state"],
                                                    decoration: InputDecoration(
                                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                                        hintText:      "TX",
                                                        hintStyle:     gfieldHintStyle
                                                    ),
                                                    keyboardType: TextInputType.name,
                                                    onChanged:    (text) {
                                                        setState(() {
                                                            // Get the fields's existing value
                                                            AddressData currentValue = AddressData.fromJson(widget.gfield.value, source: LocationEncoding.database);

                                                            // Set the field's value
                                                            currentValue.state = text;
                                                            widget.gfield.value = json.encode(currentValue.toJson(destination: LocationEncoding.database));

                                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                                            widget.refreshForm();
                                                        });
                                                    },
                                                )
                                            ])
                                        ),

                                        const SizedBox(width: 10),

                                        // Postal code
                                        Expanded(child:
                                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                                formFieldLabel(labelText:  "ZIP Code",
                                                            fieldId:    widget.gfield.id,
                                                            isRequired: widget.gfield.isRequired),

                                                TextFormField(
                                                    controller: widget.textEditingControllers["zip"],
                                                    decoration: InputDecoration(
                                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                                        hintText:      "12345",
                                                        hintStyle:     gfieldHintStyle
                                                    ),
                                                    keyboardType: TextInputType.number,
                                                    onChanged:    (text) {
                                                        setState(() {
                                                            // Get the fields's existing value
                                                            AddressData currentValue = AddressData.fromJson(widget.gfield.value, source: LocationEncoding.database);

                                                            // Set the field's value
                                                            currentValue.zip = text;
                                                            widget.gfield.value = json.encode(currentValue.toJson(destination: LocationEncoding.database));

                                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                                            widget.refreshForm();
                                                        });
                                                    }
                                                )
                                            ])
                                        )
                                    ]
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Checkbox Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "checkbox":
                if (widget.gfield.choices == null) { return Text("Error: No choices were found for checkbox field."); }

                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                    fieldId:          widget.gfield.id,
                                                    isRequired:       widget.gfield.isRequired),

                                // Field label
                                // !widget.showTitle ? null :
                                //     formFieldLabel(labelText:  widget.gfield.label,
                                //                 fieldId:    widget.gfield.id,
                                //                 isRequired: widget.gfield.isRequired),

                                // Checkbox validation message
                                gfieldValidationMessage,

                                // Checkbox field list
                                Container(
                                    decoration: BoxDecoration(
                                        border:       isValid ? null : Border.fromBorderSide(gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                        borderRadius: gfieldRoundedBorder.borderRadius,
                                    ),
                                    child:      ListView.builder(
                                        itemBuilder: (context, index) => InkWell(
                                            onTap: () {
                                                // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                                widget.refreshForm();
                                            },
                                            child: CheckboxListTile(
                                                checkboxScaleFactor: 1.4,
                                                onChanged: (value) {
                                                    setState(() {
                                                        widget.gfield.choices![index]["isSelected"] = value;

                                                        // Set the field's value
                                                        final newValue = json.encode(widget.gfield.choices!.where((choice) => choice["isSelected"]).map((choice) => choice["text"]).toList());

                                                        widget.gfield.value = newValue;

                                                        // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                                        widget.refreshForm();
                                                    });
                                                },
                                                title: Text(widget.gfield.choices![index]["text"]),
                                                value: widget.gfield.choices![index]["isSelected"],
                                            )
                                        ),
                                        itemCount:  widget.gfield.choices!.length,
                                        physics:    const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                    )
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Consent Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "consent":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(                    padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                      fieldId:          widget.gfield.id,
                                                      isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment:  MainAxisAlignment.start,
                                    children: <Widget>[
                                        Container(
                                            width: 36,
                                            child: CheckboxListTile(
                                                checkboxScaleFactor: 1.4,
                                                side:                isValid ? null : gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red),
                                                onChanged:           (value) {
                                                    setState(() {
                                                        widget.gfield.choices![0]["isSelected"] = value;

                                                        // Set the field's value
                                                        widget.gfield.value = widget.gfield.choices![0]["isSelected"] ? widget.gfield.choices![0]["value"].toString() : "";

                                                        // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                                        widget.refreshForm();
                                                    });
                                                },
                                                value: widget.gfield.choices![0]["isSelected"] ?? false
                                            ),
                                        ),

                                        // Is required indicator
                                        (() => widget.gfield.isRequired ?
                                            Text("* ", style: beTextTheme.headingSecondary.merge(TextStyle(color: beColorScheme.text.accent2)))
                                            : const SizedBox(height: 0))(),

                                        // Consent field heading
                                        Flexible(
                                            flex: 5,
                                            child: Text(widget.gfield.label,
                                                softWrap: true,
                                                style:    TextStyle(fontSize:   beTextTheme.bodyPrimary.fontSize,
                                                                    fontWeight: beTextTheme.bodyPrimary.fontWeight
                                                )
                                            )
                                        ),
                                    ]
                                ),
                                Text(widget.gfield.description)
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Email Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "email":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                      fieldId:          widget.gfield.id,
                                                      isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Field label
                                // !widget.showTitle ? null :
                                //     formFieldLabel(labelText:  "Email",
                                //                 fieldId:    widget.gfield.id,
                                //                 isRequired: widget.gfield.isRequired),

                                // Field
                                TextFormField(
                                    controller: widget.textEditingControllers["email"],
                                    decoration: InputDecoration(
                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                        hintText:      "name@example.com",
                                        hintStyle:     gfieldHintStyle
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged:    (text) {
                                        setState(() {
                                            // Get the fields's existing value
                                            Map<String, dynamic> currentValue = (widget.gfield.value != null) ? json.decode(widget.gfield.value!) : emailDefaultValue;

                                            // Trim whitespace and canonicalize the email address
                                            // Then set the field's value
                                            currentValue["email"] = normalizeEmail(trim(text));
                                            widget.gfield.value = json.encode(currentValue);

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    },
                                ),

                                const SizedBox(height: 10),

                                // Confirm email field label
                                formFieldLabel(labelText:  "Confirm Email",
                                            fieldId:    widget.gfield.id,
                                            isRequired: widget.gfield.isRequired),

                                // Confirm email field
                                TextFormField(
                                    controller: widget.textEditingControllers["email_confirmation"],
                                    decoration: InputDecoration(
                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                        hintText:      "name@example.com",
                                        hintStyle:     gfieldHintStyle
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged:    (text) {
                                        setState(() {
                                            // Get the fields's existing value
                                            Map<String, dynamic> currentValue = (widget.gfield.value != null) ? json.decode(widget.gfield.value!) : emailDefaultValue;

                                            // Set the field's value
                                            currentValue["email_confirmation"] = text;
                                            widget.gfield.value = json.encode(currentValue);

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    }
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Multi-Select Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "multiselect":
                if (widget.gfield.choices == null) { return Text("Error: No choices were found for multi-select field."); }

                String value = widget.gfield.value ?? "Choose an option";

                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                     fieldId:           widget.gfield.id,
                                                     isRequired:        widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Field label
                                // !widget.showTitle ? null :
                                //     formFieldLabel(
                                //         labelText:  widget.gfield.label,
                                //         fieldId:    widget.gfield.id,
                                //         isRequired: widget.gfield.isRequired),

                                Container(
                                    decoration: gfieldBoxDecoration.merge(
                                        BoxDecoration(
                                            border: isValid ? null : Border.all(
                                                color: BeColorSwatch.red,
                                                width: gfieldBoxDecoration.border!.top.width
                                            ),
                                            color:  Theme.of(context).colorScheme.surfaceContainer
                                        )
                                    ),
                                    height:     250,
                                    child:      RawScrollbar(
                                        thickness:  8,
                                        thumbColor: BeColorSwatch.lightGray,
                                        radius:     Radius.circular(fullRadius),
                                        child:      SingleChildScrollView(
                                            padding: gfieldVerticalPadding,
                                            child:   Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                spacing:            1,
                                                children:           (){
                                                    List<Widget> output = [];
                                                    for (final choice in widget.gfield.choices!) {
                                                        final choiceAsMap = choice as Map<String, dynamic>;
                                                        output.add(
                                                            Material(
                                                                color: Colors.transparent,
                                                                child: InkWell(
                                                                    splashFactory: NoSplash.splashFactory,
                                                                    splashColor:   BeColorSwatch.gray,
                                                                    onTap:         () {
                                                                        setState(() {
                                                                            var   choices    = widget.gfield.choices;
                                                                            final index      = choices!.indexWhere((choice) => choice["value"] == choiceAsMap["value"]);
                                                                            final isSelected = !choices[index]["isSelected"];

                                                                            // Toggle the choice's isSelected value
                                                                            widget.gfield.choices![index]["isSelected"] = isSelected;

                                                                            // Update the gfield's value
                                                                            var gfieldValue = widget.gfield.choices!.where((choice) => choice["isSelected"]).map((choice) => choice["value"]).toList();
                                                                            widget.gfield.value = json.encode(gfieldValue);

                                                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                                                            widget.refreshForm();
                                                                        });
                                                                    },
                                                                    child: Container(
                                                                        alignment: Alignment.centerLeft,
                                                                        color:     choiceAsMap["isSelected"] ? BeColorSwatch.blue : Colors.transparent,
                                                                        padding:   EdgeInsets.only(top: 6, right: gfieldHorizontalPadding.horizontal/2, bottom: 8, left: gfieldHorizontalPadding.horizontal/2),
                                                                        child:     Text(
                                                                            "${parseFragment(choiceAsMap["text"]).text}",
                                                                            overflow: TextOverflow.ellipsis,
                                                                            style:    beTextTheme.bodyPrimary.merge(
                                                                                TextStyle(
                                                                                    color:      choiceAsMap["isSelected"] ? BeColorSwatch.white : BeColorSwatch.black,
                                                                                    fontWeight: choiceAsMap["isSelected"] ? FontWeight.bold     : FontWeight.normal
                                                                                )
                                                                            ),
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        );
                                                    }
                                                    return output;
                                                }()
                                            )
                                        )
                                    )
                                ),
                                Padding(padding: EdgeInsets.all(4),
                                    child: Wrap(
                                        runSpacing: 4,
                                        spacing:    6,
                                        children:   () {
                                            List<Widget> output = [];
                                            final valueAsList = json.decode(widget.gfield.value ?? "[]");

                                            for (var value in valueAsList) {
                                                output.add(EnclosedText(value));
                                            }
                                            return output;
                                        }()
                                    )
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Name Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "name":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                      fieldId:          widget.gfield.id,
                                                      isRequired:       widget.gfield.isRequired),

                                // Name validation message
                                gfieldValidationMessage,

                                // Field label
                                // !widget.showTitle ? null :
                                //     formFieldLabel(labelText:  widget.gfield.label,
                                //                 fieldId:    widget.gfield.id,
                                //                 isRequired: widget.gfield.isRequired),

                                Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[

                                        // Name field
                                        Expanded(child:
                                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                                formFieldLabel(labelText:  "First Name",
                                                            fieldId:    widget.gfield.id,
                                                            isRequired: widget.gfield.isRequired),

                                                TextFormField(
                                                    controller: widget.textEditingControllers["first"],
                                                    decoration: InputDecoration(
                                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                                        hintText:      "John",
                                                        hintStyle:     gfieldHintStyle
                                                    ),
                                                    keyboardType: TextInputType.name,
                                                    onChanged:    (text) {
                                                        setState(() {
                                                            // Get the fields's existing value
                                                            NameData currentValue = NameData.fromJson(widget.gfield.value, source: LocationEncoding.database);

                                                            // Set the field's value
                                                            currentValue.first = text;
                                                            widget.gfield.value = json.encode(currentValue.toJson(destination: LocationEncoding.database));

                                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                                            widget.refreshForm();
                                                        });
                                                    },
                                                ),
                                            ])
                                        ),

                                        const SizedBox(width: 10),

                                        Expanded(child:
                                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                                formFieldLabel(labelText:  "Last Name",
                                                            fieldId:    widget.gfield.id,
                                                            isRequired: widget.gfield.isRequired),

                                                TextFormField(
                                                    controller:   widget.textEditingControllers["last"],
                                                    decoration:   InputDecoration(
                                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                                        hintText:      "Smith",
                                                        hintStyle:     gfieldHintStyle
                                                    ),
                                                    keyboardType: TextInputType.name,
                                                    onChanged:    (text) {
                                                        setState(() {
                                                            // Get the fields's existing value
                                                            NameData currentValue = NameData.fromJson(widget.gfield.value, source: LocationEncoding.database);

                                                            // Set the field's value
                                                            currentValue.last = text;
                                                            widget.gfield.value = json.encode(currentValue.toJson(destination: LocationEncoding.database));

                                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                                            widget.refreshForm();
                                                        });
                                                    }
                                                )
                                            ])
                                        )
                                    ]
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Password Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "password":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                      fieldId:          widget.gfield.id,
                                                      isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Field label
                                // !widget.showTitle ? null :
                                //     formFieldLabel(labelText:  "Password",
                                //                 fieldId:    widget.gfield.id,
                                //                 isRequired: widget.gfield.isRequired),

                                // Field
                                TextFormField(
                                    controller: widget.textEditingControllers["password"],
                                    decoration: InputDecoration(
                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                        hintText:      "password",
                                        hintStyle:     gfieldHintStyle,
                                        suffixIcon:    IconButton(
                                            icon: Icon(
                                                widget.passwordVisible ? Icons.visibility : Icons.visibility_off,
                                                color: Theme.of(context).primaryColorDark
                                            ),
                                            onPressed: () {
                                                setState(() {
                                                    widget.passwordVisible = !widget.passwordVisible;
                                                });
                                            }
                                        )
                                    ),
                                    keyboardType: TextInputType.text,
                                    obscureText:  !widget.passwordVisible,
                                    onChanged:    (text) {
                                        setState(() {
                                            // Get the field's existing value
                                            Map<String, dynamic> currentValue = (widget.gfield.value != null) ? json.decode(widget.gfield.value!) : passwordDefaultValue;

                                            // Set the field's value
                                            currentValue["password"] = text;
                                            widget.gfield.value = json.encode(currentValue);

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    },
                                ),

                                const SizedBox(height: 10),

                                // Confirm password field label
                                formFieldLabel(labelText:  "Confirm Password",
                                            fieldId:    widget.gfield.id,
                                            isRequired: widget.gfield.isRequired),

                                // Confirm password field
                                TextFormField(
                                    controller: widget.textEditingControllers["password_confirmation"],
                                    decoration: InputDecoration(
                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                        hintText:      "password",
                                        hintStyle:     gfieldHintStyle
                                    ),
                                    keyboardType: TextInputType.text,
                                    obscureText:  !widget.passwordVisible,
                                    onChanged:    (text) {
                                        setState(() {
                                            // Get the field's existing value
                                            Map<String, dynamic> currentValue = (widget.gfield.value != null) ? json.decode(widget.gfield.value!) : passwordDefaultValue;

                                            // Set the field's value
                                            currentValue["password_confirmation"] = text;
                                            widget.gfield.value = json.encode(currentValue);

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    },
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Phone Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "phone":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: (!widget.gfield.label.toLowerCase().contains("confirm")) ? gfieldVerticalPadding : EdgeInsets.zero,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                    fieldId:          widget.gfield.id,
                                                    isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Field label
                                /* (!widget.showTitle && */ (!widget.gfield.label.toLowerCase().contains("confirm")) ? null :
                                    formFieldLabel(labelText:  widget.gfield.label,
                                                fieldId:    widget.gfield.id,
                                                isRequired: widget.gfield.isRequired),

                                // Field
                                TextFormField(
                                    controller: widget.textEditingControllers[widget.gfield.label],
                                    decoration: InputDecoration(
                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                        hintText:      "(555) 555-5555",
                                        hintStyle:     gfieldHintStyle),
                                    keyboardType: TextInputType.phone,
                                    onChanged:    (text) {
                                        setState(() {
                                            // Set the field's value
                                            String currentValue = text;
                                            widget.gfield.value = json.encode(currentValue);

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    }
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Radio Button (Single-Select) Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "radio":
                if (widget.gfield.choices == null) { return Text("Error: No options were found."); }

                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                    fieldId:          widget.gfield.id,
                                                    isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Field label
                                // !widget.showTitle ? null :
                                //     formFieldLabel(labelText:  widget.gfield.label,
                                //                 fieldId:    widget.gfield.id,
                                //                 isRequired: widget.gfield.isRequired),

                                // Field
                                Container(
                                    decoration: isValid ? null : gfieldBoxDecoration.merge(
                                        BoxDecoration(
                                            border: Border.all(
                                                color: BeColorSwatch.red,
                                                width: gfieldBoxDecoration.border!.top.width
                                            ),
                                        )
                                    ),
                                    child: ListView.builder(
                                        itemBuilder: (context, index) => Transform.scale(
                                            origin: Offset(-160, 0),
                                            scale: 1.2,
                                            child: RadioListTile(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 0),
                                                groupValue:     (() {
                                                    var selectedChoiceList = widget.gfield.choices!.where((choice) => choice["isSelected"]).toList();
                                                    if (selectedChoiceList.isEmpty) { return ""; }
                                                    return selectedChoiceList[0]["value"];
                                                })(),
                                                materialTapTargetSize: MaterialTapTargetSize.padded,
                                                onChanged: (value) {
                                                    setState(() {
                                                        for (var choice in widget.gfield.choices!) {
                                                            if (value == choice["value"]) {
                                                                choice["isSelected"] = true;

                                                                // Set the field's value
                                                                widget.gfield.value = json.encode(choice["text"]);

                                                            } else {
                                                                choice["isSelected"] = false;
                                                            }
                                                        }
                                                        // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                                        widget.refreshForm();
                                                    });
                                                },
                                                selected:     widget.gfield.choices![index]["isSelected"],
                                                title:        Text(
                                                    widget.gfield.choices![index]["text"],
                                                    style: TextStyle(
                                                        color:     Theme.of(context).colorScheme.onSurface,
                                                        fontSize: (Theme.of(context).textTheme.bodyMedium!.fontSize! / 1.2)
                                                    )
                                                ),
                                                value:         widget.gfield.choices![index]["value"],
                                                visualDensity: VisualDensity.compact,
                                            )
                                        ),

                                        itemCount:   widget.gfield.choices!.length,
                                        physics:     const NeverScrollableScrollPhysics(),
                                        shrinkWrap:  true,
                                    )
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Select (Drop-Down) Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "select":
                if (widget.gfield.choices == null) { return Text("Error: No options were found for drop-down field."); }

                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                    fieldId:          widget.gfield.id,
                                                    isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Field label
                                // !widget.showTitle ? null :
                                //     formFieldLabel(labelText:  widget.gfield.label,
                                //                 fieldId:    widget.gfield.id,
                                //                 isRequired: widget.gfield.isRequired),

                                // Field
                            DropdownButtonFormField<dynamic>(
                                    decoration: isValid ? gfieldInputDecoration : gfieldInputDecoration.copyWith(
                                        enabledBorder: gfieldInputDecoration.enabledBorder!.copyWith(
                                            borderSide: gfieldInputDecoration.enabledBorder!.borderSide.copyWith(color: BeColorSwatch.red)
                                        )
                                    ),
                                    icon:       gfieldDropDownIcon,
                                    isExpanded: true,
                                    style:      Theme.of(context).textTheme.bodyMedium,
                                    value:      (() {
                                        var selectedChoiceList = widget.gfield.choices!.where((choice) => choice["isSelected"]).toList();

                                        if (selectedChoiceList.isEmpty) { return ""; }
                                        return selectedChoiceList[0]["value"];
                                    })(),
                                    items:  widget.gfield.choices!.map<DropdownMenuItem<dynamic>>((dynamic value) {
                                        return DropdownMenuItem<dynamic>(
                                            value: value["value"],
                                            child: Text(value["text"]),
                                        );
                                    }).toList(),
                                    onChanged: (value) {
                                        setState(() {
                                            for (var choice in widget.gfield.choices!) {
                                                if (value == choice["value"]) {
                                                    choice["isSelected"] = true;

                                                    // Set the field's value
                                                    widget.gfield.value = json.encode(choice["value"]);

                                                } else {
                                                    choice["isSelected"] = false;
                                                }
                                            }

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    }
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Text Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "text":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                      fieldId:          widget.gfield.id,
                                                      isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Field label
                                // !widget.showTitle ? null :
                                //     formFieldLabel(
                                //         fieldId:    widget.gfield.id,
                                //         labelText:  widget.gfield.label,
                                //         isRequired: widget.gfield.isRequired,
                                //     ),

                                // Field
                                TextFormField(
                                    controller: widget.textEditingControllers[widget.gfield.label],
                                    decoration: InputDecoration(
                                        enabledBorder: isValid ? null : gfieldRoundedBorder.copyWith(borderSide: gfieldRoundedBorder.borderSide.copyWith(color: BeColorSwatch.red)),
                                        hintText:      widget.gfield.placeholder,
                                        hintStyle:     gfieldHintStyle),
                                    keyboardType: TextInputType.text,
                                    onChanged:    (text) {
                                        setState(() {
                                            // Set the field's value
                                            String currentValue = text;
                                            widget.gfield.value = json.encode(currentValue);

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    }
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Signature Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "signature":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                    fieldId:          widget.gfield.id,
                                                    isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                Row(crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                                    children: [

                                        // Field label
                                        !widget.showTitle ? null :
                                            formFieldLabel(labelText:  widget.gfield.label,
                                                        fieldId:    widget.gfield.id,
                                                        isRequired: widget.gfield.isRequired
                                            ),

                                        // Reset field button
                                        InkWell(
                                            onTap: () { signatureGlobalKey.currentState!.clear(); },
                                            child: Text("Clear".toUpperCase(), style: beTextTheme.captionPrimary.merge(TextStyle(color: BeColorSwatch.blue))),
                                        )
                                    ].nonNulls.toList()
                                ),

                                Container(
                                    decoration: gfieldBoxDecoration,

                                    // Signature field
                                    child: SfSignaturePad(
                                        key:                signatureGlobalKey,
                                        backgroundColor:    Colors.transparent,
                                        strokeColor:        Colors.black,
                                        minimumStrokeWidth: 1.0,
                                        maximumStrokeWidth: 4.0,
                                        onDrawEnd: () async {
                                            ByteData data = (await _getSignatureAsByteData())!;
                                            final dataAsList = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
                                            final newValue = Utf8Decoder().convert(dataAsList);
                                            logPrint("ℹ️  New Value: ${newValue}");

                                            setState(() {
                                                // Get the signature image's byte data and save it to the field's value
                                                widget.gfield.value = newValue;
                                            });
                                            // On submit, upload signatures to /uploads/gravity_forms/signatures
                                            // Name the file using uniqid("", true) PHP func.
                                            // ONce returned, use that filename as the field value - submit form
                                        }
                                    )
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Username Field
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "username":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                    fieldId:          widget.gfield.id,
                                                    isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Field label
                                !widget.showTitle ? null :
                                    formFieldLabel(labelText:  "Username",
                                                fieldId:    widget.gfield.id,
                                                isRequired: widget.gfield.isRequired),

                                // Field
                                TextFormField(
                                    controller:   widget.textEditingControllers[widget.gfield.label],
                                    decoration:   InputDecoration(
                                        hintText:  "myusername123",
                                        hintStyle: gfieldHintStyle
                                    ),
                                    keyboardType: TextInputType.text,
                                    onChanged:    (text) {
                                        setState(() {
                                            // Set the field's value
                                            String currentValue = text;
                                            widget.gfield.value = json.encode(currentValue);

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    }
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Section (Heading)
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "section":
                if (widget.gfield.label.isEmpty) { const Divider(); }

                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Text(
                            widget.gfield.label,
                            style: TextStyle(
                                        fontSize:   28,
                                        fontWeight: FontWeight.w900
                            )
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Page Break
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "page":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 12),
                        child:   Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                // Only show the previous/next page buttons if their respective functions exist

                                (widget.previousPage is! Function) ? null :
                                    ElevatedButton(
                                        onPressed:       () { widget.previousPage!(); },
                                        child:           Text("Previous")
                                    ),

                                const Spacer(),

                                (widget.nextPage is! Function) ? null :
                                    ElevatedButton(
                                        onPressed:       () { widget.nextPage!(); },
                                        child:           Text("Next")
                                    )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Multi-Line Text
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "textarea":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                    fieldId:          widget.gfield.id,
                                                    isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Field label
                                !widget.showTitle ? null :
                                    formFieldLabel(labelText:  widget.gfield.label,
                                                fieldId:    widget.gfield.id,
                                                isRequired: widget.gfield.isRequired),

                                // Field
                                TextField(
                                    controller:   widget.textEditingControllers[widget.gfield.label],
                                    keyboardType: TextInputType.multiline,
                                    maxLines:     null,
                                    minLines:     4,
                                    onChanged:    (text) {
                                        setState(() {
                                            // Set the field's value
                                            String currentValue = text;
                                            widget.gfield.value = json.encode(currentValue);

                                            // Rebuild the form to ensure conditionally associated widgets are rebuilt
                                            widget.refreshForm();
                                        });
                                    }
                                )
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: File Upload
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "fileupload":
                return  Visibility(
                    maintainState: true,
                    visible:       widget.onPage,
                    child:         Padding(
                        padding: gfieldVerticalPadding,
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           [

                                // Field description
                                !widget.showDescription ? null :
                                    formFieldDescription(descriptionText:  widget.gfield.description,
                                                    fieldId:          widget.gfield.id,
                                                    isRequired:       widget.gfield.isRequired),

                                // Validation message
                                gfieldValidationMessage,

                                // Field label
                                !widget.showTitle ? null :
                                    formFieldLabel(labelText:  widget.gfield.label,
                                                fieldId:    widget.gfield.id,
                                                isRequired: widget.gfield.isRequired),

                                // Field
                                // CameraRollUploader()
                                Text("Photo Uploader (temporarily disabled for debugging)")
                            ].nonNulls.toList()
                        )
                    )
                );




            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Non-Rendered Fields
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            case "html":
            default:
                return const SizedBox.shrink();
        }
    }
}
