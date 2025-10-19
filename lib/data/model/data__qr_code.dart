/**
 * Created by:  Blake Davis
 * Description: QR code data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";


import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";




/* =============================================================================
 * MARK: QR Code Data Model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 */
class QrCodeData {

    String  id;

    // int?    parentId;

    String  imageData,
            //parentType,
            url;





    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Constructor
     */
    QrCodeData({ required this.id,

                               imageData,
                //  required this.parentId,
                //  required this.parentType,
                 required this.url

    })  :   this.imageData = imageData ?? "";




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: == Operator Override
     */
    @override
    bool operator ==(Object other) {
        return other is QrCodeData          &&
               other.id        == id        &&
               other.imageData == imageData &&
               other.url       == url;
    }




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: HashCode Override
     */
    @override
    int get hashCode => Object.hash(id, imageData, url);








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: QrCodeData -> JSON
     */
    Map<String, String> toJson({ required LocationEncoding destination }) {
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  QrCodeDataInfo.id        .jsonName  :  QrCodeDataInfo.id        .columnName):    id,
            (apiOrDatabase  ?  QrCodeDataInfo.imageData .jsonName  :  QrCodeDataInfo.imageData .columnName):    imageData,
            // (apiOrDatabase  ?  QrCodeDataInfo.parentId  .jsonName  :  QrCodeDataInfo.parentId  .columnName):    parentId,
            // (apiOrDatabase  ?  QrCodeDataInfo.parentType.jsonName  :  QrCodeDataInfo.parentType.columnName):    parentType,
            (apiOrDatabase  ?  QrCodeDataInfo.url       .jsonName  :  QrCodeDataInfo.url       .columnName):    url
        };
    }




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: JSON -> QrCodeData
     */
    factory QrCodeData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {
        final bool apiOrDatabase = (source == LocationEncoding.api);

        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return QrCodeData.empty(); }
        }

        return QrCodeData(
            id:         jsonAsMap[apiOrDatabase  ?  QrCodeDataInfo.id        .jsonName  :   QrCodeDataInfo.id        .columnName]    as String,

            imageData:  jsonAsMap[apiOrDatabase  ?  QrCodeDataInfo.imageData .jsonName  :   QrCodeDataInfo.imageData .columnName]    as String?,
            // parentId:   jsonAsMap[apiOrDatabase  ?  QrCodeDataInfo.parentId  .jsonName  :   QrCodeDataInfo.parentId  .columnName]    as int,
            // parentType: jsonAsMap[apiOrDatabase  ?  QrCodeDataInfo.parentType.jsonName  :   QrCodeDataInfo.parentType.columnName]    as String,
            url:        jsonAsMap[apiOrDatabase  ?  QrCodeDataInfo.url       .jsonName  :   QrCodeDataInfo.url       .columnName]    as String
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Default/Empty QrCodeData
     */
    factory QrCodeData.empty() {
        return QrCodeData(id: "", imageData: "", url: "");
    }
}








/* =============================================================================
 * MARK: Object & Table Info
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 */
enum QrCodeDataInfo {

    id(         "id",             "identifier",       idType),
    imageData(  "image_data",     "image_data",     blobType),
    // parentId(   "parent_id",      "parent_id",       intType),
    // parentType( "parent_type",    "parent_type",    textType),
    url(        "url",            "url",            textType);

    const QrCodeDataInfo(this.columnName, this.jsonName, this.columnType);

    final String columnName;
    final String columnType;
    final String jsonName;


    static List<String> get columnNameValues {
        return QrCodeDataInfo.values.map((value) { return value.columnName; }).toList();
    }

    static List<String> get jsonNameValues {
        return QrCodeDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static const String blobType = "BLOB NOT NULL";
    static const String idType   = "TEXT PRIMARY KEY";
    static const String intType  = "INTEGER NOT NULL";
    static const String textType = "TEXT NOT NULL";




    static Type   get objectType     => QrCodeData;
    static String get objectTypeName => "qr_code";
    static String get tableName      => "qr_codes";

    static String get tableBuilder {

        final columns = QrCodeDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}