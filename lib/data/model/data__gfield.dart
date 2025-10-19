//
// GField Data
//
// Created by:  Blake Davis
// Description: Gravity Forms field data model
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

import "dart:convert";

import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/type_extensions.dart";

import "package:collection/collection.dart";








// =====================================================================================================================
// MARK: GField Data Model
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class GFieldData {

    int     id,
            formId,
            pageNumber;

    bool    displayOnly,
            isRequired,
            validateState;

    dynamic conditionalLogic;

    List<dynamic>?
            choices,
            inputs;

    String  defaultValue,
            description,
            errorMessage,
            inputName,
            label,
            placeholder,
            type,
            visibility;

     // content: Used (only?) by HTML fields to store a string of HTML tags
     // value:   Used by GFormEntry objects to store the GField's value-to-be-submitted
    String? content,
            value;




    // -----------------------------------------------------------------------------------------------------------------
    // MARK: Constructor
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    GFieldData({    required this.id,

                    required this.choices,
                    required this.conditionalLogic,
                    required this.content,
                    required this.defaultValue,
                    required this.description,
                    required this.displayOnly,
                    required this.errorMessage,
                    required this.formId,
                    required this.inputName,
                    required this.inputs,
                    required this.isRequired,
                    required this.label,
                    required this.pageNumber,
                    required this.placeholder,
                    required this.type,
                    required this.validateState,
                                  value,
                    required this.visibility
    });








    // -----------------------------------------------------------------------------------------------------------------
    // MARK: Default/Empty GFieldData
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    factory GFieldData.empty() {
        return GFieldData(
            id:               0,
            choices:          <dynamic>[],
            conditionalLogic: null,
            content:          "",
            defaultValue:     "",
            description:      "",
            displayOnly:      false,
            errorMessage:     "",
            formId:           0,
            inputName:        "",
            inputs:           <dynamic>[],
            isRequired:       false,
            label:            "",
            pageNumber:        1, // Annoyingly, Gravity Forms starts the page numbers on 1
            placeholder:      "",
            type:             "",
            validateState:    false,
            value:            "",
            visibility:       "visible"
        );
    }







    // -----------------------------------------------------------------------------------------------------------------
    // MARK: == Operator Override
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    @override
    bool operator ==(Object other) {
                                 return other is GFieldData                           &&
                                        other.id                 == id                &&
        DeepCollectionEquality().equals(other.choices,              choices)          &&
        DeepCollectionEquality().equals(other.conditionalLogic,     conditionalLogic) &&
                                        other.content            == content           &&
                                        other.defaultValue       == defaultValue      &&
                                        other.description        == description       &&
                                        other.displayOnly        == displayOnly       &&
                                        other.errorMessage       == errorMessage      &&
                                        other.formId             == formId            &&
                                        other.inputName          == inputName         &&
        DeepCollectionEquality().equals(other.inputs,               inputs)           &&
                                        other.isRequired         == isRequired        &&
                                        other.label              == label             &&
                                        other.pageNumber         == pageNumber        &&
                                        other.placeholder        == placeholder       &&
                                        other.type               == type              &&
                                        other.validateState      == validateState     &&
                                        other.value              == value             &&
                                        other.visibility         == visibility;
    }








    // -----------------------------------------------------------------------------------------------------------------
    // MARK: HashCode Override
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    @override
    int get hashCode => Object.hash(
                                        id,
                         Object.hashAll(choices ?? []),
          DeepCollectionEquality().hash(conditionalLogic),
                                        content,
                                        defaultValue,
                                        description,
                                        displayOnly,
                                        errorMessage,
                                        formId,
                                        inputName,
                         Object.hashAll(inputs ?? []),
                                        isRequired,
                                        label,
                                        pageNumber,
                                        placeholder,
                                        type,
                                        validateState,
                                        value,
                                        visibility
    );








    // -----------------------------------------------------------------------------------------------------------------
    // MARK: GFieldData -> JSON
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  GFieldDataInfo.id              .jsonName  :  GFieldDataInfo.id              .columnName):                id,

            (apiOrDatabase  ?  GFieldDataInfo.choices         .jsonName  :  GFieldDataInfo.choices         .columnName):    json.encode(choices),
            (apiOrDatabase  ?  GFieldDataInfo.conditionalLogic.jsonName  :  GFieldDataInfo.conditionalLogic.columnName):    json.encode(conditionalLogic),
            (apiOrDatabase  ?  GFieldDataInfo.content         .jsonName  :  GFieldDataInfo.content         .columnName):                content,
            (apiOrDatabase  ?  GFieldDataInfo.defaultValue    .jsonName  :  GFieldDataInfo.defaultValue    .columnName):                defaultValue,
            (apiOrDatabase  ?  GFieldDataInfo.description     .jsonName  :  GFieldDataInfo.description     .columnName):                description,
            (apiOrDatabase  ?  GFieldDataInfo.displayOnly     .jsonName  :  GFieldDataInfo.displayOnly     .columnName):                displayOnly,
            (apiOrDatabase  ?  GFieldDataInfo.errorMessage    .jsonName  :  GFieldDataInfo.errorMessage    .columnName):                errorMessage,
            (apiOrDatabase  ?  GFieldDataInfo.formId          .jsonName  :  GFieldDataInfo.formId          .columnName):                formId,
            (apiOrDatabase  ?  GFieldDataInfo.inputName       .jsonName  :  GFieldDataInfo.inputName       .columnName):                inputName,
            (apiOrDatabase  ?  GFieldDataInfo.inputs          .jsonName  :  GFieldDataInfo.inputs          .columnName):    json.encode(inputs),
            (apiOrDatabase  ?  GFieldDataInfo.isRequired      .jsonName  :  GFieldDataInfo.isRequired      .columnName):                (apiOrDatabase ? isRequired : isRequired.toInt()),
            (apiOrDatabase  ?  GFieldDataInfo.label           .jsonName  :  GFieldDataInfo.label           .columnName):                label,
            (apiOrDatabase  ?  GFieldDataInfo.pageNumber      .jsonName  :  GFieldDataInfo.pageNumber      .columnName):                pageNumber,
            (apiOrDatabase  ?  GFieldDataInfo.placeholder     .jsonName  :  GFieldDataInfo.placeholder     .columnName):                placeholder,
            (apiOrDatabase  ?  GFieldDataInfo.type            .jsonName  :  GFieldDataInfo.type            .columnName):                type,
            (apiOrDatabase  ?  GFieldDataInfo.validateState   .jsonName  :  GFieldDataInfo.validateState   .columnName):                validateState,
            (apiOrDatabase  ?  GFieldDataInfo.value           .jsonName  :  GFieldDataInfo.value           .columnName):                value,
            (apiOrDatabase  ?  GFieldDataInfo.visibility      .jsonName  :  GFieldDataInfo.visibility      .columnName):                visibility,
        };
    }








    // -----------------------------------------------------------------------------------------------------------------
    // MARK: JSON -> GFieldData
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    factory GFieldData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions)
        final bool apiOrDatabase = (source == LocationEncoding.api);

        // Convert jsonAsDynamic to a Map if it isn't
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return GFieldData.empty(); }
        }

        // Decode "choices"
        dynamic choicesAsDynamic = (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.choices.jsonName]  :  jsonAsMap[GFieldDataInfo.choices.columnName]);
        List<dynamic> choicesAsList = [];

        if (choicesAsDynamic is List) {
            choicesAsList = choicesAsDynamic;
        } else {
            choicesAsList = json.decodeTo(List.empty, dataAsString: (choicesAsDynamic ?? "").toString());
        }


        // Decode "inputs"
        dynamic inputsAsDynamic = (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.inputs.jsonName]  :  jsonAsMap[GFieldDataInfo.inputs.columnName]);
        List<dynamic> inputsAsList = [];

        if (inputsAsDynamic is List) {
            inputsAsList = inputsAsDynamic;
        } else {
            inputsAsList = json.decodeTo(List.empty, dataAsString: (inputsAsDynamic ?? "").toString());
        }


        // Decode "conditionalLogic"
        dynamic conditionalLogicAsDynamic = (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.conditionalLogic.jsonName]  :  jsonAsMap[GFieldDataInfo.conditionalLogic.columnName]);
        Map<String, dynamic> conditionalLogicAsMap = {};

        if (conditionalLogicAsDynamic is Map) {
            conditionalLogicAsMap = conditionalLogicAsDynamic as Map<String, dynamic>;
        } else {
            conditionalLogicAsMap = json.decodeTo(Map.new, dataAsString: (conditionalLogicAsDynamic ?? "").toString());
        }


        return GFieldData(
            id:                (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.id              .jsonName]  :  jsonAsMap[GFieldDataInfo.id              .columnName])    as int,

            choices:            choicesAsList,
            conditionalLogic:   conditionalLogicAsMap,
            content:           (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.content         .jsonName]  :  jsonAsMap[GFieldDataInfo.content         .columnName])    as String?,
            defaultValue:      (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.defaultValue    .jsonName]  :  jsonAsMap[GFieldDataInfo.defaultValue    .columnName])    as String,
            description:       (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.description     .jsonName]  :  jsonAsMap[GFieldDataInfo.description     .columnName])    as String,
            displayOnly:      ((apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.displayOnly     .jsonName]  :  jsonAsMap[GFieldDataInfo.displayOnly     .columnName])    == "1"),
            errorMessage:      (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.errorMessage    .jsonName]  :  jsonAsMap[GFieldDataInfo.errorMessage    .columnName])    as String,
            formId:            (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.formId          .jsonName]  :  jsonAsMap[GFieldDataInfo.formId          .columnName])    as int,
            inputName:         (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.inputName       .jsonName]  :  jsonAsMap[GFieldDataInfo.inputName       .columnName])    as String,
            inputs:             inputsAsList,
            isRequired:       ((apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.isRequired      .jsonName]  :  jsonAsMap[GFieldDataInfo.isRequired      .columnName])    == (apiOrDatabase ? true : 1)),
            label:             (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.label           .jsonName]  :  jsonAsMap[GFieldDataInfo.label           .columnName])    as String,
            pageNumber:        (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.pageNumber      .jsonName]  :  jsonAsMap[GFieldDataInfo.pageNumber      .columnName])    as int,
            placeholder:       (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.placeholder     .jsonName]  :  jsonAsMap[GFieldDataInfo.placeholder     .columnName])    as String,
            type:              (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.type            .jsonName]  :  jsonAsMap[GFieldDataInfo.type            .columnName])    as String,
            validateState:    ((apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.validateState   .jsonName]  :  jsonAsMap[GFieldDataInfo.validateState   .columnName])    == "1"),
            value:             (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.value           .jsonName]  :  jsonAsMap[GFieldDataInfo.value           .columnName])    as String?,
            visibility:        (apiOrDatabase  ?  jsonAsMap[GFieldDataInfo.visibility      .jsonName]  :  jsonAsMap[GFieldDataInfo.visibility      .columnName])    as String
        );
    }
}








