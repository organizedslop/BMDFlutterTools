/*
 * Connection Retry Service
 *
 * Created by:  Blake Davis
 * Description: Retries unsynced ConnectionData when network is restored.
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__connection_survey_answer.dart";
import "package:bmd_flutter_tools/data/model/data__user_note.dart";




/* ======================================================================================================================
 * MARK: Connection Retry Service
 * ------------------------------------------------------------------------------------------------------------------ */
class ConnectionSyncSummary {
    final int attempts;
    final int successCount;
    final int incompleteCount;
    final int failureCount;

    const ConnectionSyncSummary({
        required this.attempts,
        required this.successCount,
        required this.incompleteCount,
        required this.failureCount,
    });

    bool get hasChanges => successCount > 0 || incompleteCount > 0;
    bool get hasFailures => failureCount > 0;

    static const ConnectionSyncSummary empty = ConnectionSyncSummary(
      attempts: 0,
      successCount: 0,
      incompleteCount: 0,
      failureCount: 0,
    );
}




class ConnectionRetryService {

    ConnectionRetryService._internal();
    static final ConnectionRetryService instance = ConnectionRetryService._internal();

    static const String pendingConnectionNoteSlug = 'pending-sync';

    final Connectivity _connectivity = Connectivity();
    StreamSubscription<ConnectivityResult>? _subscription;
    Timer? _periodicTimer;
    ConnectivityResult? _lastStatus;
    Future<ConnectionSyncSummary>? _retryInFlight;


    /* -------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    void initialize() {
        if (_subscription != null) {
            // Already listening
            return;
        }
        /*
         *  Listen for when the device regains any network
         */
        _connectivity.checkConnectivity().then((result) {
            _lastStatus = result;
            logPrint("🛜  Initial connectivity: $_lastStatus");
            if (result != ConnectivityResult.none) {
                logPrint("🔄 Checking for pending data after initialization...");
                retryPendingConnections();
            }
        });

