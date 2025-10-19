/*
 * App Router
 *
 * Created by:  Blake Davis
 * Description: Handles routing and transitions between app views
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "dart:convert";
import "package:bmd_flutter_tools/services/analytics_service.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__seminar_session.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";
import "package:bmd_flutter_tools/views/form__registration.dart";
import "package:bmd_flutter_tools/views/view__account_created_confirmation.dart";
import "package:bmd_flutter_tools/views/view__account_settings.dart";
import "package:bmd_flutter_tools/views/view__badge_scanner.dart";
import "package:bmd_flutter_tools/views/view__connection_info.dart";
import "package:bmd_flutter_tools/views/view__contact_us.dart";
import "package:bmd_flutter_tools/views/view__document_reader.dart";
import "package:bmd_flutter_tools/views/view__exhibitors_list.dart";

import "package:bmd_flutter_tools/views/view__connections_list.dart";
import "package:bmd_flutter_tools/views/view__my_registrations_list.dart";
import "package:bmd_flutter_tools/views/view__notifications_list.dart";
import "package:bmd_flutter_tools/views/view__seminar_info.dart";
import "package:bmd_flutter_tools/views/view__seminars_list.dart";
import "package:bmd_flutter_tools/views/view__show_home.dart";
import "package:bmd_flutter_tools/views/view__show_info.dart";
import "package:bmd_flutter_tools/views/view__sign_in_form.dart";
import "package:bmd_flutter_tools/views/view__all_shows_list.dart";
import "package:bmd_flutter_tools/views/view__user_home.dart";
import "package:bmd_flutter_tools/views/view__user_profile.dart";
import "package:bmd_flutter_tools/views/view__web_view.dart";
import "package:bmd_flutter_tools/widgets/navigation_bar__primary.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";

final swipeMessage = Padding(
    padding: EdgeInsets.only(bottom: 40),
    child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Swipe for more info",
              style: beTextTheme.bodyPrimary.merge(
                  TextStyle(color: beColorScheme.text.inverse, height: 1.33))),
          const SizedBox(width: 6),
          SFIcon(SFIcons.sf_arrow_right,
              color: beColorScheme.text.inverse,
              fontSize: beTextTheme.bodyPrimary.fontSize)
        ]));

final leadScannerAd = DocumentReader(
    title: "Lead Retrieval",
    assetPath: "assets/pdfs/ad-lead-retrieval-features-001.pdf",
    actions: {
      0: {"label": swipeMessage},
      1: {"label": swipeMessage},
      2: {"label": swipeMessage},
      3: {"label": swipeMessage},
      4: {"label": swipeMessage},
      5: {
        "label": Padding(
            padding: EdgeInsets.only(bottom: 75),
            child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(fullRadius),
                    color: beColorScheme.background.accent),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    child: Text("Buy now".toUpperCase(),
                        style: beTextTheme.headingPrimary.merge(
                            TextStyle(color: beColorScheme.text.inverse)))))),
        "action": () {
          appRouter.pushNamed("lead retrieval purchase form");
        }
      }
    });

class TrackingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];

  stack() => _stack;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previous) {
    _stack.add(route);
    final name = route.settings.name ?? route.runtimeType.toString();
    logPrint("🔎 TrackingNavigatorObserver: logging screen push → $name");
    unawaited(AnalyticsService.instance.logScreenView(screenName: name));

    super.didPush(route, previous);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      final idx = _stack.indexOf(oldRoute);
      if (idx != -1 && newRoute != null) {
        _stack[idx] = newRoute;
      }
    }
    if (newRoute != null) {
      final name = newRoute.settings.name ?? newRoute.runtimeType.toString();
      logPrint("🔎 TrackingNavigatorObserver: logging screen replace → $name");
      unawaited(AnalyticsService.instance.logScreenView(screenName: name));
    }

    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previous) {
    _stack.remove(route);
    super.didPop(route, previous);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previous) {
    _stack.remove(route);
    super.didRemove(route, previous);
  }

  bool containsRouteNamed(String name) {
    return _stack.any((r) => r.settings.name == name);
  }
}

final navigatorObserver = TrackingNavigatorObserver();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/* ======================================================================================================================
 * MARK: App Router
 * ------------------------------------------------------------------------------------------------------------------ */
