/**
 * Created by:  Blake Davis
 * Description: Gravity Forms entry data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";


import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/api_client.dart";

import "package:bmd_flutter_tools/data/model/data__gfield.dart";
import "package:bmd_flutter_tools/data/model/data__gform.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";

import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/type_extensions.dart";


import "package:collection/collection.dart";

import "package:uuid/uuid.dart";




/* =============================================================================
 * MARK: GForm Entry Data Model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 */
class GFormEntryData extends GFormData {

    String id;        // Entry ID

    int createdBy;    // User ID

    String created,   // Unix date-time
           modified,  //
           status;    //

            // resume url
            // is_approved


    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Constructor
     */
    GFormEntryData({    id,

                        created,
                        createdBy,
                  super.description = "",
                  super.fields      = const <GFieldData>[],
         required super.formId,
                        modified,
                  super.pagination  = const {},
                  super.saveEnabled = false,
                        status,
                  super.title       = "",
                  super.version     = "0.0.1",

    })  :   this.id        =  id         ?? Uuid().v4(),
            this.created   =  created    ?? DateTime.now().millisecondsSinceEpoch.toString(),
            this.createdBy =  createdBy  ?? 0,
            this.modified  =  modified   ?? DateTime.now().millisecondsSinceEpoch.toString(),
            this.status    =  status     ?? "pending";




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: == Operator Override
     */
    @override
    bool operator ==(Object other) {
        return other is GFormEntryData          &&
               other.id          == id          &&
               other.created     == created     &&
               other.createdBy   == createdBy   &&
               other.description == description &&
               DeepCollectionEquality().equals(other.fields, fields)         &&
               other.formId      == formId      &&
               other.modified    == modified    &&
               DeepCollectionEquality().equals(other.pagination, pagination) &&
               other.saveEnabled == saveEnabled &&
               other.status      == status      &&
               other.title       == title       &&
               other.version     == version;
    }




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: HashCode Override
     */
    @override
    int get hashCode => Object.hash(super.hashCode,
                                    id,
                                    created,
                                    createdBy,
                                    modified,
                                    status);








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: GFormEntryData -> JSON
     */
    @override
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions).
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  GFormEntryDataInfo.id         .jsonName  :  GFormEntryDataInfo.id         .columnName):                id,

            (apiOrDatabase  ?  GFormEntryDataInfo.created    .jsonName  :  GFormEntryDataInfo.created    .columnName):                created,
            (apiOrDatabase  ?  GFormEntryDataInfo.createdBy  .jsonName  :  GFormEntryDataInfo.createdBy  .columnName):                createdBy,
            (apiOrDatabase  ?  GFormEntryDataInfo.description.jsonName  :  GFormEntryDataInfo.description.columnName):                description,
            (apiOrDatabase  ?  GFormEntryDataInfo.fields     .jsonName  :  GFormEntryDataInfo.fields     .columnName):    json.encode(fields.map((field) { return field.toJson(destination: destination); }).toList()),
            (apiOrDatabase  ?  GFormEntryDataInfo.formId     .jsonName  :  GFormEntryDataInfo.formId     .columnName):                formId,
            (apiOrDatabase  ?  GFormEntryDataInfo.modified   .jsonName  :  GFormEntryDataInfo.modified   .columnName):                modified,
            (apiOrDatabase  ?  GFormEntryDataInfo.pagination .jsonName  :  GFormEntryDataInfo.pagination .columnName):    json.encode(pagination),
            (apiOrDatabase  ?  GFormEntryDataInfo.saveEnabled.jsonName  :  GFormEntryDataInfo.saveEnabled.columnName):                saveEnabled.toInt(),
            (apiOrDatabase  ?  GFormEntryDataInfo.status     .jsonName  :  GFormEntryDataInfo.status     .columnName):                status,
            (apiOrDatabase  ?  GFormEntryDataInfo.title      .jsonName  :  GFormEntryDataInfo.title      .columnName):                title,
            (apiOrDatabase  ?  GFormEntryDataInfo.version    .jsonName  :  GFormEntryDataInfo.version    .columnName):                version,
        };
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: JSON -> GFormEntryData
     */
    @override
    factory GFormEntryData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions).
        final bool apiOrDatabase = (source == LocationEncoding.api);


        // Create boolean value for the JSON's source (to shorten ternary expressions).
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return GFormEntryData.empty(); }
        }

        // Decode "pagination"
        dynamic paginationAsDynamic =  jsonAsMap[apiOrDatabase  ?  GFormDataInfo.pagination.jsonName  :  GFormDataInfo.pagination.columnName];
        Map<String, dynamic> paginationAsMap = {};

        if (paginationAsDynamic is Map) {
            paginationAsMap = paginationAsDynamic as Map<String, dynamic>;
        } else {
            paginationAsMap = json.decodeTo(Map.new, dataAsString: paginationAsDynamic.toString());
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




        return GFormEntryData(
            id:             jsonAsMap[apiOrDatabase  ?  GFormEntryDataInfo.id         .jsonName  :  GFormEntryDataInfo.id         .columnName]    as String,

            created:        jsonAsMap[apiOrDatabase  ?  GFormEntryDataInfo.created    .jsonName  :  GFormEntryDataInfo.created    .columnName]    as String,
            createdBy:      jsonAsMap[apiOrDatabase  ?  GFormEntryDataInfo.createdBy  .jsonName  :  GFormEntryDataInfo.createdBy  .columnName]    as int,
            description:    jsonAsMap[apiOrDatabase  ?  GFormEntryDataInfo.description.jsonName  :  GFormEntryDataInfo.description.columnName]    as String,
            fields:         fieldsAsListOfGFieldData,
            formId:         jsonAsMap[apiOrDatabase  ?  GFormEntryDataInfo.formId     .jsonName  :  GFormEntryDataInfo.formId     .columnName]    as int,
            modified:       jsonAsMap[apiOrDatabase  ?  GFormEntryDataInfo.modified   .jsonName  :  GFormEntryDataInfo.modified   .columnName]    as String,
            pagination:     paginationAsMap,
            saveEnabled:    jsonAsMap[apiOrDatabase  ?  GFormEntryDataInfo.saveEnabled.jsonName  :  GFormEntryDataInfo.saveEnabled.columnName] == 1 ? true : false,
            status:         jsonAsMap[apiOrDatabase  ?  GFormEntryDataInfo.status     .jsonName  :  GFormEntryDataInfo.status     .columnName]    as String,
            title:          jsonAsMap[apiOrDatabase  ?  GFormEntryDataInfo.title      .jsonName  :  GFormEntryDataInfo.title      .columnName]    as String,
            version:        jsonAsMap[apiOrDatabase  ?  GFormEntryDataInfo.version    .jsonName  :  GFormEntryDataInfo.version    .columnName]    as String,
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: GFormData -> GFormEntryData
     */
    factory GFormEntryData.fromGFormData(GFormData gformData) {
        return GFormEntryData(
                    formId:      gformData.formId,
                    description: gformData.description,
                    fields:      gformData.fields,
                    pagination:  gformData.pagination,
                    saveEnabled: gformData.saveEnabled,
                    title:       gformData.title,
                    version:     gformData.version
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Default/Empty GFormEntryData
     */
    factory GFormEntryData.empty() {
        // ID is not specified, so a UUID will be generated
        return GFormEntryData(id: null, created: "", createdBy: 0, description: "", fields: <GFieldData>[], formId: 0, modified: "", pagination: {}, saveEnabled: false, status: "", title: "", version: "0.0.0");
    }
}








/* =============================================================================
 * MARK: Object & Table Info
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 */
enum GFormEntryDataInfo {

    id(         "gform_entry_id", "id",               idType),
    created(    "created",        "date_created",   textType),
    createdBy(  "created_by",     "created_by",      intType),
    description("description",    "description",    textType),
    fields(     "fields",         "fields",         blobType),
    formId(     "gform_id",       "form_id",         intType),
    // isApproved( "is_approved",    "is_approved",     intType), // Actual int -- not bool represented with int
    modified(   "modified",       "date_saved",     textType),
    pagination( "pagination",     "pagination",     blobType),
    // resumeUrl(  "resume_url",     "resume_url",     textType),
    saveEnabled("save_enabled",   "saveEnabled",     intType),
    status(     "status",         "status",         textType),
    title(      "title",          "title",          textType),
    version(    "version",        "version",        textType);

    const GFormEntryDataInfo(this.columnName, this.jsonName, this.columnType);

    final String columnName;
    final String columnType;
    final String jsonName;


    static List<String> get columnNameValues {
        return GFormEntryDataInfo.values.map((value) { return value.columnName; }).toList();
    }

    static List<String> get jsonNameValues {
        return GFormEntryDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static const String blobType = "BLOB NOT NULL";
    static const String idType   = "TEXT PRIMARY KEY";
    static const String intType  = "INTEGER NOT NULL";
    static const String textType = "TEXT NOT NULL";




    static Type   get objectType     => GFormEntryData;
    static String get objectTypeName => "gform_entry";
    static String get tableName      => "gform_entries";

    static String get tableBuilder {

        return "CREATE TABLE IF NOT EXISTS ${GFormEntryDataInfo.tableName} (" +
            GFormEntryDataInfo.id         .columnName    + " " +    GFormEntryDataInfo.id         .columnType    + ", " +
            GFormEntryDataInfo.created    .columnName    + " " +    GFormEntryDataInfo.created    .columnType    + ", " +
            GFormEntryDataInfo.createdBy  .columnName    + " " +    GFormEntryDataInfo.createdBy  .columnType    + ", " +
            GFormEntryDataInfo.description.columnName    + " " +    GFormEntryDataInfo.description.columnType    + ", " +
            GFormEntryDataInfo.fields     .columnName    + " " +    GFormEntryDataInfo.fields     .columnType    + ", " +
            GFormEntryDataInfo.formId     .columnName    + " " +    GFormEntryDataInfo.formId     .columnType    + ", " +
            // GFormEntryDataInfo.isApproved .columnName    + " " +    GFormEntryDataInfo.isApproved .columnType    + ", " +
            GFormEntryDataInfo.modified   .columnName    + " " +    GFormEntryDataInfo.modified   .columnType    + ", " +
            GFormEntryDataInfo.pagination .columnName    + " " +    GFormEntryDataInfo.pagination .columnType    + ", " +
            // GFormEntryDataInfo.resumeUrl  .columnName    + " " +    GFormEntryDataInfo.resumeUrl  .columnType    + ", " +
            GFormEntryDataInfo.saveEnabled.columnName    + " " +    GFormEntryDataInfo.saveEnabled.columnType    + ", " +
            GFormEntryDataInfo.status     .columnName    + " " +    GFormEntryDataInfo.status     .columnType    + ", " +
            GFormEntryDataInfo.title      .columnName    + " " +    GFormEntryDataInfo.title      .columnType    + ", " +
            GFormEntryDataInfo.version    .columnName    + " " +    GFormEntryDataInfo.version    .columnType    + ")";
    }
    // TODO: Enable isApproved and resumeUrl
}