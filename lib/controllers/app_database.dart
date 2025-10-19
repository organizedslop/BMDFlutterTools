/*
 * App Database
 *
 * Created by:  Blake Davis
 * Description: App's SQLite database
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__company.dart";
import "package:bmd_flutter_tools/data/model/data__company_user.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__connection_survey_answer.dart";
import "package:bmd_flutter_tools/data/model/data__exhibitor.dart";
import "package:bmd_flutter_tools/data/model/data__gform_entry.dart";
import "package:bmd_flutter_tools/data/model/data__gform.dart";
import "package:bmd_flutter_tools/data/model/data__notification.dart";
import "package:bmd_flutter_tools/data/model/data__qr_code.dart";
import "package:bmd_flutter_tools/data/model/data__seminar.dart";
import "package:bmd_flutter_tools/data/model/data__seminar_category.dart";
import "package:bmd_flutter_tools/data/model/data__seminar_session.dart";
import "package:bmd_flutter_tools/data/model/data__seminar_speaker.dart";
import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/data/model/data__survey_question.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/data/model/data__user_note.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:path/path.dart";
import "package:sentry_flutter/sentry_flutter.dart";
import "package:sqflite/sqflite.dart";




/* ======================================================================================================================
 * MARK: App Database
 * ------------------------------------------------------------------------------------------------------------------ */
class AppDatabase {

    // Make this a singleton class
    static final AppDatabase instance = AppDatabase._internal();

    // Use a single reference to the database app-wide
    static Database? _database;

    AppDatabase._internal();

