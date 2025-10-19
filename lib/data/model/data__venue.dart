/*
 * Venue Data
 *
 * Created by:  Blake Davis
 * Description: Venue data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";

import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/data/model/data__address.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";




/* ======================================================================================================================
 * MARK: Location Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class VenueData {

    String  id,
            dateCreated,
            description,
            name,
            slug,
            timezone;

    String? dateDeleted,
            dateModified;

    AddressData
            address;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    VenueData({ required this.id,
                required this.address,
                required this.dateCreated,
                         this.dateModified,
                         this.dateDeleted,
                required this.description,
                required this.name,
                required this.slug,
                required this.timezone
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
      bool operator ==(Object other) {
        return other is VenueData              &&
            other.id           == id           &&
            other.address      == address      &&
            other.dateCreated  == dateCreated  &&
            other.dateDeleted  == dateDeleted  &&
            other.dateModified == dateModified &&
            other.description  == description  &&
            other.name         == name         &&
            other.slug         == slug         &&
            other.timezone     == timezone;
      }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        id,
        address,
        dateCreated,
        dateDeleted,
        dateModified,
        description,
        name,
        slug,
        timezone
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: VenueData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions).
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  VenueDataInfo.id          .jsonName  :  VenueDataInfo.id          .columnName):              id,
            (apiOrDatabase  ?  VenueDataInfo.address     .jsonName  :  VenueDataInfo.address     .columnName):  json.encode(address     .toJson(destination: destination)),
            (apiOrDatabase  ?  VenueDataInfo.dateCreated .jsonName  :  VenueDataInfo.dateCreated .columnName):              dateCreated,
            (apiOrDatabase  ?  VenueDataInfo.dateDeleted .jsonName  :  VenueDataInfo.dateDeleted .columnName):              dateDeleted,
            (apiOrDatabase  ?  VenueDataInfo.dateModified.jsonName  :  VenueDataInfo.dateModified.columnName):              dateModified,
            (apiOrDatabase  ?  VenueDataInfo.description .jsonName  :  VenueDataInfo.description .columnName):              description,
            (apiOrDatabase  ?  VenueDataInfo.name        .jsonName  :  VenueDataInfo.name        .columnName):              name,
            (apiOrDatabase  ?  VenueDataInfo.slug        .jsonName  :  VenueDataInfo.slug        .columnName):              slug,
            (apiOrDatabase  ?  VenueDataInfo.timezone    .jsonName  :  VenueDataInfo.timezone    .columnName):              timezone,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> VenueData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory VenueData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

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
            if (defaultOnFailure) { return VenueData.empty(); }
        }


        return VenueData(
            id:                           jsonAsMap[apiOrDatabase  ?  VenueDataInfo.id          .jsonName  :  VenueDataInfo.id          .columnName]    as String,
            address: AddressData.fromJson(jsonAsMap[apiOrDatabase  ?  VenueDataInfo.address     .jsonName  :  VenueDataInfo.address     .columnName],   source: source),
            dateCreated:                  jsonAsMap[apiOrDatabase  ?  VenueDataInfo.dateCreated .jsonName  :  VenueDataInfo.dateCreated .columnName]    as String,
            dateDeleted:                  jsonAsMap[apiOrDatabase  ?  VenueDataInfo.dateDeleted .jsonName  :  VenueDataInfo.dateDeleted .columnName]    as String?,
            dateModified:                 jsonAsMap[apiOrDatabase  ?  VenueDataInfo.dateModified.jsonName  :  VenueDataInfo.dateModified.columnName]    as String?,
            description:                  jsonAsMap[apiOrDatabase  ?  VenueDataInfo.description .jsonName  :  VenueDataInfo.description .columnName]    as String,
            name:                         jsonAsMap[apiOrDatabase  ?  VenueDataInfo.name        .jsonName  :  VenueDataInfo.name        .columnName]    as String,
            slug:                         jsonAsMap[apiOrDatabase  ?  VenueDataInfo.slug        .jsonName  :  VenueDataInfo.slug        .columnName]    as String,
            timezone:                     jsonAsMap[apiOrDatabase  ?  VenueDataInfo.timezone    .jsonName  :  VenueDataInfo.timezone    .columnName]    as String,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty VenueData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory VenueData.empty() {
        return VenueData(
            id:           "",
            address:      AddressData.empty(),
            dateCreated:  "0",
            description:  "",
            name:         "",
            slug:         "",
            timezone:     ""
        );
    }
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum VenueDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    id(                  "id",                      "id",                       "ID",                       idType),
    address(             "address",                 "address",                  "Address",                  blobType),
    dateCreated(         "date_created",            "created_at",               "Date Created",             textType),
    dateDeleted(         "date_deleted",            "deleted_at",               "Date Deleted",             textType),
    dateModified(        "date_modified",           "updated_at",               "Date Modified",            textType),
    description(         "description",             "description",              "Description",              textType),
    name(                "name",                    "name",                     "Name",                     textType),
    slug(                "slug",                    "slug",                     "Slug",                     textType),
    timezone(            "timezone",                "timezone",                 "Timezone",                 textType);


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    static const String blobType = "BLOB NOT NULL";
    static const String idType   = "TEXT PRIMARY KEY";
    static const String intType  = "INTEGER NOT NULL";
    static const String textType = "TEXT NOT NULL";


    const VenueDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return VenueDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return VenueDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return VenueDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => VenueData;
    static String get objectTypeName => "venue";
    static String get tableName      => "venues";

    static String get tableBuilder {

        final columns = VenueDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}