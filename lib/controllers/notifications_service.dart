import 'dart:convert';
import 'package:bmd_flutter_tools/controllers/api_client.dart';
import 'package:bmd_flutter_tools/controllers/deep_link_service.dart';
import 'package:flutter/widgets.dart';
import 'package:bmd_flutter_tools/controllers/app_database.dart';
import 'package:bmd_flutter_tools/controllers/global_state.dart';
import 'package:bmd_flutter_tools/main.dart';
import 'package:bmd_flutter_tools/data/model/data__company.dart';
import 'package:bmd_flutter_tools/data/model/data__badge.dart';
import 'package:bmd_flutter_tools/data/model/data__show.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bmd_flutter_tools/utilities/utilities__print.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

final FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel defaultAndroidChannel = AndroidNotificationChannel(
  'high_importance', // id
  'High Importance', // name
  description: 'Used for important notifications.',
  importance: Importance.high,
);

final Set<String> _shownNotificationIds = <String>{};

bool _alreadyShown(RemoteMessage message) {
  final id = message.messageId ?? message.data['id']?.toString() ?? message.hashCode.toString();
  if (_shownNotificationIds.contains(id)) return true;
  _shownNotificationIds.add(id);
  return false;
}

Future<void> initLocalNotifications() async {
  // Create Android channel
  await flnp
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(defaultAndroidChannel);

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();

  await flnp.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
    onDidReceiveNotificationResponse: (NotificationResponse resp) {
      try {
        logPrint('🔔 Local notification tapped; payload=${resp.payload}');
        // Optionally persist payload for app shell navigation
      } catch (_) {}
    },
  );
}

/// Background message handler - must be a top-level function.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await initLocalNotifications();
  await showNotificationFromMessage(message);
}

/// Show a local notification built from RemoteMessage
Future<void> showNotificationFromMessage(RemoteMessage message) async {
  try {
    // Prevent duplicate shows across listeners
    if (_alreadyShown(message)) {
      logPrint('🔔 Notification deduped: ${message.messageId}');
      return;
    }

    // On iOS foreground, if a notification block is present, let the system banner handle it.
    if (defaultTargetPlatform == TargetPlatform.iOS && message.notification != null) {
      logPrint('🔔 iOS foreground notification displayed by system: ${message.messageId}');
      return;
    }

    final title = message.notification?.title ?? message.data['title'] ?? '';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    final androidDetails = AndroidNotificationDetails(
      defaultAndroidChannel.id,
      defaultAndroidChannel.name,
      channelDescription: defaultAndroidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: message.notification?.android?.smallIcon ?? '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final payload = (message.data.isNotEmpty) ? json.encode(message.data) : null;

    await flnp.show(message.hashCode, title, body, details, payload: payload);
  } catch (e) {
    logPrint('❌ showNotificationFromMessage error: $e');
  }
}

/// Central initialization that wires FCM -> local notifications and app handlers.
/// Call this once at app startup after Firebase.initializeApp().
Future<void> initializeNotifications() async {
  await initLocalNotifications();

  // Background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    logPrint('🔔 FCM (foreground) received: ${message.messageId} data=${message.data}');
    await showNotificationFromMessage(message);
    // Optionally update providers / app state here
  });

  // When the user taps a notification (background -> foreground)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    logPrint('🔔 FCM tapped (onMessageOpenedApp): ${message.data}');
    await _applyProvidersFromMessage(message);
    final uri = _extractLinkWithContext(message);
    if (uri != null) {
      // Defer to the next frame to ensure router is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DeepLinkService.instance.handle(uri, from: 'fcm-opened');
      });
    }
  });

  // If app was launched by tapping a notification while terminated
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    logPrint('🔔 FCM initialMessage (app launched): ${initial.data}');
    await _applyProvidersFromMessage(initial);
    final uri = _extractLinkWithContext(initial);
    if (uri != null) {
      _pendingInitialLink = uri;
    }
  }
}

/// Try to read a deep link URL from the message payload.
Uri? _extractLink(RemoteMessage message) {
  try {
    final data = message.data;
    final raw = data['link'] ?? data['url'] ?? data['deeplink'];
    if (raw is String && raw.trim().isNotEmpty) {
      final s = raw.trim();
      if (s.startsWith('http://') || s.startsWith('https://')) {
        return Uri.parse(s);
      }
      // Support bare host paths by assuming https
      return Uri.parse('https://$s');
    }
  } catch (e) {
    logPrint('❌ extractLink error: $e');
  }
  return null;
}

