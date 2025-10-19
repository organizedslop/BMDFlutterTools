/**
 *  Image Data Model
 *
 * Created by:  Blake Davis
 * Description: Image data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";


import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";

import "package:bmd_flutter_tools/utilities/utilities__print.dart";








/* =====================================================================================================================
 * MARK: Image Data Model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
class ImageData {

    int id;

    String localUrl,
           remoteUrl;

    String data; // This type needs to be changed to something that can easily store raw img data



    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Constructor
     */
    ImageData({ required this.id,
                required this.data,
                required this.localUrl,
                required this.remoteUrl
    });









    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: == Operator Override
     */
    @override
    bool operator ==(Object other) {
        return other is ImageData         &&
            other.id        == id         &&
            other.data      == data       &&
            other.localUrl  == localUrl   &&
            other.remoteUrl == remoteUrl;
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: HashCode Override
     */
    @override
    int get hashCode => Object.hash(
        id,
        data,
        localUrl,
        remoteUrl
    );








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: ImageData -> JSON
     */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions).
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  ImageDataInfo.id       .jsonName  :  ImageDataInfo.id       .columnName):    id,
            (apiOrDatabase  ?  ImageDataInfo.data     .jsonName  :  ImageDataInfo.data     .columnName):    data,
            (apiOrDatabase  ?  ImageDataInfo.localUrl .jsonName  :  ImageDataInfo.localUrl .columnName):    localUrl,
            (apiOrDatabase  ?  ImageDataInfo.remoteUrl.jsonName  :  ImageDataInfo.remoteUrl.columnName):    remoteUrl
        };
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: JSON -> ImageData
     */
    factory ImageData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {
        /**
         *  Create boolean value for the JSON's source (to shorten ternary expressions).
         */
        final bool apiOrDatabase = (source == LocationEncoding.api);


        /**
         *  Determine if the JSON data is a string or a map. Otherwise, throw an error.
         */
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return ImageData.empty(); }
        }




        return ImageData(
            id:                  jsonAsMap[apiOrDatabase  ?  ImageDataInfo.id       .jsonName  :      ImageDataInfo.id       .columnName]    as int,
            data:                jsonAsMap[apiOrDatabase  ?  ImageDataInfo.data     .jsonName  :      ImageDataInfo.data     .columnName]    as String,
            localUrl:            "",
            remoteUrl:           jsonAsMap[apiOrDatabase  ?  ImageDataInfo.remoteUrl.jsonName  :      ImageDataInfo.remoteUrl.columnName]    as String
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Default/Empty ImageData
     */
    factory ImageData.empty() {
        return ImageData(
            id:        0,
            data:      "",
            localUrl:  "",
            remoteUrl: ""
        );
    }
}








/* =====================================================================================================================
 * MARK: Object & Table Info
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
enum ImageDataInfo {

    id(       "id",             "id",             "ID",              idType),
    data(     "data",           "data",           "Data",            blobType),
    localUrl( "localUrl",       "",               "Local URL",       textType),
    remoteUrl("remoteUrl",      "url",            "Remote URL",      textType);


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    static const String blobType = "BLOB NOT NULL";
    static const String idType   = "INTEGER PRIMARY KEY";
    static const String intType  = "INTEGER NOT NULL";
    static const String textType = "TEXT NOT NULL";


    const ImageDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return ImageDataInfo.values.map((value) { return value.columnName; }).toList();
    }

    static List<String> get displayNameValues {
        return ImageDataInfo.values.map((value) { return value.displayName; }).toList();
    }

    static List<String> get jsonNameValues {
        return ImageDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => ImageData;
    static String get objectTypeName => "image";
    static String get tableName      => "images";

    static String get tableBuilder {

        final columns = ImageDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}