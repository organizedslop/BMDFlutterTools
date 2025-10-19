/*
 * Connection Info
 *
 * Created by:  Blake Davis
 * Description: A widget which displays a connection's info
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "dart:io";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__connection_survey_answer.dart";
import "package:bmd_flutter_tools/data/model/data__survey_answer.dart";
import "package:bmd_flutter_tools/data/model/data__survey_question.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/data/model/data__user_note.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/components/component__button_plain.dart";
import "package:bmd_flutter_tools/widgets/components/component__foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/panels/panel__user_note.dart";
import "package:bmd_flutter_tools/widgets/navigation/navigation_bar__primary.dart";
import "package:bmd_flutter_tools/widgets/navigation/navigation_bar__bottom.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";
import "package:url_launcher/url_launcher.dart";
import "package:uuid/uuid.dart";
import "package:dio/dio.dart";
import "package:bmd_flutter_tools/services/connection_retry_service.dart";




/* ======================================================================================================================
 * MARK: Connection Info
 * ------------------------------------------------------------------------------------------------------------------ */
class ConnectionInfo extends ConsumerStatefulWidget {

    final ConnectionData? connection;

    static const Key rootKey = Key("connection_info__root");

    final String title;


    ConnectionInfo({ super.key,
          required this.title,
                   this.connection
    });


    @override
    ConsumerState<ConnectionInfo> createState() => _ConnectionInfoState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _ConnectionInfoState extends ConsumerState<ConnectionInfo> {

    AppDatabase appDatabase = AppDatabase.instance;

    bool refresh                 = false,
         _loadingApi             = false,
         isFetchingFromDatabase  = false,
         isSubmittingNewUserNote = false,
         _loadingQualifyingQuestions = false,
         _qualifyingQuestionsLoaded  = false;

    bool _scannedByLoading = false;

    ConnectionData? _connection;

    UserData? _scannedByUser;

    final FlutterSecureStorage storage = FlutterSecureStorage();

    final _focusNode = FocusNode();

    final TextEditingController newUserNoteController = TextEditingController();

    // Controllers and FocusNodes for qualifying questions
    List<FocusNode> _qualifyingFocusNodes = [];
    List<TextEditingController> _qualifyingControllers = [];

    List<UserNoteData> _comments = [];
    Map<String, ConnectionSurveyAnswerData> _cachedSurveyAnswers = {};

    final ScrollController _scrollController = ScrollController();




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        showSystemUiOverlays();

        if (widget.connection != null) {
          // Initialize local connection state for immediate rendering
          _connection = widget.connection;

          unawaited(_resolveScannedByUser(userId: widget.connection?.userId));

          _loadComments();

          // Load connection record and qualifying questions in parallel (does not block the top summary UI)
          _loadConnection();
        }
        // Rebuild when note text changes to update button state
        newUserNoteController.addListener(() {
          if (!mounted) { return; }
          setState(() {});
        });
    }