// Attach company_id and badge_id from data to the link as query params so DeepLinkService can read them.
Uri? _extractLinkWithContext(RemoteMessage message) {
  final base = _extractLink(message);
  if (base == null) return null;
  try {
    final qp = Map<String, String>.from(base.queryParameters);
    final data = message.data;
    final companyId = (data['company_id'] ?? data['companyId'] ?? data['company'] ?? '').toString();
    final badgeId   = (data['badge_id']   ?? data['badgeId']   ?? data['badge']   ?? '').toString();
    if (companyId.isNotEmpty) qp['company_id'] = companyId;
    if (badgeId.isNotEmpty)   qp['badge_id']   = badgeId;
    return base.replace(queryParameters: qp);
  } catch (_) {
    return base;
  }
}

// Update companyProvider, badgeProvider, and showProvider from the message data before navigation.
Future<void> _applyProvidersFromMessage(RemoteMessage message) async {
    try {
        final data = message.data;

        // Company
        final String companyId = (data['company_id'] ?? data['companyId'] ?? data['company'] ?? '').toString();
        if (companyId.isNotEmpty) {
            final companies = await AppDatabase.instance.readCompanies(where: "${CompanyDataInfo.id.columnName} = ?", whereArgs: [companyId]);

            if (companies.isNotEmpty) {
                providerContainer.read(companyProvider.notifier).update(companies.first);
                logPrint("✅ FCM: Company provider set to ID ${companyId}.");

            } else {
                logPrint("⚠️  FCM: Found no company with the ID ${companyId}.");
            }
        } else {
            logPrint("⚠️  FCM: Data contains no company ID.");
        }

        // Badge
        final String badgeId = (data['badge_id'] ?? data['badgeId'] ?? data['badge'] ?? '').toString();
        if (badgeId.isNotEmpty) {
            var badge = (await AppDatabase.instance.readBadges(where: "${BadgeDataInfo.id.columnName} = ?", whereArgs: [badgeId])).firstOrNull;

            if (badge == null) {
                // Not in DB yet (brand new) → fetch from API and persist
                try {
                    final fetched = await ApiClient.instance.getBadges(id: badgeId);
                    badge = fetched.firstOrNull;
                } catch (_) {}
            }

            if (badge != null) {
                providerContainer.read(badgeProvider.notifier).update(badge);
                logPrint("✅ FCM: Badge provider set to ID ${badgeId}.");
            } else {
                logPrint("⚠️  FCM: Found no badge with ID ${badgeId}.");
            }
        } else {
            logPrint("⚠️  FCM: Data contains no badge ID.");
        }

        // Show
        final String showId   = (data['show_id'] ?? '').toString();
        final String showSlug = (data['show_slug'] ?? data['slug'] ?? '').toString();

        ShowData? match;
        if (showId.isNotEmpty) {
            final shows = await AppDatabase.instance.readShows(where: "${ShowDataInfo.id.columnName} = ?", whereArgs: [showId]);
            if (shows.isNotEmpty) match = shows.first;

        } else {
            logPrint("⚠️  FCM: Data contains no show ID.");
        }

        if (match == null && showSlug.isNotEmpty) {
            final all    = await AppDatabase.instance.readShows();
            final slugLc = showSlug.trim().toLowerCase();

            for (final s in all) {
                final byId    = s.id.trim().toLowerCase() == slugLc;
                final byVenue = s.venue.slug.trim().toLowerCase() == slugLc;
                final byTitle = _slugifyTitle(s.title) == slugLc;

                if (byId || byVenue || byTitle) {
                    match = s;
                    break;
                }
            }
        }
        if (match != null) {
            providerContainer.read(showProvider.notifier).update(match);
            logPrint("✅ FCM: Show provider set to ID ${match.id}.");
        } else {
            logPrint("⚠️  FCM: Found no show match.");
        }

    } catch (e) {
        logPrint("❌ ${e}");
    }
}

String _slugifyTitle(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

// Pending link captured at cold start via getInitialMessage(); flushed from main.dart after startup.
Uri? _pendingInitialLink;

Future<void> flushPendingNotificationLink() async {
  final uri = _pendingInitialLink;
  if (uri == null) return;
  _pendingInitialLink = null;
  // Defer to next frame to ensure router and app tree are ready
  WidgetsBinding.instance.addPostFrameCallback((_) {
    DeepLinkService.instance.handle(uri, from: 'fcm-initial');
  });
}
