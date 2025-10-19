/**
 *  Type Extensions
 *
 * Created by:  Blake Davis
 * Description: Type extensions
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";


import "package:bmd_flutter_tools/utilities/print_utilities.dart";


import "package:flutter/material.dart";








/* =====================================================================================================================
 * MARK: Bool Extensions
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
extension BoolExtensions on bool {

    int toInt() => this ? 1 : 0;
}








/* =====================================================================================================================
 * MARK: BoxDecoration Extensions
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
extension BoxDecorationExtensions on BoxDecoration {

    BoxDecoration merge(BoxDecoration? other) {
        return BoxDecoration(
            color:                  other?.color                ?? color,
            image:                  other?.image                ?? image,
            border:                 other?.border               ?? border,
            borderRadius:           other?.borderRadius         ?? borderRadius,
            boxShadow:              other?.boxShadow            ?? boxShadow,
            gradient:               other?.gradient             ?? gradient,
            backgroundBlendMode:    other?.backgroundBlendMode  ?? backgroundBlendMode,
            shape:                  other?.shape                ?? shape,
        );
    }
}








/* =====================================================================================================================
 * MARK: InputDecoration Extensions
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
extension InputDecorationExtensions on InputDecoration {

    InputDecoration merge(InputDecoration? other) {

        return InputDecoration(
            alignLabelWithHint:     other?.alignLabelWithHint       ?? alignLabelWithHint,
            border:                 other?.border                   ?? border,
            counter:                other?.counter                  ?? counter,
            counterStyle:           other?.counterStyle             ?? counterStyle,
            counterText:            other?.counterText              ?? counterText,
            contentPadding:         other?.contentPadding           ?? contentPadding,
            disabledBorder:         other?.disabledBorder           ?? disabledBorder,
            enabled:                other?.enabled                  ?? enabled,
            enabledBorder:          other?.enabledBorder            ?? enabledBorder,
            errorBorder:            other?.errorBorder              ?? errorBorder,
            errorMaxLines:          other?.errorMaxLines            ?? errorMaxLines,
            errorStyle:             other?.errorStyle               ?? errorStyle,
            errorText:              other?.errorText                ?? errorText,
            fillColor:              other?.fillColor                ?? fillColor,
            filled:                 other?.filled                   ?? filled,
            floatingLabelBehavior:  other?.floatingLabelBehavior    ?? floatingLabelBehavior,
            focusColor:             other?.focusColor               ?? focusColor,
            focusedBorder:          other?.focusedBorder            ?? focusedBorder,
            focusedErrorBorder:     other?.focusedErrorBorder       ?? focusedErrorBorder,
            helperStyle:            other?.helperStyle              ?? helperStyle,
            helperText:             other?.helperText               ?? helperText,
            hintMaxLines:           other?.hintMaxLines             ?? hintMaxLines,
            hintStyle:              other?.hintStyle                ?? hintStyle,
            hintText:               other?.hintText                 ?? hintText,
            hoverColor:             other?.hoverColor               ?? hoverColor,
            icon:                   other?.icon                     ?? icon,
            isCollapsed:            other?.isCollapsed              ?? isCollapsed,
            isDense:                other?.isDense                  ?? isDense,
            labelStyle:             other?.labelStyle               ?? labelStyle,
            labelText:              other?.labelText                ?? labelText,
            prefix:                 other?.prefix                   ?? prefix,
            prefixIcon:             other?.prefixIcon               ?? prefixIcon,
            prefixStyle:            other?.prefixStyle              ?? prefixStyle,
            prefixText:             other?.prefixText               ?? prefixText,
            semanticCounterText:    other?.semanticCounterText      ?? semanticCounterText,
            suffix:                 other?.suffix                   ?? suffix,
            suffixIcon:             other?.suffixIcon               ?? suffixIcon,
            suffixStyle:            other?.suffixStyle              ?? suffixStyle,
            suffixText:             other?.suffixText               ?? suffixText,
        );
    }
}








/* =====================================================================================================================
 * MARK: JSON Extensions
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
typedef ItemCreator<T> = T Function();

extension JSONExtensions on JsonCodec {
    /**
     *  Parse the JSON string to a specified type; returns an empty instance of the type
     *  if the string is empty or if there is a type mismatch between the input string
     *  and the specified type.
     *
     *  Useful for cases where an API may return an empty string for an empty value, but a
     *  string representation of a JSON object for a non-empty value. E.g.:
     *
     *  |  case  |  input                              |  json.decode output           |  json.decodeTo output (where T is List) |
     *  |--------|-------------------------------------|-------------------------------|-----------------------------------------|
     *  |     1  |  '{ "expectsArray": "[1, 2, 3]" }'  |  { expectsArray: [1, 2, 3] }  |  { expectsArray: [1, 2, 3] }            |
     *  |     2  |  '{ "expectsArray": "" }'           |  { expectsArray: "" }         |  { expectsArray: [] }                   |
     *
     *      Non-empty values return as JSON string, as expected,
     *      but empty values return as the "wrong" type: an empty string.
     *
     */
    T decodeTo<T>(T Function() creator, { required String dataAsString }) {

        T dataAsT = creator();

        if (dataAsString != "") {
            try {
                dataAsT = json.decode(dataAsString) as T;

            } catch(error) {
                logPrint("❌  decoding JSON string: ${error}");
            }
        }
        return dataAsT;
    }
}








/* =====================================================================================================================
 * MARK: Object Extensions
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
extension JsonToListX on Object? {

    List<Map<String, dynamic>> ensureList() {

        if (this is List) {
            return (this as List).cast<Map<String, dynamic>>();
        }
        if (this is Map) {
            return [(this as Map).cast<String, dynamic>()];
        }
        return const [];
    }
}








/* =====================================================================================================================
 * MARK: String Extensions
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
extension StringExtensions on String {

    int? toInt() {
        return int.parse(this);
    }
}