    Future<void> _loadConnection() async {
        try {
        if (mounted) {
          setState(() {
            _loadingQualifyingQuestions = true;
            _qualifyingQuestionsLoaded = false;
          });
        }
        final conn = widget.connection!;

        await _resolveScannedByUser(userId: conn.userId);

        // DB-first connection (pick up any local edits)
        final localList = await ApiClient.instance.appDatabase.readConnections(
            where: "${ConnectionDataInfo.id.columnName} = ?",
            whereArgs: [conn.id],
        );
        ConnectionData updated = localList.isNotEmpty ? localList.first : conn;

        if (localList.isEmpty) {
          try {
            final badgeId = conn.badgeId;
            final companyId = conn.companyId;
            final showId = conn.showId;
            if (badgeId != null && companyId != null && showId != null) {
              final possibleMatches = await appDatabase.readConnections(
                where:
                    "${ConnectionDataInfo.badgeId.columnName} = ? AND ${ConnectionDataInfo.companyId.columnName} = ? AND ${ConnectionDataInfo.showId.columnName} = ?",
                whereArgs: [badgeId, companyId, showId],
              );

              if (possibleMatches.isNotEmpty) {
                final syncedMatch = possibleMatches.firstWhere(
                  (candidate) => candidate.dateSynced != null,
                  orElse: () => possibleMatches.first,
                );
                updated = syncedMatch;
              }
            }
          } catch (error) {
            logPrint("❌ Failed to locate synced connection record: $error");
          }
        }

        await _resolveScannedByUser(userId: updated.userId);

        final exhibitorId = ref.read(companyProvider)?.exhibitorId;
        const timeoutDuration = Duration(seconds: 6);

        Future<List<SurveyQuestionData>> loadSurveyQuestions() async {
          Future<List<SurveyQuestionData>> fetchFromProvider({
            required bool forceRefresh,
          }) async {
            if (exhibitorId == null) {
              return <SurveyQuestionData>[];
            }

            try {
              final future = forceRefresh
                  ? ref.refresh(exhibitorSurveyQuestionsProvider.future)
                  : ref.read(exhibitorSurveyQuestionsProvider.future);

              final questions = await future.timeout(timeoutDuration);
              if (questions.isNotEmpty) {
                await appDatabase.write(questions);
              }
              return questions;
            } on TimeoutException catch (error) {
              logPrint("⌛️ Timed out fetching survey questions: $error");
            } catch (error) {
              logPrint("❌ Failed to fetch survey questions from API: $error");
            }

            return <SurveyQuestionData>[];
          }

          List<SurveyQuestionData> questions =
              await fetchFromProvider(forceRefresh: true);

          if (questions.isEmpty) {
            questions = await fetchFromProvider(forceRefresh: false);
          }

          if (questions.isEmpty && exhibitorId != null) {
            try {
              questions = await appDatabase.readSurveyQuestions(
                where: "${SurveyQuestionDataInfo.exhibitorId.columnName} = ?",
                whereArgs: [exhibitorId],
              );
            } catch (error) {
              logPrint("❌ Failed to read cached survey questions: $error");
            }
          }

          return questions;
        }

        final surveyQuestions = await loadSurveyQuestions();
        final Map<String, SurveyQuestionData> questionById = {
          for (final question in surveyQuestions) question.id: question,
        };

        List<SurveyAnswerData> connectionQualifyingQuestions = [];
        bool fetchedFromApi = false;
        try {
          connectionQualifyingQuestions = await ApiClient.instance
              .getSurveyQuestionsWithAnswers(connectionId: updated.id)
              .timeout(timeoutDuration);
          fetchedFromApi = connectionQualifyingQuestions.isNotEmpty;

          final nowIso = DateTime.now().toUtc().toIso8601String();
          await appDatabase.deleteSurveyAnswersForConnection(
            connectionId: updated.id,
            onlyNonPending: true,
          );
          if (connectionQualifyingQuestions.isNotEmpty) {
            final rows = connectionQualifyingQuestions.map(
              (answer) => ConnectionSurveyAnswerData(
                connectionId: updated.id,
                surveyQuestionId: answer.surveyQuestionId,
                answer: answer.existingAnswer ?? '',
                isPending: false,
                updatedAt: nowIso,
              ),
            );
            await appDatabase.write(rows.toList());
          }
        } on TimeoutException catch (error) {
          logPrint("⌛️ Timed out fetching survey answers: $error");
        } catch (error) {
          logPrint("❌ Failed to load survey answers from API: $error");
        }

        if (!fetchedFromApi) {
          try {
            final cachedAnswers = await appDatabase.readConnectionSurveyAnswers(
              connectionId: updated.id,
            );
            if (cachedAnswers.isNotEmpty) {
              connectionQualifyingQuestions = cachedAnswers.map((cached) {
                final question = questionById[cached.surveyQuestionId];
                return SurveyAnswerData(
                  id: cached.surveyQuestionId,
                  exhibitorId: question?.exhibitorId ?? (exhibitorId ?? ''),
                  existingAnswer: cached.answer.isEmpty ? null : cached.answer,
                  question: question?.question ?? '',
                  surveyQuestionId: cached.surveyQuestionId,
                );
              }).toList();
            }
          } catch (error) {
            logPrint("❌ Failed to read cached survey answers: $error");
          }
        }

        final Map<String, SurveyAnswerData> answerByQuestion = {
          for (final answer in connectionQualifyingQuestions)
            answer.surveyQuestionId: answer,
        };

        final cachedAnswerRows = await appDatabase.readConnectionSurveyAnswers(
          connectionId: updated.id,
        );
        for (final cached in cachedAnswerRows) {
          final question = questionById[cached.surveyQuestionId];
          answerByQuestion[cached.surveyQuestionId] = SurveyAnswerData(
            id: cached.surveyQuestionId,
            exhibitorId: question?.exhibitorId ?? (exhibitorId ?? ''),
            existingAnswer: cached.answer.isEmpty ? null : cached.answer,
            question: question?.question ?? '',
            surveyQuestionId: cached.surveyQuestionId,
          );
        }

        for (final question in surveyQuestions) {
          answerByQuestion.putIfAbsent(
            question.id,
            () => SurveyAnswerData(
              id: question.id,
              exhibitorId: question.exhibitorId,
              existingAnswer: null,
              question: question.question,
              surveyQuestionId: question.id,
            ),
          );
        }

        connectionQualifyingQuestions = answerByQuestion.values.toList()
          ..sort((a, b) => (questionById[a.surveyQuestionId]?.order ?? 0)
              .compareTo(questionById[b.surveyQuestionId]?.order ?? 0));

        _cachedSurveyAnswers = {
          for (final row in cachedAnswerRows) row.surveyQuestionId: row,
        };

        // Add the SurveyAnswers to the Connection
        updated.qualifyingQuestions = connectionQualifyingQuestions;

        if (!mounted) return;
        setState(() {
            _connection = updated;
            // Initialize controllers/focus nodes directly from connection’s qualifyingQuestions
            _qualifyingControllers = (updated.qualifyingQuestions)
                .map((q) => TextEditingController(text: q.existingAnswer ?? ""))
                .toList();
            _qualifyingFocusNodes = List.generate(
            _qualifyingControllers.length,
            (_) => FocusNode(),
            );
            for (var i = 0; i < _qualifyingFocusNodes.length; i++) {
            _qualifyingFocusNodes[i].addListener(() async {
                if (!_qualifyingFocusNodes[i].hasFocus) {
                final q = updated.qualifyingQuestions[i];
                final answer = _qualifyingControllers[i].text;
                await _saveSurveyAnswerLocally(
                  connectionId: updated.id,
                  questionId: q.surveyQuestionId,
                  answer: answer,
                );
                debugPrint('Cached answer for ${q.id}: $answer');
                }
            });
            }
        });
        if (mounted) {
          setState(() {
            _loadingQualifyingQuestions = false;
            _qualifyingQuestionsLoaded = true;
          });
        }
        } catch (e) {
        debugPrint("ConnectionInfo: _loadConnection failed → $e");
        if (mounted) {
          setState(() {
            _loadingQualifyingQuestions = false;
            _qualifyingQuestionsLoaded = true;
          });
        }
        }
    }



    Future<List<UserNoteData>> getCommentsForConnection(String connectionId) async {
        final commentsFromDatabase = await appDatabase.read(
            tableName:  UserNoteDataInfo.tableName,
            whereAsMap: { UserNoteDataInfo.recipientId.columnName: connectionId }
        );
        return commentsFromDatabase;
    }

