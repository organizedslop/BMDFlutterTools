/*
 * Seminar Data Model
 *
 * Created by:  Blake Davis
 * Description: Seminar (class) data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/data__seminar_category.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/type_extensions.dart";
import "package:collection/collection.dart";




/* ======================================================================================================================
 * MARK: Seminar Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class SeminarData {

    String id;

    bool isFeatured;

    List<SeminarCategoryData> categories;

    Map<String, dynamic> credits;

    String  dateCreated,
            title;

    String? dateDeleted,
            dateModified,
            description,
            targetAudience;


    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    SeminarData({
        required this.id,
        required this.categories,
        required this.credits,
        required this.dateCreated,
                 this.dateDeleted,
        required this.dateModified,
                 this.description,
        required this.isFeatured,
                 this.targetAudience,
        required this.title,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
                                 return other is SeminarData                                 &&
                                        other.id                    == id                    &&
        DeepCollectionEquality().equals(other.categories,              categories)           &&
        DeepCollectionEquality().equals(other.credits,                 credits)              &&
                                        other.dateCreated           == dateCreated           &&
                                        other.dateDeleted           == dateDeleted           &&
                                        other.dateModified          == dateModified          &&
                                        other.description           == description           &&
                                        other.isFeatured            == isFeatured            &&
                                        other.targetAudience        == targetAudience        &&
                                        other.title                 == title;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
                        id,
         Object.hashAll(categories),
         Object.hashAll(credits.entries),
                        dateCreated,
                        dateDeleted,
                        dateModified,
                        description,
                        isFeatured,
                        targetAudience,
                        title
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: SeminarData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  SeminarDataInfo.id                   .jsonName  :  SeminarDataInfo.id                   .columnName):               id,
            (apiOrDatabase  ?  SeminarDataInfo.categories           .jsonName  :  SeminarDataInfo.categories           .columnName):   json.encode(categories.map((category) { return category.toJson(destination: destination); }).toList()),
            (apiOrDatabase  ?  SeminarDataInfo.credits              .jsonName  :  SeminarDataInfo.credits              .columnName):   json.encode(credits),
            (apiOrDatabase  ?  SeminarDataInfo.dateCreated          .jsonName  :  SeminarDataInfo.dateCreated          .columnName):               dateCreated,
            (apiOrDatabase  ?  SeminarDataInfo.dateDeleted          .jsonName  :  SeminarDataInfo.dateDeleted          .columnName):               dateDeleted,
            (apiOrDatabase  ?  SeminarDataInfo.dateModified         .jsonName  :  SeminarDataInfo.dateModified         .columnName):               dateModified,
            (apiOrDatabase  ?  SeminarDataInfo.description          .jsonName  :  SeminarDataInfo.description          .columnName):               description,
            (apiOrDatabase  ?  SeminarDataInfo.isFeatured           .jsonName  :  SeminarDataInfo.isFeatured           .columnName):  apiOrDatabase ? isFeatured : isFeatured.toInt(),
            (apiOrDatabase  ?  SeminarDataInfo.targetAudience       .jsonName  :  SeminarDataInfo.targetAudience       .columnName):               targetAudience,
            (apiOrDatabase  ?  SeminarDataInfo.title                .jsonName  :  SeminarDataInfo.title                .columnName):               title,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> SeminarData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SeminarData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

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
            if (defaultOnFailure) { return SeminarData.empty(); }
        }


        return SeminarData(
            id:             jsonAsMap[apiOrDatabase  ?  SeminarDataInfo.id                   .jsonName  :  SeminarDataInfo.id                   .columnName]    as String,
            dateCreated:    jsonAsMap[apiOrDatabase  ?  SeminarDataInfo.dateCreated          .jsonName  :  SeminarDataInfo.dateCreated          .columnName]    as String,
            dateDeleted:    jsonAsMap[apiOrDatabase  ?  SeminarDataInfo.dateDeleted          .jsonName  :  SeminarDataInfo.dateDeleted          .columnName]    as String?,
            dateModified:   jsonAsMap[apiOrDatabase  ?  SeminarDataInfo.dateModified         .jsonName  :  SeminarDataInfo.dateModified         .columnName]    as String?,
            description:    jsonAsMap[apiOrDatabase  ?  SeminarDataInfo.description          .jsonName  :  SeminarDataInfo.description          .columnName]    as String?,
            isFeatured:    (jsonAsMap[apiOrDatabase  ?  SeminarDataInfo.isFeatured           .jsonName  :  SeminarDataInfo.isFeatured           .columnName]    == (apiOrDatabase ? true : 1)),
            targetAudience: jsonAsMap[apiOrDatabase  ?  SeminarDataInfo.targetAudience       .jsonName  :  SeminarDataInfo.targetAudience       .columnName]    as String?,
            title:          jsonAsMap[apiOrDatabase  ?  SeminarDataInfo.title                .jsonName  :  SeminarDataInfo.title                .columnName]    as String,

            categories: apiOrDatabase  ?  () {
                return <SeminarCategoryData>[...(jsonAsMap[SeminarDataInfo.categories.jsonName].map((category) { return SeminarCategoryData.fromJson(category, source: LocationEncoding.api); }).toList())];
            }()  :  () {
                List<dynamic> categoriesAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[SeminarDataInfo.categories.columnName]);
                return <SeminarCategoryData>[...categoriesAsDynamicList.map((category) => SeminarCategoryData.fromJson(category, source: LocationEncoding.database))];
            }(),

            credits: {},
            // apiOrDatabase  ?  () {
            //     return jsonAsMap[SeminarDataInfo.credits.jsonName] as Map<String, dynamic>;
            // }()  :  () {
            //     return json.decode(jsonAsMap[SeminarDataInfo.credits.columnName]) as Map<String, dynamic>;
            // }(),
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty SeminarData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SeminarData.empty() {
        return SeminarData(
            id:                    "",
            categories:            <SeminarCategoryData>[],
            credits:               { "credits": null, "type": null },
            dateCreated:           "0",
            dateModified:          "0",
            description:           "",
            isFeatured:            false,
            targetAudience:        "",
            title:                 "",
        );
    }
}







/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum SeminarDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    id(                  "id",                      "id",                       "ID",                       "TEXT PRIMARY KEY"),
    categories(          "categories",              "categories",               "Categories",               "BLOB NOT NULL"),
    credits(             "credits",                 "credits",                  "Credits",                  "BLOB NOT NULL"),
    dateCreated(         "date_created",            "created_at",               "Date Created",             "TEXT NOT NULL"),
    dateDeleted(         "date_deleted",            "deleted_at",               "Date Deleted",             "TEXT"),
    dateModified(        "date_modified",           "updated_at",               "Date Modified",            "TEXT"),
    description(         "description",             "description",              "Description",              "TEXT"),
    isFeatured(          "is_featured",             "featured",                 "Featured",                 "INTEGER NOT NULL"),
    targetAudience(      "target_audience",         "target_audience",          "Target Audience",          "TEXT"),
    title(               "title",                   "name",                     "Title",                    "TEXT NOT NULL");


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    const SeminarDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return SeminarDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return SeminarDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return SeminarDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => SeminarData;
    static String get objectTypeName => "seminar";
    static String get tableName      => "seminars";

    static String get tableBuilder {

        final columns = SeminarDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}