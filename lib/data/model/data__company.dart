/*
 * Company Data
 *
 * Created by:  Blake Davis
 * Description: Company data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/data__address.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";



/* ======================================================================================================================
 * MARK: Company Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class CompanyData {

    String  id;

    AddressData address;

    List<String> categories;

    String  name;

    String? description,
            email,
            exhibitorId,
            phone,
            website;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    CompanyData({ required this.id,

                  required this.address,
                                categories,
                           this.description,
                           this.email,
                           this.exhibitorId,
                  required this.name,
                           this.phone,
                           this.website,

    })  :   this.categories  = categories  ?? <String>[];




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
        return other is CompanyData              &&
               other.id          == id           &&
               other.address     == address      &&
               other.categories  == categories   &&
               other.description == description  &&
               other.email       == email        &&
               other.exhibitorId == exhibitorId  &&
               other.name        == name         &&
               other.phone       == phone        &&
               other.website     == website;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        id,
        address,
        categories,
        description,
        email,
        exhibitorId,
        name,
        phone,
        website
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: CompanyData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions).
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  CompanyDataInfo.id           .jsonName  :  CompanyDataInfo.id            .columnName):                id,

            (apiOrDatabase  ?  CompanyDataInfo.address      .jsonName  :  CompanyDataInfo.address       .columnName):    json.encode(address       .toJson(destination: destination)),
            (apiOrDatabase  ?  CompanyDataInfo.categories   .jsonName  :  CompanyDataInfo.categories    .columnName):    json.encode(categories),
            (apiOrDatabase  ?  CompanyDataInfo.description  .jsonName  :  CompanyDataInfo.description   .columnName):                description,
            (apiOrDatabase  ?  CompanyDataInfo.email        .jsonName  :  CompanyDataInfo.email         .columnName):                email,
            (apiOrDatabase  ?  CompanyDataInfo.exhibitorId  .jsonName  :  CompanyDataInfo.exhibitorId   .columnName):                exhibitorId,
            (apiOrDatabase  ?  CompanyDataInfo.name         .jsonName  :  CompanyDataInfo.name          .columnName):                name,
            (apiOrDatabase  ?  CompanyDataInfo.phone        .jsonName  :  CompanyDataInfo.phone         .columnName):                phone,
            (apiOrDatabase  ?  CompanyDataInfo.website      .jsonName  :  CompanyDataInfo.website       .columnName):                website,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> CompanyData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory CompanyData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions).
        final bool apiOrDatabase = (source == LocationEncoding.api);

        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return CompanyData.empty(); }
        }

        return CompanyData(
            id:                              jsonAsMap[apiOrDatabase  ?  CompanyDataInfo.id            .jsonName  :       CompanyDataInfo.id         .columnName]           as String,
            address:    AddressData.fromJson(jsonAsMap[apiOrDatabase  ?  CompanyDataInfo.address       .jsonName  :       CompanyDataInfo.address    .columnName],          source: source),
            description:                     jsonAsMap[apiOrDatabase  ?  CompanyDataInfo.description   .jsonName  :       CompanyDataInfo.description.columnName]           as String?,
            email:                           jsonAsMap[apiOrDatabase  ?  CompanyDataInfo.email         .jsonName  :       CompanyDataInfo.email      .columnName]           as String?,
            exhibitorId:                     jsonAsMap[apiOrDatabase  ?  CompanyDataInfo.exhibitorId   .jsonName  :       CompanyDataInfo.exhibitorId.columnName]           as String?,
            name:                            jsonAsMap[apiOrDatabase  ?  CompanyDataInfo.name          .jsonName  :       CompanyDataInfo.name       .columnName]           as String,
            phone:                           jsonAsMap[apiOrDatabase  ?  CompanyDataInfo.phone         .jsonName  :       CompanyDataInfo.phone      .columnName]           as String?,
            website:                         jsonAsMap[apiOrDatabase  ?  CompanyDataInfo.website       .jsonName  :       CompanyDataInfo.website    .columnName]           as String?,

            categories: apiOrDatabase  ?  () {
                return <String>[]; //[...jsonAsMap[CompanyDataInfo.categories.jsonName]];
            }()  :  () {
                return <String>[];
                // List<dynamic> categoriesAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[CompanyDataInfo.categories.columnName]);
                // return <String>[...categoriesAsDynamicList];
            }()
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty CompanyData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory CompanyData.empty() {
        return CompanyData(
            id:          "",
            address:     AddressData.empty(),
            categories:  <String>[],
            name:        "",
        );
    }
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum CompanyDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    id(                  "id",                      "id",                       "ID",                       idType),
    address(             "address",                 "address",                  "Address",                  blobType),
    categories(          "categories",              "categories",               "Categories",               textType),
    description(         "description",             "description",              "Description",              "TEXT"),
    email(               "email",                   "email",                    "Email",                    "TEXT"),
    exhibitorId(         "exhibitor_id",            "exhibitor_id",             "Exhibitor ID",             "TEXT"),
    name(                "name",                    "name",                     "Name",                     textType),
    phone(               "phone",                   "phone",                    "Phone",                    "TEXT"),
    website(             "website",                 "website",                  "Website",                  "TEXT");


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    static const blobType = "BLOB NOT NULL";
    static const idType   = "TEXT PRIMARY KEY";
    static const intType  = "INTEGER NOT NULL";
    static const textType = "TEXT NOT NULL";


    const CompanyDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return CompanyDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return CompanyDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return CompanyDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => CompanyData;
    static String get objectTypeName => "company";
    static String get tableName      => "companies";

    static String get tableBuilder {

        final columns = CompanyDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}