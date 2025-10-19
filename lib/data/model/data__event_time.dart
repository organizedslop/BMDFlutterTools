/**
 *  Event Date & Time Data
 *
 * Created by:  Blake Davis
 * Description: Event time data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";


import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/data/model/data__event_time_range.dart";

import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/type_extensions.dart";


import "package:collection/collection.dart";
import 'package:intl/intl.dart';







/* =====================================================================================================================
 * MARK: Event Time Data Model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 *  Represents the time frame of an event, with a list of time ranges, and time zone
 * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
class EventTimeData {

    List<EventTimeRangeData> dates;

    String timeZone;




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Constructor
     */
    EventTimeData({ required this.dates,
                    timeZone,

    })  :   //this.dates    = dates ?? [],
            this.timeZone = timeZone ?? "GMT";








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: == Operator Override
     */
    @override
    bool operator ==(Object other) {
        return other is EventTimeData                                       &&
            DeepCollectionEquality().equals(other.dates,        dates)      &&
                                            other.timeZone   == timeZone;
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: HashCode Override
     */
    @override
    int get hashCode => Object.hash(
        Object.hashAll(dates),
                       timeZone
    );








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: EventTimeData -> JSON
     */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions).
        final bool apiOrDatabase = (destination == LocationEncoding.api);


        return {
            (apiOrDatabase  ?  EventTimeDataInfo.dates      .jsonName  :  EventTimeDataInfo.dates       .columnName):  json.encode(dates.map((date) { return date.toJson(destination: destination); }).toList()),
            (apiOrDatabase  ?  EventTimeDataInfo.timeZone   .jsonName  :  EventTimeDataInfo.timeZone    .columnName):              timeZone,
        };
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: JSON -> EventTimeData
     */
    factory EventTimeData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {
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
            if (defaultOnFailure) { return EventTimeData.empty(); }
        }




        return EventTimeData(
            timeZone:  "GMT", // jsonAsMap[apiOrDatabase  ?  EventTimeDataInfo.timeZone.jsonName  :      EventTimeDataInfo.timeZone.columnName]    as String,
            dates:
                apiOrDatabase  ?  () {
                    return <EventTimeRangeData>[...(jsonAsMap[EventTimeDataInfo.dates.jsonName].map((date) => EventTimeRangeData.fromJson(date, source: source)).toList())];
                }()  :  () {
                    List<dynamic> datesAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[EventTimeDataInfo.dates.columnName]);
                    return datesAsDynamicList.map((date) => EventTimeRangeData.fromJson(date, source: source)).toList();
                }(),
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Default/Empty EventTimeData
     */
    factory EventTimeData.empty() {
        return EventTimeData(
            dates: <EventTimeRangeData>[]
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: EventTimeData -> Formatted String
     */
    @override
    String toString() {
      if (dates.isEmpty) return "";

      // Determine overall start and end across ranges
      final startMs = dates.map((r) => r.start).reduce((a, b) => a < b ? a : b) * 1000;
      final endMs   = dates.map((r) => r.end)  .reduce((a, b) => a > b ? a : b) * 1000;

      // Treat stored seconds as UTC to avoid local TZ shifting dates
      final start = DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true);
      final end   = DateTime.fromMillisecondsSinceEpoch(endMs,   isUtc: true);

      final sameYear  = start.year == end.year;
      final sameMonth = sameYear && start.month == end.month;
      final sameDay   = sameMonth && start.day == end.day;

      if (sameDay) {
        // e.g., August 27, 2025
        return DateFormat('LLLL d, yyyy').format(start);
      }

      if (sameMonth) {
        // e.g., August 27 - 30, 2025
        final month = DateFormat('LLLL').format(start);
        return '$month ${start.day} - ${end.day}, ${start.year}';
      }

      if (sameYear) {
        // e.g., August 27 - November 30, 2025
        final m1 = DateFormat('LLLL').format(start);
        final m2 = DateFormat('LLLL').format(end);
        return '$m1 ${start.day} - $m2 ${end.day}, ${start.year}';
      }

      // Cross-year
      // e.g., December 30, 2025 - January 2, 2026
      final left  = DateFormat('LLLL d, yyyy').format(start);
      final right = DateFormat('LLLL d, yyyy').format(end);
      return '$left - $right';
    }
}








/* =====================================================================================================================
 * MARK: Object & Table Info
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
enum EventTimeDataInfo {

    dates(   "dates",       "dates",        "Dates",        blobType),
    timeZone("timeZone",    "time_zone",    "Time Zone",    textType);

    const EventTimeDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static Type   get objectType     => EventTimeData;
    static String get objectTypeName => "eventTime";


    static List<String> get columnNameValues {
        return EventTimeDataInfo.values.map((value) { return value.columnName; }).toList();
    }

    static List<String> get displayNameValues {
        return EventTimeDataInfo.values.map((value) { return value.displayName; }).toList();
    }

    static List<String> get jsonNameValues {
        return EventTimeDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */

    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    static const String blobType = "BLOB NOT NULL";
    static const String idType   = "INTEGER PRIMARY KEY";
    static const String intType  = "INTEGER NOT NULL";
    static const String textType = "TEXT NOT NULL";
}
