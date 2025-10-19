/*
 * Survey Question Data
 *
 * Created by:  Blake Davis
 * Description: Survey question data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/type_extensions.dart";
import "package:collection/collection.dart";




/* ======================================================================================================================
 * MARK: Survey Question Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class SurveyQuestionData {

    String id;

    bool isRequired;

    int order;

    List<String>? options;

    String  exhibitorId,
            question,
            status,
            type;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    SurveyQuestionData({
        required this.id,
        required this.exhibitorId,
        required this.isRequired,
                 this.options,
        required this.order,
        required this.question,
        required this.status,
        required this.type,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
                        exhibitorId,
                        id,
                        isRequired,
         Object.hashAll(options ?? []),
                        order,
                        question,
                        status,
                        type,
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
                                 return other is SurveyQuestionData      &&
                                        other.id          == id          &&
                                        other.exhibitorId == exhibitorId &&
                                        other.isRequired  == isRequired  &&
        DeepCollectionEquality().equals(other.options,       options)    &&
                                        other.order       == order       &&
                                        other.question    == question    &&
                                        other.status      == status      &&
                                        other.type        == type;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: SurveyQuestionData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  SurveyQuestionDataInfo.id            .jsonName  :  SurveyQuestionDataInfo.id            .columnName):      id,
            (apiOrDatabase  ?  SurveyQuestionDataInfo.exhibitorId   .jsonName  :  SurveyQuestionDataInfo.exhibitorId   .columnName):      exhibitorId,
            (apiOrDatabase  ?  SurveyQuestionDataInfo.isRequired    .jsonName  :  SurveyQuestionDataInfo.isRequired    .columnName):      isRequired.toInt(),
            (apiOrDatabase  ?  SurveyQuestionDataInfo.options       .jsonName  :  SurveyQuestionDataInfo.options       .columnName):      json.encode(options),
            (apiOrDatabase  ?  SurveyQuestionDataInfo.order         .jsonName  :  SurveyQuestionDataInfo.order         .columnName):      order,
            (apiOrDatabase  ?  SurveyQuestionDataInfo.question      .jsonName  :  SurveyQuestionDataInfo.question      .columnName):      question,
            (apiOrDatabase  ?  SurveyQuestionDataInfo.status        .jsonName  :  SurveyQuestionDataInfo.status        .columnName):      status,
            (apiOrDatabase  ?  SurveyQuestionDataInfo.type          .jsonName  :  SurveyQuestionDataInfo.type          .columnName):      type,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> SurveyQuestionData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SurveyQuestionData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions).
        final bool apiOrDatabase = (source == LocationEncoding.api);

        // Normalize any Map to Map<String, dynamic>
        Map<String, dynamic> jsonAsMap;
        if (jsonAsDynamic is String) {
          jsonAsMap = json.decode(jsonAsDynamic) as Map<String, dynamic>;
        } else if (jsonAsDynamic is Map) {
          jsonAsMap = Map<String, dynamic>.from(jsonAsDynamic);
        } else {
          logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
          if (defaultOnFailure) return SurveyQuestionData.empty();
          jsonAsMap = <String, dynamic>{};
        }

        var q = SurveyQuestionData(
          id: jsonAsMap[apiOrDatabase ? SurveyQuestionDataInfo.id.jsonName : SurveyQuestionDataInfo.id.columnName] as String? ?? '',
          exhibitorId: jsonAsMap[apiOrDatabase ? SurveyQuestionDataInfo.exhibitorId.jsonName : SurveyQuestionDataInfo.exhibitorId.columnName] as String? ?? '',
          isRequired: apiOrDatabase
              ? (jsonAsMap[SurveyQuestionDataInfo.isRequired.jsonName] as bool? ?? false)
              : ((jsonAsMap[SurveyQuestionDataInfo.isRequired.columnName] as int? ?? 0) == 1),
          options: apiOrDatabase
              ? (jsonAsMap[SurveyQuestionDataInfo.options.jsonName] as List<dynamic>?)?.cast<String>()
              : (jsonAsMap[SurveyQuestionDataInfo.options.columnName] != null
                  ? (json.decode(jsonAsMap[SurveyQuestionDataInfo.options.columnName] as String) as List).cast<String>()
                  : null),
          order: jsonAsMap[apiOrDatabase ? SurveyQuestionDataInfo.order.jsonName : SurveyQuestionDataInfo.order.columnName] as int? ?? 0,
          question: jsonAsMap[apiOrDatabase ? SurveyQuestionDataInfo.question.jsonName : SurveyQuestionDataInfo.question.columnName] as String? ?? '',
          status: jsonAsMap[apiOrDatabase ? SurveyQuestionDataInfo.status.jsonName : SurveyQuestionDataInfo.status.columnName] as String? ?? '',
          type: jsonAsMap[apiOrDatabase ? SurveyQuestionDataInfo.type.jsonName : SurveyQuestionDataInfo.type.columnName] as String? ?? '',
        );
        // print(q);
        return q;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty SurveyAnswerData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SurveyQuestionData.empty() => SurveyQuestionData(
        id:          "",
        exhibitorId: "",
        isRequired:  false,
        order:       0,
        question:    "",
        status:      "",
        type:        "",
    );
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum SurveyQuestionDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    id(                  "id",                      "id",                       "ID",                      "TEXT PRIMARY KEY"),
    exhibitorId(         "exhibitor_id",            "exhibitor_id",             "Exhibitor ID",            "TEXT"),
    isRequired(          "required",                "required",                 "Required",                "INTEGER"),
    options(             "options",                 "options",                  "Options",                 "BLOB"),
    order(               "sort_order",              "order",                    "Order",                   "INTEGER"),
    question(            "question",                "question",                 "Question",                "TEXT NOT NULL"),
    status(              "status",                  "status",                   "Status",                  "TEXT"),
    type(                "type",                    "type",                     "Type",                    "TEXT");

    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;


    const SurveyQuestionDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return SurveyQuestionDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return SurveyQuestionDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return SurveyQuestionDataInfo.values.map((value) { return value.jsonName; }).toList();
    }

    static Type   get objectType     => SurveyQuestionData;
    static String get objectTypeName => "surveyQuestion";
    static String get tableName      => "survey_questions";

    static String get tableBuilder {

        final columns = SurveyQuestionDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}