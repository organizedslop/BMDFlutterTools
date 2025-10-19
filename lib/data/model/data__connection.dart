/**
 * Created by:  Blake Davis
 * Description: Connection data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/data__address.dart";
import "package:bmd_flutter_tools/data/model/data__survey_answer.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/type_extensions.dart";
import "package:collection/collection.dart";




/* ======================================================================================================================
 * MARK: Connection Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class ConnectionData {

    String id;

    double? rating;

    List<String> badgeCompanyCategories;

    String? badgeId,            // The connected Badge ID
            companyId,          // The owner's Company ID
            companyName,        // The owner's Company name
            showId;             // The Show ID

    AddressData? badgeUserAddress;   // The connected Badge's User's address

    String? badgeCompanyName,   // The connected Badge's Company's name
            badgeUserEmail,
            badgeUserId,        // The connected Badge's User ID
            badgeUserJobTitle,  // The connected Badge's User's job title
            badgeUserPhone,
            badgeUserName,      // The connected Badge's User's name
            legacyBadgeId,      // The connected Badge's legacy identifier
            dateCreated,
            dateDeleted,
            dateModified,
            dateSynced,
            userId;             // The owner's User ID

    List<SurveyAnswerData> qualifyingQuestions;



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    ConnectionData({
        required this.id,
                      badgeCompanyCategories,
                 this.badgeCompanyName,
                 this.badgeId,
                 this.badgeUserAddress,
                 this.badgeUserEmail,
                 this.badgeUserPhone,
                 this.badgeUserJobTitle,
                 this.badgeUserId,
                 this.badgeUserName,
                 this.legacyBadgeId,
                 this.companyId,
                 this.companyName,
                 this.dateCreated,
                 this.dateDeleted,
                 this.dateModified,
                 this.dateSynced,
                      qualifyingQuestions,
                 this.rating,
                 this.showId,
                 this.userId,

    })  :   this.badgeCompanyCategories = badgeCompanyCategories ?? <String>[],
            this.qualifyingQuestions    = qualifyingQuestions    ?? <SurveyAnswerData>[];




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
        return other is ConnectionData                                  &&
               other.id                     ==  id                      &&
               other.badgeCompanyCategories ==  badgeCompanyCategories  &&
               other.badgeCompanyName       ==  badgeCompanyName        &&
               other.badgeId                ==  badgeId                 &&
               other.badgeUserAddress       ==  badgeUserAddress        &&
               other.badgeUserEmail         ==  badgeUserEmail          &&
               other.badgeUserPhone         ==  badgeUserPhone          &&
               other.badgeUserJobTitle      ==  badgeUserJobTitle       &&
               other.badgeUserId            ==  badgeUserId             &&
               other.badgeUserName          ==  badgeUserName           &&
               other.legacyBadgeId          ==  legacyBadgeId           &&
               other.companyId              ==  companyId               &&
               other.companyName            ==  companyName             &&
               other.dateCreated            ==  dateCreated             &&
               other.dateDeleted            ==  dateDeleted             &&
               other.dateModified           ==  dateModified            &&
               other.dateSynced             ==  dateSynced              &&
               other.rating                 ==  rating                  &&
               DeepCollectionEquality().equals(other.qualifyingQuestions, qualifyingQuestions) &&
               other.showId                 ==  showId                  &&
               other.userId                 ==  userId;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        id,
        badgeCompanyCategories,
        badgeCompanyName,
        badgeId,
        badgeUserAddress,
        badgeUserEmail,
        badgeUserPhone,
        badgeUserJobTitle,
        badgeUserId,
        badgeUserName,
        legacyBadgeId,
        companyId,
        companyName,
        Object.hashAll([
            dateCreated,
            dateDeleted,
            dateModified,
            dateSynced,
        ]),
        rating,
        Object.hashAll(qualifyingQuestions),
        showId,
        userId
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: ConnectionData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions).
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  ConnectionDataInfo.id                    .jsonName  :  ConnectionDataInfo.id                     .columnName):               id,
            (apiOrDatabase  ?  ConnectionDataInfo.badgeCompanyCategories.jsonName  :  ConnectionDataInfo.badgeCompanyCategories .columnName):   json.encode(badgeCompanyCategories.map((category) { return category.toString(); }).toList()),
            (apiOrDatabase  ?  ConnectionDataInfo.badgeCompanyName      .jsonName  :  ConnectionDataInfo.badgeCompanyName       .columnName):               badgeCompanyName,
            (apiOrDatabase  ?  ConnectionDataInfo.badgeId               .jsonName  :  ConnectionDataInfo.badgeId                .columnName):               badgeId,
            (apiOrDatabase  ?  ConnectionDataInfo.legacyBadgeId         .jsonName  :  ConnectionDataInfo.legacyBadgeId          .columnName):               legacyBadgeId,
            (apiOrDatabase  ?  ConnectionDataInfo.badgeUserJobTitle     .jsonName  :  ConnectionDataInfo.badgeUserJobTitle      .columnName):               badgeUserJobTitle,
            (apiOrDatabase  ?  ConnectionDataInfo.badgeUserAddress      .jsonName  :  ConnectionDataInfo.badgeUserAddress       .columnName):               (() {
                final addressJson = badgeUserAddress?.toJson(destination: destination);
                if (addressJson == null || addressJson.isEmpty) {
                    return null;
                }
                return json.encode(addressJson);
            })(),
            (apiOrDatabase  ?  ConnectionDataInfo.badgeUserEmail        .jsonName  :  ConnectionDataInfo.badgeUserEmail         .columnName):               badgeUserEmail,
            (apiOrDatabase  ?  ConnectionDataInfo.badgeUserPhone        .jsonName  :  ConnectionDataInfo.badgeUserPhone         .columnName):               badgeUserPhone,
            (apiOrDatabase  ?  ConnectionDataInfo.badgeUserId           .jsonName  :  ConnectionDataInfo.badgeUserId            .columnName):               badgeUserId,
            (apiOrDatabase  ?  ConnectionDataInfo.companyId             .jsonName  :  ConnectionDataInfo.companyId              .columnName):               companyId,
            (apiOrDatabase  ?  ConnectionDataInfo.companyName           .jsonName  :  ConnectionDataInfo.companyName            .columnName):               companyName,
            (apiOrDatabase  ?  ConnectionDataInfo.badgeUserName         .jsonName  :  ConnectionDataInfo.badgeUserName          .columnName):               badgeUserName,
            (apiOrDatabase  ?  ConnectionDataInfo.dateCreated           .jsonName  :  ConnectionDataInfo.dateCreated            .columnName):               dateCreated,
            (apiOrDatabase  ?  ConnectionDataInfo.dateDeleted           .jsonName  :  ConnectionDataInfo.dateDeleted            .columnName):               dateDeleted,
            (apiOrDatabase  ?  ConnectionDataInfo.dateModified          .jsonName  :  ConnectionDataInfo.dateModified           .columnName):               dateModified,
            (apiOrDatabase  ?  ConnectionDataInfo.dateSynced            .jsonName  :  ConnectionDataInfo.dateSynced             .columnName):               dateSynced,
            (apiOrDatabase  ?  ConnectionDataInfo.qualifyingQuestions   .jsonName  :  ConnectionDataInfo.qualifyingQuestions    .columnName):   json.encode(qualifyingQuestions.map((question) { return question.toJson(destination: destination); }).toList()),
            (apiOrDatabase  ?  ConnectionDataInfo.rating                .jsonName  :  ConnectionDataInfo.rating                 .columnName):               rating,
            (apiOrDatabase  ?  ConnectionDataInfo.showId                .jsonName  :  ConnectionDataInfo.showId                 .columnName):               showId,
            (apiOrDatabase  ?  ConnectionDataInfo.userId                .jsonName  :  ConnectionDataInfo.userId                 .columnName):               userId,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> ConnectionData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory ConnectionData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions).
        final bool apiOrDatabase = (source == LocationEncoding.api);

        // Determine if the JSON data is a string or a map. Otherwise, throw an error
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            ("JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return ConnectionData.empty(); }
        }


        return ConnectionData(
            id:                                     jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.id                    .jsonName  :  ConnectionDataInfo.id                    .columnName] as String,
            badgeCompanyName:                       jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.badgeCompanyName      .jsonName  :  ConnectionDataInfo.badgeCompanyName      .columnName] as String?,
            badgeId:                                jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.badgeId               .jsonName  :  ConnectionDataInfo.badgeId               .columnName] as String?,
            legacyBadgeId:                          jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.legacyBadgeId         .jsonName  :  ConnectionDataInfo.legacyBadgeId         .columnName] as String?,
            badgeUserJobTitle:                      jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.badgeUserJobTitle     .jsonName  :  ConnectionDataInfo.badgeUserJobTitle     .columnName] as String?,
            badgeUserAddress: (() {
                final dynamic rawAddress = jsonAsMap[apiOrDatabase
                    ? ConnectionDataInfo.badgeUserAddress.jsonName
                    : ConnectionDataInfo.badgeUserAddress.columnName];

                if (rawAddress == null) {
                    return null;
                }

                if (rawAddress is String) {
                    if (rawAddress.trim().isEmpty || rawAddress == 'null') {
                        return null;
                    }
                }

                try {
                    return AddressData.fromJson(rawAddress,
                        source: source, defaultOnFailure: false);
                } catch (_) {
                    logPrint("❌ Failed to parse badgeUserAddress. Returning null. Raw: ${rawAddress.runtimeType}");
                    return null;
                }
            })(),
            badgeUserEmail:                         jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.badgeUserEmail        .jsonName  :  ConnectionDataInfo.badgeUserEmail        .columnName] as String?,
            badgeUserPhone:                         jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.badgeUserPhone        .jsonName  :  ConnectionDataInfo.badgeUserPhone        .columnName] as String?,
            badgeUserId:                            jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.badgeUserId           .jsonName  :  ConnectionDataInfo.badgeUserId           .columnName] as String?,
            badgeUserName:                          jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.badgeUserName         .jsonName  :  ConnectionDataInfo.badgeUserName         .columnName] as String?,
            companyId:                              jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.companyId             .jsonName  :  ConnectionDataInfo.companyId             .columnName] as String?,
            companyName:                            jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.companyName           .jsonName  :  ConnectionDataInfo.companyName           .columnName] as String?,
            dateCreated:                            jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.dateCreated           .jsonName  :  ConnectionDataInfo.dateCreated           .columnName] as String?,
            dateDeleted:                            jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.dateDeleted           .jsonName  :  ConnectionDataInfo.dateDeleted           .columnName] as String?,
            dateModified:                           jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.dateModified          .jsonName  :  ConnectionDataInfo.dateModified          .columnName] as String?,
            showId:                                 jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.showId                .jsonName  :  ConnectionDataInfo.showId                .columnName] as String?,
            userId:                                 jsonAsMap[apiOrDatabase  ?  ConnectionDataInfo.userId                .jsonName  :  ConnectionDataInfo.userId                .columnName] as String?,

            badgeCompanyCategories: apiOrDatabase
                ? () {
                    final raw = jsonAsMap[ConnectionDataInfo
                        .badgeCompanyCategories.jsonName];
                    if (raw is List) {
                      return raw.map((category) => category.toString()).toList();
                    }
                    return <String>[];
                  }()
                : () {
                    final encoded =
                        jsonAsMap[ConnectionDataInfo.badgeCompanyCategories.columnName];
                    if (encoded == null || encoded.toString().isEmpty) {
                      return <String>[];
                    }
                    List<dynamic> categoriesAsDynamicList = json.decodeTo(
                      List.empty,
                      dataAsString: encoded,
                    );
                    return <String>[...categoriesAsDynamicList.map((category) => category.toString())];
                  }(),

            dateSynced: apiOrDatabase  ?  () {
                return DateTime.now().toUtc().toIso8601String();
            }()  :  () {
                return jsonAsMap[ConnectionDataInfo.dateSynced.columnName] as String?;
            }(),

            qualifyingQuestions: apiOrDatabase  ?  () {
               return <SurveyAnswerData>[];
            }()  :  () {
                return <SurveyAnswerData>[];
            }(),

            rating: (() {
                final raw = jsonAsMap[
                    apiOrDatabase
                        ? ConnectionDataInfo.rating.jsonName
                        : ConnectionDataInfo.rating.columnName
                    ];
                if (raw == null) return null;
                if (raw is num) {
                    return raw.toDouble();
                }
                final strValue = raw.toString().trim();
                return strValue.isNotEmpty ? double.tryParse(strValue) : null;
            })(),
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty ConnectionData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory ConnectionData.empty() {
        return ConnectionData(
            id:                 "",
            badgeId:            null,
            badgeUserId:        "",
            companyId:          null,
            companyName:        null,
            showId:             null,
        );
    }
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum ConnectionDataInfo {

    /* Property          | Column name                  | JSON name                     | Display name                  | Column type
     * ------------------|------------------------------|-------------------------------|-------------------------------|---------- */
    id(                    "id",                          "id",                           "ID",                           "TEXT PRIMARY KEY"),
    badgeCompanyCategories("badge_company_categories",    "badge_company_categories",     "Badge Company Categories",     "BLOB"),
    badgeCompanyName(      "badge_company_name",          "badge_company_name",           "Badge Company Name",           "TEXT"),
    badgeId(               "badge_id",                    "badge_id",                     "Badge ID",                     "TEXT"),
    legacyBadgeId(         "legacy_badge_id",             "legacy_badge_id",              "Legacy Badge ID",              "TEXT"),
    badgeUserJobTitle(     "badge_user_job_title",        "badge_user_job_title",         "Badge Job Title",              "TEXT"),
    badgeUserAddress(      "badge_user_address",          "badge_user_address",           "Badge Address",                "BLOB"),
    badgeUserEmail(        "badge_user_email",            "badge_user_email",             "Badge Email",                  "TEXT"),
    badgeUserPhone(        "badge_user_phone",            "badge_user_phone",             "Badge Phone",                  "TEXT"),
    badgeUserId(           "badge_user_id",               "badge_user_id",                "Badge User ID",                "TEXT"),
    badgeUserName(         "badge_user_name",             "badge_user_name",              "Badge User Name",              "TEXT"),
    companyId(             "company_id",                  "company_id",                   "Company ID",                   "TEXT"),
    companyName(           "company_name",                "company_name",                 "Company Name",                 "TEXT"),
    dateCreated(           "date_created",                "created_at",                   "Date Created",                 "TEXT"),
    dateDeleted(           "date_deleted",                "deleted_at",                   "Date Deleted",                 "TEXT"),
    dateModified(          "date_modified",               "updated_at",                   "Date Modified",                "TEXT"),
    dateSynced(            "date_synced",                 "synced_at",                    "Date Synced",                  "TEXT"),
    rating(                "rating",                      "rating",                       "Rating",                       "DOUBLE"),
    showId(                "show_id",                     "show_id",                      "Show ID",                      "TEXT"),
    userId(                "user_id",                     "user_id",                      "User ID",                      "TEXT"),
    qualifyingQuestions(   "qualifying_questions",        "qualifying_questions",         "Qualifying Questions",         "BLOB"),
;

    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    const ConnectionDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    // Returns a List of each property's columnName
    static List<String> get columnNameValues {
        return ConnectionDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    // Returns a List of each property's displayName
    static List<String> get displayNameValues {
        return ConnectionDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    // Returns a List of each property's jsonName
    static List<String> get jsonNameValues {
        return ConnectionDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => ConnectionData;
    static String get objectTypeName => "connection";
    static String get tableName      => "connections";

    static String get tableBuilder {

        final columns = ConnectionDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}







class ConnectionsRequest {
  final String companyId, showId;
  ConnectionsRequest(this.companyId, this.showId);
  @override bool operator ==(o) =>
    o is ConnectionsRequest && o.companyId == companyId && o.showId == showId;
  @override int get hashCode => Object.hash(companyId, showId);
}
