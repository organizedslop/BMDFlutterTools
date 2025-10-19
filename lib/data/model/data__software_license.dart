/*
 *  Software License Data
 *
 * Created by:  Blake Davis
 * Description: Software license data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";

import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";




/* ======================================================================================================================
 * MARK: Software License Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class SoftwareLicenseData {

    int     id;

    int     userId,
            ownerId,
            transactionId;

    String? dateModified;

    String  dateCreated,
            license,
            status;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    SoftwareLicenseData({   required this.id,
                            required this.dateCreated,
                                     this.dateModified,
                            required this.license,
                            required this.ownerId,
                            required this.status,
                            required this.transactionId,
                            required this.userId,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
         return other is SoftwareLicenseData            &&
                other.id             == id              &&
                other.dateCreated    == dateCreated     &&
                other.dateModified   == dateModified    &&
                other.license        == license         &&
                other.ownerId        == ownerId         &&
                other.status         == status          &&
                other.transactionId  == transactionId   &&
                other.userId         == userId;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        id,
        dateCreated,
        dateModified,
        license,
        ownerId,
        status,
        transactionId,
        userId
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: SoftwareLicenseData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  SoftwareLicenseDataInfo.id           .jsonName  :  SoftwareLicenseDataInfo.id           .columnName):       id,
            (apiOrDatabase  ?  SoftwareLicenseDataInfo.dateCreated  .jsonName  :  SoftwareLicenseDataInfo.dateCreated  .columnName):       dateCreated,
            (apiOrDatabase  ?  SoftwareLicenseDataInfo.dateModified .jsonName  :  SoftwareLicenseDataInfo.dateModified .columnName):       dateModified,
            (apiOrDatabase  ?  SoftwareLicenseDataInfo.license      .jsonName  :  SoftwareLicenseDataInfo.license      .columnName):       license,
            (apiOrDatabase  ?  SoftwareLicenseDataInfo.ownerId      .jsonName  :  SoftwareLicenseDataInfo.ownerId      .columnName):       ownerId,
            (apiOrDatabase  ?  SoftwareLicenseDataInfo.status       .jsonName  :  SoftwareLicenseDataInfo.status       .columnName):       status,
            (apiOrDatabase  ?  SoftwareLicenseDataInfo.transactionId.jsonName  :  SoftwareLicenseDataInfo.transactionId.columnName):       transactionId,
            (apiOrDatabase  ?  SoftwareLicenseDataInfo.userId       .jsonName  :  SoftwareLicenseDataInfo.userId       .columnName):       userId,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> SoftwareLicenseData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SoftwareLicenseData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions)
        final bool apiOrDatabase = (source == LocationEncoding.api);

        // Determine if the JSON data is a string or a map. Otherwise, throw an error
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return SoftwareLicenseData.empty(); }
        }


        return SoftwareLicenseData(
            id:             jsonAsMap[apiOrDatabase  ?  SoftwareLicenseDataInfo.id           .jsonName  :        SoftwareLicenseDataInfo.id           .columnName].toString().toInt()!,
            dateCreated:    jsonAsMap[apiOrDatabase  ?  SoftwareLicenseDataInfo.dateCreated  .jsonName  :        SoftwareLicenseDataInfo.dateCreated  .columnName].toString(),
            dateModified:   jsonAsMap[apiOrDatabase  ?  SoftwareLicenseDataInfo.dateModified .jsonName  :        SoftwareLicenseDataInfo.dateModified .columnName].toString(),
            license:        jsonAsMap[apiOrDatabase  ?  SoftwareLicenseDataInfo.license      .jsonName  :        SoftwareLicenseDataInfo.license      .columnName].toString(),
            ownerId:        jsonAsMap[apiOrDatabase  ?  SoftwareLicenseDataInfo.ownerId      .jsonName  :        SoftwareLicenseDataInfo.ownerId      .columnName].toString().toInt()!,
            status:         jsonAsMap[apiOrDatabase  ?  SoftwareLicenseDataInfo.status       .jsonName  :        SoftwareLicenseDataInfo.status       .columnName].toString(),
            transactionId:  jsonAsMap[apiOrDatabase  ?  SoftwareLicenseDataInfo.transactionId.jsonName  :        SoftwareLicenseDataInfo.transactionId.columnName].toString().toInt()!,
            userId:         jsonAsMap[apiOrDatabase  ?  SoftwareLicenseDataInfo.userId       .jsonName  :        SoftwareLicenseDataInfo.userId       .columnName].toString().toInt()!,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty SoftwareLicenseData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SoftwareLicenseData.empty() {
        return SoftwareLicenseData(
            id:            0,
            dateCreated:   "0",
            license:       "",
            ownerId:       0,
            status:        "pending",
            transactionId: 0,
            userId:        0,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Pre-purchase SoftwareLicenseData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SoftwareLicenseData.prepurchase({ required String license ,
                                              required int ownerId,
                                              required int userId    }) {
        return SoftwareLicenseData(
            id:            0,
            dateCreated:   "0",
            license:       license,
            ownerId:       ownerId,
            status:        "pending",
            transactionId: 0,
            userId:        userId
        );
    }
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum SoftwareLicenseDataInfo {

    id(           "id",                 "id",                   "ID",                   idType),
    dateCreated(  "date_created",       "date_created",         "Date Created",         textType),
    dateModified( "date_modified",      "date_updated",         "Date Modified",        textType),
    license(      "license",            "license",              "License",              textType),
    ownerId(      "owner_id",           "owner_id",             "Owner ID",             intType),
    status(       "status",             "status",               "Status",               textType),
    transactionId("transaction_id",     "transaction_id",       "Transaction ID",       intType),
    userId(       "user_id",            "user_id",              "User ID",              intType);


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    static const String blobType = "BLOB NOT NULL";
    static const String idType   = "INTEGER PRIMARY KEY";
    static const String intType  = "INTEGER NOT NULL";
    static const String textType = "TEXT NOT NULL";


    const SoftwareLicenseDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return SoftwareLicenseDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return SoftwareLicenseDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return SoftwareLicenseDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => SoftwareLicenseData;
    static String get objectTypeName => "softwareLicense";
    static String get tableName      => "softwareLicenses";

    static String get tableBuilder {

        return "CREATE TABLE IF NOT EXISTS ${SoftwareLicenseDataInfo.tableName} (" +
            SoftwareLicenseDataInfo.id           .columnName     + " " +     SoftwareLicenseDataInfo.id           .columnType     + ", " +
            SoftwareLicenseDataInfo.dateCreated  .columnName     + " " +     SoftwareLicenseDataInfo.dateCreated  .columnType     + ", " +
            SoftwareLicenseDataInfo.dateModified .columnName     + " " +     SoftwareLicenseDataInfo.dateModified .columnType     + ", " +
            SoftwareLicenseDataInfo.license      .columnName     + " " +     SoftwareLicenseDataInfo.license      .columnType     + ", " +
            SoftwareLicenseDataInfo.ownerId      .columnName     + " " +     SoftwareLicenseDataInfo.ownerId      .columnType     + ", " +
            SoftwareLicenseDataInfo.status       .columnName     + " " +     SoftwareLicenseDataInfo.status       .columnType     + ", " +
            SoftwareLicenseDataInfo.transactionId.columnName     + " " +     SoftwareLicenseDataInfo.transactionId.columnType     + ", " +
            SoftwareLicenseDataInfo.userId       .columnName     + " " +     SoftwareLicenseDataInfo.userId       .columnType     + ")";
    }
}