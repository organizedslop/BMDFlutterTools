import 'dart:convert';

import 'package:bmd_flutter_tools/data/model/enum__location_encoding.dart';

class NotificationData {
  final String id;
  final String type;
  final String title;
  final String body;
  final String actionUrl;
  final Map<String, dynamic>? data;
  final String? readAt;
  final String createdAt;
  final String updatedAt;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.actionUrl,
    this.data,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

 factory NotificationData.fromJson(Map<String, dynamic> json) {
    // Accept both Map (from API) and String (from DB) for `data`
    Map<String, dynamic>? parsedData;
    final rawData = json['data'];
    if (rawData is String && rawData.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) parsedData = Map<String, dynamic>.from(decoded);
      } catch (_) {
        parsedData = null; // bad payload; ignore
      }
    } else if (rawData is Map) {
      parsedData = Map<String, dynamic>.from(rawData);
    } else {
      parsedData = null;
    }

    return NotificationData(
      id:         json['id'] ?? '',
      type:       json['type'] ?? '',
      title:      json['title'] ?? '',
      body:       json['body'] ?? '',
      actionUrl:  json['action_url'] ?? '',
      data:       parsedData,
      readAt:     json['read_at'],              // nullable TEXT in schema
      createdAt:  json['created_at'] ?? '',
      updatedAt:  json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson({ required LocationEncoding destination }) {
    // For DB writes, store `data` as a JSON string; for API, keep it as a Map.
    final dataField = switch (destination) {
      LocationEncoding.database => (data == null ? null : jsonEncode(data)),
      _                         => data,
    };

    return {
      'id':          id,
      'type':        type,
      'title':       title,
      'body':        body,
      'action_url':  actionUrl,
      'data':        dataField,
      'read_at':     readAt,
      'created_at':  createdAt,
      'updated_at':  updatedAt,
    };
  }

  /// Encode as a JSON string
  String encode() => jsonEncode(toJson(destination: LocationEncoding.database));

  /// Decode from a JSON string
  static NotificationData decode(String jsonString) =>
      NotificationData.fromJson(jsonDecode(jsonString));

  /// Equality operator
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          title == other.title &&
          body == other.body &&
          actionUrl == other.actionUrl &&
          data.toString() == other.data.toString() &&
          readAt == other.readAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  /// Hash code
  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      title.hashCode ^
      body.hashCode ^
      actionUrl.hashCode ^
      data.hashCode ^
      readAt.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'NotificationData(id: $id, type: $type, title: $title, body: $body, actionUrl: $actionUrl, readAt: $readAt, createdAt: $createdAt, updatedAt: $updatedAt, data: $data)';
  }
}

/// Optional helper class for extra notification info
/// Enum for NotificationDataInfo with metadata for each field
enum NotificationDataInfo {
    id(
        columnName: "id",
        jsonName: "id",
        displayName: "ID",
        columnType: idType,
    ),
    type(
        columnName: "type",
        jsonName: "type",
        displayName: "Type",
        columnType: textType,
    ),
    title(
        columnName: "title",
        jsonName: "title",
        displayName: "Title",
        columnType: textType,
    ),
    body(
        columnName: "body",
        jsonName: "body",
        displayName: "Body",
        columnType: textType,
    ),
    actionUrl(
        columnName: "action_url",
        jsonName: "action_url",
        displayName: "Action URL",
        columnType: textType,
    ),
    data(
        columnName: "data",
        jsonName: "data",
        displayName: "Data",
        columnType: blobType,
    ),
    readAt(
        columnName: "read_at",
        jsonName: "read_at",
        displayName: "Read At",
        columnType: textType,
    ),
    createdAt(
        columnName: "created_at",
        jsonName: "created_at",
        displayName: "Created At",
        columnType: textType,
    ),
    updatedAt(
        columnName: "updated_at",
        jsonName: "updated_at",
        displayName: "Updated At",
        columnType: textType,
    );
    final String columnName;
    final String jsonName;
    final String displayName;
    final String columnType;

    const NotificationDataInfo({
        required this.columnName,
        required this.jsonName,
        required this.displayName,
        required this.columnType,
    });

    static const String blobType = "BLOB";
    static const String idType = "TEXT PRIMARY KEY";
    static const String intType = "INTEGER";
    static const String textType = "TEXT";

    static List<String> get columnNameValues =>
        NotificationDataInfo.values.map((e) => e.columnName).toList();

    static List<String> get displayNameValues =>
        NotificationDataInfo.values.map((e) => e.displayName).toList();

    static List<String> get jsonNameValues =>
        NotificationDataInfo.values.map((e) => e.jsonName).toList();

    static final Type objectType = NotificationData;
    static const String objectTypeName = "notification";
    static const String tableName = "notifications";

    static String get tableBuilder {

        final columns = NotificationDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}