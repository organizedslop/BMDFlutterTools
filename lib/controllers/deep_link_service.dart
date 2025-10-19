import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:bmd_flutter_tools/controllers/app_database.dart';
import 'package:bmd_flutter_tools/controllers/global_state.dart';
import 'package:bmd_flutter_tools/main.dart';
import 'package:bmd_flutter_tools/data/model/data__show.dart';
import 'package:bmd_flutter_tools/data/model/data__company.dart';
import 'package:bmd_flutter_tools/data/model/data__badge.dart';
import 'package:bmd_flutter_tools/utilities/print_utilities.dart';
import 'package:flutter/widgets.dart';
import 'package:bmd_flutter_tools/controllers/app_router.dart' show appRouter, navigatorObserver;


/// Central deep link initialization using the `app_links` package.
/// Call this once during app startup *after* Firebase/etc. are ready.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;

  Future<void> initialize() async {
    _appLinks ??= AppLinks();

    // Handle cold start
    try {
      final initial = await _appLinks!.getInitialLink();
      if (initial != null) {
        _handleUri(initial, from: 'initial');
      }
    } catch (_) {}

    // Handle links while app is running
    _sub?.cancel();
    _sub = _appLinks!.uriLinkStream.listen(
      (uri) => _handleUri(uri, from: 'stream'),
      onError: (_) {},
      cancelOnError: false,
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _appLinks = null;
  }

  // Public entry to route a deep link URI from external sources (e.g., FCM, custom logic)
  void handle(Uri uri, {String from = 'external'}) {
    _handleUri(uri, from: from);
  }

// (Intentionally minimal logging: only provider-setting logs elsewhere)

// Push Show Home for a given slug, then optionally push a sub-route (exhibitors, seminars, etc.).
Future<void> _pushShowThen(String slugRaw, {String? subRouteName, Uri? sourceUri}) async {
  final slug = slugRaw.trim().toLowerCase();
  try {
    // Set company/badge context from query params before navigation
    await _setContextFromQuery(sourceUri);

    // Resolve and set the Show by slug before navigation
    if (slug.isNotEmpty) {
      final db = AppDatabase.instance;
      final List<ShowData> all = await db.readShows();
      ShowData? match;
      for (final s in all) {
        final idOk    = s.id.trim().toLowerCase() == slug;
        final venueOk = (s.venue.slug.trim().toLowerCase() == slug);
        final titleOk = _slugify(s.title) == slug;
        if (idOk || venueOk || titleOk) { match = s; break; }
      }
      if (match != null) {
        providerContainer.read(showProvider.notifier).update(match);
        logPrint('🔗 [DeepLink] provider set: show=${match.id}');
      }
    }

    // Push Show first (synchronously)
    try {
      appRouter.pushNamed('show');
    } catch (e) {
      final fb = _nameToPath['show'];
      if (fb != null) { try { appRouter.push(fb); } catch (_) {} }
    }

    // Then push sub-route on top, after ensuring Show is on stack
    final sr = subRouteName?.trim();
    if (sr != null && sr.isNotEmpty) {
      final end = DateTime.now().add(const Duration(seconds: 1));
      while (DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        final stack = navigatorObserver.stack();
        if (stack.isNotEmpty && stack.last.settings.name == 'show') break;
      }
      try {
        appRouter.pushNamed(sr);
      } catch (e) {
        final fb = _nameToPath[sr];
        if (fb != null) { try { appRouter.push(fb); } catch (_) {} }
      }
    }
    } catch (_) {
    try { appRouter.pushNamed('show'); } catch (_) {}
    }
}

// Read company_id and badge_id from query parameters and update providers if present
Future<void> _setContextFromQuery(Uri? uri) async {
  if (uri == null) return;
  try {
    final qp = uri.queryParameters;
    final companyId = qp['company_id'] ?? qp['companyId'] ?? qp['company'];
    final badgeId   = qp['badge_id']   ?? qp['badgeId']   ?? qp['badge'];

    final db = AppDatabase.instance;

    if (companyId != null && companyId.trim().isNotEmpty) {
        final companies = await db.readCompanies(
            where: "${CompanyDataInfo.id.columnName} = ?",
            whereArgs: [companyId.trim()],
        );
        final company = companies.isNotEmpty ? companies.first : null;
        if (company != null) {
            providerContainer.read(companyProvider.notifier).update(company);
            logPrint('🔗 [DeepLink] context set: company=${company.id}');
        }
    }

    if (badgeId != null && badgeId.trim().isNotEmpty) {
      final badges = await db.readBadges(
        where: "${BadgeDataInfo.id.columnName} = ?",
        whereArgs: [badgeId.trim()],
      );
      final badge = badges.isNotEmpty ? badges.first : null;
      if (badge != null) {
        providerContainer.read(badgeProvider.notifier).update(badge);
        logPrint('🔗 [DeepLink] context set: badge=${badge.id}');
      }
    }
  } catch (_) {}
}

String _slugify(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

    void _handleUri(Uri uri, {required String from}) {

        final scheme   = uri.scheme;              // bmd_flutter_tools or https
        final host     = uri.host;                // might be empty for bmd_flutter_tools:/home
        final path     = uri.path;                // e.g., /home
        final firstSeg = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
        String pick(String a, String b) => (a.isNotEmpty ? a : b).toLowerCase();

        // Custom scheme: handle both bmd_flutter_tools://home and bmd_flutter_tools:/home
        if (scheme == 'bmd_flutter_tools') {
            final key = pick(host, firstSeg); // prefer host, else first segment

            if (key == 'home') {
                _safePushNamed('home');
                return;
            }

            if (key == 'profile' || key == 'user-profile' || key == 'attend-profile') {
                // Route is named "user profile" in app_router
                _safePushNamed('user profile');
                return;
            }

            if (key == 'delete-account' || key == 'delete_account') {
                // No dedicated delete account route; send to settings
                _safePushNamed('user settings');
                return;
            }

            // Fallback: try to navigate using key directly as a GoRouter name
            if (key.isNotEmpty) {
                _safePushNamed(key);
                return;
            }
        }

        // Universal links mapped to AASA components
        if (scheme == 'https') {
            final segs = uri.pathSegments;

            // Exclude API endpoints: "/api/*"
            if (segs.isNotEmpty && segs.first.toLowerCase() == 'api') {
                return; // ignore silently
            }

            // Root "/"
            if (segs.isEmpty || path == '/') {
                _safePushNamed('home');
                return;
            }

            // "/*/login" or explicit "/login" or "/*/signin"
            if (segs.last.toLowerCase() == 'login' || segs.last.toLowerCase() == 'signin') {
                final qp = uri.queryParameters;
                final initialUsername = qp['username'] ?? qp['user'] ?? qp['email'];
                final initialPassword = qp['password'] ?? qp['pass'];
                final submitOnLoad    = (qp['submit'] == '1' || qp['submit'] == 'true');
                final extras = <String, dynamic>{
                  if (initialUsername != null) 'initialUsername': initialUsername,
                  if (initialPassword != null) 'initialPassword': initialPassword,
                  if (submitOnLoad) 'submitOnLoad': true,
                };
                WidgetsBinding.instance.addPostFrameCallback((_) {
                    try {
                        appRouter.pushNamed('signin', extra: extras);
                    } catch (_) {}
                });
                return;
            }

            // "/attend/register" or generic "/*/register"
            final isAttendRegister = (segs.length == 2 && segs[0].toLowerCase() == 'attend' && segs[1].toLowerCase() == 'register');
            final isAnyRegister   = segs.last.toLowerCase() == 'register';
            if (isAttendRegister || isAnyRegister) {
                final qp = uri.queryParameters;
                final initialEmail = qp['email'] ?? qp['e'];
                final extras = <String, dynamic>{
                  if (initialEmail != null) 'initialEmail': initialEmail,
                };
                WidgetsBinding.instance.addPostFrameCallback((_) {
                    try {
                        appRouter.pushNamed('register', extra: extras);
                    } catch (_) {}
                });
                return;
            }

            // Paths containing "shows"
            final showsIdx = segs.indexWhere((s) => s.toLowerCase() == 'shows');
            if (showsIdx != -1) {
                // Exactly "/shows" → All Shows
                final isExactlyShows = segs.length == showsIdx + 1;
                if (isExactlyShows) {
                    _safePushNamed('all shows');
                    return;
                }

                // "/shows/:slug" or deeper
                final slug = (segs.length > showsIdx + 1) ? segs[showsIdx + 1] : '';
                final last = segs.last.toLowerCase();

                if (last == 'exhibitors') {
                    _pushShowThen(slug, subRouteName: 'exhibitors list', sourceUri: uri);
                    return;
                }
                if (last == 'schedules' || last == 'schedule' || last == 'seminars') {
                    _pushShowThen(slug, subRouteName: 'seminars list', sourceUri: uri);
                    return;
                }

                // Default for /shows/:slug → push Show Home only
                _pushShowThen(slug, sourceUri: uri);
                return;
            }

            // Common fallbacks
            if (path == '/home' || path.endsWith('/home')) {
                _safePushNamed('home');
                return;
            }
            if (path.endsWith('/profile') || path.contains('/attend/profile')) {
                _safePushNamed('user profile');
                return;
            }
        }

        // Otherwise, ignore or navigate to a safe default
        _safePushNamed('home');
    }


static const Map<String, String> _nameToPath = {
  'home': '/home',
  'user profile': '/user_profile',
  'user settings': '/user_settings',
  'register': '/register',
  'signin': '/signin',
  'all shows': '/all_shows',
  'show': '/show',
  'exhibitors list': '/exhibitors',
  'seminars list': '/seminars_list',
};

 void _safePushNamed(String routeName) {
  final name = routeName.trim();
  final pathFallback = _nameToPath[name];

  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      appRouter.pushNamed(name);
    } catch (_) {
      if (pathFallback != null) {
        try {
          appRouter.push(pathFallback);
        } catch (_) {}
      }
    }
  });
 }
}
