/*
 *  Seminar Category Data Model
 *
 * Created by:  Blake Davis
 * Description: Seminar category data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";




/* =====================================================================================================================
 * MARK: Seminar Category Data Model
 * ------------------------------------------------------------------------------------------------------------------ */class SeminarCategoryData {

    String id;

    String? description,
            name,
            slug;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    SeminarCategoryData({
        required this.id,
                 this.description,
                 this.name,
                 this.slug,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
        return other is SeminarCategoryData         &&
               other.id             == id           &&
               other.description    == description  &&
               other.name           == name         &&
               other.slug           == slug;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        id,
        description,
        name,
        slug,
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: SeminarCategoryData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  SeminarCategoryDataInfo.id         .jsonName  :  SeminarCategoryDataInfo.id         .columnName):  id,
            (apiOrDatabase  ?  SeminarCategoryDataInfo.description.jsonName  :  SeminarCategoryDataInfo.description.columnName):  description,
            (apiOrDatabase  ?  SeminarCategoryDataInfo.name       .jsonName  :  SeminarCategoryDataInfo.name       .columnName):  name,
            (apiOrDatabase  ?  SeminarCategoryDataInfo.slug       .jsonName  :  SeminarCategoryDataInfo.slug       .columnName):  slug,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> SeminarCategoryData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SeminarCategoryData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

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
            if (defaultOnFailure) { return SeminarCategoryData.empty(); }
        }


        return SeminarCategoryData(
            id:           jsonAsMap[apiOrDatabase  ?  SeminarCategoryDataInfo.id         .jsonName  :  SeminarCategoryDataInfo.id         .columnName]    as String,
            description:  jsonAsMap[apiOrDatabase  ?  SeminarCategoryDataInfo.description.jsonName  :  SeminarCategoryDataInfo.description.columnName]    as String?,
            name:         jsonAsMap[apiOrDatabase  ?  SeminarCategoryDataInfo.name       .jsonName  :  SeminarCategoryDataInfo.name       .columnName]    as String?,
            slug:         jsonAsMap[apiOrDatabase  ?  SeminarCategoryDataInfo.slug       .jsonName  :  SeminarCategoryDataInfo.slug       .columnName]    as String?,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty SeminarCategoryData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SeminarCategoryData.empty() {
        return SeminarCategoryData(
            id:          "",
            description: "",
            name:        "",
            slug:        "",

        );
    }
}




/* =====================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */enum SeminarCategoryDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    id(                  "id",                      "id",                      "ID",                        "TEXT PRIMARY KEY"),
    description(         "description",             "description",             "Description",               "TEXT"),
    name(                "name",                    "name",                    "Name",                      "TEXT"),
    slug(                "slug",                    "slug",                    "Slug",                      "TEXT");


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    const SeminarCategoryDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return SeminarCategoryDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return SeminarCategoryDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return SeminarCategoryDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => SeminarCategoryData;
    static String get objectTypeName => "seminarCategory";
    static String get tableName      => "seminar_categories";

    static String get tableBuilder {

        final columns = SeminarCategoryDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}