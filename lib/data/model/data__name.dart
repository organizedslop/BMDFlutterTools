/*
 * Name Data
 *
 * Created by:  Blake Davis
 * Description: Name data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";

import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";




/* ======================================================================================================================
 * MARK: Name Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class NameData {

    String  prefix,
            first,
            middle,
            last,
            suffix;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    NameData({          prefix,
          required this.first,
                        middle,
                        last,
                        suffix

    })  :   this.prefix = prefix ?? "",
            this.middle = middle ?? "",
            this.last   = last   ?? "",
            this.suffix = suffix ?? "";




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
        return other is NameData      &&
               other.prefix == prefix &&
               other.first  == first  &&
               other.middle == middle &&
               other.last   == last   &&
               other.suffix == suffix;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(prefix, first, middle, last, suffix);




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: NameData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, String> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions).
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  NameDataInfo.prefix.jsonName  :  NameDataInfo.prefix.columnName):  prefix,
            (apiOrDatabase  ?  NameDataInfo.first .jsonName  :  NameDataInfo.first .columnName):  first,
            (apiOrDatabase  ?  NameDataInfo.middle.jsonName  :  NameDataInfo.middle.columnName):  middle,
            (apiOrDatabase  ?  NameDataInfo.last  .jsonName  :  NameDataInfo.last  .columnName):  last,
            (apiOrDatabase  ?  NameDataInfo.suffix.jsonName  :  NameDataInfo.suffix.columnName):  suffix
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> NameData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory NameData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions).
        final bool apiOrDatabase = (source == LocationEncoding.api);

        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return NameData.empty(); }
        }

        return NameData(
            prefix: jsonAsMap[apiOrDatabase  ?  NameDataInfo.prefix.jsonName  :  NameDataInfo.prefix.columnName]  as String?,
            first:  jsonAsMap[apiOrDatabase  ?  NameDataInfo.first .jsonName  :  NameDataInfo.first .columnName]  as String,
            middle: jsonAsMap[apiOrDatabase  ?  NameDataInfo.middle.jsonName  :  NameDataInfo.middle.columnName]  as String?,
            last:   jsonAsMap[apiOrDatabase  ?  NameDataInfo.last  .jsonName  :  NameDataInfo.last  .columnName]  as String?,
            suffix: jsonAsMap[apiOrDatabase  ?  NameDataInfo.suffix.jsonName  :  NameDataInfo.suffix.columnName]  as String?
        );
    }




    String get full {
        return [prefix, first, middle, last, suffix].where((name) => name.isNotEmpty).toList().join(" ").trim();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty NameData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory NameData.empty() {
        return NameData(prefix: "", first: "", middle: "", last: "", suffix: "");
    }
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum NameDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    prefix(              "prefix",                  "prefix",                   "Prefix",                   textType,      "2"),
    first(               "first",                   "first_name",               "First Name",               textType,      "3"),
    middle(              "middle",                  "middle_name",              "Middle Name",              textType,      "4"),
    last (               "last",                    "last_name",                "Last Name",                textType,      "6"),
    suffix(              "suffix",                  "suffix",                   "Suffix",                   textType,      "8");


    final String  columnName;
    final String  columnType;
    final String  displayName;
    final String? gformSubfieldId;
    final String  jsonName;

    static const String blobType = "BLOB NOT NULL";
    static const String intType  = "INTEGER NOT NULL";
    static const String textType = "TEXT NOT NULL";


    const NameDataInfo(this.columnName, this.jsonName, this.columnType, this.displayName, this.gformSubfieldId);



    static List<String> get columnNameValues {
        return NameDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return NameDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static Map<String, String?> get gformSubfieldIds {
        return { for (var value in NameDataInfo.values) value.columnName: value.gformSubfieldId };
    }
    static List<String> get jsonNameValues {
        return NameDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => NameData;
    static String get objectTypeName => "name";
}