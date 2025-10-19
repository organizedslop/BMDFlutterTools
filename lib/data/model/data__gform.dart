/**
 * Created by:  Blake Davis
 * Description: Gravity Forms form data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";

import "package:bmd_flutter_tools/data/model/data__gfield.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";

import "package:collection/collection.dart";




/* =============================================================================
 * MARK: GForm Data Model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 */
class GFormData {

    int     formId;

    bool    saveEnabled;

    List<GFieldData>
            fields;

    Map<String, dynamic>
            pagination;

    String  description,
            title,
            version;




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Constructor
     */
    GFormData({ required this.formId,

                required this.description,
                required this.fields,
                required this.pagination,
                required this.saveEnabled,
                required this.title,
                required this.version,
    });




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: == Operator Override
     */
    @override
    bool operator ==(Object other) {
        return other is GFormData               &&
               other.formId      == formId      &&
               other.description == description &&
               DeepCollectionEquality().equals(other.fields, fields)         &&
               DeepCollectionEquality().equals(other.pagination, pagination) &&
               other.saveEnabled == saveEnabled &&
               other.title       == title       &&
               other.version     == version;
    }




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: HashCode Override
     */
    @override
    int get hashCode => Object.hash(formId,
                                    description,
                                    Object.hashAll(fields),
                                    DeepCollectionEquality().hash(pagination),
                                    saveEnabled,
                                    title,
                                    version);








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: GFormData -> JSON
     */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions).
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  GFormDataInfo.formId     .jsonName  :  GFormDataInfo.formId     .columnName):                formId,

            (apiOrDatabase  ?  GFormDataInfo.description.jsonName  :  GFormDataInfo.description.columnName):                description,
            (apiOrDatabase  ?  GFormDataInfo.fields     .jsonName  :  GFormDataInfo.fields     .columnName):    json.encode(fields.map((field) { return field.toJson(destination: destination); }).toList()),
            (apiOrDatabase  ?  GFormDataInfo.pagination .jsonName  :  GFormDataInfo.pagination .columnName):    json.encode(pagination),
            (apiOrDatabase  ?  GFormDataInfo.saveEnabled.jsonName  :  GFormDataInfo.saveEnabled.columnName):                saveEnabled.toInt(),
            (apiOrDatabase  ?  GFormDataInfo.title      .jsonName  :  GFormDataInfo.title      .columnName):                title,
            (apiOrDatabase  ?  GFormDataInfo.version    .jsonName  :  GFormDataInfo.version    .columnName):                version,
        };
    }




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: JSON -> GFormData
     */
    factory GFormData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions).
        final bool apiOrDatabase = (source == LocationEncoding.api);


        // Determine if the JSON data is a string or a map. Otherwise, throw an error.
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return GFormData.empty(); }
        }

        // Decode "pagination"
        dynamic paginationAsDynamic =  jsonAsMap[apiOrDatabase  ?  GFormDataInfo.pagination.jsonName  :  GFormDataInfo.pagination.columnName];
        Map<String, dynamic> paginationAsMap = {};

        if (paginationAsDynamic is Map) {
            paginationAsMap = paginationAsDynamic as Map<String, dynamic>;
        } else {
            paginationAsMap = json.decodeTo(Map.new, dataAsString: paginationAsMap.toString());
        }


        // Decode "fields"
        dynamic fieldsAsDynamic = jsonAsMap[apiOrDatabase  ?  GFormDataInfo.fields.jsonName  :  GFormDataInfo.fields.columnName];
        List<dynamic>    fieldsAsList             = [];
        List<GFieldData> fieldsAsListOfGFieldData = [];

        if (fieldsAsDynamic is List) {
            fieldsAsList = fieldsAsDynamic;
        } else {
            fieldsAsList = json.decodeTo(List.empty, dataAsString: fieldsAsDynamic.toString());
        }

        for (var fieldJson in fieldsAsList) {
            if (fieldJson is Map) {
                fieldsAsListOfGFieldData.add(GFieldData.fromJson(fieldJson, source: source));
            }
        }




        return GFormData(
            formId:                jsonAsMap[apiOrDatabase  ?  GFormDataInfo.formId     .jsonName  :  GFormDataInfo.formId     .columnName]    as int,

            description:           jsonAsMap[apiOrDatabase  ?  GFormDataInfo.description.jsonName  :  GFormDataInfo.description.columnName]    as String,
            fields:                fieldsAsListOfGFieldData,
            pagination:            paginationAsMap,
            saveEnabled:           jsonAsMap[apiOrDatabase  ?  GFormDataInfo.saveEnabled.jsonName  :  GFormDataInfo.saveEnabled.columnName] == 1 ? true : false,
            title:                 jsonAsMap[apiOrDatabase  ?  GFormDataInfo.title      .jsonName  :  GFormDataInfo.title      .columnName]    as String,
            version:               jsonAsMap[apiOrDatabase  ?  GFormDataInfo.version    .jsonName  :  GFormDataInfo.version    .columnName]    as String,
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Default/Empty GFormData
     */
    factory GFormData.empty() {
        return GFormData(formId: 0, description: "", fields: <GFieldData>[], pagination: {}, saveEnabled: false, title: "", version: "0.0.0");
    }
}








/* =============================================================================
 * MARK: Object & Table Info
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 */
enum GFormDataInfo {

    formId(     "gform_id",       "id",               idType),
    description("description",    "description",    textType),
    fields(     "fields",         "fields",         blobType),
    pagination( "pagination",     "pagination",     blobType),
    saveEnabled("saveEnabled",    "saveEnabled",     intType),
    title(      "title",          "title",          textType),
    version(    "version",        "version",        textType);

    const GFormDataInfo(this.columnName, this.jsonName, this.columnType);

    final String columnName;
    final String columnType;
    final String jsonName;


    static List<String> get columnNameValues {
        return GFormDataInfo.values.map((value) { return value.columnName; }).toList();
    }

    static List<String> get jsonNameValues {
        return GFormDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static const String blobType = "BLOB NOT NULL";
    static const String idType   = "INTEGER PRIMARY KEY";
    static const String intType  = "INTEGER NOT NULL";
    static const String textType = "TEXT NOT NULL";




    static Type   get objectType     => GFormData;
    static String get objectTypeName => "gform";
    static String get tableName      => "gforms";

    static String get tableBuilder {

        return "CREATE TABLE IF NOT EXISTS ${GFormDataInfo.tableName} (" +
            GFormDataInfo.formId     .columnName    + " " +    GFormDataInfo.formId     .columnType    + ", " +
            GFormDataInfo.description.columnName    + " " +    GFormDataInfo.description.columnType    + ", " +
            GFormDataInfo.fields     .columnName    + " " +    GFormDataInfo.fields     .columnType    + ", " +
            GFormDataInfo.pagination .columnName    + " " +    GFormDataInfo.pagination .columnType    + ", " +
            GFormDataInfo.saveEnabled.columnName    + " " +    GFormDataInfo.saveEnabled.columnType    + ", " +
            GFormDataInfo.title      .columnName    + " " +    GFormDataInfo.title      .columnType    + ", " +
            GFormDataInfo.version    .columnName    + " " +    GFormDataInfo.version    .columnType    + ")";
    }
}