// =====================================================================================================================
// MARK: Object & Table Info
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
enum GFieldDataInfo {

    id(               "id",                  "id",                    idType),
    choices(          "choices",             "choices",             blobType),
    conditionalLogic( "conditionalLogic",    "conditionalLogic",    blobType),
    content(          "content",             "content",             textType),
    defaultValue(     "defaultValue",        "defaultValue",        textType),
    description(      "description",         "description",         textType),
    displayOnly(      "displayOnly",         "displayOnly",          intType),
    errorMessage(     "errorMessage",        "errorMessage",        textType),
    formId(           "formId",              "formId",               intType),
    inputName(        "inputName",           "inputName",           textType),
    inputs(           "inputs",              "inputs",              blobType),
    isRequired(       "isRequired",          "isRequired",           intType),
    label(            "label",               "label",               textType),
    pageNumber(       "pageNumber",          "pageNumber",           intType),
    placeholder(      "placeholder",         "placeholder",         textType),
    type(             "type",                "type",                textType),
    validateState(    "validateState",       "validateState",        intType),
    value(            "value",               "value",               textType),
    visibility(       "visibility",          "visibility",          textType);

    const GFieldDataInfo(this.columnName, this.jsonName, this.columnType);

    final String columnName;
    final String columnType;
    final String jsonName;


    static List<String> get columnNameValues {
        return GFieldDataInfo.values.map((value) { return value.columnName; }).toList();
    }

    static List<String> get jsonNameValues {
        return GFieldDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static const blobType = "BLOB NOT NULL";
    static const idType   = "INTEGER PRIMARY KEY";
    static const intType  = "INTEGER NOT NULL";
    static const textType = "TEXT NOT NULL";




    static Type   get objectType     => GFieldData;
    static String get objectTypeName => "gfield";
}