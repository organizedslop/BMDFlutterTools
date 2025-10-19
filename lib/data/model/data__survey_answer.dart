/*
 * Survey Answer Data
 *
 * Created by:  Blake Davis
 * Description: Survey answer data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/data/model/data__survey_question.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";




/* ======================================================================================================================
 * MARK: Survey Answer Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class SurveyAnswerData {

    String id;

    String  exhibitorId,
            surveyQuestionId,
            question;

    String? existingAnswer;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    SurveyAnswerData({  required this.id,
                        required this.exhibitorId,
                                 this.existingAnswer,
                        required this.question,
                        required this.surveyQuestionId,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        id,
        exhibitorId,
        existingAnswer,
        question,
        surveyQuestionId,
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
        return other is SurveyAnswerData                  &&
               other.id               == id               &&
               other.exhibitorId      == exhibitorId      &&
               other.existingAnswer   == existingAnswer   &&
               other.question         == question         &&
               other.surveyQuestionId == surveyQuestionId;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: SurveyAnswerData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  SurveyAnswerDataInfo.id              .jsonName  :  SurveyAnswerDataInfo.id              .columnName):      id,
            (apiOrDatabase  ?  SurveyAnswerDataInfo.exhibitorId     .jsonName  :  SurveyAnswerDataInfo.exhibitorId     .columnName):      exhibitorId,
            (apiOrDatabase  ?  SurveyAnswerDataInfo.existingAnswer  .jsonName  :  SurveyAnswerDataInfo.existingAnswer  .columnName):      existingAnswer,
            (apiOrDatabase  ?  SurveyAnswerDataInfo.question        .jsonName  :  SurveyAnswerDataInfo.question        .columnName):      question,
            (apiOrDatabase  ?  SurveyAnswerDataInfo.surveyQuestionId.jsonName  :  SurveyAnswerDataInfo.surveyQuestionId.columnName):      surveyQuestionId,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> SurveyAnswerData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SurveyAnswerData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

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
          if (defaultOnFailure) return SurveyAnswerData.empty();
          jsonAsMap = <String, dynamic>{};
        }

        // If the source is the API, decode the SurveyQuestion and save it to the database
        SurveyQuestionData surveyQuestion;
        if (apiOrDatabase) {
          final questionField = jsonAsMap['survey_question'];
          if (questionField is Map) {
            surveyQuestion = SurveyQuestionData.fromJson(
              questionField,
              source: LocationEncoding.api,
            );
            AppDatabase.instance.write(surveyQuestion);
          } else {
            surveyQuestion = SurveyQuestionData.empty();
          }
        } else {
          surveyQuestion = SurveyQuestionData.empty();
        }

        var answer = SurveyAnswerData(
          id:               jsonAsMap[apiOrDatabase  ?  SurveyAnswerDataInfo.id               .jsonName  :            SurveyAnswerDataInfo.id              .columnName]     as String,
          exhibitorId:      jsonAsMap[apiOrDatabase  ?  SurveyAnswerDataInfo.exhibitorId      .jsonName  :            SurveyAnswerDataInfo.exhibitorId     .columnName]     as String,
          existingAnswer:   jsonAsMap[apiOrDatabase  ?  SurveyAnswerDataInfo.existingAnswer   .jsonName  :            SurveyAnswerDataInfo.existingAnswer  .columnName]     as String?,
          surveyQuestionId: surveyQuestion.id,
          question:         surveyQuestion.question,
        );

        return answer;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty SurveyAnswerData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory SurveyAnswerData.empty() => SurveyAnswerData(
        id:               "",
        exhibitorId:      "",
        question:         "",
        surveyQuestionId: "",
    );
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum SurveyAnswerDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    id(                  "id",                      "id",                       "ID",                      "TEXT PRIMARY KEY"),
    exhibitorId(         "exhibitor_id",            "exhibitor_id",             "Exhibitor ID",            "TEXT NOT NULL"),
    existingAnswer(      "existing_answer",         "answer",                   "Existing Answer",         "TEXT"),
    question(            "question",                "question",                 "Question",                "TEXT NOT NULL"),
    surveyQuestionId(    "survey_question_id",      "survey_question_id",       "Survey Question ID",      "TEXT NOT NULL");

    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;


    const SurveyAnswerDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return SurveyAnswerDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return SurveyAnswerDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return SurveyAnswerDataInfo.values.map((value) { return value.jsonName; }).toList();
    }

    static Type   get objectType     => SurveyAnswerData;
    static String get objectTypeName => "surveyAnswer";
    static String get tableName      => "survey_answers";

    static String get tableBuilder {

        final columns = SurveyAnswerDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}