        _subscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult status) {
            if (status == _lastStatus) return;

            logPrint("🛜  Connectivity changed: $status");

            if (status != ConnectivityResult.none) {
                retryPendingConnections();
            }

            _lastStatus = status;
        });

        _periodicTimer ??= Timer.periodic(const Duration(minutes: 5), (_) {
            _performPeriodicSync();
        });
    }


    Future<void> _performPeriodicSync() async {
        final currentStatus = await _connectivity.checkConnectivity();
        if (currentStatus != ConnectivityResult.none) {
            logPrint("🔄 Periodic sync check running (status: $currentStatus)");
            await retryPendingConnections();
        }
    }




    /* -------------------------------------------------------------------------------------------------------------
     * MARK: Retry
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<ConnectionSyncSummary> retryPendingConnections() async {

        if (_retryInFlight != null) {
            logPrint("⚠️  retryPendingConnections already running; coalescing call");
            return _retryInFlight!;
        }

        final future = _retryPendingConnectionsInternal();
        _retryInFlight = future;

        try {
            final summary = await future;
            return summary;
        } finally {
            if (_retryInFlight == future) {
                _retryInFlight = null;
            }
        }
    }

    Future<ConnectionSyncSummary> _retryPendingConnectionsInternal() async {

        final unsyncedConnections = await AppDatabase.instance.readConnections(
            where:     "${ConnectionDataInfo.dateSynced.columnName} IS NULL",
            whereArgs: [],
        );
        ConnectionSyncSummary summary = ConnectionSyncSummary.empty;

        if (unsyncedConnections.isNotEmpty) {
            logPrint("🔄 Syncing ${unsyncedConnections.length} pending lead(s): ${unsyncedConnections.map((c) => c.id).join(', ')}");

            int failureCount    = 0;
            int successCount    = 0;
            int incompleteCount = 0;
            final Set<({String showId, String companyId})> refreshedScopes = {};

            for (final unsyncedConnection in unsyncedConnections) {
                if (unsyncedConnection.dateSynced != null && unsyncedConnection.dateSynced!.isNotEmpty) {
                  logPrint("⏭️ Skipping connection ${unsyncedConnection.id}: already marked as synced.");
                  continue;
                }
                try {
                    final double? pendingRating = unsyncedConnection.rating;
                    final badgeId = unsyncedConnection.badgeId?.isNotEmpty == true ? unsyncedConnection.badgeId : null;
                    final legacyBadgeId = unsyncedConnection.legacyBadgeId?.isNotEmpty == true ? unsyncedConnection.legacyBadgeId : null;
                    final idForSync = badgeId ?? legacyBadgeId;
                    logPrint("🔄 Attempting to sync connection ${unsyncedConnection.id} (badge ${idForSync ?? 'unknown'})...");
                    final companyId = unsyncedConnection.companyId;
                    final showId = unsyncedConnection.showId;
                    if (idForSync == null || companyId == null || showId == null) {
                      logPrint("⚠️ Skipping connection ${unsyncedConnection.id}: missing badge/company/show ids.");
                      incompleteCount++;
                      continue;
                    }
                    final syncedConnection = await ApiClient.instance.createConnection(
                        badgeId:   idForSync,
                        companyId: companyId,
                        showId:    showId,
                        persistResponse: false,
                    );
                    if (syncedConnection.isNotEmpty) {
                        final ConnectionData synced = syncedConnection.first!;
                        logPrint("✅ API returned connection ${synced.id} for local ${unsyncedConnection.id}");
                        synced.dateSynced = synced.dateSynced ??
                            DateTime.now().toUtc().toIso8601String();

                        await AppDatabase.instance.write([synced]);
                        logPrint("✅ Stored synced connection ${synced.id} (dateSynced=${synced.dateSynced})");

                        await AppDatabase.instance.delete(
                          tableName: ConnectionDataInfo.tableName,
                          whereAsMap: { ConnectionDataInfo.id.columnName: unsyncedConnection.id },
                        );
                        logPrint("✅ Deleted local pending connection ${unsyncedConnection.id}");

                        final syncedBadgeId = synced.badgeId ?? synced.legacyBadgeId ?? idForSync;
                        final syncedCompanyId = synced.companyId;
                        final syncedShowId = synced.showId;
                        if (syncedBadgeId != null && syncedCompanyId != null && syncedShowId != null) {
                          await AppDatabase.instance.deleteWhere(
                            tableName: ConnectionDataInfo.tableName,
                            where:
                                "${ConnectionDataInfo.badgeId.columnName} = ? AND ${ConnectionDataInfo.companyId.columnName} = ? AND ${ConnectionDataInfo.showId.columnName} = ? AND ${ConnectionDataInfo.dateSynced.columnName} IS NULL",
                            whereArgs: [
                              syncedBadgeId,
                              syncedCompanyId,
                              syncedShowId,
                            ],
                          );
                          logPrint("✅ Removed any remaining pending duplicates for badge=${idForSync}");
                        }

                        successCount++;
                        try {
                          await AppDatabase.instance.updateUserNoteRecipient(
                            fromConnectionId: unsyncedConnection.id,
                            toConnectionId: synced.id,
                          );
                          await AppDatabase.instance.updateSurveyAnswerRecipient(
                            fromConnectionId: unsyncedConnection.id,
                            toConnectionId: synced.id,
                          );
                          logPrint("✅ Migrated notes/survey answers to ${synced.id} from ${unsyncedConnection.id}");
                        } catch (error) {
                          logPrint("❌ Failed to reassign related data to ${synced.id}: $error");
                        }
                        if (pendingRating != null && pendingRating > 0) {
                          final int ratingToSync = pendingRating.round().clamp(1, 5).toInt();
                          try {
                            await ApiClient.instance.rateConnection(
                              connectionId: synced.id,
                              rating: ratingToSync,
                            );
                            logPrint("✅ Restored rating $ratingToSync for connection ${synced.id} after sync.");
                          } catch (error) {
                            logPrint("❌ Failed to restore rating for ${synced.id}: $error");
                          }
                        }
                        refreshedScopes.add((showId: showId, companyId: companyId));
                    }
                    else {
                        logPrint("❌ API returned empty response for pending connection ${unsyncedConnection.id}");
                    }
                } catch (error) {
                    logPrint("❌ : ${error}");
                    failureCount++;
                }
            }

            for (final ({String showId, String companyId}) scope in refreshedScopes) {
              try {
                await ApiClient.instance.getConnections(showId: scope.showId, companyId: scope.companyId);
              } catch (error) {
                logPrint("❌ Failed to refresh connections after syncing: $error");
              }
            }
            mlogPrint([
                "${(failureCount > 0) ? ((successCount == 0) ? "❌" : "") : "✅"} Finished syncing pending data.",
                "   | ${unsyncedConnections.length} attempts",
                "   | ${successCount} successes",
                "   | ${incompleteCount} incomplete",
                "   | ${failureCount} failures",
            ]);
            summary = ConnectionSyncSummary(
              attempts: unsyncedConnections.length,
              successCount: successCount,
              incompleteCount: incompleteCount,
              failureCount: failureCount,
            );

        } else {
            logPrint("✅ No pending leads to sync.");
        }

        await _syncPendingNotes();
        await _syncPendingSurveyAnswers();

        return summary;
    }



    Future<void> _syncPendingNotes() async {
      final pendingNotesRaw = await AppDatabase.instance.read(
        tableName: UserNoteDataInfo.tableName,
        whereAsMap: { UserNoteDataInfo.slug.columnName: pendingConnectionNoteSlug },
      );

      if (pendingNotesRaw is! List<UserNoteData> || pendingNotesRaw.isEmpty) {
        logPrint("✅ No pending notes to sync.");
        return;
      }

      final pendingNotes = pendingNotesRaw as List<UserNoteData>;
      logPrint("🔄 Syncing ${pendingNotes.length} pending note(s)...");

      int noteSuccess = 0;
      int noteFailure = 0;

      for (final pendingNote in pendingNotes) {
        try {
          final syncedNotes = await ApiClient.instance.saveUserNote(
            noteBody: pendingNote.noteBody,
            recipientId: pendingNote.recipientId,
            persistResponse: true,
          );

          if (syncedNotes.isNotEmpty) {
            await AppDatabase.instance.delete(
              tableName: UserNoteDataInfo.tableName,
              whereAsMap: { UserNoteDataInfo.id.columnName: pendingNote.id },
            );
            noteSuccess++;
          } else {
            noteFailure++;
          }
        } catch (error) {
          logPrint("❌ Failed to sync pending note: $error");
          noteFailure++;
        }
      }

      mlogPrint([
        "${noteFailure > 0 ? '❌' : '✅'} Finished syncing pending notes.",
        "| ${pendingNotes.length} attempts",
        "| $noteSuccess successes",
        "| $noteFailure failures",
      ]);
    }

    Future<void> _syncPendingSurveyAnswers() async {
      final pendingAnswers = await AppDatabase.instance.readConnectionSurveyAnswers(
        pendingOnly: true,
      );

      if (pendingAnswers.isEmpty) {
        logPrint("✅ No pending survey answers to sync.");
        return;
      }

      logPrint("🔄 Syncing ${pendingAnswers.length} pending survey answer(s)...");

      int successCount = 0;
      int failureCount = 0;

      for (final pending in pendingAnswers) {
        try {
          if (pending.answer.trim().isEmpty) {
            final updated = pending.copyWith(
              isPending: false,
              updatedAt: DateTime.now().toUtc().toIso8601String(),
            );
            await AppDatabase.instance.write(updated);
            continue;
          }
          await ApiClient.instance.updateSurveyAnswers(
            connectionId: pending.connectionId,
            surveyQuestionId: pending.surveyQuestionId,
            answer: pending.answer,
          );

          final updated = pending.copyWith(
            isPending: false,
            updatedAt: DateTime.now().toUtc().toIso8601String(),
          );
          await AppDatabase.instance.write(updated);
          successCount++;
        } catch (error) {
          failureCount++;
          logPrint("❌ Failed to sync survey answer ${pending.connectionId}/${pending.surveyQuestionId}: $error");
        }
      }

      mlogPrint([
        "${failureCount > 0 ? '❌' : '✅'} Finished syncing pending survey answers.",
        "| ${pendingAnswers.length} attempts",
        "| $successCount successes",
        "| $failureCount failures",
      ]);
    }

    /* -------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    void dispose() {
        _subscription?.cancel();
        _subscription = null;
        _periodicTimer?.cancel();
        _periodicTimer = null;
    }
}
