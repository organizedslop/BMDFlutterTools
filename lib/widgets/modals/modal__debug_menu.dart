/*
 *  Debug Menu
 *
 * Created by:  Blake Davis
 * Description: A widget which displays a modal debugging menu
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_sficon/flutter_sficon.dart";





/* ======================================================================================================================
 * MARK: Debug Menu
 * ------------------------------------------------------------------------------------------------------------------ */
class DebugMenu extends ConsumerStatefulWidget {


    DebugMenu({ super.key });


    @override
    ConsumerState<DebugMenu> createState() => _DebugMenuState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _DebugMenuState extends ConsumerState<DebugMenu> {

    final appDatabase = AppDatabase.instance;
    final storage     = FlutterSecureStorage();

    Future<String?>? username,
                     userEmail;

    final TextEditingController verificationCodeController = TextEditingController();

    bool refresh = false;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();
        username  = storage.read(key: "username");
        userEmail = storage.read(key: "user_email");
    }



    Widget _buildSection(BuildContext context, {String? title, required List<Widget> children, bool showBackground = true}) {
        final sectionContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                if (title != null && title.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(title, style: beTextTheme.headingSecondary),
                    ),
                ...children,
            ],
        );

        if (!showBackground) {
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: sectionContent,
            );
        }

        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
                decoration: BoxDecoration(
                    color: beColorScheme.background.secondary,
                    borderRadius: BorderRadius.circular(mediumRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: sectionContent,
            ),
        );
    }


    Widget _buildLabelValueRow({
        Key? key,
        String? label,
        Widget? labelWidget,
        Object? value,
        Widget? valueWidget,
        EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        bool ellipsizeValue = false,
        int labelFlex = 3,
        int valueFlex = 6,
    }) {
        final Widget resolvedLabel = labelWidget ?? Text(label ?? "", style: beTextTheme.bodyPrimary);

        Widget resolvedValue;
        if (valueWidget != null) {
            resolvedValue = valueWidget;
        } else if (value is Widget) {
            resolvedValue = value;
        } else {
            final textValue = value?.toString() ?? "null";
            resolvedValue = Text(
                textValue,
                style: beTextTheme.bodyPrimary,
                textAlign: TextAlign.end,
                overflow: ellipsizeValue ? TextOverflow.ellipsis : TextOverflow.visible,
                maxLines: ellipsizeValue ? 1 : null,
            );
        }

        return Padding(
            key: key,
            padding: padding,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Expanded(
                        flex: labelFlex,
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: resolvedLabel,
                        ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        flex: valueFlex,
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: resolvedValue,
                        ),
                    )
                ],
            ),
        );
    }



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {
        const channel = MethodChannel("icmMethodChannel");

        return FutureBuilder(
            future: Future.wait([
                FlutterSecureStorage().readAll(),
                appDatabase.read(tableName: "state_data"),
                channel.invokeMethod("getBuildTime"),
            ]),
            builder: (context, snapshot) {

                // Display loading indicator
                if (snapshot.connectionState != ConnectionState.done) {
                    return Center(child: CircularProgressIndicator());
                }

                // Display error message
                if (snapshot.hasError) {
                    return Center(child: Text("Snapshot Error: ${snapshot.error.toString()}", style: beTextTheme.bodyPrimary));
                }

                // Display not-found message
                if (!snapshot.hasData) {
                    return Center(child: Text("No data was found.", style: beTextTheme.bodyPrimary));
                }

                final List<dynamic> data = snapshot.data! as List<dynamic>;
                final Map<dynamic, dynamic> savedState = data[1]["data"] as Map<dynamic, dynamic>;
                final dynamic buildTime = data[2];

                return AlertDialog(
                    backgroundColor: beColorScheme.background.tertiary,
                    contentPadding:  EdgeInsets.only(top: 0, right: 12, bottom: 0, left: 12),
                    insetPadding:    EdgeInsets.all(16),
                    shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title:           Text("Debug", style: beTextTheme.headingPrimary),
                    titlePadding:    EdgeInsets.only(top: 12, right: 0, bottom: 0, left: 20),
                    content:         SizedBox(
                        width: double.maxFinite,
                        child: SizedBox(
                            height: 550,
                            child: ListView(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                children: [

                                    // Build
                                    _buildSection(
                                        context,
                                        title: "App State",
                                        children: [
                                            _buildLabelValueRow(label: "Build", value: buildTime),
                                            _buildLabelValueRow(label: "kDebugMode", value: kDebugMode),
                                            _buildLabelValueRow(label: "developmentFeaturesEnabled", value: developmentFeaturesEnabled),
                                        ],
                                    ),

                                    // State
                                    _buildSection(
                                        context,
                                        title: "App State",
                                        children: [
                                            _buildLabelValueRow(
                                                key: const Key("debug_modal__debugging_mode_toggle_button"),
                                                label: "Debugging Mode",
                                                valueWidget: Switch(
                                                    value: ref.read(isDebuggingProvider),
                                                    onChanged: (value) {
                                                        ref.read(isDebuggingProvider.notifier).state = value;
                                                        setState(() { refresh = !refresh; });
                                                    },
                                                ),
                                                padding: EdgeInsets.zero,
                                            ),
                                            _buildLabelValueRow(
                                                key: const Key("debug_modal__custom_server_toggle_button"),
                                                label: "Custom Sever",
                                                valueWidget: Switch(
                                                    value: ref.read(isDevelopmentProvider),
                                                    onChanged: (value) {
                                                        ref.read(isDevelopmentProvider.notifier).state = value;
                                                        setState(() { refresh = !refresh; });
                                                    },
                                                ),
                                                padding: EdgeInsets.zero,
                                            ),
                                            _buildLabelValueRow(
                                                key: const Key("debug_modal__custom_server_field"),
                                                label: "Server",
                                                valueWidget: ref.read(isDevelopmentProvider)
                                                    ? Container(
                                                        margin: const EdgeInsets.only(left: 24),
                                                        child: TextField(
                                                            controller: TextEditingController()..text = ref.read(developmentSiteBaseUrlProvider),
                                                            onChanged: (text) { ref.read(developmentSiteBaseUrlProvider.notifier).state = text; },
                                                            textAlign: TextAlign.end,
                                                        ),
                                                    )
                                                    : null,
                                                value: ref.read(isDevelopmentProvider) ? null : ref.read(productionSiteBaseUrlProvider),
                                                valueFlex: 8,
                                                labelFlex: 3,
                                                ellipsizeValue: !ref.read(isDevelopmentProvider),
                                            ),
                                            _buildLabelValueRow(
                                                key: const Key("debug_modal__https_toggle_button"),
                                                label: "HTTPS",
                                                valueWidget: Switch(
                                                    value: ref.read(protocolIsHttpsProvider),
                                                    onChanged: (value) {
                                                        ref.read(protocolIsHttpsProvider.notifier).state = value;
                                                        setState(() { refresh = !refresh; });
                                                    },
                                                ),
                                                padding: EdgeInsets.zero,
                                            ),
                                            _buildLabelValueRow(
                                                labelWidget: TextButton.icon(
                                                    onPressed: () { ApiClient.instance.refreshToken(); },
                                                    iconAlignment: IconAlignment.end,
                                                    icon: SFIcon(
                                                        SFIcons.sf_arrow_clockwise,
                                                        color: BeColorSwatch.blue,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                    ),
                                                    style: ButtonStyle(padding: WidgetStateProperty.all(const EdgeInsets.only(top: 0, right: 8, bottom: 0, left: 0))),
                                                    label: Text(
                                                        "Access Token",
                                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: BeColorSwatch.blue, fontWeight: FontWeight.bold),
                                                    ),
                                                ),
                                                value: (savedState["access_token"] ?? "null").toString().replaceAll("\"", ""),
                                                valueFlex: 8,
                                                labelFlex: 4,
                                                ellipsizeValue: true,
                                            ),
                                            _buildLabelValueRow(
                                                label: "Send FCM",
                                                valueWidget: TextButton.icon(
                                                    onPressed: () async {
                                                        logPrint("🔄 Sending FCM");

                                                        String? fcmToken = await const FlutterSecureStorage().read(key: "fcm_token");
                                                        String? userId   = ref.read(userProvider)?.id;

                                                        if (fcmToken == null) {
                                                            logPrint("⚠️  fcmToken is null");
                                                            return;
                                                        }
                                                        if (userId == null) {
                                                            logPrint("⚠️  userId is null");
                                                            return;
                                                        }
                                                        final ok = await ApiClient.instance.sendFcmNotificationToUser(
                                                            userId: userId,
                                                            token:  fcmToken,
                                                            title:  "Debug FCM",
                                                            body:   "Sent from Debug Menu",
                                                        );
                                                        logPrint("✅ FCM send returned: ${ok}");
                                                    },
                                                    icon: SFIcon(SFIcons.sf_bell, color: BeColorSwatch.blue, fontSize: 16),
                                                    label: Text("Send", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: BeColorSwatch.blue, fontWeight: FontWeight.bold)),
                                                    style: ButtonStyle(padding: WidgetStateProperty.all(const EdgeInsets.only(top: 0, right: 8, bottom: 0, left: 0))),
                                                ),
                                                valueFlex: 8,
                                            ),
                                            _buildLabelValueRow(label: "User", value: ref.read(userProvider)?.name.full, valueFlex: 8, ellipsizeValue: true),
                                            _buildLabelValueRow(label: "Badge", value: ref.read(badgeProvider)?.id, valueFlex: 8, ellipsizeValue: true),
                                            _buildLabelValueRow(label: "Company", value: ref.read(companyProvider)?.name, valueFlex: 8, ellipsizeValue: true),
                                            _buildLabelValueRow(label: "Job Title", value: ref.read(companyUserProvider)?.jobTitle, valueFlex: 8, ellipsizeValue: true),
                                            _buildLabelValueRow(label: "Show", value: ref.read(showProvider)?.title, valueFlex: 8, ellipsizeValue: true),
                                            _buildLabelValueRow(
                                                label: "Lead Retrieval",
                                                valueWidget: Switch(
                                                    value: ref.read(badgeProvider)?.hasLeadScannerLicense ?? false,
                                                    onChanged: (value) {
                                                        BadgeData? newBadgeState = ref.read(badgeProvider);
                                                        if (newBadgeState != null) {
                                                            newBadgeState.hasLeadScannerLicense = value;
                                                            ref.read(badgeProvider.notifier).update(newBadgeState);
                                                            setState(() { refresh = !refresh; });
                                                        }
                                                    },
                                                ),
                                                padding: EdgeInsets.zero,
                                            ),
                                        ],
                                    ),


                                    // Database
                                    if (ref.read(userProvider) != null)
                                        _buildSection(
                                            context,
                                            title: "Saved State",
                                            children: [
                                                for (final entry in savedState.entries)
                                                    _buildLabelValueRow(
                                                        label: entry.key.toString(),
                                                        value: entry.value,
                                                        valueFlex: 7,
                                                        ellipsizeValue: true,
                                                    ),
                                            ],
                                        ),


                                    // Bottom spacer for more comfortable scrolling
                                    const SizedBox(height: 60),
                                ],
                            ),
                        ),
                    ),
                );
            }
        );
    }
}




/* ======================================================================================================================
 * MARK: Debug Menu Toggle
 * ------------------------------------------------------------------------------------------------------------------ */
class DebugMenuToggle extends StatelessWidget {

    static const Key rootKey = Key("debug_menu_toggle_button");


    DebugMenuToggle({ super.key });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Container(
            alignment: AlignmentDirectional.centerEnd,
            height:    50,
            child:     IconButton(
                key:       rootKey,
                onPressed: () { showDialog(context: context, builder: (BuildContext context) => DebugMenu()); },
                icon:      Container(
                    decoration: BoxDecoration(
                        color:        BeColorSwatch.magenta,
                        borderRadius: BorderRadius.circular(fullRadius)
                    ),
                    width:  16,
                    height: 16,
                )
            )
        );
    }
}
