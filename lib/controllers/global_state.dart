/*
 *  Global State
 *
 * Created by:  Blake Davis
 * Description: The app's global state, managed using Riverpod
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "dart:convert";
import "package:bmd_flutter_tools/services/analytics_service.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import 'package:bmd_flutter_tools/controllers/api_client.dart';
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__company.dart";
import "package:bmd_flutter_tools/data/model/data__company_user.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__notification.dart";
import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/data/model/data__survey_question.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

// TODO: This whole document needs to be organized
/* --------------------------------------------------------------------------------------------------------------------
 * MARK: Save State to Database
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
/// Writes the current global state to the database, using the shared providerContainer.
Future<void> saveStateToDatabase() async {
  final ref = providerContainer; // global container
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final String? accessToken = await storage.read(key: "access_token");
  final String? fcmToken = await storage.read(key: "fcm_token");

  logPrint("💾 Saving the state...");
  final UserData? user = ref.read(userProvider);

  await AppDatabase.instance.write({
    "user_id": user?.id,
    "data": {
      "access_token": accessToken,
      "badge": ref
          .read(badgeProvider)
          ?.toJson(destination: LocationEncoding.database),
      "company": ref
          .read(companyProvider)
          ?.toJson(destination: LocationEncoding.database),
      "custom_server": ref.read(isDevelopmentProvider),
      "debugging_mode": ref.read(isDebuggingProvider),
      "fcm_token": fcmToken,
      "is_new_signup": ref.read(isNewSignupProvider),
      "protocol": ref.read(protocolProvider),
      "theme_mode": themeModeToStorage(ref.read(appThemeModeProvider)),
      "server": ref.read(developmentSiteBaseUrlProvider),
      "show": ref
          .read(showProvider)
          ?.toJson(destination: LocationEncoding.database),
      "user": user?.toJson(destination: LocationEncoding.database),
    }
  }, table: "state_data");
}

final initializeGlobalStateProvider =
    AsyncNotifierProvider<InitializeGlobalState, void>(
        InitializeGlobalState.new);

final registrationUserStageCompletedProvider =
    StateProvider<bool>((ref) => false);

final registrationUserStageUserIdProvider =
    StateProvider<String?>((ref) => null);

class InitializeGlobalState extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    ref.read(registrationUserStageCompletedProvider.notifier).state = false;
    ref.read(registrationUserStageUserIdProvider.notifier).state = null;

    // 1) Read your saved row
    final raw = await AppDatabase.instance.read(tableName: "state_data");
    final dataField = raw['data'];
    final stateData = switch (dataField) {
      null => <String, dynamic>{},
      String s when s.trim().isEmpty => <String, dynamic>{},
      String s => jsonDecode(s) as Map<String, dynamic>,
      Map<String, dynamic> m => m,
      _ => <String, dynamic>{},
    };

    if (stateData.isEmpty) return;

    dynamic _normalizePersisted(dynamic value) {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return '';

        try {
          final decoded = jsonDecode(trimmed);

          if (decoded is String && decoded != value) {
            return _normalizePersisted(decoded);
          }

          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded as Map);
          }

          if (decoded is List) {
            return decoded.map(_normalizePersisted).toList();
          }

          return decoded;
        } catch (_) {
          if (trimmed.length >= 2 &&
              trimmed.startsWith('"') &&
              trimmed.endsWith('"')) {
            return trimmed.substring(1, trimmed.length - 1);
          }
          return trimmed;
        }
      }

      if (value is Map) {
        return Map<String, dynamic>.from(value as Map);
      }

      if (value is List) {
        return value.map(_normalizePersisted).toList();
      }

      return value;
    }

    final Map<String, dynamic> stateDataNormalized = stateData.map(
      (key, value) => MapEntry(key, _normalizePersisted(value)),
    );

    final storage = FlutterSecureStorage();

    // Only continue if we have an access token
    final accessToken = stateDataNormalized['access_token'];
    if (accessToken is String && accessToken.isNotEmpty) {
      // Set the keychain access token
      storage.write(
          key: "access_token",
          value: accessToken,
          iOptions: IOSOptions(
            // Update the value if it already exists
            accessibility: KeychainAccessibility.first_unlock,
            synchronizable: false,
          ));

      // 3) Restore your three flags/URL
      final custom = stateDataNormalized['custom_server'];
      ref.read(isDevelopmentProvider.notifier).state =
          custom == true || custom == 'true';

      final debug = stateDataNormalized['debugging_mode'];
      ref.read(isDebuggingProvider.notifier).state =
          debug == true || debug == 'true';

      final server = stateDataNormalized['server'];
      if (server is String) {
        ref.read(developmentSiteBaseUrlProvider.notifier).state = server;
      }

      // Restore protocol (http/https) if present
      final protocol = stateDataNormalized['protocol'];
      if (protocol is String && protocol.isNotEmpty) {
        ref.read(protocolIsHttpsProvider.notifier).state =
            protocol.startsWith('https');
      } else {
        // Fallback: HTTPS in production, HTTP in development
        ref.read(protocolIsHttpsProvider.notifier).state =
            !ref.read(isDevelopmentProvider);
      }

      final savedThemeMode = stateDataNormalized['theme_mode'];
      if (savedThemeMode != null) {
        ref.read(appThemeModeProvider.notifier).state =
            themeModeFromStorage(savedThemeMode);
      }

      // Parse dynamic to Map helper function
      // TODO: This should be refactored into a place that makes more sense -- utilities
      Map<String, dynamic>? _parseToMap(dynamic rawValue) {
        if (rawValue == null) {
          return null;
        }
        final normalized = _normalizePersisted(rawValue);
        if (normalized is Map) {
          return Map<String, dynamic>.from(normalized as Map);
        }
        return null;
      }

      // Parse and set the User
      final userAsMap = _parseToMap(stateDataNormalized["user"]);
      logPrint(
          "ℹ️  Setting the app state's User (${json.encode(userAsMap)})...");

      if (userAsMap != null && userAsMap.isNotEmpty) {
        final savedUser = UserData.fromJson(
          userAsMap,
          source: LocationEncoding.database,
        );
        ref.read(userProvider.notifier).update(savedUser);

        // Set the User data in app storage
        storage.write(
            key: "user_email",
            value: savedUser.email,
            iOptions: IOSOptions(
              // Update the value if it already exists
              accessibility: KeychainAccessibility.first_unlock,
              synchronizable: false,
            ));
        storage.write(
            key: "username",
            value: savedUser.username,
            iOptions: IOSOptions(
              // Update the value if it already exists
              accessibility: KeychainAccessibility.first_unlock,
              synchronizable: false,
            ));
      } else {
        logPrint("⚠️  Found no user in saved state data.");
        return; // Return early if we don't have a valid User
      }

      // Parse and set Badge
      final badgeAsMap = _parseToMap(stateDataNormalized["badge"]);
      logPrint("ℹ️  Setting the app state's Badge (${badgeAsMap?["id"]})...");

      if (badgeAsMap != null && badgeAsMap.isNotEmpty) {
        final savedBadge = BadgeData.fromJson(
          badgeAsMap,
          source: LocationEncoding.database,
        );
        ref.read(badgeProvider.notifier).update(savedBadge);
      }

      // Parse and set Company
      final companyAsMap = _parseToMap(stateDataNormalized["company"]);
      logPrint(
          "ℹ️  Setting the app state's Company (${companyAsMap?["id"]})...");

      if (companyAsMap != null && companyAsMap.isNotEmpty) {
        final savedCompany = CompanyData.fromJson(
          companyAsMap,
          source: LocationEncoding.database,
        );
        ref.read(companyProvider.notifier).update(savedCompany);
      }

      // Parse and set Show
      final showAsMap = _parseToMap(stateDataNormalized["show"]);
      logPrint("ℹ️  Setting the app state's Show (${showAsMap?["id"]})...");

      if (showAsMap != null && showAsMap.isNotEmpty) {
        final savedShow = ShowData.fromJson(
          showAsMap,
          source: LocationEncoding.database,
        );
        ref.read(showProvider.notifier).update(savedShow);
      }

      logPrint("✅ Saved state restored.");
    } else {
      logPrint("⚠️  Found no access token in saved state data.");
    }
  }
}

/*
 * Automatically persist global state whenever any persisting provider value changes
 */
