/*
 * Seminar Speaker Data Model
 *
 * Created by:  Blake Davis
 * Description: Seminar speaker data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/data__address.dart";
import "package:bmd_flutter_tools/data/model/data__name.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";




/* ======================================================================================================================
 * MARK: Seminar Speaker Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class SeminarSpeakerData {

    String id;

    AddressData address;

    NameData name;

    String dateCreated;

    String? bio,
            companyId,
            companyName,
            dateModified,
            dateDeleted,
            email,
            phone,
            photoUrl,
            status,
            title,
            userId;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    SeminarSpeakerData({
        required this.id,
        required this.address,
                 this.bio,
                 this.companyId,
                 this.companyName,
        required this.dateCreated,
                 this.dateDeleted,
                 this.dateModified,
                 this.email,
        required this.name,
                 this.phone,
                 this.photoUrl,
                 this.status,
                 this.title,
                 this.userId
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
        return other is SeminarSpeakerData          &&
               other.address        == address      &&
               other.bio            == bio          &&
               other.companyId      == companyId    &&
               other.companyName    == companyName  &&
               other.dateCreated    == dateCreated  &&
               other.dateDeleted    == dateDeleted  &&
               other.dateModified   == dateModified &&
               other.email          == email        &&
               other.name           == name         &&
               other.phone          == phone        &&
               other.photoUrl       == photoUrl     &&
               other.status         == status       &&
               other.title          == title        &&
               other.userId         == userId;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        id,
        address,
        bio,
        companyId,
        companyName,
        dateCreated,
        dateDeleted,
        dateModified,
        email,
        name,
        phone,
        photoUrl,
        status,
        title,
        userId
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: SeminarSpeakerData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.id               .jsonName  :  SeminarSpeakerDataInfo.id              .columnName):               id,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.address          .jsonName  :  SeminarSpeakerDataInfo.address         .columnName):   json.encode(address         .toJson(destination: destination)),
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.bio              .jsonName  :  SeminarSpeakerDataInfo.bio             .columnName):               bio,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.companyId        .jsonName  :  SeminarSpeakerDataInfo.companyId       .columnName):               companyId,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.companyName      .jsonName  :  SeminarSpeakerDataInfo.companyName     .columnName):               companyName,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.dateCreated      .jsonName  :  SeminarSpeakerDataInfo.dateCreated     .columnName):               dateCreated,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.dateDeleted      .jsonName  :  SeminarSpeakerDataInfo.dateDeleted     .columnName):               dateDeleted,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.dateModified     .jsonName  :  SeminarSpeakerDataInfo.dateModified    .columnName):               dateModified,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.email            .jsonName  :  SeminarSpeakerDataInfo.email           .columnName):               email,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.name             .jsonName  :  SeminarSpeakerDataInfo.name            .columnName):   json.encode(name            .toJson(destination: destination)),
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.phone            .jsonName  :  SeminarSpeakerDataInfo.phone           .columnName):               phone,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.photoUrl         .jsonName  :  SeminarSpeakerDataInfo.photoUrl        .columnName):               photoUrl,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.status           .jsonName  :  SeminarSpeakerDataInfo.status          .columnName):               status,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.title            .jsonName  :  SeminarSpeakerDataInfo.title           .columnName):               title,
            (apiOrDatabase  ?  SeminarSpeakerDataInfo.userId           .jsonName  :  SeminarSpeakerDataInfo.userId          .columnName):               userId,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> SeminarSpeakerData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SeminarSpeakerData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

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
            if (defaultOnFailure) { return SeminarSpeakerData.empty(); }
        }


        return SeminarSpeakerData(
            id:                           jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.id             .jsonName  :  SeminarSpeakerDataInfo.id              .columnName]    as String,
            address: AddressData.fromJson(jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.address        .jsonName  :  SeminarSpeakerDataInfo.address         .columnName], source: source),
            bio:                          jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.bio            .jsonName  :  SeminarSpeakerDataInfo.bio             .columnName]    as String?,
            companyId:                    jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.companyId      .jsonName  :  SeminarSpeakerDataInfo.companyId       .columnName]    as String?,
            companyName:                  jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.companyName    .jsonName  :  SeminarSpeakerDataInfo.companyName     .columnName]    as String?,
            dateCreated:                  jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.dateCreated    .jsonName  :  SeminarSpeakerDataInfo.dateCreated     .columnName]    as String,
            dateDeleted:                  jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.dateDeleted    .jsonName  :  SeminarSpeakerDataInfo.dateDeleted     .columnName]    as String?,
            dateModified:                 jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.dateModified   .jsonName  :  SeminarSpeakerDataInfo.dateModified    .columnName]    as String?,
            email:                        jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.email          .jsonName  :  SeminarSpeakerDataInfo.email           .columnName]    as String?,
            name:       NameData.fromJson(jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.name           .jsonName  :  SeminarSpeakerDataInfo.name            .columnName], source: source),
            phone:                        jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.phone          .jsonName  :  SeminarSpeakerDataInfo.phone           .columnName]    as String?,
            photoUrl:                     jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.photoUrl       .jsonName  :  SeminarSpeakerDataInfo.photoUrl        .columnName]    as String?,
            status:                       jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.status         .jsonName  :  SeminarSpeakerDataInfo.status          .columnName]    as String?,
            title:                        jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.title          .jsonName  :  SeminarSpeakerDataInfo.title           .columnName]    as String?,
            userId:                       jsonAsMap[apiOrDatabase  ?  SeminarSpeakerDataInfo.userId         .jsonName  :  SeminarSpeakerDataInfo.userId          .columnName]    as String?,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty SeminarSpeakerData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SeminarSpeakerData.empty() {
        return SeminarSpeakerData(
            id:          "",
            address:     AddressData.empty(),
            dateCreated: "",
            name:        NameData.empty(),
            title:       "",
            userId:      "",
        );
    }
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum SeminarSpeakerDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    id(                  "id",                      "id",                       "ID",                       "TEXT PRIMARY KEY"),
    address(             "address",                 "address",                  "Address",                  "BLOB NOT NULL"),
    bio(                 "bio",                     "bio",                      "Bio",                      "TEXT"),
    companyId(           "company_id",              "company_id",               "Company ID",               "TEXT"),
    companyName(         "company_name",            "company_name",             "Company Name",             "TEXT"),
    dateCreated(         "date_created",            "created_at",               "Date Created",             "TEXT NOT NULL"),
    dateDeleted(         "date_deleted",            "deleted_at",               "Date Deleted",             "TEXT"),
    dateModified(        "date_modified",           "updated_at",               "Date Modified",            "TEXT"),
    email(               "email",                   "email",                    "Email",                    "TEXT"),
    name(                "name",                    "name",                     "Name",                     "BLOB NOT NULL"),
    phone(               "phone",                   "phone",                    "Phone",                    "TEXT"),
    photoUrl(            "photo_url",               "photo_url",                "Photo URL",                "TEXT"),
    status(              "status",                  "status",                   "Status",                   "TEXT"),
    title(               "title",                   "title",                    "Title",                    "TEXT"),
    userId(              "user_id",                 "user_id",                  "User ID",                  "TEXT");


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    const SeminarSpeakerDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return SeminarSpeakerDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return SeminarSpeakerDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return SeminarSpeakerDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => SeminarSpeakerData;
    static String get objectTypeName => "seminarSpeaker";
    static String get tableName      => "seminar_speakers";

    static String get tableBuilder {

        final columns = SeminarSpeakerDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}