/*
 * Booth Data
 *
 * Created by:  Blake Davis
 * Description: Booth data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";




/* ======================================================================================================================
 * MARK: Booth Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class BoothData {

    String  id,
            number,
            roomId,
            showId,
            size,
            status,
            type;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    BoothData({  required this.id,
                 required this.number,
                 required this.roomId,
                 required this.showId,
                 required this.size,
                 required this.status,
                 required this.type,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
         return other is BoothData             &&
                other.id            == id      &&
                other.number        == number  &&
                other.roomId        == roomId  &&
                other.showId        == showId  &&
                other.size          == size    &&
                other.status        == status  &&
                other.type          == type;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        id,
        number,
        roomId,
        showId,
        size,
        status,
        type
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: BoothData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  BoothDataInfo.id    .jsonName  :  BoothDataInfo.id    .columnName):     id,
            (apiOrDatabase  ?  BoothDataInfo.number.jsonName  :  BoothDataInfo.number.columnName):     number,
            (apiOrDatabase  ?  BoothDataInfo.roomId.jsonName  :  BoothDataInfo.roomId.columnName):     roomId,
            (apiOrDatabase  ?  BoothDataInfo.showId.jsonName  :  BoothDataInfo.showId.columnName):     showId,
            (apiOrDatabase  ?  BoothDataInfo.size  .jsonName  :  BoothDataInfo.size  .columnName):     size  ,
            (apiOrDatabase  ?  BoothDataInfo.status.jsonName  :  BoothDataInfo.status.columnName):     status,
            (apiOrDatabase  ?  BoothDataInfo.type  .jsonName  :  BoothDataInfo.type  .columnName):     type  ,
        };
    }





    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> BoothData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory BoothData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions)
        final bool apiOrDatabase = (source == LocationEncoding.api);

        // Determine if the JSON data is a string or a map. Otherwise, throw an error
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return BoothData.empty(); }
        }


        return BoothData(
            id:     jsonAsMap[apiOrDatabase  ?  BoothDataInfo.id        .jsonName  :    BoothDataInfo.id          .columnName].toString(),
            number: jsonAsMap[apiOrDatabase  ?  BoothDataInfo.number    .jsonName  :    BoothDataInfo.number      .columnName].toString(),
            roomId: jsonAsMap[apiOrDatabase  ?  BoothDataInfo.roomId    .jsonName  :    BoothDataInfo.roomId      .columnName].toString(),
            showId: jsonAsMap[apiOrDatabase  ?  BoothDataInfo.showId    .jsonName  :    BoothDataInfo.showId      .columnName].toString(),
            size:   jsonAsMap[apiOrDatabase  ?  BoothDataInfo.size      .jsonName  :    BoothDataInfo.size        .columnName].toString(),
            status: jsonAsMap[apiOrDatabase  ?  BoothDataInfo.status    .jsonName  :    BoothDataInfo.status      .columnName].toString(),
            type:   jsonAsMap[apiOrDatabase  ?  BoothDataInfo.type      .jsonName  :    BoothDataInfo.type        .columnName].toString(),
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty BadgeData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory BoothData.empty() {
        return BoothData(
            id:     "",
            number: "",
            roomId: "",
            showId: "",
            size:   "",
            status: "",
            type:   "",
        );
    }
}




/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum BoothDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    id(                  "id",                      "id",                       "ID",                       "TEXT PRIMARY KEY"),
    number(              "number",                  "number",                   "Number",                   "TEXT NOT NULL"),
    roomId(              "roomId",                  "room_id",                  "Room ID",                  "TEXT NOT NULL"),
    showId(              "showId",                  "show_id",                  "Show ID",                  "TEXT NOT NULL"),
    size(                "size",                    "size",                     "Size",                     "TEXT NOT NULL"),
    status(              "status",                  "status",                   "Status",                   "TEXT NOT NULL"),
    type(                "type",                    "type",                     "Type",                     "TEXT NOT NULL");


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;


    const BoothDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return BoothDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return BoothDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return BoothDataInfo.values.map((value) { return value.jsonName; }).toList();
    }
}