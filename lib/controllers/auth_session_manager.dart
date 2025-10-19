import 'dart:async';
import 'dart:io';

import 'package:bmd_flutter_tools/controllers/api_client.dart';
import 'package:bmd_flutter_tools/controllers/app_database.dart';
import 'package:bmd_flutter_tools/controllers/global_state.dart';
import 'package:bmd_flutter_tools/data/model/data__badge.dart';
import 'package:bmd_flutter_tools/data/model/data__user.dart';
import 'package:bmd_flutter_tools/utilities/utilities__print.dart';
import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AuthSessionManager {
  const AuthSessionManager._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: false,
  );

  static Future<void> storeAccessToken(String token) async {
    await _secureStorage.write(
      key: 'access_token',
      value: token,
      iOptions: _iosOptions,
    );
  }

  static Future<UserData?> initializeSession({
    required WidgetRef ref,
    required String password,
    bool markAsNewSignup = false,
  }) async {
    final currentUser =
        await ApiClient.instance.getUser(getAdditionalData: true);

    if (currentUser == null) {
      logPrint('❌ AuthSessionManager: currentUser is null after login');
      return null;
    }

    ref.read(userProvider.notifier).update(currentUser);

    if (currentUser.companies.isNotEmpty) {
      final sortedCompanies = [...currentUser.companies]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      ref.read(companyProvider.notifier).update(sortedCompanies.first);
    }

    if (markAsNewSignup) {
      ref.read(isNewSignupProvider.notifier).state = true;
    }

    final emailWrite = _secureStorage.write(
      key: 'user_email',
      value: currentUser.email,
      iOptions: _iosOptions,
    );
    final passwordWrite = _secureStorage.write(
      key: 'user_password',
      value: password,
      iOptions: _iosOptions,
    );
    final userIdWrite = _secureStorage.write(
      key: 'user_id',
      value: currentUser.id,
      iOptions: _iosOptions,
    );

    final showsFuture = ApiClient.instance.getShows(onlyUpcomingShows: true);
    final notificationsFuture =
        ApiClient.instance.getNotificationsByUserId(userId: currentUser.id);

    await Future.wait([
      emailWrite,
      passwordWrite,
      userIdWrite,
      notificationsFuture,
    ]);

    final upcomingShowsSorted = await showsFuture;
    upcomingShowsSorted.sort((showA, showB) =>
        (showA.dates.dates.firstOrNull?.start ?? 0)
            .compareTo(showB.dates.dates.firstOrNull?.start ?? 0));

    final String? nextShowId = upcomingShowsSorted.firstOrNull?.id;
    BadgeData? nextBadge;
    if (nextShowId != null) {
      nextBadge = currentUser.badges.firstWhereOrNull(
        (badge) => badge.showId == nextShowId,
      );
    }

    if (nextBadge != null) {
      ref.read(badgeProvider.notifier).update(nextBadge);

      final companyForBadge = currentUser.companies
          .firstWhereOrNull((company) => company.id == nextBadge!.companyId);
      if (companyForBadge != null) {
        ref.read(companyProvider.notifier).update(companyForBadge);
      }

      final showForBadge = upcomingShowsSorted
          .firstWhereOrNull((show) => show.id == nextBadge!.showId);
      if (showForBadge != null) {
        ref.read(showProvider.notifier).update(showForBadge);
      }
    } else {
      ref.read(badgeProvider.notifier).update(null);
    }

    await _registerFcmForCurrentUser();

    final accessToken = await _secureStorage.read(key: 'access_token');

    await AppDatabase.instance.write({
      'user_id': currentUser.id,
      'data': {
        'access_token': accessToken,
        'badge': ref.read(badgeProvider),
        'company': ref.read(companyProvider),
        'custom_server': ref.read(isDevelopmentProvider),
        'debugging_mode': ref.read(isDebuggingProvider),
        'is_new_signup': ref.read(isNewSignupProvider),
        'server': ref.read(developmentSiteBaseUrlProvider),
        'show': ref.read(showProvider),
        'user': ref.read(userProvider),
      }
    }, table: 'state_data');

    return currentUser;
  }

  static Future<void> _registerFcmForCurrentUser() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        logPrint(
            '⚠️  FCM: Notifications not authorized (${settings.authorizationStatus}). Skipping registration.');
        return;
      }

      if (Platform.isIOS) {
        const int maxAttempts = 10;
        const Duration waitBetween = Duration(milliseconds: 300);
        String? apnsToken;
        for (int attempt = 0; attempt < maxAttempts; attempt++) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null && apnsToken.isNotEmpty) break;
          await Future.delayed(waitBetween);
        }

        if (apnsToken == null || apnsToken.isEmpty) {
          logPrint(
              '⚠️  FCM: APNS token unavailable. Will wait for refresh callback.');
          unawaited(FirebaseMessaging.instance.onTokenRefresh.first
              .then(_sendFcmTokenToApi)
              .catchError((error) {
            logPrint('❌ FCM onTokenRefresh (APNS wait) failed: $error');
          }));
          return;
        }
      }

      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        logPrint(
            '⚠️  FCM: getToken() returned null/empty. Waiting for refresh...');
        unawaited(FirebaseMessaging.instance.onTokenRefresh.first
            .then(_sendFcmTokenToApi)
            .catchError((error) {
          logPrint('❌ FCM onTokenRefresh failed: $error');
        }));
        return;
      }

      await _sendFcmTokenToApi(fcmToken);
    } catch (error) {
      logPrint('❌ FCM registration failed: $error');
    }
  }

  static Future<void> _sendFcmTokenToApi(String fcmToken) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown-device';
      final deviceType =
          Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'unknown');

      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        deviceId = ios.identifierForVendor ?? deviceId;
      } else if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        deviceId = android.id ?? deviceId;
      }

      final package = await PackageInfo.fromPlatform();
      final appVersion =
          package.version.isNotEmpty ? package.version : 'unknown';

      String? installationId;
      try {
        installationId = await FirebaseInstallations.instance.getId();
      } catch (error) {
        logPrint('❌ FCM: Failed to get Firebase Installation ID: $error');
      }

      logPrint(
          '🔄 FCM: Registering token (type=$deviceType, version=$appVersion, fid=${installationId ?? 'n/a'})');

      await ApiClient.instance.registerFcmToken(
        fcmToken: fcmToken,
        deviceId: deviceId,
        deviceType: deviceType,
        appVersion: appVersion,
      );
      logPrint('✅ FCM: Token registration complete.');
    } catch (error) {
      logPrint('❌ FCM: Failed to send token to API: $error');
    }
  }
}