    static const _databaseName    = "buildExpoAppDatabase.db";
    static const _databaseVersion = 1;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Database Getter
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<Database> get database async {
        if (_database != null) {
            return _database!;
        }
        _database = await _initDatabase();
        await _database!.execute(ConnectionSurveyAnswerDataInfo.tableBuilder);
        return _database!;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Schema Changed
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * Determine if the database schema changed since the last launch
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<bool> schemaChanged() async {
        final db = await instance.database;
        final currentSchema = await db.query("sqlite_master");

        // Convert the current schema to a JSON string
        String currentSchemaJson = "[";
        for (var i = 0; i < currentSchema.length; i++) {
            currentSchemaJson += jsonEncode(currentSchema[i]);
            if (i < (currentSchema.length-1)) {
                currentSchemaJson += ",";
            }
        }
        currentSchemaJson += "]";

        final storage = FlutterSecureStorage();
        var oldSchemaJson = await storage.read(key: "app_database_schema");

        if (currentSchemaJson != oldSchemaJson) {
            logPrint("🗄️  Database schema changed.");
            storage.write(
                key:   "app_database_schema",
                value: currentSchemaJson,
                iOptions: IOSOptions(
                    // Update the value if it already exists
                    accessibility:  KeychainAccessibility.first_unlock,
                    synchronizable: false,
                )
            );
            return true;

        } else {
            logPrint("🗄️  Database schema did not change.");
            return false;
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize Database
     *
     * Open the database, or create it, if necessary
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<Database> _initDatabase() async {
        String path = join(await getDatabasesPath(), _databaseName);

        return await openDatabase(
            path,
            version:  _databaseVersion,
            onCreate: _createDatabase,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Create the Tables
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<void> _createDatabase (Database db, int version) async {

        // State Persistence table
        await db.execute("CREATE TABLE IF NOT EXISTS state_data ("  +
            "user_id"       + " " +     "TEXT PRIMARY KEY"          + ", " +
            "data"          + " " +     "BLOB NOT NULL"             + ")"
        );

        // Badges table
        await db.execute(BadgeDataInfo.tableBuilder);

        // Companies table
        await db.execute(CompanyDataInfo.tableBuilder);

        // CompanyUsers table
        await db.execute(CompanyUserDataInfo.tableBuilder);

        // Connections table
        await db.execute(ConnectionDataInfo.tableBuilder);

        // Connection survey answers table
        await db.execute(ConnectionSurveyAnswerDataInfo.tableBuilder);

        // Exhibitors table
        await db.execute(ExhibitorDataInfo.tableBuilder);

        // GForms table
        await db.execute(GFormDataInfo.tableBuilder);

        // GFormEntries table
        await db.execute(GFormEntryDataInfo.tableBuilder);

        // Notifications table
        await db.execute(NotificationDataInfo.tableBuilder);

        // QrCodes table
        await db.execute(QrCodeDataInfo.tableBuilder);

        // SeminarCategories table
        await db.execute(SeminarCategoryDataInfo.tableBuilder);

        // SeminarSessions table
        await db.execute(SeminarSessionDataInfo.tableBuilder);

        // SeminarSpeakers table
        await db.execute(SeminarSpeakerDataInfo.tableBuilder);

        // Seminars table
        await db.execute(SeminarDataInfo.tableBuilder);

        // Shows table
        await db.execute(ShowDataInfo.tableBuilder);

        // SurveyQuestions table
        await db.execute(SurveyQuestionDataInfo.tableBuilder);

        // Users table
        await db.execute(UserDataInfo.tableBuilder);

        // UserNotes table
        await db.execute(UserNoteDataInfo.tableBuilder);
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Close the Database
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<void> closeDatabase() async {
        if (_database != null) {
            await _database!.close();
            _database = null;                 // ← forget the closed instance
        }
    }

    /// Force-open a fresh database instance (used after delete).
    Future<void> reopen() async {
        await database;     // getter handles _database == null
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Delete an Entry
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<int> delete({ required String               tableName,
                                  Map<String, String>? whereAsMap }) async {

        Map<String, dynamic> whereAndArgs = { "where": "", "whereArgs": <String>[] };

        if (whereAsMap != null) {
            for (var key in whereAsMap.keys) {
                whereAndArgs["where"] = whereAndArgs["where"]! + "${key} = ?";
                if (key != whereAsMap.keys.last) { whereAndArgs["where"] = whereAndArgs["where"]! + " AND "; }

                whereAndArgs["whereArgs"].add(whereAsMap[key]!);
            }
        }
        final db = await instance.database;

        logPrint("🗄️  Deleting entry from ${tableName}...");

        return await db.delete(
            tableName,
            where:     whereAndArgs["where"],
            whereArgs: whereAndArgs["whereArgs"],
        );
    }

    /// Delete rows using a raw WHERE string with positional arguments.
    Future<int> deleteWhere({
      required String tableName,
      required String where,
      List<Object?>? whereArgs,
    }) async {
      final db = await instance.database;
      logPrint("🗄️  Deleting from $tableName where: $where");
      return await db.delete(
        tableName,
        where: where,
        whereArgs: whereArgs,
      );
    }

    Future<int> updateUserNoteRecipient({
      required String fromConnectionId,
      required String toConnectionId,
    }) async {
      final db = await instance.database;
      logPrint("🗄️  Reassigning user notes from $fromConnectionId to $toConnectionId...");
      return await db.update(
        UserNoteDataInfo.tableName,
        {UserNoteDataInfo.recipientId.columnName: toConnectionId},
        where: "${UserNoteDataInfo.recipientId.columnName} = ?",
        whereArgs: [fromConnectionId],
      );
    }

    Future<int> updateSurveyAnswerRecipient({
      required String fromConnectionId,
      required String toConnectionId,
    }) async {
      final db = await instance.database;
      logPrint("🗄️  Reassigning survey answers from $fromConnectionId to $toConnectionId...");
      return await db.update(
        ConnectionSurveyAnswerDataInfo.tableName,
        {ConnectionSurveyAnswerDataInfo.connectionId.columnName: toConnectionId},
        where: "${ConnectionSurveyAnswerDataInfo.connectionId.columnName} = ?",
        whereArgs: [fromConnectionId],
      );
    }

    Future<int> deleteSurveyAnswersForConnection({
      required String connectionId,
      bool onlyNonPending = false,
    }) async {
      final db = await instance.database;
      final whereClauses = <String>[
        '${ConnectionSurveyAnswerDataInfo.connectionId.columnName} = ?'
      ];
      final whereArgs = <Object?>[connectionId];

      if (onlyNonPending) {
        whereClauses.add('${ConnectionSurveyAnswerDataInfo.isPending.columnName} = 0');
      }

      return await db.delete(
        ConnectionSurveyAnswerDataInfo.tableName,
        where: whereClauses.join(' AND '),
        whereArgs: whereArgs,
      );
    }

    Future<void> replaceConnectionWithSynced({
      required String localId,
      required ConnectionData synced,
    }) async {
      final db = await instance.database;
      final replacement = synced.toJson(destination: LocationEncoding.database);
      final rows = await db.update(
        ConnectionDataInfo.tableName,
        replacement,
        where: "${ConnectionDataInfo.id.columnName} = ?",
        whereArgs: [localId],
      );

      if (rows == 0) {
        await db.insert(
          ConnectionDataInfo.tableName,
          replacement,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    Future<void> deleteData() async {
        final db = await instance.database;

        final List<String> tables = [
            BadgeDataInfo           .tableName,
            CompanyDataInfo         .tableName,
            ConnectionDataInfo      .tableName,
            ExhibitorDataInfo       .tableName,
            GFormDataInfo           .tableName,
            GFormEntryDataInfo      .tableName,
            NotificationDataInfo    .tableName,
            QrCodeDataInfo          .tableName,
            SeminarDataInfo         .tableName,
            SeminarCategoryDataInfo .tableName,
            SeminarSessionDataInfo  .tableName,
            SeminarSpeakerDataInfo  .tableName,
            ShowDataInfo            .tableName,
            SurveyQuestionDataInfo  .tableName,
            UserDataInfo            .tableName,
            UserNoteDataInfo        .tableName,
        ];

        for (final table in tables) {
            db.delete(table);
        }
    }


    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Delete the Database
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<void> deleteDatabase() async =>
        databaseFactory.deleteDatabase(join(await getDatabasesPath(), _databaseName));




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Clear the State Data Table
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<int> deleteStateData() async {
        logPrint("🗄️  Deleting state data from database...");

        final db = await instance.database;

        // Delete all entries in the table, and return the number of entries deleted
        return await db.delete("state_data");
    }





    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Write to the Database
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<dynamic> write(dynamic data, { String? table }) async {

        // Determine the data type and corresponding table
        String? tableName = table;

        if (tableName == null) {
            if (data is BadgeData || data is List<BadgeData>) {
                tableName = BadgeDataInfo.tableName;

            } else if (data is CompanyData || data is List<CompanyData>) {
                tableName = CompanyDataInfo.tableName;

            } else if (data is CompanyUserData || data is List<CompanyUserData>) {
                tableName = CompanyUserDataInfo.tableName;

            } else if (data is ConnectionData || data is List<ConnectionData>) {
                tableName = ConnectionDataInfo.tableName;

            } else if (data is ConnectionSurveyAnswerData || data is List<ConnectionSurveyAnswerData>) {
                tableName = ConnectionSurveyAnswerDataInfo.tableName;

            } else if (data is ExhibitorData || data is List<ExhibitorData>) {
                tableName = ExhibitorDataInfo.tableName;

            } else if (data is GFormEntryData || data is List<GFormEntryData>) {
                tableName = GFormEntryDataInfo.tableName;

            } else if (data is GFormData || data is List<GFormData>) {
                tableName = GFormDataInfo.tableName;

            } else if (data is NotificationData || data is List<NotificationData>) {
                tableName = NotificationDataInfo.tableName;

            } else if (data is QrCodeData || data is List<QrCodeData>) {
                tableName = QrCodeDataInfo.tableName;

            } else if (data is SeminarData || data is List<SeminarData>) {
                tableName = SeminarDataInfo.tableName;

            } else if (data is SeminarCategoryData || data is List<SeminarCategoryData>) {
                tableName = SeminarCategoryDataInfo.tableName;

            } else if (data is SeminarSessionData || data is List<SeminarSessionData>) {
                tableName = SeminarSessionDataInfo.tableName;

            } else if (data is SeminarSpeakerData || data is List<SeminarSpeakerData>) {
                tableName = SeminarSpeakerDataInfo.tableName;

            } else if (data is ShowData || data is List<ShowData>) {
                tableName = ShowDataInfo.tableName;

            } else if (data is SurveyQuestionData || data is List<SurveyQuestionData>) {
                tableName = SurveyQuestionDataInfo.tableName;

            } else if (data is UserData || data is List<UserData>) {
                tableName = UserDataInfo.tableName;

            } else if (data is UserNoteData || data is List<UserNoteData>) {
                tableName = UserNoteDataInfo.tableName;

            } else {
                throw("❌ Attempted to write an unsupported data type to the database: ${data.runtimeType}.");
            }
        }

        // logPrint("🗄️  Writing to ${tableName}...");

        final db = await instance.database;

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle saving app state data
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
        if (tableName == "state_data") {
            Map<String, dynamic> serializedState = {};

            data["data"].forEach((key, value) {
              serializedState[key] = _encodeStateValue(value);
            });

            final payload = {
              "user_id": data["user_id"],
              "data": json.encode(serializedState),
            };

            final id = await db.insert(
              tableName,
              payload,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            logPrint("🗄️  Wrote state data ${id} to database.");
            return id;

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle saving all other data
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
        } else {

            // Wrap the data if it isn't already a List
            if (data is! List) {
                data = [data];
            }

            List<int> ids = [];
            // logPrint("🗄️  Writing ${data.runtimeType} to database...");

            for (var item in data) {
                /*
                 *  If this is a User, save its Badges, Companies, and CompanyUsers
                 *  Change these if statements to be recursive calls to write()
                 */
                if (item is UserData) {
                    if (item.badges.isNotEmpty) {
                        for (final badge in item.badges) {
                            await db.insert(
                                BadgeDataInfo.tableName,
                                badge.toJson(destination: LocationEncoding.database),
                                conflictAlgorithm: ConflictAlgorithm.replace,
                            );
                        }
                    }
                    if (item.companies.isNotEmpty) {
                        for (final company in item.companies) {
                            await db.insert(
                                CompanyDataInfo.tableName,
                                company.toJson(destination: LocationEncoding.database),
                                conflictAlgorithm: ConflictAlgorithm.replace,
                            );
                        }
                    }
                    if (item.companyUsers.isNotEmpty) {
                        for (final companyUser in item.companyUsers) {
                            await db.insert(
                                CompanyUserDataInfo.tableName,
                                companyUser.toJson(destination: LocationEncoding.database),
                                conflictAlgorithm: ConflictAlgorithm.replace,
                            );
                        }
                    }
                }
                /*
                 *  If this is a SeminarSession, save its Seminar and Presenters/Speakers
                 */
                if (item is SeminarSessionData) {
                    await db.insert(
                        SeminarDataInfo.tableName,
                        item.seminar.toJson(destination: LocationEncoding.database),
                        conflictAlgorithm: ConflictAlgorithm.replace,
                    );
                    if (item.presenters.isNotEmpty) {
                        for (final presenter in item.presenters) {
                            await db.insert(
                                SeminarSpeakerDataInfo.tableName,
                                presenter.toJson(destination: LocationEncoding.database),
                                conflictAlgorithm: ConflictAlgorithm.replace,
                            );
                        }
                    }
                }

                // Handle data that does not have properties to save to other tables
                final id = await db.insert(
                    tableName,
                    item.toJson(destination: LocationEncoding.database),
                    conflictAlgorithm: ConflictAlgorithm.replace
                );

                ids.add(id);

                final identifier = _logIdentifierFor(item, id);
                logPrint("🗄️  Wrote ${item.runtimeType} ${identifier} to database.");
            }
            return ids;
        }
    }

    dynamic _encodeStateValue(dynamic value) {
      if (value == null) return null;
      if (value is num || value is bool || value is String) return value;

      if (value is Map) {
        return Map<String, dynamic>.from(value as Map);
      }

      if (value is Iterable) {
        return value.map(_encodeStateValue).toList();
      }

      try {
        final dynamic encoded = value.toJson(destination: LocationEncoding.database);
        if (encoded is Map || encoded is Iterable) {
          return _encodeStateValue(encoded);
        }
        return encoded;
      } catch (_) {
        try {
          final dynamic encoded = value.toJson();
          if (encoded is Map || encoded is Iterable) {
            return _encodeStateValue(encoded);
          }
          return encoded;
        } catch (_) {
          return value.toString();
        }
      }
    }

    String _logIdentifierFor(dynamic item, int fallback) {
      if (item is ConnectionData) return item.id;
      if (item is UserNoteData) return item.id;
      if (item is BadgeData) return item.id;
      if (item is CompanyData) return item.id;
      if (item is UserData) return item.id;
      return fallback.toString();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Read from the Database
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<dynamic> read({ required String                tableName,
                                    Map<String, String?>? whereAsMap }) async {

        Map<String, dynamic> whereAndArgs = { "where": "", "whereArgs": <String?>[] };

        if (whereAsMap != null) {
            for (var key in whereAsMap.keys) {
                whereAndArgs["where"] = whereAndArgs["where"]! + "${key} = ?";
                if (key != whereAsMap.keys.last) { whereAndArgs["where"] = whereAndArgs["where"]! + " AND ";}

                whereAndArgs["whereArgs"].add(whereAsMap[key]);
            }
        }

        // TODO: Add handling for other tables
        // Determine which table to query
        if (tableName == CompanyDataInfo.tableName) {
            return readCompanies(where: whereAndArgs["where"], whereArgs: whereAndArgs["whereArgs"]);

        } else if (tableName == ExhibitorDataInfo.tableName) {
            return _readExhibitors(where: whereAndArgs["where"], whereArgs: whereAndArgs["whereArgs"]);

        } else if (tableName == CompanyUserDataInfo.tableName) {
            return _readCompanyUsers(where: whereAndArgs["where"], whereArgs: whereAndArgs["whereArgs"]);

        } else if (tableName == ConnectionDataInfo.tableName) {
            return readConnections(where: whereAndArgs["where"], whereArgs: whereAndArgs["whereArgs"]);

        } else if (tableName == ExhibitorDataInfo.tableName) {
            return _readExhibitors(where: whereAndArgs["where"], whereArgs: whereAndArgs["whereArgs"]);

        } else if (tableName == GFormDataInfo.tableName) {
            return readGForms(where: whereAndArgs["where"], whereArgs: whereAndArgs["whereArgs"]);

        } else if (tableName == GFormEntryDataInfo.tableName) {
            return readGFormEntries(where: whereAndArgs["where"], whereArgs: whereAndArgs["whereArgs"]);

        } else if (tableName == NotificationDataInfo.tableName) {
            return _readNotifications(where: whereAndArgs["where"], whereArgs: whereAndArgs["whereArgs"]);

        } else if (tableName == UserNoteDataInfo.tableName) {
            return _readUserNotes(where: whereAndArgs["where"], whereArgs: whereAndArgs["whereArgs"]);

        } else if (tableName == "state_data") {
            final db = await instance.database;

            // Get the data from the database
            final dataAsListOfMaps = await db.query("state_data");

            if (dataAsListOfMaps.isNotEmpty) {
                Map<String, dynamic> dataAsMap = Map.of(dataAsListOfMaps[0]);

                if (dataAsMap["data"] != null) {
                    Map<String, dynamic> dataDecoded = json.decode(dataAsMap["data"]);

                    dataAsMap.update("data", (_) => dataDecoded);
                }
                return dataAsMap;

            // If there is no saved state
            } else {
                return { "user_id": null, "data": { } };
            }
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Internal Use Functions
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read Companies
     *
     * TODO: Make private, phase out direct use
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<CompanyData>> readCompanies({ required String where, required List<String?> whereArgs }) async {
        final db = await instance.database;

        // Get the data from the database
        final dataAsListOfMaps = await db.query(
            CompanyDataInfo.tableName,
            columns:    CompanyDataInfo.columnNameValues,
            where:      where,
            whereArgs:  whereArgs
        );

        // Decode and return the data
        List<CompanyData> companiesAsList = [];

        if (dataAsListOfMaps.isNotEmpty) {
            for (var dataAsMap in dataAsListOfMaps) {
                companiesAsList.add(CompanyData.fromJson(dataAsMap, source: LocationEncoding.database));
            }
        }
        return companiesAsList;
    }






    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read Badges
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<BadgeData>> readBadges({ required String where, required List<String?> whereArgs }) async {
        final db = await instance.database;

        // Get the data from the database
        final dataAsListOfMaps = await db.query(
            BadgeDataInfo.tableName,
            columns:   BadgeDataInfo.columnNameValues,
            where:     where,
            whereArgs: whereArgs,
        );

        // Decode and return the data
        List<BadgeData> badgesAsList = [];

        if (dataAsListOfMaps.isNotEmpty) {
            for (var dataAsMap in dataAsListOfMaps) {
                badgesAsList.add(BadgeData.fromJson(dataAsMap, source: LocationEncoding.database));
            }
        }
        return badgesAsList;
    }





    Future<List<NotificationData>> _readNotifications({ required String where, required List<String?> whereArgs }) async {
        final db = await instance.database;

        // Get the data from the database
        final dataAsListOfMaps = await db.query(
            NotificationDataInfo.tableName,
            columns:    NotificationDataInfo.columnNameValues,
            where:      where,
            whereArgs:  whereArgs
        );

        // Decode and return the data
        List<NotificationData> notificationsAsList = [];

        if (dataAsListOfMaps.isNotEmpty) {
            for (var dataAsMap in dataAsListOfMaps) {
                notificationsAsList.add(NotificationData.fromJson(dataAsMap)); //, source: LocationEncoding.database));
            }
        }
        return notificationsAsList;
    }





    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read CompanyUsers
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<CompanyUserData>> _readCompanyUsers({ required String where, required List<String?> whereArgs }) async {
        final db = await instance.database;

        // Get the data from the database
        final dataAsListOfMaps = await db.query(
            CompanyUserDataInfo.tableName,
            columns:    CompanyUserDataInfo.columnNameValues,
            where:      where,
            whereArgs:  whereArgs
        );

        // Decode and return the data
        List<CompanyUserData> companyUsersAsList = [];

        if (dataAsListOfMaps.isNotEmpty) {
            for (var dataAsMap in dataAsListOfMaps) {
                companyUsersAsList.add(CompanyUserData.fromJson(dataAsMap, source: LocationEncoding.database));
            }
        }
        return companyUsersAsList;
    }




    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read Connections
     *
     * TODO: Make private, phase out direct use
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<ConnectionData>> readConnections({ required String where, required List<String?> whereArgs }) async {
        final db = await instance.database;

        // Get the data from the database
        final dataAsListOfMaps = await db.query(
            ConnectionDataInfo.tableName,
            columns:   ConnectionDataInfo.columnNameValues,
            where:     where,
            whereArgs: whereArgs
        );

        // Decode and return the data
        List<ConnectionData> connectionsAsList = [];

        if (dataAsListOfMaps.isNotEmpty) {
            for (var dataAsMap in dataAsListOfMaps) {
                connectionsAsList.add(ConnectionData.fromJson(dataAsMap, source: LocationEncoding.database));
            }
        }
        return connectionsAsList;
    }

    Future<List<ConnectionSurveyAnswerData>> readConnectionSurveyAnswers({
      String? connectionId,
      bool pendingOnly = false,
    }) async {
      final db = await instance.database;

      final whereClauses = <String>[];
      final whereArgs = <Object?>[];

      if (connectionId != null) {
        whereClauses.add('${ConnectionSurveyAnswerDataInfo.connectionId.columnName} = ?');
        whereArgs.add(connectionId);
      }

      if (pendingOnly) {
        whereClauses.add('${ConnectionSurveyAnswerDataInfo.isPending.columnName} = 1');
      }

      final rows = await db.query(
        ConnectionSurveyAnswerDataInfo.tableName,
        columns: ConnectionSurveyAnswerDataInfo.columnNameValues,
        where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
        whereArgs: whereClauses.isEmpty ? null : whereArgs,
      );

      return rows
          .map((row) => ConnectionSurveyAnswerData.fromJson(
                row,
                source: LocationEncoding.database,
              ))
          .toList();
    }

    Future<List<SurveyQuestionData>> readSurveyQuestions({
      required String where,
      required List<String?> whereArgs,
    }) async {
      final db = await instance.database;

      final rows = await db.query(
        SurveyQuestionDataInfo.tableName,
        columns: SurveyQuestionDataInfo.columnNameValues,
        where: where.isEmpty ? null : where,
        whereArgs: where.isEmpty ? null : whereArgs,
      );

      return rows
          .map((row) => SurveyQuestionData.fromJson(
                row,
                source: LocationEncoding.database,
              ))
          .toList();
    }




    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read GForm Entries
     *
     * TODO: Make private, phase out direct use
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<GFormEntryData>> readGFormEntries({ required String where, required List<String?> whereArgs }) async {
        final db = await instance.database;

        // Get the data from the database
        final dataAsListOfMaps = await db.query(
            GFormEntryDataInfo.tableName,
            columns:   GFormEntryDataInfo.columnNameValues,
            where:     where,
            whereArgs: whereArgs
        );

        // Decode and return the data
        List<GFormEntryData> gformEntriesAsList= [];

        if (dataAsListOfMaps.isNotEmpty) {
            for (var dataAsMap in dataAsListOfMaps) {
                gformEntriesAsList.add(GFormEntryData.fromJson(dataAsMap, source: LocationEncoding.database));
            }
        }
        return gformEntriesAsList;
    }




    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read GForms
     *
     * TODO: Make private, phase out direct use
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<GFormData>> readGForms({ required String where, required List<String?> whereArgs }) async {
        final db = await instance.database;

        // Get the data from the database
        final dataAsListOfMaps = await db.query(
            GFormDataInfo.tableName,
            columns:   GFormDataInfo.columnNameValues,
            where:     where,
            whereArgs: whereArgs
        );

        // Decode and return the data
        List<GFormData> gformsAsList= [];

        if (dataAsListOfMaps.isNotEmpty) {
            for (var dataAsMap in dataAsListOfMaps) {
                gformsAsList.add(GFormData.fromJson(dataAsMap, source: LocationEncoding.database));
            }
        }
        return gformsAsList;
    }




    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read User Notes
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<UserNoteData>> _readUserNotes({ required String where, required List<String?> whereArgs }) async {
        final db = await instance.database;

        // Get the data from the database
        final dataAsListOfMaps = await db.query(
            UserNoteDataInfo.tableName,
            columns:   UserNoteDataInfo.columnNameValues,
            where:     where,
            whereArgs: whereArgs
        );

        // Decode and return the data
        List<UserNoteData> userNotesAsList = [];

        if (dataAsListOfMaps.isNotEmpty) {
            for (var dataAsMap in dataAsListOfMaps) {
                userNotesAsList.add(UserNoteData.fromJson(dataAsMap, source: LocationEncoding.database));
            }
        }
        return userNotesAsList;
    }




    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read Users
     *
     * TODO: Make private, phase out direct use
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<UserData>> readUsers({ required String where, required List<String?> whereArgs }) async {
        final db = await instance.database;

        // Get the data from the database
        final dataAsListOfMaps = await db.query(
            UserDataInfo.tableName,
            columns:   UserDataInfo.columnNameValues,
            where:     where,
            whereArgs: whereArgs
        );

        // Decode and return the data
        List<UserData> usersAsList = [];

        if (dataAsListOfMaps.isNotEmpty) {
            for (var dataAsMap in dataAsListOfMaps) {
                usersAsList.add(UserData.fromJson(dataAsMap, source: LocationEncoding.database));
            }
        }
        return usersAsList;
    }




    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read SeminarSessions by ID
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<SeminarSessionData>> readSeminarSessionsByIds(List<String> ids) async {

        if (ids.isEmpty) {
            return const [];
        }

        final db = await instance.database;

        final placeholders = List.filled(ids.length, '?').join(',');
        final rows = await db.query(
            SeminarSessionDataInfo.tableName,
            columns: SeminarSessionDataInfo.columnNameValues,
            where:  '${SeminarSessionDataInfo.id.columnName} IN ($placeholders)',
            whereArgs: ids,
        );

        return rows
            .map((m) =>
                SeminarSessionData.fromJson(m, source: LocationEncoding.database))
            .toList();
    }




    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read Shows
     *
     * TODO: Make private, phase out direct use
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<ShowData>> readShows({ String? where, List<String?>? whereArgs }) async {
        final db = await instance.database;

        List<dynamic> dataAsListOfMaps = [];

        // Form the query and retrieve the data
        dataAsListOfMaps = await db.query(
            ShowDataInfo.tableName,
            columns:   ShowDataInfo.columnNameValues,
            where:     where,
            whereArgs: whereArgs
        );

        // Decode the data
        List<ShowData> showsAsList = [];


        if (dataAsListOfMaps.isNotEmpty) {
            for (var dataAsMap in dataAsListOfMaps) {
                showsAsList.add(ShowData.fromJson(dataAsMap, source: LocationEncoding.database));
            }
        }

        // Return the decoded data
        return showsAsList;
    }




    // TODO: Deprecated, phase out use
    Future<UserData?> getUser({ String? username,
                                String? userId   }) async {

        if ((username == null || username == "") && (userId == null || userId == "")) {
            logPrint("❌ No user ID or username provided.");
            return null;
        }

        final db   = await instance.database;
        dynamic maps;

        if (userId != null && userId != "") {
            maps = await db.query(
                UserDataInfo.tableName,
                columns:   UserDataInfo.columnNameValues,
                where:     "${UserDataInfo.id.columnName } = ?",
                whereArgs: [userId],
            );

        } else if (username != null && username != "") {
            maps = await db.query(
                UserDataInfo.tableName,
                columns:   UserDataInfo.columnNameValues,
                where:     "${UserDataInfo.username.columnName } = ?",
                whereArgs: [username],
            );
        }

        if (maps.isNotEmpty) {
            return UserData.fromJson(maps.first, source: LocationEncoding.database);

        } else {
            logPrint("⚠️  User with username \"${username}\" not found.");
            return null;
        }
    }




    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Read Exhibitors
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    Future<List<ExhibitorData>> _readExhibitors({ required String where, required List<String?> whereArgs }) async {
      final db   = await instance.database;

      // Query all columns; ExhibitorData.fromJson handles DB decoding
      final dataAsListOfMaps = await db.query(
        ExhibitorDataInfo.tableName,
        where: where.isEmpty ? null : where,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
      );

      final exhibitors = <ExhibitorData>[];
      if (dataAsListOfMaps.isNotEmpty) {
        for (final row in dataAsListOfMaps) {
          try {
            exhibitors.add(ExhibitorData.fromJson(row, source: LocationEncoding.database));
          } catch (error, stackTrace) {
            logPrint('❌ Failed to decode ExhibitorData row: $error');
                await Sentry.captureException(error, stackTrace: stackTrace);
          }
        }
      }
      return exhibitors;
    }
}
