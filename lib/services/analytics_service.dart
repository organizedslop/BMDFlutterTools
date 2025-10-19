import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:firebase_analytics/firebase_analytics.dart";
import "package:sentry_flutter/sentry_flutter.dart";

/// Thin wrapper around [FirebaseAnalytics] to keep analytics usage in one place.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  /// Lazily create the analytics instance and attach an observer for navigation tracking.
  Future<void> initialize() async {
    if (_analytics != null) {
      logPrint("📈 AnalyticsService: initialize skipped (already ready)");
      return;
    }

    logPrint("📈 AnalyticsService: initializing FirebaseAnalytics instance...");
    final analytics = FirebaseAnalytics.instance;

    _analytics = analytics;
    _observer = FirebaseAnalyticsObserver(analytics: analytics);
    logPrint("📈 AnalyticsService: initialization complete");
  }

  FirebaseAnalytics get analytics => _analytics ?? FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      _observer ?? FirebaseAnalyticsObserver(analytics: analytics);

  Future<void> logAppOpen() async {
    logPrint("📈 AnalyticsService: logging app_open event");
    try {
      await analytics.logAppOpen();
      logPrint("📈 AnalyticsService: app_open logged");
    } catch (error, stackTrace) {
      logPrint("📈 AnalyticsService: failed to log app_open → $error");
        await Sentry.captureException(error, stackTrace: stackTrace);

    }
  }

  Future<void> logLogin({String? loginMethod}) async {
    logPrint("📈 AnalyticsService: logging login event (method=${loginMethod ?? 'unspecified'})");
    try {
      await analytics.logLogin(loginMethod: loginMethod);
      logPrint("📈 AnalyticsService: login event logged");
    } catch (error, stackTrace) {
      logPrint("📈 AnalyticsService: failed to log login → $error");
          await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> logLogout() async {
    logPrint("📈 AnalyticsService: logging logout event");
    try {
      await analytics.logEvent(name: "logout");
      logPrint("📈 AnalyticsService: logout event logged");
    } catch (error, stackTrace) {
      logPrint("📈 AnalyticsService: failed to log logout → $error");
          await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> setUserId(String? userId) async {
    logPrint("📈 AnalyticsService: setting userId=${userId ?? 'null'}");
    try {
      await analytics.setUserId(id: userId);
      logPrint("📈 AnalyticsService: userId applied");
    } catch (error, stackTrace) {
      logPrint("📈 AnalyticsService: failed to set userId → $error");
          await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> logScreenView(
      {required String screenName, String? screenClass}) async {
    logPrint("📈 AnalyticsService: logging screen_view (name=$screenName, class=${screenClass ?? 'null'})");
    try {
      await analytics.logScreenView(
          screenName: screenName, screenClass: screenClass);
      logPrint("📈 AnalyticsService: screen_view logged");
    } catch (error, stackTrace) {
      logPrint("📈 AnalyticsService: failed to log screen_view → $error");
          await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    logPrint("📈 AnalyticsService: logging custom event '$name' params=${parameters ?? {}}");
    try {
      await analytics.logEvent(name: name, parameters: parameters);
      logPrint("📈 AnalyticsService: event '$name' logged");
    } catch (error, stackTrace) {
      logPrint("📈 AnalyticsService: failed to log event '$name' → $error");
          await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }
}
