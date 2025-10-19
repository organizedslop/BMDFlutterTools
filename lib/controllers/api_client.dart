/*
 * API Client
 *
 * Created by:  Blake Davis
 * Description: Client for BuildExpo.us' REST API
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "dart:convert";
import "dart:io";
import "package:bmd_flutter_tools/services/analytics_service.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart" as global_state;
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__company.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__exhibitor.dart";
import "package:bmd_flutter_tools/data/model/data__seminar_session.dart";
import "package:bmd_flutter_tools/data/model/data__seminar_speaker.dart";
import 'package:bmd_flutter_tools/data/model/data__survey_answer.dart';
import "package:bmd_flutter_tools/data/model/data__survey_question.dart";
import "package:bmd_flutter_tools/data/model/data__user_note.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/data/model/data__gform.dart";
import "package:bmd_flutter_tools/data/model/data__icecrm_response.dart";
import "package:bmd_flutter_tools/data/model/data__image.dart";
import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/data/model/data__notification.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/snackbar_styles.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/type_extensions.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class RegistrationSubmissionException implements Exception {
  RegistrationSubmissionException(this.messages);

  final List<String> messages;

  @override
  String toString() =>
      'RegistrationSubmissionException(messages: ${messages.join(" | ")})';
}

/* =====================================================================================================================
 * MARK: API Client
 * ------------------------------------------------------------------------------------------------------------------ */
class ApiClient {
  // Make this a singleton class
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  AppDatabase appDatabase = AppDatabase.instance;

  final Dio dio = Dio();

  // ---- Persistence guards ----------------------------------------------------
  bool _isSuccessful(Response r) =>
      r.statusCode != null && r.statusCode! >= 200 && r.statusCode! < 300;

  /// Only persist when the list has data. Never clear tables with empty sets.
  Future<void> _writeIfNotEmpty<T>(List<T> items) async {
    if (items.isEmpty) return;
    await appDatabase.write(items);
  }