    Future<void> _loadComments() async {
      final conn = widget.connection;
      if (conn == null) return;
      final connectionId = _connection?.id ?? conn.id;

      setState(() {
        isFetchingFromDatabase = true;
        _loadingApi = false;
      });

      try {
        final localComments = await getCommentsForConnection(connectionId);
        if (!mounted) return;

        setState(() {
          _comments = localComments;
          isFetchingFromDatabase = false;
          _loadingApi = true;
        });

        try {
          final commentsFromApi = await ApiClient.instance
              .getUserNotes(recipientId: connectionId)
              .timeout(const Duration(seconds: 6));

          final seenIds = <String>{};
          final merged = <UserNoteData>[];

          for (final comment in localComments) {
            if (seenIds.add(comment.id)) {
              merged.add(comment);
            }
          }
          for (final comment in commentsFromApi) {
            if (seenIds.add(comment.id)) {
              merged.add(comment);
            }
          }

          if (!mounted) return;
          setState(() {
            _comments = merged;
          });
        } on TimeoutException catch (error) {
          logPrint("⌛️Timed out while loading notes: $error");
        } catch (error) {
          logPrint("❌ Failed to load notes from API: $error");
        }
      } finally {
        if (mounted) {
          setState(() {
            _loadingApi = false;
            isFetchingFromDatabase = false;
          });
        }
      }
    }