final statePersistenceProvider = Provider<void>((ref) {
  // Helper that writes the current state snapshot to the DB using the global providerContainer
  void _persist(_, __) => saveStateToDatabase();

  /*
   * Listen to each provider that needs to persist
   *
   * Listeners stay active for as long as this provider is alive
   */
  ref.listen<bool>(isDevelopmentProvider, _persist);
  ref.listen<bool>(isDebuggingProvider, _persist);
  ref.listen<String>(developmentSiteBaseUrlProvider, _persist);
  ref.listen<bool>(isNewSignupProvider, _persist);
  ref.listen<CompanyData?>(companyProvider, _persist);
  ref.listen<bool>(protocolIsHttpsProvider, _persist);
  ref.listen<ThemeMode>(appThemeModeProvider, _persist);
  ref.listen<ShowData?>(showProvider, _persist);
  ref.listen<BadgeData?>(badgeProvider, _persist);
  ref.listen<UserData?>(userProvider, _persist);
});

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Selected Navigation Item
 *
 * Tracks which QuickNavigationBar item is selected
 * ------------------------------------------------------------------------------------------------------------------ */
final selectedNavigationItemProvider = StateProvider<String>((ref) => "Home");

final isDebuggingProvider = StateProvider<bool>((ref) => false);
final isDevelopmentProvider =
    StateProvider<bool>((ref) => developmentFeaturesEnabled);