  void _showSnackBarMessages(
    Iterable<dynamic> rawMessages, {
    bool ignoreUnauthorized = false,
    TextStyle? textStyle,
    TextAlign? textAlign,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    for (final message in rawMessages) {
      final String sanitizedMessage = message.toString().trim();
      if (sanitizedMessage.isEmpty) {
        continue;
      }

      if (ignoreUnauthorized && sanitizedMessage == "Unauthorized") {
        continue;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sanitizedMessage,
            style: textStyle,
            textAlign: textAlign,
          ),
        ),
      );
    }
  }

  void _showMessagesFromResponse(
    IceCrmResponseData response, {
    bool ignoreUnauthorized = false,
    TextStyle? textStyle,
    TextAlign? textAlign,
  }) {
    _showSnackBarMessages(
      response.messages,
      ignoreUnauthorized: ignoreUnauthorized,
      textStyle: textStyle,
      textAlign: textAlign,
    );
  }

  String siteBaseUrl() {
    final isDev = providerContainer.read(global_state.isDevelopmentProvider);
    if (isDev) {
      // Read the dynamic host from the Riverpod state
      return providerContainer
          .read(global_state.developmentSiteBaseUrlProvider);
    } else {
      // Fallback to the production host
      return providerContainer.read(global_state.productionSiteBaseUrlProvider);
    }
  }

  String apiRootUrl() {
    final isDev = providerContainer.read(global_state.isDevelopmentProvider);
    final envKey = isDev ? 'development' : 'production';
    final host = siteBaseUrl();
    final prefix = global_state.apiPrefix[envKey]!;
    final proto = providerContainer.read(global_state.protocolProvider);
    return '$proto$host/$prefix';
  }

  String mobileApiRootUrl() {
    final isDev = providerContainer.read(global_state.isDevelopmentProvider);
    final envKey = isDev ? 'development' : 'production';
    final host = siteBaseUrl();
    final prefix = global_state.apiPrefix[envKey]!;
    final mobile = global_state.mobilePrefix[envKey]!;
    final version = global_state.apiVersion[envKey]!;
    final proto = providerContainer.read(global_state.protocolProvider);
    return '$proto$host/$prefix/$mobile/$version';
  }

  /// Wrap a Dio call with Bearer auth. If the call returns 401, immediately log the user out.
  Future<Response<T>> _authorized<T>(
    Future<Response<T>> Function(Options opts) doCall,
  ) async {
    final storage = const FlutterSecureStorage();
    String? token = await storage.read(key: 'access_token');

    Options _optsWith([Map<String, dynamic>? extra]) => Options(
          headers: {
            if (token?.isNotEmpty == true) 'authorization': 'Bearer $token',
            ...?extra,
          },
        );

    try {
      // First attempt
      return await doCall(_optsWith());
    } on DioException catch (e) {
      // Only handle 401 specially
      if (e.response?.statusCode == 401) {
        providerContainer.invalidate(userProvider);
        providerContainer.invalidate(badgeProvider);
        providerContainer.invalidate(companyProvider);
        providerContainer.invalidate(showProvider);

        /*
            * Wait for sign out to complete before navigating to sign in page, to
            * prevent the app from trying to automatically sign back in.
            */
        await logout();

        // Use "go" to pop all pages on the stack
        appRouter.goNamed("signin");
      }
      rethrow;
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Authentication
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<IceCrmResponseData?> login(
      {String? email, String? password, String? accessCode}) async {
    final String url = "${apiRootUrl()}/login";

    Response response;

    final bool usingAccessCode =
        accessCode != null && accessCode.trim().isNotEmpty;

    try {
      if (accessCode != null) {
        logPrint("🔄 Signing in via access code (${accessCode})...");

        response = await dio.post(url, data: {"access_code": accessCode});
      } else if (email != null && password != null) {
        ("🔄 Signing in ${email}...");

        response =
            await dio.post(url, data: {"email": email, "password": password});
      } else {
        throw Exception(
            "❌ An access code or both an email address and password are required to sign in.");
      }
      ;
      // Success
      if (response.statusCode == 200) {
        var iceCrmResponse = IceCrmResponseData.fromJson(
          response.data,
          dataParser: (dataAsJson) => dataAsJson,
        );

        logPrint("📈 ApiClient: logging analytics login event");
        unawaited(AnalyticsService.instance.logLogin(
            loginMethod: accessCode != null ? "access_code" : "password"));
        // Save FCM token to secure storage along with access token
        try {
          final messaging = FirebaseMessaging.instance;
          final String? fcmToken = await messaging.getToken();
          if (fcmToken != null && fcmToken.isNotEmpty) {
            await const FlutterSecureStorage().write(
              key: 'fcm_token',
              value: fcmToken,
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
                synchronizable: false,
              ),
            );
            logPrint("💾 FCM token saved to secure storage: $fcmToken");
          }
        } catch (error, stackTrace) {
          logPrint("❌ Failed to save FCM token: $error");
              await Sentry.captureException(error, stackTrace: stackTrace);

        }
        _showMessagesFromResponse(
          iceCrmResponse,
          ignoreUnauthorized: !usingAccessCode,
        );
        return iceCrmResponse;
      }

      // If status is not 200, fall through to catch
    } on DioException catch (error) {
      if (error.response != null) {
        var iceCrmResponseData = IceCrmResponseData.fromJson(
          error.response!.data,
          dataParser: (dataAsJson) => dataAsJson,
        );
        _showMessagesFromResponse(
          iceCrmResponseData,
          ignoreUnauthorized: !usingAccessCode,
          textAlign: TextAlign.center,
        );

        return iceCrmResponseData;
      } else {
        return null;
      }
    }
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Submit 2FA Code
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
  Future<IceCrmResponseData?> submitTwoFactorAuthenticationCode(
      String code, String email, String token) async {
    logPrint("🔄 Submitting 2FA code...");

    final String url = "${apiRootUrl()}/login/2fa";

    Response response;

    try {
      response = await dio.post(
        url,
        data: {"code": code, "email": email, "token": token},
        options: Options(headers: {"Accept": "application/json"}),
      );

      if (response.statusCode == 200) {
        var iceCrmResponse = IceCrmResponseData.fromJson(
          response.data,
          dataParser: (dataAsJson) => dataAsJson,
        );
        _showMessagesFromResponse(iceCrmResponse);
        return iceCrmResponse;
      }

      // If response status code is not 200...
    } on DioException catch (error) {
      logPrint("❌ ${error}");

      if (error.response != null &&
          error.response!.data.runtimeType == Map<String, dynamic>) {
        var iceCrmResponseData = IceCrmResponseData.fromJson(
          error.response!.data,
          dataParser: (dataAsJson) => dataAsJson,
        );
        _showMessagesFromResponse(iceCrmResponseData);
        return iceCrmResponseData;
      } else {
        logPrint("❌ is null or wrong runtimeType");
        return null;
      }
    }
  }

  // Revoke the JWT token and all app state data
  Future<void> logout() async {
    final String url = "${apiRootUrl()}/logout";

    logPrint("🔄 Signing out...");

    logPrint("📈 Logging logout event...");
    unawaited(AnalyticsService.instance.logLogout());
    unawaited(AnalyticsService.instance.setUserId(null));

    final storage = const FlutterSecureStorage();

    // Read access token BEFORE we modify/clear anything so the API calls are authorized.
    final String? accessToken = await storage.read(key: "access_token");

    // 1) Deactivate FCM token on server, then delete locally.
    try {
      final messaging = FirebaseMessaging.instance;
      final String? fcmToken = await messaging.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        try {
          // Uses the already-existing ApiClient helper
          await deactivateFcmTokenByValue(fcmToken);
          logPrint("✅ FCM: deactivated token on server.");
        } catch (error, stackTrace) {
          logPrint("❌ FCM: server deactivation failed → $error");
              await Sentry.captureException(error, stackTrace: stackTrace);
        }

        try {
          await messaging.deleteToken();
          logPrint("✅ FCM: local token deleted.");
        } catch (error, stackTrace) {
          logPrint("❌ FCM: failed to delete local token → $error");
              await Sentry.captureException(error, stackTrace: stackTrace);
        }
      } else {
        logPrint("⚠️  FCM: no token found to deactivate.");
      }
    } catch (error, stackTrace) {
      // Non-fatal; continue logout
      logPrint("❌ FCM: logout token step failed → $error");
          await Sentry.captureException(error, stackTrace: stackTrace);
    }

    // 2) Hit API logout endpoint (best-effort; continue even if it fails)
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        final Response response = await dio.get(
          url,
          options: Options(headers: {"authorization": "Bearer $accessToken"}),
        );

        if (response.statusCode == 200) {
          logPrint(
              "✅ Sign-out request complete (Status code: ${response.statusCode}).");
        } else {
          throw DioException(
              requestOptions: RequestOptions(path: ""), response: response);
        }
      } else {
        logPrint("⚠️  No access token available for /logout request; skipping.");
      }
    } on DioException catch (error, stackTrace) {
        await Sentry.captureException(error, stackTrace: stackTrace);
      if (error.response != null) {
        logPrint("❌ API logout exception: ${error.response!.data}");
      } else {
        logPrint("❌ API logout network error: $error");
      }
    } catch (error, stackTrace) {
      logPrint("❌ API logout unexpected error: $error");
          await Sentry.captureException(error, stackTrace: stackTrace);
    }

    // 3) Clear local app state & database AFTER network calls
    try {
      await appDatabase.deleteStateData();
      await appDatabase.deleteData();
    } catch (error, stackTrace) {
      logPrint("❌ DB cleanup failed during logout → $error");
          await Sentry.captureException(error, stackTrace: stackTrace);
    }

    // 4) Clear secure storage last
    try {
      await storage.deleteAll();
    } catch (error, stackTrace) {
      logPrint("❌ Secure storage cleanup failed during logout → $error");
          await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Forgot Password
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
  Future<void> requestPasswordReset({required String email}) async {
    final String url = "${mobileApiRootUrl()}/users/forgot-password";

    logPrint("🔄 Requesting password reset link for ${email}...");

    /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
         * Make the request
         */
    try {
      Response response = await dio.get(
        url,
        queryParameters: {"email": Uri.encodeComponent(email)},
      );
      return;

      /* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
         *  Handle errors
         */
    } catch (error, stackTrace) {
      logPrint("❌ ${error}");
          await Sentry.captureException(error, stackTrace: stackTrace);
      return;
    }
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Request Account Deletion
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
  Future<void> requestAccountDeletion(
      {bool confirmed = true, bool deactivateOnly = true}) async {
    final String url = "${mobileApiRootUrl()}/users/deactivate";

    logPrint("🔄 Submitting account deletion request...");

    // TODO: Update API to use more appropriate method than GET
    try {
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(url, options: options);
      });

      return;
    } catch (error, stackTrace) {
      logPrint("❌ ${error}");
          await Sentry.captureException(error, stackTrace: stackTrace);
      return;
    }
  }

  /// Fetch a panel token via POST /panel-token
  Future<String?> fetchPanelToken() async {
    final String url = "${mobileApiRootUrl()}/panel-token";
    logPrint("🔄 Fetching panel token...");

    try {
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.post(url, options: options);
      });

      if (!_isSuccessful(response)) {
        logPrint(
            "⚠️  fetchPanelToken: non-success status ${response.statusCode}");
        return null;
      }

      if (response.data == null) return null;

      return response.data["code"];
    } on DioException catch (error, stackTrace) {
      logPrint("❌ DioException: ${error.response?.statusCode} ${error.response?.data}");
          await Sentry.captureException(error, stackTrace: stackTrace);
      return null;

    } catch (error, stackTrace) {
      logPrint("❌ $error");
          await Sentry.captureException(error, stackTrace: stackTrace);
      return null;
    }
  }

  /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Validate JWT token
     */
  Future<bool> validateToken(String jwt) async {
    final String url = "${apiRootUrl()}/validate";

    logPrint("🔄 Validating token...");

    try {
      Response response = await dio.get(
        "${url}",
        data: {"Authorization": jwt},
      );
      dynamic responseData = response.data;
      // Check if token is valid
      return responseData["success"] == true;

    } on DioException catch (error, stackTrace) {
      // Handle validation error
      logPrint("❌ Token validation error: ${error}");
          await Sentry.captureException(error, stackTrace: stackTrace);
      return false;
    }
  }

  /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Refresh auth token
     */
  Future<String?> refreshToken() async {
    final String url = "${apiRootUrl()}/refresh-token";

    logPrint("🔄 Requesting refresh token...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      final storage = const FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");
      final email = await storage.read(key: "user_email");
      final password = await storage.read(key: "user_password");

      Response response = await dio.get(
        url,
        data: {
          "email": email,
          "password": password,
        },
        options: Options(headers: {"authorization": "Bearer $accessToken"}),
      );

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return null;
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((accessTokenAsJson) {
              try {
                return accessTokenAsJson["access_token"];
              } catch (error) {
                logPrint("❌ ${error.toString()}");

                return null;
              }
            })
            .whereType<String>()
            .toList();
      });

      if (_isSuccessful(response)) {
        if (iceCrmResponse.data.isNotEmpty && iceCrmResponse.data[0] != null) {
          await storage.write(
              key: "access_token",
              value: iceCrmResponse.data[0],
              iOptions: IOSOptions(
                // Update the value if it already exists
                accessibility: KeychainAccessibility.first_unlock,
                synchronizable: false,
              ));

          await saveStateToDatabase();

          return iceCrmResponse.data[0];
        }
      }

      return null;
    } on DioException catch (error, stackTrace) {
      // Handle refresh error
      logPrint("❌ ${error}");
          await Sentry.captureException(error, stackTrace: stackTrace);
      return null;
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Badges
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Get Badges
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<BadgeData>> getBadges({String? id, String? userId}) async {
    final String url = mobileApiRootUrl();

    // logPrint("🔄 Getting badges...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Form the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      String query = "";

      if (id != null) {
        query = "/badges/${id}";
      } else if (userId != null) {
        query = "/users/${userId}/badges";
      }

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get("${url}${query}", options: options);
      });

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((badgeAsJson) {
              try {
                return BadgeData.fromJson(badgeAsJson,
                    source: LocationEncoding.api);
              } catch (error, stackTrace) {
                logPrint("❌ ${error.toString()}");
                Sentry.captureException(error, stackTrace: stackTrace);
                return null;
              }
            })
            .whereType<BadgeData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<BadgeData> badges = iceCrmResponse.data ?? [];

      // Persist fresh badges first
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(badges);

        // --- Reconcile deletions: remove any local badges for this user that were not returned ---
        try {
          if (userId != null && userId.isNotEmpty) {
            // Read current local badges for this user
            final localBadges = await AppDatabase.instance.readBadges(
              where: "${BadgeDataInfo.userId.columnName} = ?",
              whereArgs: [userId],
            );

            final returnedIds = badges.map((b) => b.id).toSet();
            final idsToDelete = <String>[];
            for (final lb in localBadges) {
              if (!returnedIds.contains(lb.id)) {
                idsToDelete.add(lb.id);
              }
            }

            if (idsToDelete.isNotEmpty) {
              final placeholders = idsToDelete.map((_) => '?').join(',');
              await AppDatabase.instance.deleteWhere(
                tableName: BadgeDataInfo.tableName,
                where: "${BadgeDataInfo.id.columnName} IN ($placeholders)",
                whereArgs: idsToDelete,
              );
            }
          }
        } catch (error, stackTrace) {
          logPrint("❌ Badge reconcile (delete missing) failed: $error");
              await Sentry.captureException(error, stackTrace: stackTrace);
        }
      }

      return badges;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } on DioException catch (error, stackTrace) {
      logPrint("❌ registerForShow DioException: $error");
      await Sentry.captureException(error, stackTrace: stackTrace);
      return [];

    } catch (error, stackTrace) {
      logPrint("❌ registerForShow error: $error");
      await Sentry.captureException(error, stackTrace: stackTrace);
      return [];
    }
  }

  Future<bool> sendFcmNotificationToUser({
    required String userId,
    required String token,
    String? title,
    String? body,
    Map<String, dynamic>? data,
  }) async {
    final String url = "${mobileApiRootUrl()}/users/${userId}/notifications/send-fcm";

    logPrint("Sending FCM notification to user $userId...");

    try {
      final String? dataJson = (data != null && data.isNotEmpty) ? json.encode(data) : null;

      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(
          url,
          options: options,
          queryParameters: {
            "token": token,
            if (title != null) "title": title,
            if (body != null)  "body":  body,
            if (dataJson != null) "data": dataJson,
          },
        );
      });

      if (response.data == null || response.data.isEmpty) {
        logPrint("sendFcmNotificationToUser: empty response.");
        return _isSuccessful(response);
      }

      // Parse wrapper for messages (consistent with other methods)
      try {
        final IceCrmResponseData ice = IceCrmResponseData.fromJson(
          response.data,
          dataParser: (raw) => raw,
        );
        _showMessagesFromResponse(ice);
      } catch (_) {
        // ignore parse errors for wrapper
      }

      return _isSuccessful(response);
    } on DioException catch (error, stackTrace) {
      logPrint("sendFcmNotificationToUser DioException: ${error}");
      await Sentry.captureException(error, stackTrace: stackTrace);
      return false;

    } catch (e, stackTrace) {
      logPrint("❌ Error (sendFcmNotificationToUser): $e");
      await Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Register for Show
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<BadgeData>> registerForShow(
      {required String? companyId, required String? showId}) async {
    final String url =
        "${mobileApiRootUrl()}/shows/${showId}/attend-as/${companyId}";

    logPrint("🔄 Registering for show...");

    try {
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(url, options: options);
      });

      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((badgeAsJson) {
              try {
                return BadgeData.fromJson(badgeAsJson,
                    source: LocationEncoding.api);
              } catch (error, stackTrace) {
                logPrint("❌ ${error.toString()}");
                Sentry.captureException(error, stackTrace: stackTrace);
                return null;
              }
            })
            .whereType<BadgeData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<BadgeData> badges = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(badges);
      }

      return badges;
    } on DioException catch (error, stackTrace) {
      logPrint("❌ registerForShow DioException: $error");
      await Sentry.captureException(error, stackTrace: stackTrace);
      return [];

    } catch (error, stackTrace) {
      logPrint("❌ registerForShow error: $error");
      await Sentry.captureException(error, stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> submitInviteForm({
    required Map<String, dynamic> formData,

    /// Timeout in milliseconds (defaults to 5s)
    int timeoutMs = 5000,
  }) async {
    final String url = mobileApiRootUrl();
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    try {
      final options = Options(
        contentType: Headers.jsonContentType,
        headers: {
          'authorization': 'Bearer $token',
        },
      );

      // Send the POST request
      final Response response = await dio.post(
        '$url/invites/create',
        data: formData,
        options: options,
      );

      // Decode the API’s JSON wrapper
      final IceCrmResponseData crmResponse = IceCrmResponseData.fromJson(
        response.data,
        dataParser: (dataAsJson) => dataAsJson,
      );
      logPrint('✅ Invite submitted successfully. Messages: ${crmResponse.messages}');
      _showMessagesFromResponse(crmResponse);

    } on DioException catch (error, stackTrace) {
      logPrint('❌ Failed to submit invite. Network error: $error');
          await Sentry.captureException(error, stackTrace: stackTrace);

      final responseData = error.response?.data;
      if (responseData != null) {
        try {
          final IceCrmResponseData crmResponse = IceCrmResponseData.fromJson(
            responseData,
            dataParser: (dataAsJson) => dataAsJson,
          );
          _showMessagesFromResponse(
            crmResponse,
            textAlign: TextAlign.center,
          );
        } catch (_) {
          // If parsing fails, allow log-only handling
        }
      }

    } catch (error, stackTrace) {
      logPrint('❌ Unexpected error submitting invite: $error');
          await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<List<ExhibitorData>> getExhibitors({required String showId}) async {
    final String url = "${mobileApiRootUrl()}/shows/$showId/exhibitors";
    // logPrint("🔄 Getting exhibitors...");

    try {
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(url, options: options);
      });

      if (!_isSuccessful(response)) {
        // Do not parse or write on non-2xx responses
        logPrint(
            "❌ getExhibitors: non-success status ${response.statusCode}; skipping persistence.");
        return <ExhibitorData>[];
      }

      if (response.data == null) return [];

      final IceCrmResponseData ice = IceCrmResponseData.fromJson(
        response.data,
        dataParser: (Object? raw) {
          // raw is the value of top-level "data"
          final root =
              (raw is Map<String, dynamic>) ? raw : const <String, dynamic>{};
          final nested = root['data']; // pagination object
          final list =
              (nested is Map<String, dynamic>) ? nested['data'] : nested;
          final items = (list is List) ? list : const [];

          return items
              .map((e) {
                try {
                  return ExhibitorData.fromJson(e,
                      source: LocationEncoding.api);
                } catch (error, stackTrace) {
                  logPrint("❌ ${error.toString()}");
                Sentry.captureException(error, stackTrace: stackTrace);
                  return null;
                }
              })
              .whereType<ExhibitorData>()
              .toList();
        },
      );

      final exhibitors = ice.data ?? <ExhibitorData>[];
      _showMessagesFromResponse(ice);

      /*
         * Write to the db if the response is successful and not empty
         */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(exhibitors);
      }
      return exhibitors;
    } on DioException catch (error, stackTrace) {
            await Sentry.captureException(error, stackTrace: stackTrace);
      if (error.response != null) {
        final IceCrmResponseData ice = IceCrmResponseData.fromJson(
          error.response!.data,
          dataParser: (Object? raw) {
            final root =
                (raw is Map<String, dynamic>) ? raw : const <String, dynamic>{};
            final nested = root['data'];
            final list =
                (nested is Map<String, dynamic>) ? nested['data'] : nested;
            final items = (list is List) ? list : const [];

            return items
                .map((e) {
                  try {
                    return ExhibitorData.fromJson(e,
                        source: LocationEncoding.api);
                  } catch (error, stackTrace) {
                    logPrint("❌ ${error.toString()}");
                     Sentry.captureException(error, stackTrace: stackTrace);
                    return null;
                  }
                })
                .whereType<ExhibitorData>()
                .toList();
          },
        );
        _showMessagesFromResponse(
          ice,
          textAlign: TextAlign.center,
        );
        return ice.data ?? <ExhibitorData>[];
      }
      rethrow;

    } catch (error, stackTrace) {
      logPrint("❌ ${error}");
          await Sentry.captureException(error, stackTrace: stackTrace);
      return <ExhibitorData>[];
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Media
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Get Booth Photos
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<ImageData>> getBoothPhotos({int page = 0}) async {
    final String url = "${apiRootUrl()}/booth-photos";

    // logPrint("🔄 Getting booth photos...");

    try {
      final storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");

      Response response = await dio.get(url,
          queryParameters: {"page": page},
          options:
              Options(headers: {"authorization": "Bearer ${accessToken}"}));

      List<dynamic> responseData = response.data;

      List<ImageData> boothPhotos = [];

      if (responseData.isNotEmpty) {
        for (var photoAsString in responseData) {
          ImageData photo =
              ImageData.fromJson(photoAsString, source: LocationEncoding.api);
          boothPhotos.add(photo);
          appDatabase.write(photo);
        }
      } else {
        logPrint("⚠️  Response is empty.");
      }
      return boothPhotos;

    } catch (error, stackTrace) {
      logPrint("❌ ${error}");
          await Sentry.captureException(error, stackTrace: stackTrace);
      return [];
    }
  }

  Future<CompanyData?> getCompanyById(String companyId) async {
    final String url = "${mobileApiRootUrl()}/companies/$companyId";
    // logPrint("🔄 Getting company by id: $companyId...");

    try {
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(url, options: options);
      });

      if (!_isSuccessful(response)) {
        logPrint(
            "❌ getCompanyById: non-success status ${response.statusCode}; skipping parse/persist.");
        return null;
      }

      if (response.data == null) return null;

      final IceCrmResponseData ice = IceCrmResponseData.fromJson(
        response.data,
        dataParser: (Object? raw) {
          // Be defensive: API may return a single object or a list
          if (raw is Map<String, dynamic>) {
            try {
              return CompanyData.fromJson(raw, source: LocationEncoding.api);
            } catch (e) {
              logPrint("❌ ${e.toString()}");
              return null;
            }
          }
          if (raw is List && raw.isNotEmpty) {
            final first = raw.first;
            if (first is Map<String, dynamic>) {
              try {
                return CompanyData.fromJson(first,
                    source: LocationEncoding.api);
              } catch (e) {
                logPrint("❌ ${e.toString()}");
                return null;
              }
            }
          }
          return null;
        },
      );

      final CompanyData? company =
          ice.data is CompanyData ? ice.data as CompanyData : null;
      _showMessagesFromResponse(ice);
      /*
         * Write to the db if the response is successful and not empty
         */
      if (_isSuccessful(response)) {
        if (company != null) {
          await _writeIfNotEmpty([company]);
        }
      }
      return company;
    } on DioException catch (error, stackTrace) {
      // Never persist on transport or non-2xx errors
        await Sentry.captureException(error, stackTrace: stackTrace);
      if (error.response != null) {
        logPrint(
            "❌ getCompanyById: DioException with status ${error.response!.statusCode}; skipping persistence.");
      } else {
        logPrint("❌ getCompanyById: DioException (network/timeout): $error");
      }
      rethrow;

    } catch (error, stackTrace) {
      logPrint("❌ ${error}");
          await Sentry.captureException(error, stackTrace: stackTrace);
      return null;
    }
  }

/* -----------------------------------------------------------------------------------------------------------------
 * MARK: Notifications
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 * MARK: Get Notifications by User ID
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

  Future<List<NotificationData>> getNotificationsByUserId({
    required String userId,
    bool unreadOnly = false,
  }) async {
    final String url = "${mobileApiRootUrl()}/users/${userId}/notifications";

//   logPrint("🔄 Getting notifications for user $userId...${unreadOnly ? " (unread only)" : ""}");

    try {
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(url, options: options);
      });

      if (response.data == null) {
        return <NotificationData>[];
      }

      final IceCrmResponseData ice = IceCrmResponseData.fromJson(
        response.data,
        dataParser: (Object? raw) {
          // API wrapper returns a list at top-level "data"
          final list = raw.ensureList();
          return list
              .map((item) {
                try {
                  return NotificationData.fromJson(
                    (item is Map<String, dynamic>) ? item : {},
                  );
                } catch (error, stackTrace) {
                  logPrint("❌ ${error.toString()}");
                     Sentry.captureException(error, stackTrace: stackTrace);
                  return null;
                }
              })
              .whereType<NotificationData>()
              .toList();
        },
      );

      final notifications = ice.data ?? <NotificationData>[];
      _showMessagesFromResponse(ice);
      if (_isSuccessful(response)) {
        if (notifications.isNotEmpty) {
          appDatabase.write(notifications).then((_) {
            providerContainer.invalidate(notificationsCountProvider);
          });
        }
      }
      return notifications;
    } on DioException catch (error, stackTrace) {
      logPrint("❌ Dio error $error");
          await Sentry.captureException(error, stackTrace: stackTrace);

      if (error.response != null) {
        try {
          final IceCrmResponseData ice = IceCrmResponseData.fromJson(
            error.response!.data,
            dataParser: (Object? raw) {
              final list = raw.ensureList();
              return list
                  .map((item) {
                    try {
                      return NotificationData.fromJson(
                        (item is Map<String, dynamic>) ? item : {},
                      );
                    } catch (error, stackTrace) {
                      logPrint("❌ ${error.toString()}");
                         Sentry.captureException(error, stackTrace: stackTrace);
                      return null;
                    }
                  })
                  .whereType<NotificationData>()
                  .toList();
            },
          );
          _showMessagesFromResponse(
            ice,
            textAlign: TextAlign.center,
          );
          return ice.data ?? <NotificationData>[];
        } catch (_) {
          // fall through
        }
      }
      rethrow;

    } catch (error, stackTrace) {
      logPrint("❌ ${error}");
          await Sentry.captureException(error, stackTrace: stackTrace);
      return <NotificationData>[];
    }
  }

  /// Update (or set) the readAt timestamp for a notification.
  /// Uses route: /users/{userId}/notifications/{notificationId}
  /// Returns the updated NotificationData when the API responds with it; otherwise null.
  Future<NotificationData?> setNotificationReadAt({
    required String userId,
    required String notificationId,
    DateTime? readAt,
  }) async {
    final String url =
        "${mobileApiRootUrl()}/users/$userId/notifications/$notificationId";
    final String readAtIso =
        (readAt ?? DateTime.now().toUtc()).toIso8601String();

    logPrint(
        "🔄 Marking notification $notificationId as read at $readAtIso...");

    try {
      final storage = const FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");

      // Some backends prefer PATCH; if unsupported, switch to POST with override or accept 2xx generically.
      final Response response = await dio.put(
        url,
        data: {"read_at": readAtIso},
        options: Options(
          headers: {"authorization": "Bearer $accessToken"},
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      // If the API includes a NotificationData (wrapped or raw), parse and persist it.
      if (response.data != null) {
        try {
          final body = response.data;

          // Some endpoints return the whole wrapper { error, status, data }.
          // Others may return raw data or even a string like "OK".
          final dynamic raw =
              (body is Map<String, dynamic> && body.containsKey('data'))
                  ? body['data']
                  : body;

          NotificationData? updated;

          if (raw is Map<String, dynamic>) {
            // Single object
            updated = NotificationData.fromJson(raw);
          } else if (raw is List) {
            // First mappable item, if any
            for (final item in raw) {
              if (item is Map<String, dynamic>) {
                updated = NotificationData.fromJson(item);
                break;
              }
            }
          } else {
            // String/num/bool/null → nothing to parse; fall through to local DB update below.
          }
          /*
         * Write to the db if the response is successful and not empty
         */
          if (_isSuccessful(response)) {
            if (updated != null) {
              await appDatabase.write([updated]);
              providerContainer.invalidate(notificationsCountProvider);
              return updated;
            }
          }
        } catch (error, stackTrace) {
          // Fall through to local DB update below – don't spam logs with type-cast noise.
          logPrint("❌ setNotificationReadAt: parse skipped – $error");
              await Sentry.captureException(error, stackTrace: stackTrace);
        }
      }

      // Fallback path: if API didn't return an object, update the local row directly.
      try {
        final db = await AppDatabase.instance.database;
        await db.update(
          NotificationDataInfo.tableName,
          {
            NotificationDataInfo.readAt.columnName: readAtIso,
          },
          where: '${NotificationDataInfo.id.columnName} = ?',
          whereArgs: [notificationId],
        );
        providerContainer.invalidate(notificationsCountProvider);
      } catch (error, stackTrace) {
          await Sentry.captureException(error, stackTrace: stackTrace);
        logPrint("❌ setNotificationReadAt: local DB update failed – $error");
      }

      return null;
    } on DioException catch (error, stackTrace) {
        await Sentry.captureException(error, stackTrace: stackTrace);
      if (error.response != null) {
        logPrint(
            "❌ DioException (setNotificationReadAt): ${error.response!.statusCode} ${error.response!.data}");
      } else {
        logPrint("❌ DioException (setNotificationReadAt): $error");
      }
      return null;

    } catch (error, stackTrace) {
        await Sentry.captureException(error, stackTrace: stackTrace);
      logPrint("❌  (setNotificationReadAt): $error");
      return null;
    }
  }

