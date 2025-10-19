/*
 * Main
 *
 * Created by:  Blake Davis
 * Description:
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
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
import "package:bmd_flutter_tools/theme/slide_transitions.dart";
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

/*
 * MARK: Show SnackBar
 */
void showSnackBar({
    Color backgroundColor = BeColorSwatch.white,
    required BuildContext context,
    required Widget content,
}) {
    if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                content: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        border: Border.all(color: BeColorSwatch.gray, width: 0.5),
                        borderRadius: BorderRadius.circular(mediumRadius),
                        color: BeColorSwatch.white,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    width: double.infinity,
                    child: content,
                ),
            ),
        );
    }
}

/* =====================================================================================================================
 * MARK: Main
 * ------------------------------------------------------------------------------------------------------------------ */ // Create a global ProviderContainer to make Providers accessible outside Widgets
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
                GlobalKey<ScaffoldMessengerState>();

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

        final checkboxTheme = CheckboxThemeData(
            fillColor: WidgetStateProperty.fromMap({
                WidgetState.selected: appAccentColor
            }),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: gfieldBoxDecoration.border!.top.color,
                    width: (gfieldBoxDecoration.border!.top.width / 1.4)
                ),
                borderRadius: BorderRadius.circular(smallRadius)
            ),
            side: BorderSide(
                color: gfieldBoxDecoration.border!.top.color,
                width: (gfieldBoxDecoration.border!.top.width / 1.4)
            ),
            splashRadius: 0,
        );

        final inputDecorationTheme = InputDecorationTheme(
            border: gfieldRoundedBorder,
            contentPadding: gfieldHorizontalPadding,
            enabledBorder: gfieldRoundedBorder,
            fillColor: appColorSchemeLight.surfaceContainer,
            filled: true,
            focusedBorder: gfieldRoundedBorder.copyWith(
                borderSide: gfieldRoundedBorder.borderSide.copyWith(
                    width: gfieldRoundedBorderWidth + 0.5,
                    color: BeColorSwatch.blue
                )
            ),
        );

        final radioTheme = RadioThemeData(
            fillColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                    return appAccentColor;
                }
                return gfieldRoundedBorder.borderSide.color;
            }),
            splashRadius: 0,
        );

        final switchTheme = SwitchThemeData(
            thumbColor: WidgetStateProperty.all(BeColorSwatch.offWhite),
            thumbIcon: WidgetStateProperty.all(
                Icon(Icons.circle, color: BeColorSwatch.offWhite)
            ),
            trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? appAccentColor
                    : BeColorSwatch.lightGray,
            ),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            trackOutlineWidth: WidgetStateProperty.all(0.0)
        );

        final textButtonTheme = TextButtonThemeData(
            style: ButtonStyle(
                animationDuration: buttonOverlayFadeDuration,
                overlayColor:      WidgetStateProperty.all(BeColorSwatch.white.withAlpha(60)),
                splashFactory:     NoSplash.splashFactory,
                tapTargetSize:     MaterialTapTargetSize.shrinkWrap,
                textStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                                color: (states.contains(WidgetState.pressed)
                                                ? appAccentColor
                                                : BeColorSwatch.gray),
                                height: 0)),
                visualDensity: VisualDensity.compact
            )
        );

        final elevatedButtonTheme = ElevatedButtonThemeData(
            style: ButtonStyle(
                animationDuration: buttonOverlayFadeDuration,
                backgroundColor:   WidgetStateProperty.all(appAccentColor),
                foregroundColor:   WidgetStateProperty.all(BeColorSwatch.white),
                overlayColor:      WidgetStateProperty.all(BeColorSwatch.white.withAlpha(60)),
                padding: WidgetStateProperty.all(EdgeInsets.symmetric(
                                horizontal: (((beTextTheme.bodyPrimary.fontSize! / 2) + 2) * 2),
                                vertical: ((beTextTheme.bodyPrimary.fontSize! / 2) + 2))),
                splashFactory: NoSplash.splashFactory,
                textStyle: WidgetStateProperty.all(
                    beTextTheme.bodyPrimary.merge(
                        TextStyle(color: BeColorSwatch.white, fontWeight: FontWeight.bold)
                    )
                ),
            )
        );

        final textTheme = TextTheme(
                bodyLarge: beTextTheme.bodyPrimary,
                bodyMedium: beTextTheme.bodyPrimary,
                bodySmall: beTextTheme.bodySecondary,
                displayLarge: beTextTheme.titlePrimary,
                displayMedium: beTextTheme.titleSecondary,
                displaySmall: beTextTheme.titleSecondary,
                headlineLarge: beTextTheme.headingPrimary,
                headlineMedium: beTextTheme.headingSecondary,
                headlineSmall: beTextTheme.headingTertiary,
                labelLarge:
                                beTextTheme.bodyPrimary.merge(TextStyle(fontWeight: FontWeight.bold)),
                labelMedium:
                                beTextTheme.bodyPrimary.merge(TextStyle(fontWeight: FontWeight.bold)),
                labelSmall: beTextTheme.bodySecondary
                                .merge(TextStyle(fontWeight: FontWeight.bold)),
                titleLarge: beTextTheme.headingPrimary,
                titleMedium: beTextTheme.headingSecondary,
                titleSmall: beTextTheme.headingTertiary,
        );

        const slideBuilder = SlideTransitionsBuilder();

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
                checkboxTheme: checkboxTheme,
                colorScheme: appColorSchemeLight,
                dividerTheme: const DividerThemeData(color: Colors.transparent), // Disable the divider below the navigation menu drawer header
                inputDecorationTheme: inputDecorationTheme,
                elevatedButtonTheme: elevatedButtonTheme,
                radioTheme: radioTheme,
                scaffoldBackgroundColor: BeColorSwatch.lighterGray,
                splashColor: Colors.transparent,
                pageTransitionsTheme: PageTransitionsTheme(
                    builders: {
                        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                        TargetPlatform.android: slideBuilder,
                        TargetPlatform.windows: slideBuilder,
                        TargetPlatform.linux: slideBuilder,
                        TargetPlatform.fuchsia: slideBuilder,
                    },
                ),
                switchTheme: switchTheme,
                textButtonTheme: textButtonTheme,
                textTheme: textTheme,
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
                switchTheme: switchTheme,
                textButtonTheme: textButtonTheme,
                textTheme: textTheme,
                snackBarTheme: snackBarTheme,
            )
        );
    }
}