final appThemeModeProvider =
    StateProvider<ThemeMode>((ref) => ThemeMode.light);

String themeModeToStorage(ThemeMode mode) => mode.name;

ThemeMode themeModeFromStorage(dynamic value) {
  if (value is ThemeMode) {
    return value;
  }
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }
  return ThemeMode.light;
}

final appStoragePathsProvider = StateProvider<Map<String, String>>((ref) => {});

/* ======================================================================================================================
 * MARK: Environment Variables
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
final Map<String, String> apiPrefix = {
  "development": "api",
  "production": "api"
};
final Map<String, String> apiVersion = {
  "development": "v1",
  "production": "v1"
};
final Map<String, String> mobilePrefix = {
  "development": "mobile",
  "production": "mobile"
};

/// Controls whether we use HTTPS (true) or HTTP (false) for API calls.
/// Default: HTTPS in production, HTTP in development.
final protocolIsHttpsProvider = StateProvider<bool>((ref) => true);

/// Exposes the actual scheme string based on the toggle above.
final protocolProvider = Provider<String>((ref) {
  final https = ref.watch(protocolIsHttpsProvider);
  return https ? 'https://' : 'http://';
});

const String developmentEmail = "adminuser@bmd_flutter_tools.com";
const String developmentPassword = "password";
const String developmentUsername = "adminuser@bmd_flutter_tools.com";

const String productionEmail = "";
const String productionPassword = "";
const String productionUsername = "";

final productionSiteBaseUrlProvider =
    StateProvider<String>((ref) => "buildexpo.app");
final developmentSiteBaseUrlProvider =
    StateProvider<String>((ref) => "demo.beusa.app");

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Edit Mode
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
final isEditingProvider = StateProvider<bool>((ref) => false);

final isNewSignupProvider = StateProvider<bool>((ref) => false);

// TODO: Deprecated, delete once confirmed is unused
/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: User ID
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
final userIdProvider = StateProvider<int>((ref) => 0);

// global_state.dart (or providers.dart)
final notificationsCountProvider = StreamProvider<int>((ref) async* {
  final db = await AppDatabase.instance.database;

  int last = -1;
  while (true) {
    try {
      // Read all notifications (we only need the count)
      final rows = await db.query(
        NotificationDataInfo.tableName,
        where: "${NotificationDataInfo.readAt.columnName} IS NULL",
      );
      final count = rows.length;

      if (count != last) {
        last = count;
        yield count;
      }
    } catch (_) {
      // If the table doesn't exist yet or any transient error occurs,
      // fall back to zero but avoid tight re-emits.
      if (last != 0) {
        last = 0;
        yield 0;
      }
    }

    // Light-weight polling; keeps the count in sync after writes.
    await Future.delayed(const Duration(seconds: 1));
  }
});

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Current Badge
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
final badgeProvider =
    NotifierProvider<BadgeNotifier, BadgeData?>(BadgeNotifier.new);

class BadgeNotifier extends Notifier<BadgeData?> {
  @override
  BadgeData? build() {
    return null;
  }

  void update(BadgeData? badge) {
    state = badge;
  }

  void reset() {
    state = null;
  }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Current Company
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
final companyProvider =
    NotifierProvider<CompanyNotifier, CompanyData?>(CompanyNotifier.new);

class CompanyNotifier extends Notifier<CompanyData?> {
  @override
  CompanyData? build() {
    return null;
  }

  void update(CompanyData? company) {
    state = company;
  }

  void reset() {
    state = null;
  }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Current Company User
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
final companyUserProvider =
    NotifierProvider<CompanyUserNotifier, CompanyUserData?>(
        CompanyUserNotifier.new);

class CompanyUserNotifier extends Notifier<CompanyUserData?> {
  @override
  CompanyUserData? build() {
    return null;
  }

  void update(CompanyUserData? companyUser) {
    state = companyUser;
  }

  void reset() {
    state = null;
  }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Current Connections
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

final connectionsProvider =
    FutureProvider.family<List<ConnectionData>, ConnectionsRequest>(
        (ref, params) async {
  final companyId = params.companyId;
  final showId = params.showId;

  logPrint('🔄 connectionsProvider start – company=$companyId show=$showId');

  final dbList = await AppDatabase.instance.readConnections(
      where:
          "${ConnectionDataInfo.companyId.columnName} = ? AND ${ConnectionDataInfo.showId.columnName} = ?",
      whereArgs: [companyId, showId]);

  logPrint('✅ connectionsProvider loaded ${dbList.length} from DB');

  return dbList;
});

/// Fetches connections from the API, writes them to the database,
/// and invalidates the provider so consumers reload from the DB.
Future<void> refreshConnectionsInBackground(
    String companyId, String showId) async {
  try {
    logPrint(
        '🌐 refreshConnectionsInBackground – calling API for company=$companyId show=$showId');

    // Fetch latest from server
    final apiList = await ApiClient.instance.getConnections(
      companyId: companyId,
      showId: showId,
    );

    logPrint(
        '📥 refreshConnectionsInBackground – API returned ${apiList.length} items');

    // Cache into local database
    if (apiList.isNotEmpty) {
      logPrint('💾 refreshConnectionsInBackground – writing to DB');

      await AppDatabase.instance.write(apiList);

      logPrint('💾 refreshConnectionsInBackground – write complete');
    }
  } catch (error, stack) {
    logPrint("❌  refreshing connections: $error");
  }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Current Show
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
final showProvider =
    NotifierProvider<ShowNotifier, ShowData?>(ShowNotifier.new);

class ShowNotifier extends Notifier<ShowData?> {
  @override
  ShowData? build() {
    return null;
  }

  void update(ShowData? show) {
    state = show;
  }

  void reset() {
    state = null;
  }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Current User
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
final userProvider =
    NotifierProvider<UserNotifier, UserData?>(UserNotifier.new);

class UserNotifier extends Notifier<UserData?> {
  @override
  UserData? build() {
    return null;
  }

  void reset() {
    logPrint("🔄 UserNotifier: clearing user and analytics userId...");
    unawaited(AnalyticsService.instance.setUserId(null));
    state = null;
  }

  void update(UserData user) {
    logPrint(
        "🔄 UserNotifier: updating user ${user.id} and syncing analytics userId...");
    state = user;
    unawaited(AnalyticsService.instance.setUserId(user.id));
  }

  void setBadges(List<BadgeData> badges) {
    final currentState = state;

    if (currentState != null) {
      state = currentState.copy(badges: badges);
    } else {
      logPrint(
          "❌ Failed to update userProvider Badges. The current state is null.");
    }
  }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Survey Questions
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
final exhibitorSurveyQuestionsProvider =
    FutureProvider<List<SurveyQuestionData>>((ref) {
  final company = ref.watch(companyProvider);
  final exhibitorId = company?.exhibitorId;

  if (exhibitorId == null) {
    logPrint(
        "⚠️  ${company?.name ?? "unnamed company"} is not an exhibitor, and thus has no SurveyQuestions.");
    return Future.value(<SurveyQuestionData>[]);
  }

  logPrint(
      "🔄 Getting SurveyQuestions for ${company?.name ?? "unnamed company"}...");
  return ApiClient.instance.getSurveyQuestions(exhibitorId: exhibitorId);
});

/// Kick off a ref.refresh of our survey‐questions whenever
/// the selected company changes.
final surveyQuestionsRefresher = Provider<void>((ref) {
  ref.listen<CompanyData?>(companyProvider, (prev, company) {
    final exhibitorId = company?.exhibitorId;
    if (exhibitorId != null) {
      // refresh will re‐run the FutureProvider
      ref.refresh(exhibitorSurveyQuestionsProvider);
    }
  });
});

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: User Mode
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

enum UserMode {
  admin("admin"),
  attendee("attendee"),
  exhibitor("exhibitor");

  const UserMode(this.stringName);

  final String stringName;

  factory UserMode.fromString(String stringName) {
    switch (stringName) {
      case "admin":
        return UserMode.admin;

      case "attendee":
        return UserMode.attendee;

      case "exhibitor":
        return UserMode.exhibitor;

      default:
        // TODO: Implement proper error handling here
        return UserMode.attendee;
    }
  }

  static List<String> get stringNameValues {
    return UserMode.values.map((value) {
      return value.stringName;
    }).toList();
  }
}

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Scanned Data
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
final scannedDataProvider =
    StateProvider<String>((ref) => "Nothing scanned yet.");

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: GForm Validation Message
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 * { <form_id>: { <field_id>: <validation_message> } }
 */
final gformValidationMessageProvider = NotifierProvider<
    GFormValidationMessageNotifier,
    Map<int, Map<dynamic, dynamic>>>(GFormValidationMessageNotifier.new);

class GFormValidationMessageNotifier
    extends Notifier<Map<int, Map<dynamic, dynamic>>> {
  @override
  Map<int, Map<String, dynamic>> build() {
    return {};
  }

  void add(int key, Map<dynamic, dynamic> value) {
    Map<int, Map<dynamic, dynamic>> newState = {...state};
    newState[key] = value;
    state = newState;
  }

  void update(int key, Map<dynamic, dynamic> updatedValue) {
    add(key, updatedValue);
  }

  void remove(int key) {
    Map<int, Map<dynamic, dynamic>> newState = {...state};
    newState.remove(key);
    state = newState;
  }

  void reset() {
    state = {};
  }
}
