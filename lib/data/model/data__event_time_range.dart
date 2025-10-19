/**
 *  Event Time Range Data
 *
 * Created by:  Blake Davis
 * Description: Event time range data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";


import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";

import "package:bmd_flutter_tools/utilities/utilities__print.dart";


import "package:intl/intl.dart";








/* =====================================================================================================================
 * MARK: Event Time Range Data Model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 *  Represents a continous time range with 24hr start and end times represented as ##:##
 *  Because the intended use for this class is for event times, seconds are disregarded.
 * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
class EventTimeRangeData {

    int start,
        end;




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Constructor
     */
    EventTimeRangeData({ start,
                         end

    })  :   this.start = start ?? 0,
            this.end   = end   ?? 0;








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: EventTimeRangeData -> JSON
     */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions).
        final bool apiOrDatabase = (destination == LocationEncoding.api);


        return {
            (apiOrDatabase  ?  EventTimeRangeDataInfo.start.jsonName  :  EventTimeRangeDataInfo.start.columnName):  start,
            (apiOrDatabase  ?  EventTimeRangeDataInfo.end  .jsonName  :  EventTimeRangeDataInfo.end  .columnName):  end
        };
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: JSON -> EventTimeRangeData
     */
    factory EventTimeRangeData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {
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
            if (defaultOnFailure) { return EventTimeRangeData.empty(); }
        }




        return EventTimeRangeData(
            start: jsonAsMap[apiOrDatabase  ?  EventTimeRangeDataInfo.start.jsonName  :    EventTimeRangeDataInfo.start.columnName]    as int,
            end:   jsonAsMap[apiOrDatabase  ?  EventTimeRangeDataInfo.end.jsonName    :    EventTimeRangeDataInfo.end.columnName]      as int,
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Default/Empty EventTimeRangeData
     */
    factory EventTimeRangeData.empty() {
        return EventTimeRangeData(
            start: 0,
            end:   0
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: EventTimeData -> Formatted String
     */
    @override
    String toString({ bool includeDates = true,
                      bool includeTimes = true  }) {

        // Convert the UNIX timestamps to Dart DateTime objects
        DateTime startAsDateTime = DateTime.fromMillisecondsSinceEpoch(start * 1000).toUtc();
        DateTime endAsDateTime   = DateTime.fromMillisecondsSinceEpoch(end   * 1000).toUtc();

        // If the date range starts and ends on the same day
        if (startAsDateTime.day   == endAsDateTime.day    &&
            startAsDateTime.month == endAsDateTime.month  &&
            startAsDateTime.year  == endAsDateTime.year   ) {

            return  (includeDates                 ? DateFormat("MMM d, yyyy").format(startAsDateTime) : "")  +
                    (includeDates && includeTimes ? " "                                               : "")  +
                    (                includeTimes ? DateFormat("h:mm aaa - ").format(startAsDateTime) : "")  +
                    (                includeTimes ? DateFormat("h:mm aaa")   .format(endAsDateTime)   : "");

        } else {
            // If the date range starts and ends in the same month
            if (startAsDateTime.month == endAsDateTime.month  &&
                startAsDateTime.year  == endAsDateTime.year   ) {

                return  (includeDates                 ? DateFormat("MMM d - ")   .format(startAsDateTime) : "")  +
                        (includeDates                 ? DateFormat("d, yyyy")    .format(endAsDateTime)   : "")  +
                        (includeDates && includeTimes ? " "                                               : "")  +
                        (                includeTimes ? DateFormat("h:mm aaa - ").format(startAsDateTime) : "")  +
                        (                includeTimes ? DateFormat("h:mm aaa")   .format(endAsDateTime)   : "");

            } else {
                // If the date range starts and ends in the same year
                if (startAsDateTime.year == endAsDateTime.year) {

                    return  (includeDates                 ? DateFormat("MMM d - ")   .format(startAsDateTime) : "")  +
                            (includeDates                 ? DateFormat("MMM d, yyyy").format(endAsDateTime)   : "")  +
                            (includeDates && includeTimes ? " "                                               : "")  +
                            (                includeTimes ? DateFormat("h:mm aaa - ").format(startAsDateTime) : "")  +
                            (                includeTimes ? DateFormat("h:mm aaa")   .format(endAsDateTime)   : "");

                } else {
                    return  (includeDates                 ? DateFormat("MMM d, yyyy - ").format(startAsDateTime) : "")  +
                            (includeDates                 ? DateFormat("MMM d, yyyy")   .format(endAsDateTime)   : "")  +
                            (includeDates && includeTimes ? " "                                                  : "")  +
                            (                includeTimes ? DateFormat("h:mm aaa - ")   .format(startAsDateTime) : "")  +
                            (                includeTimes ? DateFormat("h:mm aaa")      .format(endAsDateTime)   : "");
                }
            }
        }
    }
}








/* =====================================================================================================================
 * MARK: Object & Table Info
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
enum EventTimeRangeDataInfo {

    start("start",      "start",        "Start",        intType),
    end(  "end",        "end",          "End",          intType);

    const EventTimeRangeDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static Type   get objectType     => EventTimeRangeData;
    static String get objectTypeName => "eventTimeRange";


    static List<String> get columnNameValues {
        return EventTimeRangeDataInfo.values.map((value) { return value.columnName; }).toList();
    }

    static List<String> get displayNameValues {
        return EventTimeRangeDataInfo.values.map((value) { return value.displayName; }).toList();
    }

    static List<String> get jsonNameValues {
        return EventTimeRangeDataInfo.values.map((value) { return value.jsonName; }).toList();
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




