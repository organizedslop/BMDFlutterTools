/*
 * QR Code Scanner
 *
 * Created by:  Blake Davis
 * Description: A widget for scanning QR codes
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "dart:convert";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/services/analytics_service.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/services/connection_retry_service.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/widgets/debug/debug__text.dart";
import "package:bmd_flutter_tools/widgets/modals/loading.dart";
import "package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart";
import "package:collection/collection.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "package:string_validator/string_validator.dart";
import "package:uuid/uuid.dart";




/* ======================================================================================================================
 * MARK: QR Code Scanner
 * ------------------------------------------------------------------------------------------------------------------ */
class BadgeScanner extends ConsumerStatefulWidget {

    Barcode? _barcode;

    bool _popup = false;

    static const Key rootKey = Key("badge_scanner__root");

    String? _scannedUsername;

    final String? testInjectedBarcode;


    BadgeScanner({ super.key,
                    this.testInjectedBarcode
    });


    @override
    ConsumerState<BadgeScanner> createState() => _BadgeScannerState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _BadgeScannerState extends ConsumerState<BadgeScanner> {

    bool makingRequest = false;

    TextEditingController simulatedScanStringController = TextEditingController(text: "03D8B85563A2F6908ACC");

    late MobileScannerController _scannerController;

    // Tap feedback state
    final List<_TapEffect> _tapEffects = <_TapEffect>[];
    void _addTapEffect(Offset pos) {
      setState(() {
        _tapEffects.add(_TapEffect(pos));
      });
    }

    // Key to measure the full-screen gesture layer for tap-to-focus
    final GlobalKey _gestureLayerKey = GlobalKey();

    // Best-effort tap-to-focus using MobileScannerController's optional API
    Future<void> _focusAt(Offset localPosition) async {
      try {
        final ctx = _gestureLayerKey.currentContext;
        if (ctx == null) return;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box == null) return;
        final size = box.size;
        if (size.width <= 0 || size.height <= 0) return;

        // Normalize to 0..1 in preview coordinates
        final nx = (localPosition.dx / size.width).clamp(0.0, 1.0);
        final ny = (localPosition.dy / size.height).clamp(0.0, 1.0);

        // Call into controller if the API exists (different versions expose different names)
        final dynamic ctrl = _scannerController;
        try {
          await ctrl.setFocusPoint(Offset(nx, ny));
          return;
        } catch (_) {}
        try {
          await ctrl.focus(Offset(nx, ny));
          return;
        } catch (_) {}
        try {
          await ctrl.setFocusPointOfInterest(Offset(nx, ny));
          return;
        } catch (_) {}
      } catch (_) {}
    }

    // Restart scanning to nudge detection after a tap-to-focus
    Future<void> _nudgeScan() async {
      try {
        // Avoid stopping the preview to prevent flicker; just ensure scanning is active
        await _scannerController.start();
      } catch (_) {}
      if (mounted) {
        setState(() { makingRequest = false; });
      }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        _scannerController = MobileScannerController();

        // If running in test and a barcode was injected, process it automatically
        if (widget.testInjectedBarcode != null) {

            // Delay slightly to allow build/context readiness
            WidgetsBinding.instance.addPostFrameCallback((_) {
                handleScannedCodeString(widget.testInjectedBarcode!, context);
            });
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Deactivate
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void deactivate() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _scannerController.stop();
        });

