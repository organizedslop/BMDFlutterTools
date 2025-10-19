/*
 * Company User Data
 *
 * Created by:  Blake Davis
 * Description: CompanyUser data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/type_extensions.dart";




/* ======================================================================================================================
 * MARK: Company User Data Model
 * ------------------------------------------------------------------------------------------------------------------ */

class CompanyUserData {

    bool    isExhibitorContact,
            isPrimaryUser;

    String  companyId,
            id,
            status,
            userId;

    String? jobTitle;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    CompanyUserData({
        required this.companyId,
        required this.id,
                 this.jobTitle,
        required this.isExhibitorContact,
        required this.isPrimaryUser,
        required this.status,
        required this.userId,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
        return other is CompanyUserData                      &&
            other.companyId          == companyId            &&
            other.id                 == id                   &&
            other.isExhibitorContact == isExhibitorContact   &&
            other.isPrimaryUser      == isPrimaryUser        &&
            other.jobTitle           == jobTitle             &&
            other.status             == status               &&
            other.userId             == userId;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        companyId,
        id,
        isExhibitorContact,
        isPrimaryUser,
        jobTitle,
        status,
        userId,
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: CompanyUserData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({required LocationEncoding destination}) {

        // Create boolean value for the JSON"s destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  CompanyUserDataInfo.companyId            .jsonName   :  CompanyUserDataInfo.companyId            .columnName):   companyId,
            (apiOrDatabase  ?  CompanyUserDataInfo.userId               .jsonName   :  CompanyUserDataInfo.userId               .columnName):   userId,
            (apiOrDatabase  ?  CompanyUserDataInfo.id                   .jsonName   :  CompanyUserDataInfo.id                   .columnName):   id,
            (apiOrDatabase  ?  CompanyUserDataInfo.status               .jsonName   :  CompanyUserDataInfo.status               .columnName):   status,
            (apiOrDatabase  ?  CompanyUserDataInfo.jobTitle             .jsonName   :  CompanyUserDataInfo.jobTitle             .columnName):   jobTitle,
            (apiOrDatabase  ?  CompanyUserDataInfo.isPrimaryUser        .jsonName   :  CompanyUserDataInfo.isPrimaryUser        .columnName):   isPrimaryUser.toInt(),
            (apiOrDatabase  ?  CompanyUserDataInfo.isExhibitorContact   .jsonName   :  CompanyUserDataInfo.isExhibitorContact   .columnName):   isExhibitorContact.toInt(),
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> CompanyUserData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory CompanyUserData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON"s source (to shorten ternary expressions).
        final bool apiOrDatabase = (source == LocationEncoding.api);


        // Determine if the JSON data is a string or a map. Otherwise, throw an error.
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return CompanyUserData.empty(); }
        }


        return CompanyUserData(
            companyId:           jsonAsMap[apiOrDatabase  ?  CompanyUserDataInfo.companyId          .jsonName  :  CompanyUserDataInfo.companyId         .columnName]    as String,
            userId:              jsonAsMap[apiOrDatabase  ?  CompanyUserDataInfo.userId             .jsonName  :  CompanyUserDataInfo.userId            .columnName]    as String,
            id:                  jsonAsMap[apiOrDatabase  ?  CompanyUserDataInfo.id                 .jsonName  :  CompanyUserDataInfo.id                .columnName]    as String,
            status:              jsonAsMap[apiOrDatabase  ?  CompanyUserDataInfo.status             .jsonName  :  CompanyUserDataInfo.status            .columnName]    as String,
            jobTitle:            jsonAsMap[apiOrDatabase  ?  CompanyUserDataInfo.jobTitle           .jsonName  :  CompanyUserDataInfo.jobTitle          .columnName]    as String?,
            isPrimaryUser:       jsonAsMap[apiOrDatabase  ?  CompanyUserDataInfo.isPrimaryUser      .jsonName  :  CompanyUserDataInfo.isPrimaryUser     .columnName] == 1 ? true : false,
            isExhibitorContact:  jsonAsMap[apiOrDatabase  ?  CompanyUserDataInfo.isExhibitorContact .jsonName  :  CompanyUserDataInfo.isExhibitorContact.columnName] == 1 ? true : false,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty CompanyUserData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory CompanyUserData.empty() {
        return CompanyUserData(
            companyId:          "",
            id:                 "",
            isExhibitorContact: false,
            isPrimaryUser:      false,
            status:             "",
            userId:             "",
        );
    }

}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum CompanyUserDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    companyId(           "company_id",              "company_id",               "Company ID",               "TEXT NOT NULL"),
    userId(              "user_id",                 "user_id",                  "User ID",                  "TEXT NOT NULL"),
    id(                  "id",                      "id",                       "ID",                       "TEXT PRIMARY KEY"),
    status(              "status",                  "status",                   "Status",                   "TEXT NOT NULL"),
    jobTitle(            "job_title",               "job_title",                "Job Title",                "TEXT"),
    isPrimaryUser(       "is_primary_user",         "is_primary_user",          "Primary User",             "INTEGER NOT NULL"),
    isExhibitorContact(  "is_exhibitor_contact",    "is_exhibitor_contact",     "Exhibitor Contact",        "INTEGER NOT NULL");


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    const CompanyUserDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return CompanyUserDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return CompanyUserDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return CompanyUserDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => CompanyUserData;
    static String get objectTypeName => "companyUser";
    static String get tableName      => "company_users";

    static String get tableBuilder {

        final columns = CompanyUserDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}