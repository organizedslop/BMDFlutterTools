/*
 * Seminar Session Data Model
 *
 * Created by:  Blake Davis
 * Description: Seminar session data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "dart:typed_data";
import "package:bmd_flutter_tools/data/model/data__seminar.dart";
import "package:bmd_flutter_tools/data/model/data__seminar_speaker.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/type_extensions.dart";
import "package:collection/collection.dart";




/* ======================================================================================================================
 * MARK: Seminar Session Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class SeminarSessionData {

    String id;

    List<SeminarSpeakerData> presenters;

    SeminarData seminar;

    String  end,
            showId,
            start,
            status;

    String? roomId,
            roomNumber;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    SeminarSessionData({
        required this.id,
        required this.end,
        required this.presenters,
                 this.roomId,
                 this.roomNumber,
        required this.seminar,
        required this.showId,
        required this.start,
                      status,

    })  :   this.status = status ?? "draft";




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
                                 return other is SeminarSessionData             &&
                                        other.id                == id           &&
                                        other.end               == end          &&
        DeepCollectionEquality().equals(other.presenters,          presenters)  &&
                                        other.roomId            == roomId       &&
                                        other.roomNumber        == roomNumber   &&
                                        other.seminar           == seminar      &&
                                        other.showId            == showId       &&
                                        other.start             == start        &&
                                        other.status            == status;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
                        id,
                        end,
                        roomId,
                        roomNumber,
                        seminar,
                        showId,
         Object.hashAll(presenters),
                        start,
                        status
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: SeminarSessionData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  SeminarSessionDataInfo.id            .jsonName  :  SeminarSessionDataInfo.id             .columnName):               id,
            (apiOrDatabase  ?  SeminarSessionDataInfo.end           .jsonName  :  SeminarSessionDataInfo.end            .columnName):               end,
            (apiOrDatabase  ?  SeminarSessionDataInfo.presenters    .jsonName  :  SeminarSessionDataInfo.presenters     .columnName):   json.encode(presenters.map((seminarSpeaker) { return seminarSpeaker.toJson(destination: destination); }).toList()),
            (apiOrDatabase  ?  SeminarSessionDataInfo.roomId        .jsonName  :  SeminarSessionDataInfo.roomId         .columnName):               roomId,
            (apiOrDatabase  ?  SeminarSessionDataInfo.roomNumber    .jsonName  :  SeminarSessionDataInfo.roomNumber     .columnName):               roomNumber,
            (apiOrDatabase  ?  SeminarSessionDataInfo.seminar       .jsonName  :  SeminarSessionDataInfo.seminar        .columnName):   json.encode(seminar.toJson(destination: destination)),
            (apiOrDatabase  ?  SeminarSessionDataInfo.showId        .jsonName  :  SeminarSessionDataInfo.showId         .columnName):               showId,
            (apiOrDatabase  ?  SeminarSessionDataInfo.start         .jsonName  :  SeminarSessionDataInfo.start          .columnName):               start,
            (apiOrDatabase  ?  SeminarSessionDataInfo.status        .jsonName  :  SeminarSessionDataInfo.status         .columnName):               status,
        };
    }



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> SeminarData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SeminarSessionData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

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
            if (defaultOnFailure) { return SeminarSessionData.empty(); }
        }


        return SeminarSessionData(
            id:                           jsonAsMap[apiOrDatabase  ?  SeminarSessionDataInfo.id           .jsonName  :  SeminarSessionDataInfo.id            .columnName]      as String,
            end:                          jsonAsMap[apiOrDatabase  ?  SeminarSessionDataInfo.end          .jsonName  :  SeminarSessionDataInfo.end           .columnName]      as String,
            roomId:                       jsonAsMap[apiOrDatabase  ?  SeminarSessionDataInfo.roomId       .jsonName  :  SeminarSessionDataInfo.roomId        .columnName]      as String?,
            roomNumber:                   jsonAsMap[apiOrDatabase  ?  SeminarSessionDataInfo.roomNumber   .jsonName  :  SeminarSessionDataInfo.roomNumber    .columnName]      as String?,
            seminar: SeminarData.fromJson(jsonAsMap[apiOrDatabase  ?  SeminarSessionDataInfo.seminar      .jsonName  :  SeminarSessionDataInfo.seminar       .columnName],     source: source),
            showId:                       jsonAsMap[apiOrDatabase  ?  SeminarSessionDataInfo.showId       .jsonName  :  SeminarSessionDataInfo.showId        .columnName]      as String,
            start:                        jsonAsMap[apiOrDatabase  ?  SeminarSessionDataInfo.start        .jsonName  :  SeminarSessionDataInfo.start         .columnName]      as String,
            status:                       jsonAsMap[apiOrDatabase  ?  SeminarSessionDataInfo.status       .jsonName  :  SeminarSessionDataInfo.status        .columnName]      as String?,

            presenters: apiOrDatabase  ?  () {
                return <SeminarSpeakerData>[...(jsonAsMap[SeminarSessionDataInfo.presenters.jsonName].map((seminarSpeaker) => SeminarSpeakerData.fromJson(seminarSpeaker, source: LocationEncoding.api)).toList())];
            }()  :  () {
                List<dynamic> seminarSpeakersAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[SeminarSessionDataInfo.presenters.columnName]);
                return <SeminarSpeakerData>[...seminarSpeakersAsDynamicList.map((seminarSpeaker) => SeminarSpeakerData.fromJson(seminarSpeaker, source: LocationEncoding.database))];
            }(),
//   presenters: apiOrDatabase
//       ? () {
//           final raw = jsonAsMap[SeminarSessionDataInfo.presenters.jsonName];
//           if (raw is List) {
//             return <SeminarSpeakerData>[
//               ...raw.map((e) => SeminarSpeakerData.fromJson(e, source: LocationEncoding.api)),
//             ];
//           }
//           return <SeminarSpeakerData>[];
//         }()
//       : () {
//           final raw = jsonAsMap[SeminarSessionDataInfo.presenters.columnName];

//           dynamic decoded;
//           if (raw is Uint8List) {
//             try { decoded = json.decode(utf8.decode(raw)); } catch (_) { decoded = null; }
//           } else if (raw is String) {
//             try { decoded = json.decode(raw); } catch (_) { decoded = null; }
//           } else if (raw is List) {
//             decoded = raw;
//           }

//           if (decoded is List) {
//             return <SeminarSpeakerData>[
//               ...decoded.map((e) => SeminarSpeakerData.fromJson(e, source: LocationEncoding.database)),
//             ];
//           }
//           return <SeminarSpeakerData>[];
//         }(),

        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty SeminarData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SeminarSessionData.empty() {
        return SeminarSessionData(
            id:         "",
            end:        "",
            presenters: <SeminarSpeakerData>[],
            seminar:    SeminarData.empty(),
            showId:     "",
            start:      "",
        );
    }
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum SeminarSessionDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    id(                  "id",                      "id",                       "ID",                       "TEXT PRIMARY KEY"),
    end(                 "end",                     "end",                      "End",                      "TEXT NOT NULL"),
    presenters(          "presenters",              "presenters",               "presenters",               "BLOB NOT NULL"),
    roomId(              "room_id",                 "room_id",                  "Room ID",                  "TEXT"),
    roomNumber(          "room_number",             "room_number",              "Room Number",              "TEXT"),
    seminar(             "seminar",                 "seminar",                  "Seminar",                  "BLOB NOT NULL"),
    showId(              "show_id",                 "show_id",                  "Show ID",                  "TEXT"),
    start(               "start",                   "start",                    "Start",                    "TEXT NOT NULL"),
    status(              "status",                  "status",                   "Status",                   "TEXT NOT NULL");


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    const SeminarSessionDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return SeminarSessionDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return SeminarSessionDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return SeminarSessionDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => SeminarSessionData;
    static String get objectTypeName => "seminarSession";
    static String get tableName      => "seminarSessions";

    static String get tableBuilder {

        final columns = SeminarSessionDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}