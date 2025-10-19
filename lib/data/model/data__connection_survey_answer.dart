/*
 * Connection Survey Answer Data
 *
 * Stores survey answers keyed by connection and question so we can
 * reuse them when the device is offline.
 */

import 'package:bmd_flutter_tools/data/model/enum__location_encoding.dart';

class ConnectionSurveyAnswerData {
  final String connectionId;
  final String surveyQuestionId;
  final String answer;
  final bool isPending;
  final String updatedAt;

  const ConnectionSurveyAnswerData({
    required this.connectionId,
    required this.surveyQuestionId,
    required this.answer,
    required this.isPending,
    required this.updatedAt,
  });

  ConnectionSurveyAnswerData copyWith({
    String? answer,
    bool? isPending,
    String? updatedAt,
  }) {
    return ConnectionSurveyAnswerData(
      connectionId: connectionId,
      surveyQuestionId: surveyQuestionId,
      answer: answer ?? this.answer,
      isPending: isPending ?? this.isPending,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson({required LocationEncoding destination}) {
    switch (destination) {
      case LocationEncoding.api:
        return {
          'connection_id': connectionId,
          'survey_question_id': surveyQuestionId,
          'answer': answer,
          'is_pending': isPending,
          'updated_at': updatedAt,
        };
      case LocationEncoding.database:
        return {
          ConnectionSurveyAnswerDataInfo.connectionId.columnName: connectionId,
          ConnectionSurveyAnswerDataInfo.surveyQuestionId.columnName: surveyQuestionId,
          ConnectionSurveyAnswerDataInfo.answer.columnName: answer,
          ConnectionSurveyAnswerDataInfo.isPending.columnName: isPending ? 1 : 0,
          ConnectionSurveyAnswerDataInfo.updatedAt.columnName: updatedAt,
        };
    }
  }

  factory ConnectionSurveyAnswerData.fromJson(
    Map<String, dynamic> json, {
    required LocationEncoding source,
  }) {
    final connectionId = source == LocationEncoding.database
        ? json[ConnectionSurveyAnswerDataInfo.connectionId.columnName] as String
        : json['connection_id'] as String;

    final surveyQuestionId = source == LocationEncoding.database
        ? json[ConnectionSurveyAnswerDataInfo.surveyQuestionId.columnName] as String
        : json['survey_question_id'] as String;

    final answer = source == LocationEncoding.database
        ? (json[ConnectionSurveyAnswerDataInfo.answer.columnName] as String? ?? '')
        : (json['answer'] as String? ?? '');

    final isPending = source == LocationEncoding.database
        ? (json[ConnectionSurveyAnswerDataInfo.isPending.columnName] as int? ?? 0) == 1
        : json['is_pending'] == true;

    final updatedAt = source == LocationEncoding.database
        ? (json[ConnectionSurveyAnswerDataInfo.updatedAt.columnName] as String? ?? '')
        : (json['updated_at'] as String? ?? '');

    return ConnectionSurveyAnswerData(
      connectionId: connectionId,
      surveyQuestionId: surveyQuestionId,
      answer: answer,
      isPending: isPending,
      updatedAt: updatedAt,
    );
  }
}

enum ConnectionSurveyAnswerDataInfo {
  connectionId('connection_id', 'connection_id', 'Connection ID', 'TEXT NOT NULL'),
  surveyQuestionId('survey_question_id', 'survey_question_id', 'Survey Question ID', 'TEXT NOT NULL'),
  answer('answer', 'answer', 'Answer', 'TEXT'),
  isPending('is_pending', 'is_pending', 'Is Pending', 'INTEGER NOT NULL DEFAULT 0'),
  updatedAt('updated_at', 'updated_at', 'Updated At', 'TEXT');

  final String columnName;
  final String jsonName;
  final String displayName;
  final String columnType;

  const ConnectionSurveyAnswerDataInfo(
    this.columnName,
    this.jsonName,
    this.displayName,
    this.columnType,
  );

  static List<String> get columnNameValues =>
      ConnectionSurveyAnswerDataInfo.values.map((value) => value.columnName).toList();

  static String get tableName => 'connection_survey_answers';

  static String get tableBuilder =>
      'CREATE TABLE IF NOT EXISTS ${ConnectionSurveyAnswerDataInfo.tableName} ('
      'connection_id TEXT NOT NULL,'
      'survey_question_id TEXT NOT NULL,'
      'answer TEXT,'
      'is_pending INTEGER NOT NULL DEFAULT 0,'
      'updated_at TEXT,'
      'PRIMARY KEY (connection_id, survey_question_id)'
      ')';
}