    Widget _buildUnsyncedBadge(BuildContext context) {
      final theme = Theme.of(context);
      return Material(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SFIcon(
                SFIcons.sf_icloud_slash,
                color: BeColorSwatch.orange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(width: 8),
              Text(
                'Waiting for network…',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: BeColorSwatch.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Future<UserNoteData?> _saveNoteLocally(String noteBody, {bool showOfflineMessage = true}) async {
      final connection = widget.connection;
      if (connection == null) {
        return null;
      }

      final userId = ref.read(userProvider)?.id ?? 'local';
      final pendingNote = UserNoteData(
        id: const Uuid().v4(),
        createdBy: userId,
        dateCreated: DateTime.now().toUtc().toIso8601String(),
        noteBody: noteBody,
        recipientId: connection.id,
        slug: ConnectionRetryService.pendingConnectionNoteSlug,
      );

      await appDatabase.write(pendingNote);

      if (mounted) {
        setState(() {
          _comments.insert(0, pendingNote);
        });
      }

      newUserNoteController.clear();

      if (showOfflineMessage) {
        _showOfflineNoteSnack();
      }

      return pendingNote;
    }

    void _showOfflineNoteSnack() {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Note saved offline. It will sync once you reconnect.'),
        ),
      );
    }

    Future<void> _syncNoteWithServer({
      required UserNoteData pendingNote,
      required String noteBody,
    }) async {
      final connection = widget.connection;
      if (connection == null) {
        return;
      }

      try {
        final savedNotes = await ApiClient.instance.saveUserNote(
          noteBody: noteBody,
          recipientId: connection.id,
        );

        if (savedNotes.isEmpty) {
          _showOfflineNoteSnack();
          return;
        }

        final savedNote = savedNotes.first;

        await appDatabase.deleteWhere(
          tableName: UserNoteDataInfo.tableName,
          where: '${UserNoteDataInfo.id.columnName} = ?',
          whereArgs: [pendingNote.id],
        );
        await appDatabase.write(savedNote);

        if (!mounted) return;

        setState(() {
          final index = _comments.indexWhere((note) => note.id == pendingNote.id);
          if (index != -1) {
            _comments[index] = savedNote;
          } else {
            _comments.insert(0, savedNote);
          }
        });
      } on DioException catch (error) {
        logPrint("❌ Failed to save note online: $error");
        _showOfflineNoteSnack();
      } catch (error) {
        logPrint("❌ Unexpected error while saving note: $error");
        _showOfflineNoteSnack();
      }
    }

    Future<ConnectionSurveyAnswerData?> _saveSurveyAnswerLocally({
      required String connectionId,
      required String questionId,
      required String answer,
    }) async {
      final record = ConnectionSurveyAnswerData(
        connectionId: connectionId,
        surveyQuestionId: questionId,
        answer: answer,
        isPending: true,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      await appDatabase.write(record);

      if (mounted) {
        setState(() {
          _cachedSurveyAnswers[questionId] = record;
          final index = _connection?.qualifyingQuestions
                  .indexWhere((element) => element.surveyQuestionId == questionId) ??
              -1;
          if (index != -1 && _connection != null) {
            _connection!.qualifyingQuestions[index].existingAnswer =
                answer.isEmpty ? null : answer;
          }
        });
      }

      if (_connection?.dateSynced != null) {
        unawaited(_syncSurveyAnswer(record));
      }

      return record;
    }

    Future<void> _syncSurveyAnswer(ConnectionSurveyAnswerData record) async {
      try {
        await ApiClient.instance.updateSurveyAnswers(
          connectionId: record.connectionId,
          surveyQuestionId: record.surveyQuestionId,
          answer: record.answer,
        );

        final updated = record.copyWith(
          isPending: false,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );

        await appDatabase.write(updated);

        if (mounted) {
          setState(() {
            _cachedSurveyAnswers[record.surveyQuestionId] = updated;
            final index = _connection?.qualifyingQuestions
                    .indexWhere((element) =>
                        element.surveyQuestionId == record.surveyQuestionId) ??
                -1;
            if (index != -1 && _connection != null) {
              _connection!.qualifyingQuestions[index].existingAnswer =
                  updated.answer.isEmpty ? null : updated.answer;
            }
          });
        }
      } on DioException catch (error) {
        logPrint("❌ Failed to sync survey answer: $error");
      } catch (error) {
        logPrint("❌ Unexpected error while syncing survey answer: $error");
      }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    dispose() {
        for (final ctrl in _qualifyingControllers) {
            ctrl.dispose();
        }
        for (final node in _qualifyingFocusNodes) {
            node.dispose();
        }
        _scrollController.dispose();
        super.dispose();
    }


    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Get the User Who Scanned the Lead
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    String _formatUserDisplayName(UserData user) {
        final prefix = user.name.prefix.trim();
        final first = user.name.first.trim();
        final middle = user.name.middle.trim();
        final last = user.name.last.trim();
        final suffix = user.name.suffix.trim();

        final List<String> parts = [];
        if (prefix.isNotEmpty) { parts.add(prefix); }
        if (first.isNotEmpty) { parts.add(first); }
        if (middle.isNotEmpty) { parts.add(middle); }
        if (last.isNotEmpty) { parts.add(last); }

        var name = parts.join(" ");
        if (suffix.isNotEmpty) {
            name = name.isEmpty ? suffix : "$name $suffix";
        }

        if (name.isEmpty) {
            if (user.username.isNotEmpty) {
                return user.username;
            }
            return user.id;
        }

        return name;
    }

    Future<UserData?> _getScannerFromDatabase(String userId) async {
        try {
            final users = await appDatabase.readUsers(
              where: "${UserDataInfo.id.columnName} = ?",
              whereArgs: [userId],
            );
            return users.isNotEmpty ? users.first : null;
        } catch (error) {
            logPrint("❌ Failed to read scanner from database: $error");
            return null;
        }
    }

    Future<UserData?> _getScannerFromApi(String userId) async {
        try {
            final user = await ApiClient.instance.getUser(id: userId);
            if (user != null) {
                await appDatabase.write(user);
            }
            return user;
        } catch (error) {
            logPrint("❌ Failed to fetch scanner from API: $error");
            return null;
        }
    }

    Future<void> _resolveScannedByUser({ String? userId }) async {
        final String? targetId = userId ?? _connection?.userId ?? widget.connection?.userId;
        if (targetId == null || targetId.isEmpty) {
            return;
        }

        if (_scannedByUser != null && _scannedByUser!.id == targetId) {
            return;
        }

        if (mounted) {
            setState(() {
                _scannedByLoading = true;
            });
        }

        UserData? user;

        user = await _getScannerFromDatabase(targetId);

        user ??= await _getScannerFromApi(targetId);

        if (!mounted) {
            return;
        }

        setState(() {
            _scannedByUser = user;
            _scannedByLoading = false;
        });
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Get the User Notes
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<List<UserNoteData>> getUserNotesFromDatabase() async {

        List<UserNoteData> userNotes = [];

        logPrint("🗄️  Getting user notes from database...");

        // if (widget.user != null) {
        //     userNotes = await appDatabase.read(tableName: UserNoteDataInfo.tableName, whereAsMap: { UserNoteDataInfo.recipientId.columnName: widget.user!.id.toString() });
        //     return userNotes;
        // }
        return [];
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Get the User Notes
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<List<UserNoteData>> getUserNotesFromApi() async {

        List<UserNoteData> userNotes = [];

        logPrint("🔄 Getting user notes from API...");

        if (widget.connection != null) {
            userNotes = await ApiClient.instance.getUserNotes(recipientId: widget.connection?.id);
        }

        return userNotes;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);


        return WillPopScope(
            key:       ConnectionInfo.rootKey,
            onWillPop: () async {
                // Signal to refresh the list when popping
                context.pop<bool>(true);
                return false; // we've handled the pop
            },
            child: Scaffold(
                appBar:               PrimaryNavigationBar(title: widget.title, subtitle: ref.read(showProvider)?.title),
                bottomNavigationBar:  QuickNavigationBar(),
                floatingActionButton: (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false) ? FloatingScannerButton() : null,
                /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                 * MARK: Widget Body
                 * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
                body: RefreshIndicator.adaptive(
                    onRefresh: () async {
                        await Future.wait([
                          _loadConnection(),
                          _loadComments(),
                        ]);
                    },
                    child: Container(
                        color: beColorScheme.background.tertiary,
                        child: (() {
                            final connection = _connection ?? widget.connection;
                            final bool isUnsynced = (connection?.dateSynced == null);

                            final Map<String, dynamic> profileData = {};

                            // Address
                            profileData["address"] = (connection?.dateSynced != null) ? (connection?.badgeUserAddress.toString() ?? "No address") : "Pending sync";

                            // Company name
                            profileData["companyName"] = (connection?.dateSynced != null) ? (connection?.badgeCompanyName ?? "No company") : "Pending sync";

                            // Company categories
                            profileData["companyCategories"] = (connection?.dateSynced != null) ? (connection?.badgeCompanyCategories ?? ["No category"]).join(", ") : "Pending sync";

                            // Email address
                            profileData["email"] = (connection?.dateSynced != null) ? (connection?.badgeUserEmail ?? "No email") : "Pending sync";

                            // Job title
                            profileData["jobTitle"] = (connection?.dateSynced != null) ? (connection?.badgeUserJobTitle ?? "No job title") : "Pending sync";

                            // Name
                            profileData["name"] = (connection?.dateSynced != null) ? (connection?.badgeUserName ?? "No name") : "Pending sync";

                            // Phone
                            profileData["phone"] = (connection?.dateSynced != null) ? (connection?.badgeUserPhone ?? "No phone") : "Pending sync";


                            return SingleChildScrollView(
                                controller: _scrollController,
                                physics:    const AlwaysScrollableScrollPhysics(),
                                padding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child:      Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        /*
                                         *  Heading
                                         */
                                        Center(
                                            child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: <Widget>[
                                                    /*
                                                     *  Profile picture
                                                     */
                                                    Padding(
                                                        padding: EdgeInsets.only(right: 16),
                                                        child: SizedBox(
                                                            height: 86,
                                                            width:  86,
                                                            child: ClipOval(
                                                                child: Image.network(
                                                                    "", // Uri.parse(user?.profilePicture ?? "").toString(),
                                                                    fit:    BoxFit.cover,
                                                                    errorBuilder: (context, exception, stackTrace) =>
                                                                        Image.asset(
                                                                            "assets/images/placeholder--user-profile-picture.png",
                                                                            fit: BoxFit.cover,
                                                                        ),
                                                                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                                                        return child;
                                                                    },
                                                                    loadingBuilder: (context, child, loadingProgress) {
                                                                        return (loadingProgress == null) ? child : Center(child: CircularProgressIndicator());
                                                                    },
                                                                ),
                                                            ),
                                                        ),
                                                    ),

                                                    Flexible(
                                                        fit: FlexFit.loose,
                                                        child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: () {
                                                                var output = <Widget>[
                                                                    Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                            /*
                                                                             *  Name
                                                                             */
                                                                            SelectableText(
                                                                                profileData["name"],
                                                                                style: beTextTheme.headingPrimary,
                                                                            ),
                                                                        ],
                                                                    ),
                                                                ];
                                                                /*
                                                                 *  Job title and company
                                                                 */
                                                                if (isUnsynced) {
                                                                    output.add(_buildUnsyncedBadge(context));
                                                                } else if (profileData["jobTitle"].isNotEmpty || profileData["companyName"].isNotEmpty) {
                                                                    output.add(
                                                                        SelectableText(
                                                                            "${profileData["jobTitle"]}${((profileData["jobTitle"].isNotEmpty && profileData["companyName"].isNotEmpty) ? " at " : "")}${profileData["companyName"]}",
                                                                            style:     beTextTheme.bodyPrimary,
                                                                            textAlign: TextAlign.left,
                                                                        ),
                                                                    );
                                                                }
                                                                /*
                                                                 *  Company categories
                                                                 */
                                                                if (!isUnsynced && profileData["companyCategories"].isNotEmpty) {
                                                                    output.addAll([
                                                                        SelectableText(
                                                                            profileData["companyCategories"],
                                                                            style:     beTextTheme.bodyPrimary.copyWith(color: BeColorSwatch.darkGray),
                                                                            textAlign: TextAlign.left,
                                                                        ),
                                                                    ]);
                                                                }
                                                                /*
                                                                 *  Connection rating
                                                                 *
                                                                 *  TODO: This can surely be optimized - this was written by the robots and uses lots of duplicate code
                                                                 */
                                                                final rating = connection?.rating ?? 0;
                                                                output.addAll([
                                                                    const SizedBox(height: 6),
                                                                    GestureDetector(
                                                                   onPanDown: (details) async {
                                                                       final box       = context.findRenderObject() as RenderBox;
                                                                       final localDx   = details.localPosition.dx;
                                                                       final starWidth = box.size.width / 5;
                                                                       final index     = (localDx / starWidth).floor().clamp(0, 4);
                                                                       final newRating = index + 1;

                                                                       if (!mounted) { return; }
                                                                       setState(() {
                                                                           _connection!.rating = newRating.toDouble();
                                                                       });
                                                                       await appDatabase.write([_connection!]);
                                                                        ApiClient.instance.rateConnection(connectionId: widget.connection!.id, rating: newRating);
                                                                   },
                                                                   onPanUpdate: (details) async {
                                                                       final box       = context.findRenderObject() as RenderBox;
                                                                       final localDx   = details.localPosition.dx;
                                                                       final starWidth = box.size.width / 5;
                                                                       final index     = (localDx / starWidth).floor().clamp(0, 4);
                                                                       final newRating = index + 1;

                                                                       if (!mounted) { return; }
                                                                       setState(() {
                                                                           _connection!.rating = newRating.toDouble();
                                                                       });
                                                                       await appDatabase.write([_connection!]);
                                                                       ApiClient.instance.rateConnection(connectionId: widget.connection!.id, rating: newRating);
                                                                   },
                                                                    child: Row(
                                                                        spacing: 8,
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                        GestureDetector(
                                                                            onTap: () async {
                                                                                final newRating = 1;

                                                                                if (!mounted) { return; }
                                                                                setState(() {
                                                                                    _connection!.rating = newRating.toDouble();
                                                                                });
                                                                                await appDatabase.write([_connection!]);
                                                                                ApiClient.instance.rateConnection(connectionId: widget.connection!.id, rating: newRating);
                                                                            },
                                                                            child: SFIcon(
                                                                                rating >= 1 ? SFIcons.sf_star_fill : SFIcons.sf_star,
                                                                                color: BeColorSwatch.blue,
                                                                                fontSize: 20,
                                                                            ),
                                                                        ),
                                                                        GestureDetector(
                                                                            onTap: () async {
                                                                                final newRating = 2;

                                                                                if (!mounted) { return; }
                                                                                setState(() {
                                                                                    _connection!.rating = newRating.toDouble();
                                                                                });
                                                                                await appDatabase.write([_connection!]);
                                                                                ApiClient.instance.rateConnection(connectionId: widget.connection!.id, rating: newRating);
                                                                            },
                                                                            child: SFIcon(
                                                                                rating >= 2 ? SFIcons.sf_star_fill : SFIcons.sf_star,
                                                                                color: BeColorSwatch.blue,
                                                                                fontSize: 20,
                                                                            ),
                                                                        ),
                                                                        GestureDetector(
                                                                            onTap: () async {
                                                                                final newRating = 3;

                                                                                if (!mounted) { return; }
                                                                                setState(() {
                                                                                    _connection!.rating = newRating.toDouble();
                                                                                });
                                                                                await appDatabase.write([_connection!]);
                                                                                ApiClient.instance.rateConnection(connectionId: widget.connection!.id, rating: newRating);
                                                                            },
                                                                            child: SFIcon(
                                                                                rating >= 3 ? SFIcons.sf_star_fill : SFIcons.sf_star,
                                                                                color: BeColorSwatch.blue,
                                                                                fontSize: 20,
                                                                            ),
                                                                        ),
                                                                        GestureDetector(
                                                                            onTap: () async {
                                                                                final newRating = 4;

                                                                                if (!mounted) { return; }
                                                                                setState(() {
                                                                                    _connection!.rating = newRating.toDouble();
                                                                                });
                                                                                await appDatabase.write([_connection!]);
                                                                                ApiClient.instance.rateConnection(connectionId: widget.connection!.id, rating: newRating);
                                                                            },
                                                                            child: SFIcon(
                                                                                rating >= 4 ? SFIcons.sf_star_fill : SFIcons.sf_star,
                                                                                color: BeColorSwatch.blue,
                                                                                fontSize: 20,
                                                                            ),
                                                                        ),
                                                                        GestureDetector(
                                                                            onTap: () async {
                                                                                final newRating = 5;

                                                                                if (!mounted) { return; }
                                                                                setState(() {
                                                                                    _connection!.rating = newRating.toDouble();
                                                                                });
                                                                                await appDatabase.write([_connection!]);
                                                                                ApiClient.instance.rateConnection(connectionId: widget.connection!.id, rating: newRating);
                                                                            },
                                                                            child: SFIcon(
                                                                                rating >= 5 ? SFIcons.sf_star_fill : SFIcons.sf_star,
                                                                                color: BeColorSwatch.blue,
                                                                                fontSize: 20,
                                                                            ),
                                                                        ),
                                                                        ],
                                                                    ),
                                                                    ),
                                                                ]);

                                                                return output;
                                                            }(),
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ),


                                        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                         * MARK: Heading Actions
                                         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                        const SizedBox(height: 18),

                                        Divider(color: BeColorSwatch.gray, height: 20),

                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                                TextButton.icon(
                                                    onPressed: () {
                                                    _scrollController.animateTo(
                                                        _scrollController.position.maxScrollExtent,
                                                        duration: const Duration(milliseconds: 300),
                                                        curve: Curves.easeOut,
                                                    );
                                                    },
                                                    icon: SFIcon(
                                                        SFIcons.sf_questionmark_circle,
                                                        color:    BeColorSwatch.blue,
                                                        fontSize: 20
                                                    ),
                                                    label: Text("Questions", style: TextStyle(color: BeColorSwatch.blue, fontWeight: FontWeight.bold))
                                                ),
                                                TextButton.icon(
                                                    onPressed: () {
                                                    _scrollController.animateTo(
                                                        _scrollController.position.maxScrollExtent,
                                                        duration: const Duration(milliseconds: 300),
                                                        curve: Curves.easeOut,
                                                    );
                                                    },
                                                    icon: SFIcon(
                                                        SFIcons.sf_pencil_and_list_clipboard,
                                                        color:    BeColorSwatch.blue,
                                                        fontSize: 20
                                                    ),
                                                label: Text("Notes", style: TextStyle(color: BeColorSwatch.blue, fontWeight: FontWeight.bold))
                                                ),
                                            ]
                                        ),

                                        Divider(color: BeColorSwatch.gray, height: 24),


                                        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                         * MARK: Connection Info
                                         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
                                         * Connection ID
                                         */
                                        if (ref.read(isDebuggingProvider))
                                        ListTile(
                                            title:    Text("Connection ID", style: TextStyle(color: BeColorSwatch.magenta, fontSize: 14, fontWeight: FontWeight.bold)),
                                            subtitle: SelectableText(
                                                connection?.id.toString() ?? "No connection ID",
                                                maxLines: 1,
                                                style:    TextStyle(color: beColorScheme.text.debug)
                                            )
                                        ),

                                        /*
                                         * Connection User ID
                                         */
                                        if (ref.read(isDebuggingProvider))
                                        ListTile(
                                            title:    Text("Connection User ID", style: TextStyle(color: BeColorSwatch.magenta, fontSize: 14, fontWeight: FontWeight.bold)),
                                            subtitle: SelectableText(
                                                connection?.userId?.toString() ?? "No user ID",
                                                maxLines: 1,
                                                style:    TextStyle(color: beColorScheme.text.debug)
                                            )
                                        ),

                                        /*
                                         * Legacy Badge ID
                                         */
                                        if (connection?.legacyBadgeId != null)
                                        ListTile(
                                            title:    Text("Legacy Badge ID", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            subtitle: SelectableText(
                                                connection?.legacyBadgeId?.toString() ?? "No legacy badge ID",
                                            )
                                        ),

                                        /*
                                         *  Email address
                                         */
                                        ListTile(
                                            title:    Text("Email", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            subtitle: (() {
                                            final email = (profileData["email"] ?? "").toString();
                                            if (email.isNotEmpty && email != "No email") {
                                                return Row(
                                                children: [
                                                    Expanded(child: SelectableText(email, maxLines: 1)),
                                                    GestureDetector(
                                                    onTap: () async {
                                                        await Clipboard.setData(ClipboardData(text: email));
                                                        scaffoldMessengerKey.currentState?.showSnackBar(
                                                        SnackBar(content: Text("Copied email address to clipboard.", textAlign: TextAlign.center))
                                                        );
                                                    },
                                                    child: const Padding(
                                                        padding: EdgeInsets.only(left: 8.0),
                                                        child: SFIcon(
                                                        SFIcons.sf_rectangle_portrait_on_rectangle_portrait,
                                                        color: BeColorSwatch.blue,
                                                        fontSize: 20,
                                                        ),
                                                    ),
                                                    ),
                                                ],
                                                );
                                            }
                                            return const Text("No email");
                                            })()
                                        ),

                                        /*
                                         *  Phone number
                                         */
                                        ListTile(
                                            title:    Text("Phone", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            subtitle: (() {
                                            final phone = (profileData["phone"] ?? "").toString();
                                            if (phone.isNotEmpty && phone != "No phone") {
                                                return Row(
                                                children: [
                                                    SelectableText(phone),
                                                    GestureDetector(
                                                    onTap: () async {
                                                        await Clipboard.setData(ClipboardData(text: phone));
                                                        scaffoldMessengerKey.currentState?.showSnackBar(
                                                        SnackBar(content: Text("Copied phone number to clipboard.", textAlign: TextAlign.center))
                                                        );
                                                    },
                                                    child: const Padding(
                                                        padding: EdgeInsets.only(left: 8.0),
                                                        child: SFIcon(
                                                        SFIcons.sf_rectangle_portrait_on_rectangle_portrait,
                                                        color: BeColorSwatch.blue,
                                                        fontSize: 20,
                                                        ),
                                                    ),
                                                    ),
                                                ],
                                                );
                                            }
                                            return const Text("No phone");
                                            })(),
                                        ),

                                        /*
                                         *  Job title
                                         */
                                        ListTile(
                                            title:    Text("Job Title", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            subtitle: (() {
                                            final String job = (profileData["jobTitle"] ?? "").toString();
                                            if (job.isNotEmpty && job != "No title") {
                                                return SelectableText(job);
                                            }
                                            return const Text("No title");
                                            })(),
                                        ),

                                        /*
                                         *  Company name
                                         */
                                        ListTile(
                                            title:    Text("Company", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            subtitle: (() {
                                                final String companyName = (profileData["companyName"] ?? "").toString();
                                                if (companyName.isNotEmpty && companyName != "No company") {
                                                    return SelectableText(companyName);
                                                }
                                                return const Text("No company");
                                            })(),
                                        ),

                                        /*
                                         *  Company category
                                         */
                                        ListTile(
                                            title:    Text("Category", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            subtitle: (() {
                                                final String companyCategories = (profileData["companyCategories"] ?? "").toString();
                                                if (companyCategories.isNotEmpty && companyCategories != "No categories") {
                                                    return SelectableText(companyCategories);
                                                }
                                                return const Text("No category");
                                            })(),
                                        ),

                                        /*
                                         *  Address
                                         */
                                        ListTile(
                                            title:    Text("Address", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            subtitle: (() {
                                            final String addr = (profileData["address"] ?? "").toString();
                                            if (addr.isNotEmpty && addr != "No address" && addr != "null") {
                                                return SelectableText(addr);
                                            }
                                            return const Text("No address");
                                            })(),
                                        ),

                                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                                TextButton.icon(
                                                    icon: SFIcon(
                                                        SFIcons.sf_map,
                                                        color:    BeColorSwatch.blue,
                                                        fontSize: 20
                                                    ),
                                                    label:     Text("Get directions", style: TextStyle(color: BeColorSwatch.blue, fontWeight: FontWeight.bold)),
                                                    onPressed: () async {
                                                        final query   = Uri.encodeComponent(profileData["address"]);
                                                        String url;

                                                        if (Platform.isIOS) {
                                                            url = "maps://?q=${query}";
                                                        } else if (Platform.isAndroid) {
                                                            url = "geo:0,0?q=${query}";
                                                        } else {
                                                            url = "https://www.google.com/maps/search/?api=1&query=${query}";
                                                        }

                                                        final uri = Uri.parse(url);

                                                        if (await canLaunchUrl(uri)) {
                                                            await launchUrl(
                                                                uri,
                                                                mode: LaunchMode.externalApplication,
                                                            );
                                                        } else {
                                                            scaffoldMessengerKey.currentState?.showSnackBar(
                                                                SnackBar(content: Text("Could not open maps for this address.", textAlign: TextAlign.center)),
                                                            );
                                                        }
                                                    },
                                                ),

                                                TextButton.icon(
                                                    icon: SFIcon(
                                                        SFIcons.sf_rectangle_portrait_on_rectangle_portrait,
                                                        color:    BeColorSwatch.blue,
                                                        fontSize: 20
                                                    ),
                                                    label:     Text((textScaleFactor > 1.35) ? "Copy" : "Copy address", style: TextStyle(color: BeColorSwatch.blue, fontWeight: FontWeight.bold)),
                                                    onPressed: () async {
                                                        await Clipboard.setData(ClipboardData(text: profileData["address"]));
                                                        scaffoldMessengerKey.currentState?.showSnackBar(
                                                            SnackBar(content: Text("Copied address to clipboard.", textAlign: TextAlign.center))
                                                        );
                                                    }
                                                )
                                            ]
                                        ),

                                        const SizedBox(height: 28),

                                        Divider(color: BeColorSwatch.gray, height: 28),




                                        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                         * MARK: User Name
                                         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                        ListTile(
                                            title:    Text("Scanned by", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            subtitle: Builder(
                                                builder: (_) {
                                                    if (_scannedByLoading) {
                                                        return Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: const [
                                                                SizedBox(
                                                                    width: 16,
                                                                    height: 16,
                                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                                ),
                                                                SizedBox(width: 8),
                                                                Text("Loading..."),
                                                            ],
                                                        );
                                                    }

                                                    String? displayName;
                                                    if (_scannedByUser != null) {
                                                        displayName = _formatUserDisplayName(_scannedByUser!);
                                                    } else {
                                                        final fallbackId = connection?.userId;
                                                        if (fallbackId != null && fallbackId.isNotEmpty) {
                                                            displayName = fallbackId;
                                                        }
                                                    }

                                                    if (displayName == null || displayName.isEmpty) {
                                                        return const Text("Unknown");
                                                    }

                                                    return SelectableText(displayName, style: beTextTheme.bodyPrimary);
                                                },
                                            ),
                                        ),

                                        const SizedBox(height: 12),

                                        Divider(color: BeColorSwatch.gray, height: 28),

                                        const SizedBox(height: 8),


                                        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                         * MARK: Qualifying Questions
                                         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                        Row(crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                                            children: [
                                                Text("Qualifying Questions", style: beTextTheme.headingSecondary),
                                                PlainButton(
                                                    backgroundColor: BeColorSwatch.blue,
                                                    key:    const Key("connection_info__submit_note_button"),
                                                    label:  (textScaleFactor > 1.2) ? "Edit" : "Edit Questions",
                                                    onTap:  () async {
                                                        if (ref.read(companyProvider) != null && ref.read(companyProvider)?.exhibitorId != null) {
                                                            final host = ref.read(isDevelopmentProvider)
                                                                ? ref.read(developmentSiteBaseUrlProvider)
                                                                : ref.read(productionSiteBaseUrlProvider);
                                                            final proto = providerContainer.read(protocolProvider);
                                                            final url = '$proto$host/exhibit/${ref.read(companyProvider)?.id}/exhibitors/${ref.read(companyProvider)?.exhibitorId}/view';

                                                            if (url != null && await canLaunchUrl(Uri.parse(url))) {
                                                                await launchUrl(
                                                                    Uri.parse(url),
                                                                    mode: LaunchMode.inAppWebView,
                                                                );

                                                            } else {
                                                                scaffoldMessengerKey.currentState?.showSnackBar(
                                                                    SnackBar(
                                                                        content: Text("Error opening URL", textAlign: TextAlign.center),
                                                                        padding: EdgeInsets.all(16),
                                                                    )
                                                                );
                                                            }
                                                        } else {
                                                            scaffoldMessengerKey.currentState?.showSnackBar(
                                                                SnackBar(
                                                                    content: Text("Error opening URL: Failed to find the exhibitor ID", textAlign: TextAlign.center),
                                                                    padding: EdgeInsets.all(16),
                                                                )
                                                            );
                                                        }
                                                    }
                                                )
                                            ]
                                        ),
                                        // Display each qualifying question and its existing answer
                                        ...(() {
                                          final questions = _connection?.qualifyingQuestions ?? [];
                                          if (_loadingQualifyingQuestions) {
                                            return [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    color: BeColorSwatch.navy,
                                                  ),
                                                ),
                                              ),
                                            ];
                                          }

                                          if (_qualifyingQuestionsLoaded && questions.isEmpty) {
                                            return [Text("No qualifying questions", style: beTextTheme.bodyPrimary)];
                                          }

                                          return questions.asMap().entries.map((entry) {
                                            final idx = entry.key;
                                            final q = entry.value;
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    q.question,
                                                    style: beTextTheme.bodyPrimary.copyWith(fontWeight: FontWeight.bold),
                                                  ),
                                                  TextFormField(
                                                    controller: _qualifyingControllers[idx],
                                                    focusNode: _qualifyingFocusNodes[idx],
                                                    decoration: gfieldInputDecoration.copyWith(
                                                      hintText: "Type your answer here.",
                                                      hintStyle: TextStyle(color: BeColorSwatch.gray),
                                                    ),
                                                    textInputAction: TextInputAction.done,
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList();
                                        })(),

                                        const SizedBox(height: 28),

                                        Divider(color: BeColorSwatch.gray, height: 28),

                                        const SizedBox(height: 8),


                                        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                        * MARK: Notes Heading
                                        * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                                Text("My Notes", style: beTextTheme.headingSecondary),
                                                isSubmittingNewUserNote
                                                    ? const SizedBox(width: 20, height: 20, child: Center(child: CircularProgressIndicator()))
                                                    : ValueListenableBuilder<TextEditingValue>(
                                                        valueListenable: newUserNoteController,
                                                        builder:         (context, value, child) {

                                                            final noteText = value.text.trim();
                                                            final hasText = noteText.isNotEmpty;

                                                            return PlainButton(
                                                                backgroundColor: hasText ? BeColorSwatch.blue : BeColorSwatch.gray,
                                                                key:    const Key("connection_info__submit_note_button"),
                                                                label:  "Save Note",
                                                                onTap:  hasText ? () async {
                                                                    if (!mounted) { return; }
                                                                    setState(() {
                                                                        isSubmittingNewUserNote = true;
                                                                    });

                                                                    final pendingNote = await _saveNoteLocally(
                                                                      noteText,
                                                                      showOfflineMessage: false,
                                                                    );

                                                                    if (!mounted) { return; }
                                                                    if (pendingNote == null) {
                                                                        setState(() {
                                                                            isSubmittingNewUserNote = false;
                                                                        });
                                                                        return;
                                                                    }
                                                                    setState(() {
                                                                        isSubmittingNewUserNote = false;
                                                                    });

                                                                    unawaited(_syncNoteWithServer(
                                                                      pendingNote: pendingNote,
                                                                      noteBody: noteText,
                                                                    ));
                                                                }  :  (() {}),
                                                            );
                                                        },
                                                    ),
                                            ],
                                        ),

                                        const SizedBox(height: 8),


                                        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                        * MARK: Notes Input
                                        * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                        Container(
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                color:        beColorScheme.background.secondary,
                                            ),
                                            child: TextFormField(
                                                controller: newUserNoteController,
                                                decoration: gfieldInputDecoration.copyWith(
                                                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                                    hintText:       "Type your note here.",
                                                    hintStyle:      TextStyle(color: BeColorSwatch.gray)
                                                ),
                                                focusNode:  _focusNode,
                                                key:        const Key("connection_info__notes_field"),
                                                maxLines:   8,
                                                minLines:   3,
                                                textInputAction: TextInputAction.done,
                                            ),
                                        ),

                                        const SizedBox(height: 16),


                                        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                        * MARK: Notes List
                                        * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                        ...(() {
                                            if (_comments.isEmpty && !_loadingApi && !isFetchingFromDatabase) {
                                                return [Center(child: Text("No notes", style: TextStyle(color: BeColorSwatch.darkGray)))];
                                            } else if (isFetchingFromDatabase || (_comments.isEmpty && _loadingApi)) {
                                                return [
                                                    Center(
                                                        child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                                const CircularProgressIndicator(color: BeColorSwatch.navy, padding: EdgeInsets.only(bottom: 8)),
                                                                Text("Loading notes...", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: BeColorSwatch.darkGray)),
                                                                const SizedBox(height: 16),
                                                            ]
                                                        )
                                                    )
                                                ];
                                            } else {
                                                final sortedComments = [..._comments]..sort((a, b) => DateTime.parse(b.dateCreated).compareTo(DateTime.parse(a.dateCreated)));
                                                return sortedComments.map((comment) => UserNotePanel(
                                                    userNote: comment,
                                                    onDelete: () {
                                                        if (!mounted) { return; }
                                                        setState(() { _comments.removeWhere((c) => c.id == comment.id); });
                                                    },
                                                )).toList();
                                            }
                                        })(),

                                    const SizedBox(height: 128),
                                ]
                            )
                            );
                        })()
                    )
                )
            )
        );
    }
}
