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
import "package:bmd_flutter_tools/widgets/inset_list.dart";
import "package:bmd_flutter_tools/widgets/inset_list_section.dart";
import "package:bmd_flutter_tools/widgets/list_value_item.dart";
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

                return AlertDialog(
                    backgroundColor: beColorScheme.background.tertiary,
                    contentPadding:  EdgeInsets.only(top: 0, right: 12, bottom: 0, left: 12),
                    insetPadding:    EdgeInsets.all(16),
                    shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title:           Text("Debug", style: beTextTheme.headingPrimary),
                    titlePadding:    EdgeInsets.only(top: 12, right: 0, bottom: 0, left: 20),
                    content:         SizedBox(
                        width: double.maxFinite,
                        child: Container(
                            height: 550,
                            child:  InsetList(
                                children: [

                                    // Build
                                    InsetListSection(
                                        title:    "App State",
                                        children: [
                                            ListValueItem(
                                                label: "Build",
                                                value: snapshot.data![2]
                                            ),
                                            ListValueItem(
                                                label: "kDebugMode",
                                                value: kDebugMode
                                            ),
                                            ListValueItem(
                                                label: "developmentFeaturesEnabled",
                                                value: developmentFeaturesEnabled
                                            ),
                                        ]
                                    ),

                                    // State
                                    InsetListSection(
                                        title:    "App State",
                                        children: [
                                            ListValueItem(
                                                key:     const Key("debug_modal__debugging_mode_toggle_button"),
                                                label:   "Debugging Mode",
                                                padding: EdgeInsets.zero,
                                                value:   Switch(
                                                    value:     ref.read(isDebuggingProvider),
                                                    onChanged: (value) {
                                                        ref.read(isDebuggingProvider.notifier).state = value;
                                                        setState(() { refresh = !refresh; });
                                                    }
                                                )
                                            ),
                                            ListValueItem(
                                                key:     const Key("debug_modal__custom_server_toggle_button"),
                                                label:   "Custom Sever",
                                                padding: EdgeInsets.zero,
                                                value:   Switch(
                                                    value:     ref.read(isDevelopmentProvider),
                                                    onChanged: (value) {
                                                        ref.read(isDevelopmentProvider.notifier).state = value;
                                                        setState(() { refresh = !refresh; });
                                                    }
                                                )
                                            ),
                                            ListValueItem(
                                                key:         const Key("debug_modal__custom_server_field"),
                                                label:       "Server",
                                                elliptValue: true,
                                                value:       ref.read(isDevelopmentProvider) ? Container(
                                                    margin: EdgeInsets.only(left: 24),
                                                    child:  TextField(
                                                        controller:  TextEditingController()..text = ref.read(developmentSiteBaseUrlProvider),
                                                        onChanged:   (text) { ref.read(developmentSiteBaseUrlProvider.notifier).state = text; },
                                                        textAlign:   TextAlign.end,
                                                    )) : ref.read(productionSiteBaseUrlProvider),
                                                valueFlex:   8,
                                            ),
                                            ListValueItem(
                                                key:     const Key("debug_modal__https_toggle_button"),
                                                label:   "HTTPS",
                                                padding: EdgeInsets.zero,
                                                value:   Switch(
                                                    value:     ref.read(protocolIsHttpsProvider),
                                                    onChanged: (value) {
                                                    ref.read(protocolIsHttpsProvider.notifier).state = value;
                                                    setState(() { refresh = !refresh; });
                                                    }
                                                )
                                            ),
                                            ListValueItem(
                                                elliptValue: true,
                                                label: TextButton.icon(
                                                    onPressed: () { ApiClient.instance.refreshToken(); },
                                                    iconAlignment: IconAlignment.end,
                                                    icon:      SFIcon(SFIcons.sf_arrow_clockwise,
                                                        color:      BeColorSwatch.blue,
                                                        fontSize:   16,
                                                        fontWeight: FontWeight.bold,
                                                    ),
                                                    style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.only(top: 0, right: 8, bottom: 0, left: 0))),
                                                    label: Text("Access Token", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: BeColorSwatch.blue, fontWeight: FontWeight.bold)),
                                                ),
                                                value:     (snapshot.data![1]["data"]["access_token"] ?? "null").replaceAll("\"", ""),
                                                valueFlex: 8,
                                            ),
                                            ListValueItem(
                                                label: "Send FCM",
                                                value: TextButton.icon(
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
                                                    style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.only(top:0, right:8, bottom:0, left:0))),
                                                ),
                                                valueFlex: 8,
                                            ),
                                            ListValueItem(label: "User",                 value: ref.read(userProvider)?.name.full,         valueFlex: 8,   elliptValue: true),
                                            ListValueItem(label: "Badge",                value: ref.read(badgeProvider)?.id,               valueFlex: 8,   elliptValue: true),
                                            ListValueItem(label: "Company",              value: ref.read(companyProvider)?.name,           valueFlex: 8,   elliptValue: true),
                                            ListValueItem(label: "Job Title",            value: ref.read(companyUserProvider)?.jobTitle,   valueFlex: 8,   elliptValue: true),
                                            ListValueItem(label: "Show",                 value: ref.read(showProvider)?.title,             valueFlex: 8,   elliptValue: true),
                                            ListValueItem(
                                                label:   "Lead Retrieval",
                                                padding: EdgeInsets.zero,
                                                value:   Switch(
                                                    value:     (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false),
                                                    onChanged: (value) {
                                                        BadgeData? newBadgeState = ref.read(badgeProvider);
                                                        if (newBadgeState != null) {
                                                            newBadgeState.hasLeadScannerLicense = value;
                                                            ref.read(badgeProvider.notifier).update(newBadgeState);
                                                            setState(() { refresh = !refresh; });
                                                        }
                                                    }
                                                )
                                            )
                                        ]
                                    ),


                                    // Database
                                    (ref.read(userProvider) == null) ? null :
                                    InsetListSection(
                                        title:    "Saved State",
                                        children: () {
                                            Map<dynamic, dynamic> savedState = snapshot.data![1]["data"];
                                            List<Widget> output = [];

                                            for (final key in savedState.keys) {
                                                output.add(
                                                    ListValueItem(label: key, value: savedState[key], valueFlex: 7, elliptValue: true,)
                                                );
                                            }
                                            return output;
                                        }()
                                    ),


                                    // Bottom spacer for more comfortable scrolling
                                    InsetListSection(showBackground: false, children: [ const SizedBox(height: 60) ])


                                ].nonNulls.toList()
                            )
                        )
                    )
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