/* -----------------------------------------------------------------------------------------------------------------
 * MARK: FCM Tokens
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 */

  /// Register a new FCM token for the authenticated user
  /// POST /fcm-tokens
  Future<Map<String, dynamic>?> registerFcmToken({
    required String fcmToken,
    required String deviceId,
    required String deviceType, // e.g. "ios" | "android"
    required String appVersion,
  }) async {
    final String url = "${mobileApiRootUrl()}/fcm-tokens";
    logPrint("🔄 Registering FCM token... ($deviceType $appVersion)");

    try {
      final storage = const FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");

      final Response response = await dio.post(
        url,
        data: {
          "fcm_token": fcmToken,
          "device_id": deviceId,
          "device_type": deviceType,
          "app_version": appVersion,
        },
        options: Options(
          headers: {"authorization": "Bearer $accessToken"},
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      if (response.data == null) return null;

      final IceCrmResponseData ice = IceCrmResponseData.fromJson(
        response.data,
        dataParser: (raw) => raw,
      );

      final data = ice.data;
      _showMessagesFromResponse(ice);
      if (data is Map<String, dynamic>) return data;
      return null;
    } on DioException catch (e) {
      logPrint("❌ DioException: ${e.response?.statusCode} ${e.response?.data}");
      return null;
    } catch (e) {
      logPrint("❌ $e");
      return null;
    }
  }

  /// Get all FCM tokens for the authenticated user
  /// GET /fcm-tokens
  Future<List<Map<String, dynamic>>> getFcmTokens() async {
    final String url = "${mobileApiRootUrl()}/fcm-tokens";
    // logPrint("Getting FCM tokens...");

    try {
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(url, options: options);
      });

      if (response.data == null) return <Map<String, dynamic>>[];

      final IceCrmResponseData ice = IceCrmResponseData.fromJson(
        response.data,
        dataParser: (raw) => raw,
      );

      final out = <Map<String, dynamic>>[];
      final data = ice.data;
      _showMessagesFromResponse(ice);
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) out.add(item);
        }
      } else if (data is Map<String, dynamic>) {
        out.add(data);
      }
      return out;
    } on DioException catch (e) {
      logPrint("❌ DioException: ${e.response?.statusCode} ${e.response?.data}");
      return <Map<String, dynamic>>[];
    } catch (e) {
      logPrint("❌ $e");
      return <Map<String, dynamic>>[];
    }
  }

  /// Get a specific FCM token by ID
  /// GET /fcm-tokens/{id}
  Future<Map<String, dynamic>?> getFcmTokenById(String id) async {
    final String url = "${mobileApiRootUrl()}/fcm-tokens/$id";
    // logPrint("🔄 Getting FCM token $id...");

    try {
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(url, options: options);
      });

      if (response.data == null) return null;

      final IceCrmResponseData ice = IceCrmResponseData.fromJson(
        response.data,
        dataParser: (raw) => raw,
      );

      final data = ice.data;
      _showMessagesFromResponse(ice);
      if (data is Map<String, dynamic>) return data;
      if (data is List &&
          data.isNotEmpty &&
          data.first is Map<String, dynamic>) {
        return data.first as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      logPrint("❌ DioException: ${e.response?.statusCode} ${e.response?.data}");
      return null;
    } catch (e) {
      logPrint("❌ $e");
      return null;
    }
  }

  /// Update an FCM token by ID
  /// PUT /fcm-tokens/{id}
  Future<Map<String, dynamic>?> updateFcmToken({
    required String id,
    String? deviceId,
    String? deviceType,
    String? appVersion,
    bool? isActive,
  }) async {
    final String url = "${mobileApiRootUrl()}/fcm-tokens/$id";
    logPrint("🔄 Updating FCM token $id...");

    try {
      final storage = const FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");

      final payload = <String, dynamic>{};
      if (deviceId != null) payload["device_id"] = deviceId;
      if (deviceType != null) payload["device_type"] = deviceType;
      if (appVersion != null) payload["app_version"] = appVersion;
      if (isActive != null) payload["is_active"] = isActive;

      final Response response = await dio.put(
        url,
        data: payload,
        options: Options(
          headers: {"authorization": "Bearer $accessToken"},
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      if (response.data == null) return null;

      final IceCrmResponseData ice = IceCrmResponseData.fromJson(
        response.data,
        dataParser: (raw) => raw,
      );

      final data = ice.data;
      _showMessagesFromResponse(ice);
      if (data is Map<String, dynamic>) return data;
      return null;
    } on DioException catch (e) {
      logPrint("❌ DioException: ${e.response?.statusCode} ${e.response?.data}");
      return null;
    } catch (e) {
      logPrint("❌ $e");
      return null;
    }
  }

  /// Deactivate an FCM token by ID
  /// DELETE /fcm-tokens/{id}
  Future<bool> deactivateFcmToken(String id) async {
    final String url = "${mobileApiRootUrl()}/fcm-tokens/$id";
    logPrint("🔄 Deactivating FCM token $id...");

    try {
      final storage = const FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");

      final Response response = await dio.delete(
        url,
        options: Options(
          headers: {"authorization": "Bearer $accessToken"},
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      if (response.data is Map) {
        final map = response.data as Map;
        final dynamic messages = map['messages'];
        if (messages is Iterable) {
          _showSnackBarMessages(messages);
        } else if (messages != null) {
          _showSnackBarMessages([messages]);
        }

        final error = map['error'];
        if (error == false || error == 0 || error == null) {
          return response.statusCode == 200 || response.statusCode == 204;
        }
      }
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      logPrint("❌ DioException: ${e.response?.statusCode} ${e.response?.data}");
      return false;
    } catch (e) {
      logPrint("❌ $e");
      return false;
    }
  }

  /// Deactivate an FCM token by token value
  /// POST /fcm-tokens/deactivate
  Future<bool> deactivateFcmTokenByValue(String fcmToken) async {
    final String url = "${mobileApiRootUrl()}/fcm-tokens/deactivate";
    logPrint("🔄 Deactivating FCM token by value...");

    try {
      final storage = const FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");

      final Response response = await dio.post(
        url,
        data: {"fcm_token": fcmToken},
        options: Options(
          headers: {"authorization": "Bearer $accessToken"},
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      if (response.data is Map) {
        final map = response.data as Map;
        final dynamic messages = map['messages'];
        if (messages is Iterable) {
          _showSnackBarMessages(messages);
        } else if (messages != null) {
          _showSnackBarMessages([messages]);
        }

        final error = map['error'];
        if (error == false || error == 0 || error == null) {
          return response.statusCode == 200 || response.statusCode == 204;
        }
      }
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      logPrint("❌ DioException: ${e.response?.statusCode} ${e.response?.data}");
      return false;
    } catch (e) {
      logPrint("❌ $e");
      return false;
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Seminars
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Get Seminar Sessions from API
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<SeminarSessionData>> getSeminars(
      {String? id, String? badgeId, String? showId}) async {
    final String url = mobileApiRootUrl();

    // logPrint("🔄 Getting seminars...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Form the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      String query = "/seminars";

      if (id != null) {
        query = "/seminars/${id}";
      } else if (badgeId != null) {
        query = "/badges/${badgeId}/seminar-sessions";
      } else if (showId != null) {
        query = "/shows/${showId}/seminar-sessions";
      }

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get("${url}${query}", options: options);
      });

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((seminarSessionAsJson) {
              try {
                return SeminarSessionData.fromJson(seminarSessionAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<SeminarSessionData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<SeminarSessionData> seminarSessions = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(seminarSessions);
      }

      return seminarSessions;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        logPrint("❌ 401 Unauthorized");
        return [];
      }

      logPrint("❌ ${error}");
      return [];
    }
  }

  /* ────────────────────────────────────────────────────────────────────────────
    * MARK: Register a Badge for a SeminarSession
    * ────────────────────────────────────────────────────────────────────────── */
  Future<bool> registerBadgeForSeminarSession({
    required String badgeId,
    required String seminarSessionId,
  }) async {
    final String url =
        '${mobileApiRootUrl()}/seminar-sessions/$seminarSessionId/register-badge/$badgeId';

    logPrint(
        '🔄 Registering badge $badgeId → seminarSession $seminarSessionId...');

    try {
      Response res = await _authorized<Map<String, dynamic>>((options) {
        return dio.post(url, options: options);
      });

      // Success: wrapper {"error":false, ...}
      if (res.statusCode == 200 &&
          res.data is Map &&
          (res.data['error'] == false || res.data['error'] == 0)) {
        logPrint('✅ Registration OK');
        return true;
      }

      logPrint('❌ Registration failed – ${res.statusCode}: ${res.data}');
      return false;
    } on DioException catch (e) {
      logPrint('❌ DioException: ${e.message}');
      return false;
    } catch (e) {
      logPrint('❌ Unhandled error: $e');
      return false;
    }
  }

  /* ────────────────────────────────────────────────────────────────────────────
    * MARK: Unregister a Badge for a SeminarSession
    * ────────────────────────────────────────────────────────────────────────── */
  Future<bool> unregisterBadgeForSeminarSession({
    required String badgeId,
    required String seminarSessionId,
  }) async {
    final String url =
        '${mobileApiRootUrl()}/seminar-sessions/$seminarSessionId/unregister-badge/$badgeId';

    logPrint(
        '🔄 Unregistering badge $badgeId → seminarSession $seminarSessionId...');

    try {
      Response res = await _authorized<Map<String, dynamic>>((options) {
        return dio.post(url, options: options);
      });

      // Success: wrapper {"error":false, ...}
      if (res.statusCode == 200 &&
          res.data is Map &&
          (res.data['error'] == false || res.data['error'] == 0)) {
        logPrint('✅ UnRegistration OK');
        return true;
      }

      logPrint('❌ UnRegistration failed – ${res.statusCode}: ${res.data}');
      return false;
    } on DioException catch (e) {
      logPrint('❌ DioException: ${e.message}');
      return false;
    } catch (e) {
      logPrint('❌ $e');
      return false;
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Seminar Speakers
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Get Seminar Speakers
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<SeminarSpeakerData>> getSeminarSpeakers({int? id}) async {
    final String url = "${mobileApiRootUrl()}/speakers";

    // logPrint("🔄 Getting seminar speakers...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Form the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      String query = "";

      if (id != null) {
        query += "?id=${id}";
      }

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(url, options: options);
      });

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((seminarSpeakerAsJson) {
              try {
                return SeminarSpeakerData.fromJson(seminarSpeakerAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<SeminarSpeakerData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<SeminarSpeakerData> seminarSpeakers = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(seminarSpeakers);
      }

      return seminarSpeakers;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } catch (error) {
      logPrint("❌ ${error}");
      return [];
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: User Notes
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Get User Notes
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<UserNoteData>> getUserNotes(
      {String? id, String? recipientId}) async {
    final String url =
        "${mobileApiRootUrl()}/connections/${recipientId}/comments";

    // logPrint("🔄 Getting user notes...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(url, options: options);
      });

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((userNoteAsJson) {
              try {
                return UserNoteData.fromJson(userNoteAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<UserNoteData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<UserNoteData> userNotes = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(userNotes);
      }

      return userNotes;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } on DioException catch (error) {
      logPrint("❌ Dio error: ${error}");
      rethrow;
    } catch (error) {
      logPrint("❌ ${error}");
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: error,
        type: DioExceptionType.unknown,
      );
    }
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Save User Note
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
  Future<List<UserNoteData>> saveUserNote(
      {UserNoteData? userNote,
      String? noteBody,
      String? recipientId,
      bool persistResponse = true}) async {
    final String url = Uri.encodeFull(
        "${mobileApiRootUrl()}/connections/${recipientId}/comments/${noteBody}");

    logPrint("🔄 Saving user note (connection ID ${recipientId}) to server...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      final storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");

      Response response = await dio.request(url,
          options: Options(
              contentType: Headers.jsonContentType,
              headers: {
                "Authorization": "Bearer ${accessToken}",
                "Content-Type": "application/x-www-form-urlencoded"
              },
              method: "GET", // TODO: FIX //(userNote != null) ? "PUT" : "POST",
              validateStatus: (status) {
                if (status == null) {
                  logPrint("❌ Can't validate status. Status is null.");
                  return false;
                }
                return status < 500;
              }));

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((userNoteAsJson) {
              try {
                return UserNoteData.fromJson(userNoteAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<UserNoteData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<UserNoteData> userNotes = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (persistResponse && _isSuccessful(response)) {
        await _writeIfNotEmpty(userNotes);
      }

      return userNotes;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } catch (error) {
      logPrint("❌ ${error}");
      return [];
    }
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Delete User Note
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
  Future<List<UserNoteData>> deleteUserNote(
      {UserNoteData? userNote, String? id}) async {
    final String url = "${mobileApiRootUrl()}/comments/${id}";

    if (userNote == null && id == null) {
      logPrint("⚠️  A user note or its ID is required.");
      return [];
    }

    logPrint("🔄 Deleting user note ${userNote?.id ?? id} from server...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.delete(url, options: options);
      });

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((userNoteAsJson) {
              try {
                return UserNoteData.fromJson(userNoteAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<UserNoteData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<UserNoteData> userNotes = iceCrmResponse.data ?? [];

      if (_isSuccessful(response)) {
        if (userNotes.isNotEmpty) {
          // Delete user note(s) from database
          for (UserNoteData userNote in userNotes) {
            await appDatabase.delete(
                tableName: UserNoteDataInfo.tableName,
                whereAsMap: {UserNoteDataInfo.id.columnName: userNote.id});
          }
        }
      }
      return userNotes;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } catch (error) {
      logPrint("❌ ${error}");
      return [];
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Connections/Leads
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Get Connections/Leads
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<ConnectionData>> getConnections(
      {required String showId, required String companyId}) async {
    final String url =
        "${mobileApiRootUrl()}/shows/${showId}/companies/${companyId}/connections";

    // logPrint("🔄 Getting connections (Company ID: ${companyId}, Show ID: ${showId})...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */

      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(url, options: options);
      });

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((connectionAsJson) {
              try {
                return ConnectionData.fromJson(connectionAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<ConnectionData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<ConnectionData> connections = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(connections);
      }

      return connections;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } catch (error) {
      logPrint("❌ ${error}");
      return [];
    }
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Rate Connection
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
  Future<List<ConnectionData?>> rateConnection(
      {required String connectionId, required int rating}) async {
    final String url = "${mobileApiRootUrl()}/connections/${connectionId}";

    logPrint("🔄 Rating connection...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      final storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");

      Response response = await dio.put(url,
          data: json.encode({"rating": rating}).replaceAll("\\\"", ""),
          options: Options(
              contentType: Headers.jsonContentType,
              headers: {"Authorization": "Bearer ${accessToken}"},
              validateStatus: (status) {
                if (status == null) {
                  logPrint("❌ Can't validate status. Status is null.");
                  return false;
                }
                return status < 500;
              }));

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((connectionAsJson) {
              try {
                return ConnectionData.fromJson(connectionAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<ConnectionData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<ConnectionData> connections = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(connections);
      }

      return connections;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } catch (error) {
      logPrint("❌ ${error}");
      return [];
    }
  }




    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Create Connection
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    Future<List<ConnectionData?>> createConnection({
        required String badgeId,
        required String companyId,
        required String showId,
        Duration timeout = const Duration(milliseconds: 5000),
        bool persistResponse = true

    }) async {

        final String url = "${mobileApiRootUrl()}/shows/${showId}/companies/${companyId}/connect/${badgeId}";

        final requestId = DateTime.now().microsecondsSinceEpoch;

        logPrint("🔄 Making connection [req=$requestId] for badge=$badgeId company=$companyId show=$showId");

        try {
            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            final storage = FlutterSecureStorage();
            final accessToken = await storage.read(key: "access_token");

            Response response = await dio.post(
                url,
                options: Options(
                    headers: {"authorization": "Bearer ${accessToken}"},
                    sendTimeout: timeout,
                    receiveTimeout: timeout,
                ),
            )
            .timeout(
                timeout,
                onTimeout: () {
                    final error = DioException(
                        requestOptions: RequestOptions(path: url),
                        error:          TimeoutException("createConnection timed out after ${timeout.inSeconds}s"),
                        type:           DioExceptionType.connectionTimeout,
                    );
                    logPrint("❌ Dio timeout: ${error.error}");
                    throw error;
                },
            );

            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            if (response.data == null || response.data.isEmpty) {
                return [];
            }

            IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
                response.data, dataParser: (Object? dataAsJson) {
                    return dataAsJson
                        .ensureList()
                        .map((connectionAsJson) {
                            try {
                                return ConnectionData.fromJson(connectionAsJson,
                                    source: LocationEncoding.api);
                            } catch (error) {
                                logPrint("❌ ${error.toString()}");
                                return null;
                            }
                        })
                        .whereType<ConnectionData>()
                        .toList();
                }
            );

            _showMessagesFromResponse(iceCrmResponse);

            List<ConnectionData> connections = iceCrmResponse.data ?? [];

            logPrint("✅ createConnection[req=$requestId] returned ${connections.length} connection(s): ${connections.map((c) => c.id).join(', ')}");

            /*
             * Write to the db if the response is successful and not empty
             */
            if (persistResponse && _isSuccessful(response)) {
                await _writeIfNotEmpty(connections);
            }

            return connections;

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
        } catch (error) {
            logPrint("❌ ${error}");
            return [];
        }
    }




  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Get Registration Form from API
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<GFormData?> getRegistrationForm() async {
    final String url = "${mobileApiRootUrl()}/registration-form";

    // logPrint("🔄 Getting registration form...");

    try {
      Response response = await dio.get(url);

      Map<String, dynamic> responseData = response.data;

      if (responseData.isNotEmpty) {
        GFormData gform =
            GFormData.fromJson(responseData, source: LocationEncoding.api);
        appDatabase.write(gform);

        return gform;
      } else {
        logPrint("⚠️  Response is empty.");
      }
    } catch (error) {
      logPrint("❌ ${error.toString()}");
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Shows
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Get Shows from API
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<ShowData>> getShows(
      {String? id,
      List<String>? ids,
      bool onlyUpcomingShows = false,
      bool onlyUserRegistered = false}) async {
    final String url = "${mobileApiRootUrl()}/shows";

    // logPrint("🔄 Getting shows...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Form the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      String query =
          "/?only_upcoming_shows=${onlyUpcomingShows.toInt()}&only_user_registered_shows=${onlyUserRegistered.toInt()}";

      if (id != null) {
        query = "/${id}";

        // TODO: Refactor for new API
      } else if (ids != null) {
        query = "?";

        for (var index = 0; index < ids.length; index++) {
          query += "ids[${index}]=${ids[index]}" +
              (index < ids.length - 1 ? "&" : "");
        }
      }

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get("${url}${query}", options: options);
      });

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((showAsJson) {
              try {
                return ShowData.fromJson(showAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<ShowData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<ShowData> shows = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(shows);
      }

      return shows;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } catch (error) {
      logPrint("❌ ${error}");
      return [];
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Users
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Get User from API
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<UserData?> getUser(
      {String? id,
      String? legacyBarcode,
      String? username,
      String? userEmail,
      bool getAdditionalData = false}) async {
    List<UserData> users = await getUsers(
        id: id,
        legacyBarcode: legacyBarcode,
        username: username,
        userEmail: userEmail,
        getAdditionalData: getAdditionalData);
    return users.firstOrNull;
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Get User(s) from API
     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
  Future<List<UserData>> getUsers(
      {String? id,
      String? legacyBarcode,
      String? username,
      String? userEmail,
      bool getAdditionalData = false}) async {
    final String url = "${mobileApiRootUrl()}/users";

    // logPrint("🔄 Getting users...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Form the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
      String query = "";

      if (id != null) {
        query = "/${id}";
      } else if (username != null) {
        // TODO: Refactor for new API
        query = "?search=${username}";
      } else if (userEmail != null) {
        // TODO: Refactor for new API
        query = "?search=${Uri.encodeComponent(userEmail)}";
      } else if (legacyBarcode != null) {
        query = "/legacy-barcode/${legacyBarcode}";
      } else {
        query = "/current";
      }

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get("${url}${query}", options: options);
      });

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((userAsJson) {
              try {
                return UserData.fromJson(userAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<UserData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<UserData> users = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(users);
      }

      return users;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    } catch (error) {
      logPrint("❌ ${error}");
      return [];
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Update User
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<UserData?> updateUser(
      String userId, Map<String, dynamic> formDataAsMap) async {
    final String url = "${mobileApiRootUrl()}/users/${userId}";

    logPrint("🔄 Updating user ${userId}...");

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Format the data
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
      String formDataAsJsonString =
          json.encode(formDataAsMap).replaceAll("\\\"", "");

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
      final storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");

      Response response = await dio.put(url,
          data: formDataAsJsonString,
          options: Options(
            contentType: Headers.jsonContentType,
            headers: {"authorization": "Bearer ${accessToken}"},
          ));

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
      if (response.data == null || response.data.isEmpty) {
        return null;
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((userAsJson) {
              try {
                return UserData.fromJson(userAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<UserData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<UserData> users = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(users);
      }

      return users.firstOrNull;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } catch (error) {
      logPrint("❌ ${error}");
      return null;
    }
  }

  List<String> _extractRegistrationErrorMessages(dynamic raw) {
    final Set<String> messages = <String>{};

    void addIfString(dynamic value) {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          messages.add(trimmed);
        }
      }
    }

    if (raw is Map) {
      addIfString(raw['message']);

      final dynamic errors = raw['errors'];
      if (errors is Map) {
        for (final entry in errors.values) {
          if (entry is Iterable) {
            for (final item in entry) {
              addIfString(item);
            }
          } else {
            addIfString(entry);
          }
        }
      }

      final dynamic messageList = raw['messages'];
      if (messageList is Iterable) {
        for (final item in messageList) {
          addIfString(item);
        }
      }
    } else if (raw is Iterable) {
      for (final item in raw) {
        addIfString(item);
      }
    } else {
      addIfString(raw);
    }

    return messages.toList();
  }

    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Submit the Registration Form
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<List<UserData>?> submitRegistrationForm(Map<String, dynamic> formDataAsMap) async {

        final String url = "${mobileApiRootUrl()}/users/register";

        logPrint("🔄 Preparing registration form for submission...");

        try {
            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Form the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */

            // Convert JSON Map to String and remove escaped double-quotes
            // String formDataAsJsonString = json.encode(formDataAsMap).replaceAll("\\\"", "");

            // Add the platform for source tracking
            formDataAsMap["device_type"] = Platform.isIOS ? "ios" : "android";

            logPrint("✅ Finished preparing form data for submission.");
            logPrint("ℹ️  Form data: ${formDataAsMap}");
            logPrint("🔄 Submitting the registration form...");

            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            Response response = await dio.post(url,
                data: formDataAsMap,
                options: Options(
                    contentType: Headers.jsonContentType,
                    headers: {
                    "Accept": "application/json",
                    },
                    validateStatus: (status) => status != null && status < 500,
                ));

            logPrint("ℹ️  Response: ${response}");

            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            final dynamic rawData = response.data;
            final int statusCode = response.statusCode ?? 0;
            final List<String> extractedErrorMessages = _extractRegistrationErrorMessages(rawData);

            if (statusCode >= 400 && extractedErrorMessages.isNotEmpty) {
                throw RegistrationSubmissionException(extractedErrorMessages);
            }

            if (rawData == null) {
                return null;
            }

            if (rawData is! Map) {
                if (extractedErrorMessages.isNotEmpty) {
                    throw RegistrationSubmissionException(extractedErrorMessages);
                }
                return null;
            }

        late IceCrmResponseData<List<UserData>> iceCrmResponse;
        try {
            final Map<String, dynamic> responseMap =
                Map<String, dynamic>.from(rawData as Map);
            iceCrmResponse = IceCrmResponseData.fromJson(responseMap,
                dataParser: (Object? dataAsJson) {
            return dataAsJson
                .ensureList()
                .map((userAsJson) {
                    try {
                    return UserData.fromJson(userAsJson,
                        source: LocationEncoding.api);
                    } catch (error) {
                    logPrint("❌ ${error.toString()}");
                    return null;
                    }
                })
                .whereType<UserData>()
                .toList();
            });
        } on RegistrationSubmissionException {
            rethrow;
        } catch (error) {
            if (extractedErrorMessages.isNotEmpty) {
            throw RegistrationSubmissionException(extractedErrorMessages);
            }
            logPrint("❌ ${error}");
            return null;
        }

        if (!iceCrmResponse.isSuccess) {
            final List<String> messages = iceCrmResponse.messages.isNotEmpty
                ? iceCrmResponse.messages
                : extractedErrorMessages;
            if (messages.isNotEmpty) {
                throw RegistrationSubmissionException(messages);
            }
        }

        _showMessagesFromResponse(iceCrmResponse);

        List<UserData> users = iceCrmResponse.data ?? [];

        /*
         * Write to the db if the response is successful and not empty
         */
        if (_isSuccessful(response)) {
            await _writeIfNotEmpty(users);
        }

        return users;

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
        } on RegistrationSubmissionException {
            rethrow;

        } catch (error) {
            logPrint("❌ ${error}");
            return null;
        }
    }

  Future<UserData?> submitRegistrationUserStage(
      Map<String, dynamic> formDataAsMap) async {
    final Map<String, dynamic> payload =
        Map<String, dynamic>.from(formDataAsMap)..['stage'] = 'user';
    final users = await submitRegistrationForm(payload);
    if (users == null || users.isEmpty) return null;
    return users.first;
  }

  Future<UserData?> submitRegistrationCompanyStage(
      Map<String, dynamic> formDataAsMap) async {
    final Map<String, dynamic> payload =
        Map<String, dynamic>.from(formDataAsMap)..['stage'] = 'company';
    final users = await submitRegistrationForm(payload);
    if (users == null || users.isEmpty) return null;
    return users.first;
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Survey Questions/Answers
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Get SurveyQuestions for an Exhibitor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<SurveyQuestionData>> getSurveyQuestions(
      {required String exhibitorId}) async {
    final String url =
        "${mobileApiRootUrl()}/exhibitors/${exhibitorId}/survey-questions";

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(
          url,
          options: options,
        );
      });

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((surveyQuestionsAsJson) {
              try {
                return SurveyQuestionData.fromJson(surveyQuestionsAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<SurveyQuestionData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<SurveyQuestionData> surveyQuestions = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      if (_isSuccessful(response)) {
        await _writeIfNotEmpty(surveyQuestions);
      }

      return surveyQuestions;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } catch (error) {
      logPrint("❌ ${error}");
      return [];
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Get SurveyAnswers for a Connection
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<SurveyAnswerData>> getSurveyQuestionsWithAnswers(
      {required String connectionId}) async {
    final String url =
        "${mobileApiRootUrl()}/connections/${connectionId}/survey-questions-with-answers";

    try {
      Response response = await _authorized<Map<String, dynamic>>((options) {
        return dio.get(
          url,
          options: options,
        );
      });

      // Handle the response
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      // Extract the nested "data" array from the response
      final rawList = (response.data['data'] as List<dynamic>);
      final surveyAnswers = rawList
          .whereType<Map<String, dynamic>>()
          .map((jsonMap) =>
              SurveyAnswerData.fromJson(jsonMap, source: LocationEncoding.api))
          .toList();

      // Show any API messages
      final messages = (response.data['messages'] as List?) ?? [];
      _showSnackBarMessages(messages);

      /*
             * Write to the db if the response is successful and not empty
             */
      // if (_isSuccessful(response)) {
      //     await _writeIfNotEmpty(surveyAnswers);
      // }

      return surveyAnswers;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } catch (error) {
      logPrint("❌ ${error}");
      return [];
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Update SurveyAnswers
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<SurveyAnswerData>> updateSurveyAnswers(
      {required String connectionId,
      required String surveyQuestionId,
      required String answer}) async {
    final String url =
        "${mobileApiRootUrl()}/connections/$connectionId/survey-questions/${surveyQuestionId}/answer";

    try {
      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Make the request
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      final storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: "access_token");

      Response response = await dio.put(url,
          data: json.encode(
              {"answer": answer, "answer_type": "text"}).replaceAll("\\\"", ""),
          options: Options(
              contentType: Headers.jsonContentType,
              headers: {"Authorization": "Bearer ${accessToken}"},
              validateStatus: (status) {
                if (status == null) {
                  logPrint("❌ Can't validate status. Status is null.");
                  return false;
                }
                return status < 500;
              }));

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             *  Handle the response
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
      if (response.data == null || response.data.isEmpty) {
        return [];
      }

      IceCrmResponseData iceCrmResponse = IceCrmResponseData.fromJson(
          response.data, dataParser: (Object? dataAsJson) {
        return dataAsJson
            .ensureList()
            .map((surveyAnswersAsJson) {
              try {
                return SurveyAnswerData.fromJson(surveyAnswersAsJson,
                    source: LocationEncoding.api);
              } catch (error) {
                logPrint("❌ ${error.toString()}");
                return null;
              }
            })
            .whereType<SurveyAnswerData>()
            .toList();
      });

      _showMessagesFromResponse(iceCrmResponse);

      List<SurveyAnswerData> surveyAnswers = iceCrmResponse.data ?? [];

      /*
             * Write to the db if the response is successful and not empty
             */
      // if (_isSuccessful(response)) {
      //     await _writeIfNotEmpty(surveyAnswers);
      // }

      return surveyAnswers;

      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         *  Handle errors
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - */
    } catch (error) {
      logPrint("❌ ${error}");
      return [];
    }
  }
}
