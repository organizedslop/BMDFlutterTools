/*
 * Phone Number Data
 *
 * Created by:  Blake Davis
 * Description: Phone number data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";

import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";




/* ======================================================================================================================
 * MARK: Phone Number Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class PhoneData {

    // TODO: Consider moving fax here

    // int parentId;

    String // parentType,
        primary;

    // String? secondary;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    PhoneData({ required this.primary,
                            //   secondary
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
        return other is PhoneData        &&
               other.primary == primary;
    }



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        primary,
        null
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: PhoneData -> String
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    String toString({ bool formatted = true }) {

        if (formatted) {
            if (primary.length == 10) {
                return "(${primary.substring(0, 3)}) ${primary.substring(3, 6)}-${primary.substring(6)}";
            }
        }
        return primary;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: PhoneData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, String> toJson({ required LocationEncoding destination }) {
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  PhoneDataInfo.primary  .jsonName  :  PhoneDataInfo.primary  .columnName):  primary,
            // (apiOrDatabase  ?  PhoneDataInfo.secondary.jsonName  :  PhoneDataInfo.secondary.columnName):  secondary,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> PhoneData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory PhoneData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {
        final bool apiOrDatabase = (source == LocationEncoding.api);

        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return PhoneData.empty(); }
        }

        return PhoneData(
            primary:    jsonAsMap[apiOrDatabase  ?  PhoneDataInfo.primary  .jsonName  :  PhoneDataInfo.primary  .columnName]    as String,
            // secondary:  jsonAsMap[apiOrDatabase  ?  PhoneDataInfo.secondary.jsonName  :  PhoneDataInfo.secondary.columnName]    as String?,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty PhoneData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory PhoneData.empty() {
        return PhoneData(primary: "");
    }
}








/* =============================================================================
 * MARK: Object & Table Info
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 */
enum PhoneDataInfo {

    primary(    "primary",        "primary",        textType); //,
    // secondary(  "secondary",      "secondary",      textType);

    const PhoneDataInfo(this.columnName, this.jsonName, this.columnType);

    final String columnName;
    final String columnType;
    final String jsonName;


    static List<String> get columnNameValues {
        return PhoneDataInfo.values.map((value) { return value.columnName; }).toList();
    }

    static List<String> get jsonNameValues {
        return PhoneDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static const String blobType = "BLOB NOT NULL";
    static const String intType  = "INTEGER NOT NULL";
    static const String textType = "TEXT NOT NULL";




    static Type   get objectType     => PhoneData;
    static String get objectTypeName => "phone";
}