GoRouter appRouter = GoRouter(
  initialLocation: "/signin",
  debugLogDiagnostics: true,
  observers: [navigatorObserver, routeObserver],
  redirect: (context, state) {
    final user = providerContainer.read(userProvider);

    // logPrint('🔀 redirect: uri=${state.uri} user=${user?.id}');

    // Do not force redirects on internal router errors here; let pages handle gracefully.

    // Normalize incoming absolute Universal Links (e.g., https://buildexpo.app/attend/register)
    final uri = state.uri;
    if (uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http')) {
      final host = uri.host.toLowerCase();
      const allowedHosts = {
        'buildexpo.app',
        'www.buildexpo.app',
        'icecrm.work',
        'www.icecrm.work',
        'demo.beusa.app',
        'www.demo.beusa.app',
      };
      if (allowedHosts.contains(host)) {
        final segs = uri.pathSegments;
        final path = uri.path;
        // Exclude API endpoints
        if (segs.isNotEmpty && segs.first.toLowerCase() == 'api') {
          // logPrint('🔀 redirect normalize: ignoring API path uri=$uri');
          return "/home"; // keep app safe
        }
        // Root
        if (segs.isEmpty || path == '/') {
          // logPrint('🔀 redirect normalize: $uri → /home');
          return "/home";
        }
        // Login/Signin
        if (segs.last.toLowerCase() == 'login' ||
            segs.last.toLowerCase() == 'signin') {
          // logPrint('🔀 redirect normalize: $uri → /signin');
          return "/signin";
        }
        // Register
        final isAttendRegister = (segs.length == 2 &&
            segs[0].toLowerCase() == 'attend' &&
            segs[1].toLowerCase() == 'register');
        final isAnyRegister = segs.last.toLowerCase() == 'register';
        if (isAttendRegister || isAnyRegister) {
          // logPrint('🔀 redirect normalize: $uri → /register');
          return "/register";
        }
        // Shows
        final showsIdx = segs.indexWhere((s) => s.toLowerCase() == 'shows');
        if (showsIdx != -1) {
          final last = segs.last.toLowerCase();
          if (last == 'exhibitors') {
            // logPrint('🔀 redirect normalize: $uri → /exhibitors');
            return "/exhibitors";
          }
          if (last == 'schedules' || last == 'schedule' || last == 'seminars') {
            // logPrint('🔀 redirect normalize: $uri → /seminars_list');
            return "/seminars_list";
          }
          // Exactly "/shows" → all shows; otherwise assume a specific show
          final isExactlyShows = segs.length == showsIdx + 1;
          if (isExactlyShows) {
            // logPrint('🔀 redirect normalize: $uri → /all_shows');
            return "/all_shows";
          }
          // logPrint('🔀 redirect normalize: $uri → /show');
          return "/show";
        }
        // Common fallbacks
        if (path == '/home' || path.endsWith('/home')) {
          // logPrint('🔀 redirect normalize: $uri → /home');
          return "/home";
        }
        if (path.endsWith('/profile') || path.contains('/attend/profile')) {
          // logPrint('🔀 redirect normalize: $uri → /user_profile');
          return "/user_profile";
        }
      }
    }

    final isPublicRoute = state.uri.toString() == "/signin" ||
        state.uri.toString() == "/register" ||
        state.uri.toString() == "/";

    // If not signed in, send to "/signin"
    if (user == null && !isPublicRoute) {
      return "/signin";
    }
    // If signed in, redirect from "/signin" to "/home"
    if (user != null && isPublicRoute) {
      return "/home";
    }
    return null;
  },
  routes: [
    /* -------------------------------------------------------------------------------------------------------------
         * MARK: All Shows
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "all shows",
        path: "/all_shows",
        builder: (context, state) =>
            AllShowsList(title: "All Shows", showAll: true)),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Account Created Confirmation
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "account created confirmation",
        path: "/account_created",
        builder: (context, state) => const AccountCreatedConfirmationView()),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: My Registrations
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "my registrations",
        path: "/my_registrations",
        builder: (context, state) =>
            MyRegistrationsList(title: "My Registrations", showAll: true)),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Contact Us
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "contact us",
        path: "/contact_us",
        builder: (context, state) => ContactUs()),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Document Reader
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "document reader",
        path: "/document_reader",
        builder: (context, state) {
          Map<int, Map<String, dynamic>> actions = {};
          try {
            (json.decode(state.uri.queryParameters["actions"] ?? "{}")
                    as Map<String, dynamic>)
                .forEach((key, value) {
              actions[key.toInt()!] =
                  json.decode(value) as Map<String, dynamic>;
            });
          } catch (error) {
            logPrint("❌ Failed decoding document page actions.");
          }

          return DocumentReader(
              title: state.uri.queryParameters["title"],
              assetPath: state.uri.queryParameters["assetPath"],
              actions: actions);
        }),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Finalize Account
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "finalize account",
        path: "/finalize_account",
        builder: (context, state) {
          UserData? user;
          bool reviewCompanyInfo = true;

          final extra = state.extra;
          if (extra is UserData) {
            user = extra;
          } else if (extra is Map) {
            user = extra['user'] as UserData?;
            final dynamic reviewFlag = extra['reviewCompanyInfo'];
            if (reviewFlag is bool) {
              reviewCompanyInfo = reviewFlag;
            }
          }

          return RegistrationForm(
            title: "Confirm Your Info",
            isFinalizing: true,
            user: user,
            reviewCompanyInfo: reviewCompanyInfo,
          );
        }),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Home
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "home",
        path: "/home",
        builder: (context, state) => UserHome(title: "Home")),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Connection Info
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "connection info",
        path: "/connection/:connection",
        builder: (context, state) => ConnectionInfo(
            title: "Lead Details",
            connection: ConnectionData.fromJson(
                state.pathParameters["connection"],
                source: LocationEncoding.database))),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Connections/Leads List
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "connections",
        path: "/connections",
        builder: (context, state) {
          return Consumer(builder: (context, ref, child) {
            if (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false) {
              return LeadsList(title: "My Leads");
            }

            return WebView(
              title: "Lead Scanning",
              url: "https://buildexpo.app/mobile/lead-scanning",
            );
          });
        }),
    GoRoute(
        name: "exhibitors list",
        path: "/exhibitors",
        builder: (context, state) {
          return ExhibitorsList(title: "Exhibitors");
        }),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Member Profile
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "member profile",
        path: "/member_profile/:badge/:connection",
        builder: (context, state) => UserProfile(
            title: "User Profile",
            badge: BadgeData.fromJson(state.pathParameters["badge"],
                source: LocationEncoding.database),
            connection: ConnectionData.fromJson(
                state.pathParameters["connection"],
                source: LocationEncoding.database))),
    GoRoute(
        name: "member profile with user",
        path: "/member_profile/:user/:badge/:connection",
        builder: (context, state) => UserProfile(
            title: "User Profile",
            user: UserData.fromJson(state.pathParameters["user"],
                source: LocationEncoding.database),
            badge: BadgeData.fromJson(state.pathParameters["badge"],
                source: LocationEncoding.database),
            connection: ConnectionData.fromJson(
                state.pathParameters["connection"],
                source: LocationEncoding.database))),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: My Profile
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "user profile",
        path: "/user_profile",
        builder: (context, state) => UserProfile(
              title: "My Badge",
            )),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Registration Form
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "register",
        path: "/register",
        builder: (context, state) {
          final extraMap = state.extra as Map<String, dynamic>?;

          return RegistrationForm(
            initialEmail: extraMap?["initialEmail"] as String?,
          );
        }),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Scanner
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "scanner",
        path: "/scanner",
        builder: (context, state) {
          final testInjectedBarcode = (state.extra is Map)
              ? (state.extra as Map)["testInjectedBarcode"]
              : null;
          return BadgeScanner(testInjectedBarcode: testInjectedBarcode);
        }),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Seminar Info
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "seminar_info",
        path: "/seminar_info/:seminarSession",
        builder: (context, state) => SeminarInfo(
              seminarSession: SeminarSessionData.fromJson(
                  state.pathParameters["seminarSession"],
                  source: LocationEncoding.database),
              presenterBoothNumber:
                  state.uri.queryParameters["presenterBoothNumber"],
            )),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Seminars List
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "seminars list",
        path: "/seminars_list",
        builder: (context, state) => SeminarsList()),
    GoRoute(
        name: "seminars list with title",
        path: "/seminars_list/:title",
        builder: (context, state) => SeminarsList(
              title: state.pathParameters["title"],
            )),
    GoRoute(
        name: "seminars list for show",
        path: "/seminars_list/:showId",
        builder: (context, state) => SeminarsList(
            title: "Seminars", showId: state.pathParameters["showId"])),
    GoRoute(
        name: "seminars list for show with title",
        path: "/seminars_list/:showId/:title",
        builder: (context, state) => SeminarsList(
            title: state.pathParameters["title"],
            showId: state.pathParameters["showId"])),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Show Home
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "show",
        path: "/show",
        builder: (context, state) {
          return ShowHome();
        }),
    GoRoute(
        name: "notifications",
        path: "/notifications",
        builder: (context, state) {
          return NotificationsList();
        }),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Show Info
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "show info",
        path: "/show_info/:showId",
        builder: (context, state) =>
            ShowInfo(showId: state.pathParameters["showId"] ?? "")),
    GoRoute(
        name: "show info with title",
        path: "/show_info/:showId/:title",
        builder: (context, state) => ShowInfo(
            title: state.pathParameters["title"] ?? "",
            showId: state.pathParameters["showId"] ?? "")),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Sign In Form
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "signin",
        path: "/signin",
        builder: (context, state) {
          if (state.extra != null) {
            final data = state.extra! as Map<String, dynamic>;

            return SignInForm(
              key: UniqueKey(),
              initialUsername: data["initialUsername"] ?? "",
              initialPassword: data["initialPassword"] ?? "",
              submitOnLoad: data["submitOnLoad"] ?? false,
            );
          } else {
            return SignInForm(key: UniqueKey());
          }
        }),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Web View
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "web view",
        path: "/web_view/:title/:url",
        builder: (context, state) => WebView(
            title: state.pathParameters["title"] ?? "",
            url: state.pathParameters["url"] ?? "")),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: Under Construction
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "wip",
        path: "/wip/:title",
        builder: (context, state) => Scaffold(
            appBar: PrimaryNavigationBar(
                title: state.pathParameters["title"] ?? ""),
            body: Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                        "Under Construction: This page is currently unavailable."))))),

    /* -------------------------------------------------------------------------------------------------------------
         * MARK: User Settings
         * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    GoRoute(
        name: "user settings",
        path: "/user_settings",
        builder: (context, state) => UserSettings(title: "Account Settings")),
  ],

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Error Page
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  errorPageBuilder: (context, state) {
    logPrint(
        '❌ Router error: uri=${state.uri} error=${state.error} → redirecting to /home');
    // Fallback safety: redirect after build if redirect() didn’t catch it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        appRouter.go('/home');
      } catch (_) {}
    });
    // Render a tiny placeholder while redirecting
    return const MaterialPage(child: SizedBox.shrink());
  },
);
