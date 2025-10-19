/*
 * Main
 *
 * Created by:  Blake Davis
 * Description:
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "package:bmd_flutter_tools/theme/snackbar_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:flutter/foundation.dart";
import "firebase_options.dart";
import "package:bmd_flutter_tools/services/analytics_service.dart";
import "package:bmd_flutter_tools/controllers/deep_link_service.dart";
import "package:bmd_flutter_tools/controllers/notifications_service.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/services/connection_retry_service.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:permission_handler/permission_handler.dart";
import "package:sentry_flutter/sentry_flutter.dart";

final providerContainer = ProviderContainer();

/* =====================================================================================================================
 * MARK: Main
 * ------------------------------------------------------------------------------------------------------------------ */ // Create a global ProviderContainer to make Providers accessible outside Widgets
Future<void> main() async {

    await SentryFlutter.init(
        (options) {
            options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: 'https://bd27c8e746ee89d6461f0be5c8a613a8@o4509607102054400.ingest.us.sentry.io/4510127275900928');
            options.environment = kReleaseMode ? 'production' : 'development';
            options.tracesSampleRate = kReleaseMode ? 1.0 : 0.0;
            options.replay.sessionSampleRate = 1.0;
            options.replay.onErrorSampleRate = 1.0;
        },
        appRunner: () async {
            await _bootstrapApplication();
        },
    );
}

Future<void> _bootstrapApplication() async {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
    );
    logPrint("📈 Main: Firebase.initializeApp completed.");
    logPrint("📈 Main: Initializing AnalyticsService...");

    await AnalyticsService.instance.initialize();

    logPrint("📈 Main: Logging initial app_open event");

    await AnalyticsService.instance.logAppOpen();

    await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
    );

    // Android 13+ (Tiramisu): request runtime notification permission
    final notifStatus = await Permission.notification.status;

    if (!notifStatus.isGranted) {
        await Permission.notification.request();
    }

    /*
     * Initialize the notification service
     */
    await initializeNotifications();

    /*
     * Initialize the deep linking service
     */
    await DeepLinkService.instance.initialize();


    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

        final initialRoute = Uri.base.path;
        final queryParams  = Uri.base.queryParameters;

        // Style the status bar for views that do not have an AppBar
        SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values
        );

        SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.dark,
            )
        );

        AppDatabase appDatabase = AppDatabase.instance;

        // Check for build-time changes to reset database if needed
        const MethodChannel _buildTimeChannel = MethodChannel('icmMethodChannel');

        final storage = FlutterSecureStorage();

        final String currentBuildTime = await _buildTimeChannel.invokeMethod('getBuildTime') as String;
        final String? lastBuildTime   = await storage.read(key: 'build_time');

        if (lastBuildTime != currentBuildTime) {
            // Build changed: destroy and recreate database
            await appDatabase.closeDatabase();
            await appDatabase.deleteDatabase();
            await appDatabase.reopen();
            await storage.write(
                key:      "build_time",
                value:    currentBuildTime,
                iOptions: IOSOptions(
                    // Update the value if it already exists
                    accessibility:  KeychainAccessibility.first_unlock,
                    synchronizable: false,
                )
            );
        }

        /* -----------------------------------------------------------------------------------------------------------------
         *  Invalidate the login session and clear the database if the schema changed
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
        if (await appDatabase.schemaChanged()) {
            logPrint("⚠️  Schema changed – wiping SQLite file and re‑initialising…");

            // 1) Close active connection (if any)
            await appDatabase.closeDatabase();

            // 2) Delete the file completely
            await appDatabase.deleteDatabase();

            // 3) Recreate fresh DB
            await appDatabase.reopen(); // helper we add next

            logPrint("🗄️  Database recreated with the new schema.");
        }

        // Kick off the background retry listener:
        ConnectionRetryService.instance.initialize();

        // Load the saved state
        await providerContainer.read(initializeGlobalStateProvider.future);

        providerContainer.read(surveyQuestionsRefresher);

        // Flush any pending notification deep link after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
            flushPendingNotificationLink();
        });

        runApp(
            SentryWidget(
                // Entire app is wrapped in a ProviderScope so the widgets will be able to read providers
                child: UncontrolledProviderScope(
                    container: providerContainer,
                    child: App(initialRoute: initialRoute, initialParams: queryParams))
            )
        );
}


/* ======================================================================================================================
 * MARK: App Widget
 * ------------------------------------------------------------------------------------------------------------------ */
class App extends ConsumerStatefulWidget {
    final String initialRoute;
    final Map<String, String> initialParams;

    const App({
        required this.initialRoute,
        required this.initialParams,
        super.key
    });

    @override
    ConsumerState<App> createState() => _AppState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _AppState extends ConsumerState<App> {
    String? jwt;
    late GoRouter _router;

    @override
    void initState() {
        super.initState();
        _router = appRouter;
    }

    @override
    void dispose() {
        super.dispose();
    }

    String? scannedData;

    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {
        final themeMode = ref.watch(appThemeModeProvider);

        return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            scaffoldMessengerKey: scaffoldMessengerKey,
            themeMode: themeMode,
            title: "Build Expo USA",

            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Light Theme
             */
            theme: ThemeData(
                checkboxTheme: appCheckboxTheme,
                colorScheme: appColorSchemeLight,
                dividerTheme: const DividerThemeData(color: Colors.transparent), // Disable the divider below the navigation menu drawer header
                inputDecorationTheme: appInputDecorationTheme,
                elevatedButtonTheme: appElevatedButtonTheme,
                radioTheme: appRadioTheme,
                scaffoldBackgroundColor: BeColorSwatch.lighterGray,
                splashColor: Colors.transparent,
                pageTransitionsTheme: PageTransitionsTheme(
                    builders: {
                        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                        TargetPlatform.android: appSlideTransitionsBuilder,
                        TargetPlatform.windows: appSlideTransitionsBuilder,
                        TargetPlatform.linux: appSlideTransitionsBuilder,
                        TargetPlatform.fuchsia: appSlideTransitionsBuilder,
                    },
                ),
                switchTheme: appSwitchTheme,
                textButtonTheme: appTextButtonTheme,
                textTheme: appTextTheme,
                snackBarTheme: snackBarTheme,
                unselectedWidgetColor: appColorSchemeLight.surfaceContainer
            ),

            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Dark Theme
             */
            darkTheme: ThemeData(
                colorScheme: appColorSchemeDark,
                dividerTheme: const DividerThemeData(color: Colors.transparent), // Disable the divider below the navigation menu drawer header
                scaffoldBackgroundColor: BeColorSwatch.black,
                switchTheme: appSwitchTheme,
                textButtonTheme: appTextButtonTheme,
                textTheme: appTextTheme,
                snackBarTheme: snackBarTheme,
            )
        );
    }
}