        super.deactivate();
    }



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {

        widget._scannedUsername = null;
        widget._popup = false;

        _scannerController.dispose();

        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Show Loading Indicator
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    void showLoadingIndicator(BuildContext context) {
        if (context.mounted) {
            showDialog(
                context:            context,
                barrierDismissible: false,
                builder:            (BuildContext context) => LoadingModal(text: "Collecting lead...", cancellable: true, cancelAction: (){ }),
            );
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Handle Scanned Code
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    void handleScannedCodeString(String barcodeString, BuildContext context) {
        if (!mounted) return;

        // Show loading indicator immediately
        showLoadingIndicator(context);

        // Defer heavy processing until after the first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
            logPrint("🔄 Processing scanned code...");
            _processScannedCode(barcodeString, context).whenComplete(() {
                // Dismiss the loading indicator when done
                // if (context.mounted) Navigator.of(context).pop();
            });
        });
    }

    Future<void> _processScannedCode(String barcodeString, BuildContext context) async {
      String scannedBadgeId = Uri.parse(barcodeString).path;
      String scannedUserId  = "";

      BadgeData? scannedBadge;
      UserData? scannedUser;
      BadgeData  currentBadge = ref.read(badgeProvider)!;

      try {
        /*
         * Check network connection
         */
        logPrint("🔄 Checking network connection...");

        final connectivity = await Connectivity().checkConnectivity();

        if (connectivity == ConnectivityResult.none) {
            logPrint("🔄 No network connection detected. Saving lead locally...");

            // Offline: save locally
            final pending = ConnectionData(
                id:          Uuid().v4(),
                badgeId:     scannedBadgeId,
                badgeUserId: null,
                companyId:   currentBadge.companyId!,
                companyName: ref.read(companyProvider)!.name,
                dateCreated: DateTime.now().toIso8601String(),
                dateSynced:  null,
                showId:      currentBadge.showId,
            );
            await AppDatabase.instance.write(pending);

            logPrint("✅ Saved lead to local database.");

            // Dismiss the loading indicator
            appRouter.pop();

            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:  Text("There was a problem connecting to the network.\n\nThe data is saved on your device and will sync when network connection is restored."),
                duration: Duration(seconds: 10)
            )
        );
            unawaited(AnalyticsService.instance.logEvent(
              "lead_scan_offline",
              parameters: {
                "badge_id": scannedBadgeId,
                "company_id": currentBadge.companyId ?? "",
                "show_id": currentBadge.showId,
              },
            ));
            return; // skip server call

        } else {
            logPrint("✅ Network connection detected.");
        }

        /*
         * Parse the scanned data as a UUID
         */
        if (scannedBadgeId.isUUID(4)) {
            final List<ConnectionData?> connections = await ApiClient.instance.createConnection(
                badgeId:   scannedBadgeId,
                companyId: currentBadge.companyId!,
                showId:    currentBadge.showId,
            );

            if (connections.isEmpty) {
              throw DioException(
                requestOptions: RequestOptions(path: 'createConnection'),
                error: 'Connection response was empty',
                type: DioExceptionType.badResponse,
              );
            }

            ApiClient.instance.getBadges(id: scannedBadgeId).then((scannedBadges) {
                scannedBadge = scannedBadges.firstOrNull;
                if (scannedBadge != null) {
                    ApiClient.instance.getUser(id: scannedBadge!.userId).then((scannedUserData) {
                        scannedUser = scannedUserData;
                    });
                }
            });

            final connection = connections.first!;

            // Dismiss the loading indicator
            appRouter.pop();

            // Pop to the ConnectionsList if it exists on the stack
            if (navigatorObserver.containsRouteNamed("connections")) {
              Navigator.of(context).popUntil((route) => route.settings.name == "connections");

            // Otherwise, replace the BadgeScanner with ConnectionsList
            } else {
              appRouter.pushReplacementNamed("connections");
            }


            // Go to the newly scanned connection
            appRouter.pushNamed(
                "connection info",
                pathParameters: {
                    "connection": json.encode(connection.toJson(destination: LocationEncoding.database)),
                },
                extra: {
                    "badge": scannedBadge,
                    "user":  scannedUser,
                },
            );
            unawaited(AnalyticsService.instance.logEvent(
              "lead_scanned",
              parameters: {
                "badge_id": scannedBadgeId,
                "company_id": currentBadge.companyId ?? "",
                "show_id": currentBadge.showId,
                "source": "uuid",
              },
            ));

        /*
         * Attempt to parse the scanned data as a legacy barcode
         */
        } else if (scannedBadgeId.length == 20 && isAlphanumeric(scannedBadgeId)) {

            logPrint("ℹ️  Detected legacy badge...");

            UserData? scannedUser = await ApiClient.instance.getUser(legacyBarcode: scannedBadgeId);

          if (scannedUser != null) {
            scannedUserId = scannedUser.id;
            scannedBadge = scannedUser.badges.firstWhereOrNull((b) => b.showId == currentBadge.showId);

            if (scannedBadge != null) {

              final connections = await ApiClient.instance.createConnection(
                badgeId:   scannedBadgeId,
                companyId: currentBadge.companyId!,
                showId:    currentBadge.showId,
              );

              if (connections.isEmpty) {
                throw DioException(
                  requestOptions: RequestOptions(path: 'createConnection'),
                  error: 'Connection response was empty',
                  type: DioExceptionType.badResponse,
                );
              }

              final connection = connections.first!;

              // Dismiss the loading indicator
              appRouter.pop();

              // Pop to the ConnectionsList if it exists on the stack
              if (navigatorObserver.containsRouteNamed("connections")) {
                Navigator.of(context).popUntil((route) => route.settings.name == "connections");

              // Otherwise, replace the BadgeScanner with ConnectionsList
              } else {
                appRouter.pushReplacementNamed("connections");
              }

              // Go to the newly scanned connection
              appRouter.pushNamed(
                "connection info",
                pathParameters: {
                  "connection": json.encode(connection.toJson(destination: LocationEncoding.database)),
                },
                extra: {
                  "badge": scannedBadge,
                  "user":  scannedUser,
                },
              );
              unawaited(AnalyticsService.instance.logEvent(
                "lead_scanned",
                parameters: {
                  "badge_id": scannedBadgeId,
                  "company_id": currentBadge.companyId ?? "",
                  "show_id": currentBadge.showId,
                  "source": "legacy",
                },
              ));

            } else {
              appRouter.pop();
              scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(content: Text("Scanned user does not have a badge for the current show.")),
              );
            }
          } else {
            final pendingLegacyConnection = ConnectionData(
              id:            Uuid().v4(),
              badgeId:       scannedBadgeId,
              legacyBadgeId: scannedBadgeId,
              badgeUserId:   null,
              companyId:     currentBadge.companyId,
              companyName:   ref.read(companyProvider)?.name,
              dateCreated:   DateTime.now().toIso8601String(),
              dateSynced:    null,
              showId:        currentBadge.showId,
            );

            await AppDatabase.instance.write(pendingLegacyConnection);

            // Try to sync immediately; if offline it will queue for later.
            unawaited(ConnectionRetryService.instance.retryPendingConnections());
            unawaited(AnalyticsService.instance.logEvent(
              "legacy_lead_queued",
              parameters: {
                "legacy_badge_id": scannedBadgeId,
                "company_id": currentBadge.companyId ?? "",
                "show_id": currentBadge.showId,
              },
            ));

            appRouter.pop();
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text("Legacy badge detected. This lead's info will be made available after the end of the show.")),
            );
            logPrint("ℹ️  Queued legacy badge scan (${scannedBadgeId}) for syncing.");
          }
        } else {
          appRouter.pop();
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text("Scanned code is not a recognized badge format.")),
          );
          logPrint("⚠️ Scanned code is not 20-character alphanumeric (${scannedBadgeId}).");
        }

        setState(() {
          widget._popup = true;
          widget._scannedUsername = scannedUserId;
        });

      } on DioException catch (error) {
        // Dismiss the loading indicator
        appRouter.pop();

        logPrint("🛜  Network error ($error), caching connection locally...");

        /*
         * Write the connection to the database to sync to the server later
         */
        final pendingConnection = ConnectionData(
            id:          Uuid().v4(),
            badgeId:     scannedBadgeId,
            badgeUserId: scannedBadge?.userId,
            companyId:   currentBadge.companyId!,
            companyName: ref.read(companyProvider)!.name,
            dateCreated: DateTime.now().toIso8601String(),
            dateSynced:  null,
            showId:      currentBadge.showId,
        );

        await AppDatabase.instance.write(pendingConnection);
        unawaited(AnalyticsService.instance.logEvent(
          "lead_scan_retry_scheduled",
          parameters: {
            "badge_id": scannedBadgeId,
            "company_id": currentBadge.companyId ?? "",
            "show_id": currentBadge.showId,
            "error_type": "dio_exception",
          },
        ));

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "There was a problem connecting to the network.\n\nThe data is saved on your device and will sync when network connection is restored.",
            ),
            duration: const Duration(seconds: 15),
          ),
        );

        return;
      } catch (error) {
        appRouter.pop();
        logPrint("❌ Unexpected error while processing badge: $error");
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Something went wrong while collecting the lead. Please try again.'),
          ),
        );
        return;
      }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Handle Barcode
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<void> _handleBarcode(BuildContext context, BarcodeCapture barcodes) async {
        if (!mounted) return;

        final barcodeString = barcodes.barcodes.firstOrNull?.displayValue;

        if (barcodeString == null) {
            logPrint("⚠️  barcodeString is null.");
            setState(() { makingRequest = false; });
            appRouter.pop();
            return;
        }
        handleScannedCodeString(barcodeString, context);

        setState(() { makingRequest = true; });
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {
        return WillPopScope(
            key:       BadgeScanner.rootKey,
            onWillPop: () async {
                _scannerController.stop();
                return true;
            },
            child: Scaffold(
                appBar: PrimaryNavigationBar(
                    title:    "Scanner",
                    subtitle: ref.read(showProvider)?.title
                ),
                backgroundColor: beColorScheme.background.inverse,
                body: Stack(
                    children: [
                        MobileScanner(
                            controller: _scannerController,
                            onDetect:   (barcodes) {
                                if (!makingRequest) {
                                    _handleBarcode(context, barcodes);
                                    setState(() {
                                        makingRequest = true;
                                    });
                                }
                            }
                        ),
                        // Capture taps to show visual feedback
                        Positioned.fill(
                          child: GestureDetector(
                            key: _gestureLayerKey,
                            behavior: HitTestBehavior.translucent,
                            onTapDown: (details) {
                              _addTapEffect(details.localPosition);
                              _focusAt(details.localPosition);
                              _nudgeScan();
                            },
                            child: const SizedBox.expand(),
                          ),
                        ),
                        // Render tap effects
                        ..._tapEffects.map((e) => Positioned(
                              left: e.position.dx - 24,
                              top:  e.position.dy - 24,
                              child: TweenAnimationBuilder<double>(
                                key: e.key,
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 400),
                                onEnd: () {
                                  if (mounted) {
                                    setState(() { _tapEffects.remove(e); });
                                  }
                                },
                                builder: (context, t, child) {
                                  final size = 16 + (48 * t);
                                  final opacity = (1 - t).clamp(0.0, 1.0);
                                  return Opacity(
                                    opacity: opacity,
                                    child: Container(
                                      width: size,
                                      height: size,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.35),
                                        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.0),
                                        borderRadius: BorderRadius.circular(fullRadius)
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )),
                        if (ref.read(isDebuggingProvider))
                          Positioned(
                            top:   16,
                            left:  16,
                            right: 16,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: simulatedScanStringController,
                                    style:      const TextStyle(color: BeColorSwatch.magenta),
                                    decoration: InputDecoration(
                                      isDense:   true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      border:    OutlineInputBorder().copyWith(borderRadius: BorderRadius.circular(fullRadius)),
                                      filled:    true,
                                      fillColor: Colors.transparent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    handleScannedCodeString(simulatedScanStringController.text, context);
                                  },
                                  child: DebugText(
                                    "Simulate scan",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        /*
                         * Go to leads list button
                         */
                        Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child:   Align(
                                alignment: AlignmentDirectional.bottomCenter,
                                child:     TextButton(
                                    onPressed: () {
                                        _scannerController.stop();
                                        if (!context.mounted) { return; }
                                        context.pushReplacementNamed("connections");
                                    },
                                    child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment:  MainAxisAlignment.end,
                                        mainAxisSize:       MainAxisSize.min,
                                        spacing:            6,
                                        children: [
                                            Text(
                                                "Go to leads list",
                                            ),
                                            SFIcon(
                                                SFIcons.sf_chevron_right,
                                                fontSize: 14,
                                            )
                                        ]
                                    )
                                )
                            )
                        )
                    ]
                )
            )
        );
    }
}

class _TapEffect {
  final Offset position;
  final Key key = UniqueKey();
  _TapEffect(this.position);
}
