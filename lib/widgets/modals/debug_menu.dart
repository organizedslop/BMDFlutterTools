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
import "package:bmd_flutter_tools/data/model/data__company.dart";
import "package:bmd_flutter_tools/data/model/data__company_user.dart";
import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart" show fullRadius;
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
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
    final AppDatabase _appDatabase = AppDatabase.instance;
    final MethodChannel _buildTimeChannel = const MethodChannel("icmMethodChannel");
    final TextEditingController _customServerController = TextEditingController();

    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Helpers
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Widget _buildLabeledValueRow({
        Key? key,
        required dynamic label,
        dynamic value,
        TextStyle? textStyle,
        int valueFlex = 5,
        EdgeInsetsGeometry? padding,
        bool ellipsizeValue = false,
    }) {
        final EdgeInsetsGeometry effectivePadding = padding ?? const EdgeInsets.symmetric(vertical: 8);

        Widget asText(dynamic input, {bool applyEllipsis = false}) {
            if (input is Widget) {
                return input;
            }
            final String display = input == null ? "null" : input.toString();
            return Text(
                display,
                style: textStyle,
                overflow: applyEllipsis ? TextOverflow.ellipsis : TextOverflow.visible,
                maxLines: applyEllipsis ? 1 : null,
                softWrap: !applyEllipsis,
            );
        }

        final Widget labelWidget = asText(label);
        final Widget valueWidget = asText(value, applyEllipsis: ellipsizeValue);

        return Padding(
            key: key,
            padding: effectivePadding,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Expanded(
                        flex: 3,
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: labelWidget,
                        ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        flex: valueFlex,
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: valueWidget,
                        ),
                    ),
                ],
            ),
        );
    }

    @override
    void dispose() {
        _customServerController.dispose();
        super.dispose();
    }

    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {
        return FutureBuilder(
            future: Future.wait([
                const FlutterSecureStorage().readAll(),
                _appDatabase.read(tableName: "state_data"),
                _buildTimeChannel.invokeMethod("getBuildTime"),
            ]),
            builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            "Snapshot Error: ${snapshot.error}",
                            style: beTextTheme.bodyPrimary,
                        ),
                    );
                }

                if (!snapshot.hasData) {
                    return Center(child: Text("No data was found.", style: beTextTheme.bodyPrimary));
                }

                final List<dynamic> payload = snapshot.data! as List<dynamic>;
                final Map<dynamic, dynamic> savedState = payload[1]["data"] as Map<dynamic, dynamic>;
                final dynamic buildTime = payload[2];

                final ThemeMode themeMode = ref.watch(appThemeModeProvider);
                const List<ThemeMode> themeOptions = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
                final List<bool> themeSelection = themeOptions.map((mode) => mode == themeMode).toList();

                final bool isDebuggingMode = ref.watch(isDebuggingProvider);
                final bool useCustomServer = ref.watch(isDevelopmentProvider);
                final bool isHttpsEnabled = ref.watch(protocolIsHttpsProvider);

                final BadgeData? badge = ref.watch(badgeProvider);
                final UserData? user = ref.watch(userProvider);
                final CompanyData? company = ref.watch(companyProvider);
                final CompanyUserData? companyUser = ref.watch(companyUserProvider);
                final ShowData? show = ref.watch(showProvider);

                final String customServerHost = ref.watch(developmentSiteBaseUrlProvider);
                final String productionServerHost = ref.watch(productionSiteBaseUrlProvider);

                if (_customServerController.text != customServerHost) {
                    _customServerController
                        ..text = customServerHost
                        ..selection = TextSelection.fromPosition(
                            TextPosition(offset: _customServerController.text.length),
                        );
                }

                final ColorScheme scheme = Theme.of(context).colorScheme;
                final TextStyle whiteTextStyle = beTextTheme.bodyPrimary.copyWith(
                    color: scheme.surfaceBright,
                    shadows: const [
                        Shadow(offset: Offset(0, -2), blurRadius: 18),
                        Shadow(offset: Offset(0, 0), blurRadius: 42),
                    ],
                );

                final Color grayOverlay = scheme.outline.withOpacity(0.33);
                final Color magentaTint = scheme.secondary.withOpacity(0.33);
                final Color blendedDialogColor = Color.alphaBlend(magentaTint, grayOverlay);

                final ThemeData baseDark = ThemeData.dark();
                final ThemeData dialogTheme = baseDark.copyWith(
                    colorScheme: baseDark.colorScheme.copyWith(
                        primary: scheme.secondary,
                        secondary: scheme.secondary,
                        surface: blendedDialogColor,
                        onSurface: scheme.surfaceBright,
                        onPrimary: scheme.surfaceBright,
                    ),
                    textTheme: baseDark.textTheme.apply(
                        bodyColor: scheme.surfaceBright,
                        displayColor: scheme.surfaceBright,
                    ),
                    switchTheme: baseDark.switchTheme.copyWith(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        thumbIcon: WidgetStateProperty.resolveWith((_) => const Icon(Icons.circle, size: 18)),
                        trackOutlineWidth: WidgetStateProperty.all(1.8),
                    ),
                    toggleButtonsTheme: baseDark.toggleButtonsTheme.copyWith(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        borderWidth: 1.2,
                        textStyle: whiteTextStyle,
                    ),
                    inputDecorationTheme: const InputDecorationTheme(
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(),
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(width: 1.5),
                        ),
                        hintStyle: TextStyle(),
                        labelStyle: TextStyle(),
                    ),
                    textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(foregroundColor: scheme.surfaceBright),
                    ),
                );

                List<Widget?> buildRows() => [
                    _buildLabeledValueRow(
                        label: "Build",
                        value: buildTime,
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        label: "kDebugMode",
                        value: kDebugMode,
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        label: "developmentFeaturesEnabled",
                        value: developmentFeaturesEnabled,
                        textStyle: whiteTextStyle,
                    ),
                    Text("App State", style: whiteTextStyle.copyWith(fontWeight: FontWeight.w600)),
                    _buildLabeledValueRow(
                        key: const Key("debug_modal__debugging_mode_toggle_button"),
                        label: "Debugging Mode",
                        padding: EdgeInsets.zero,
                        value: Switch(
                            value: isDebuggingMode,
                            onChanged: (value) {
                                ref.read(isDebuggingProvider.notifier).state = value;
                                setState(() {});
                            },
                        ),
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        key: const Key("debug_modal__custom_server_toggle_button"),
                        label: "Custom Server",
                        padding: EdgeInsets.zero,
                        value: Switch(
                            value: useCustomServer,
                            onChanged: (value) {
                                ref.read(isDevelopmentProvider.notifier).state = value;
                                setState(() {});
                            },
                        ),
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        key: const Key("debug_modal__custom_server_field"),
                        label: "Server",
                        ellipsizeValue: true,
                        value: useCustomServer
                            ? Container(
                                margin: const EdgeInsets.only(left: 24),
                                child: TextField(
                                    controller: _customServerController,
                                    onChanged: (text) {
                                        ref.read(developmentSiteBaseUrlProvider.notifier).state = text;
                                    },
                                    textAlign: TextAlign.end,
                                ),
                            )
                            : productionServerHost,
                        valueFlex: 8,
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        key: const Key("debug_modal__https_toggle_button"),
                        label: "HTTPS",
                        padding: EdgeInsets.zero,
                        value: Switch(
                            value: isHttpsEnabled,
                            onChanged: (value) {
                                ref.read(protocolIsHttpsProvider.notifier).state = value;
                                setState(() {});
                            },
                        ),
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        label: TextButton.icon(
                            onPressed: () { ApiClient.instance.refreshToken(); },
                            icon: SFIcon(
                                SFIcons.sf_arrow_clockwise,
                                color: scheme.secondary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                            ),
                            style: ButtonStyle(
                                padding: WidgetStateProperty.all(
                                    const EdgeInsets.only(top: 0, right: 8, bottom: 0, left: 0),
                                ),
                            ),
                            label: Text("Access Token", style: whiteTextStyle.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        value: (savedState["access_token"] ?? "null").toString().replaceAll("\"", ""),
                        valueFlex: 8,
                        ellipsizeValue: true,
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        label: "Send FCM",
                        value: TextButton.icon(
                            onPressed: () async {
                                logPrint("🔄 Sending FCM");
                                final FlutterSecureStorage storage = const FlutterSecureStorage();
                                final String? fcmToken = await storage.read(key: "fcm_token");
                                final String? userId = ref.read(userProvider)?.id;
                                if (fcmToken == null) {
                                    logPrint("⚠️  fcmToken is null");
                                    return;
                                }
                                if (userId == null) {
                                    logPrint("⚠️  userId is null");
                                    return;
                                }
                                final bool ok = await ApiClient.instance.sendFcmNotificationToUser(
                                    userId: userId,
                                    token:  fcmToken,
                                    title:  "Debug FCM",
                                    body:   "Sent from Debug Menu",
                                );
                                logPrint("✅ FCM send returned: $ok");
                            },
                            icon: SFIcon(SFIcons.sf_bell, fontSize: 16),
                            label: Text("Send", style: whiteTextStyle.copyWith(fontWeight: FontWeight.bold)),
                            style: ButtonStyle(
                                padding: WidgetStateProperty.all(
                                    const EdgeInsets.only(top: 0, right: 8, bottom: 0, left: 0),
                                ),
                            ),
                        ),
                        valueFlex: 8,
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        label: "User",
                        value: user?.name.full,
                        valueFlex: 8,
                        ellipsizeValue: true,
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        label: "Badge",
                        value: badge?.id,
                        valueFlex: 8,
                        ellipsizeValue: true,
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        label: "Company",
                        value: company?.name,
                        valueFlex: 8,
                        ellipsizeValue: true,
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        label: "Job Title",
                        value: companyUser?.jobTitle,
                        valueFlex: 8,
                        ellipsizeValue: true,
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        label: "Show",
                        value: show?.title,
                        valueFlex: 8,
                        ellipsizeValue: true,
                        textStyle: whiteTextStyle,
                    ),
                    _buildLabeledValueRow(
                        label: "Lead Retrieval",
                        padding: EdgeInsets.zero,
                        value: Switch(
                            value: badge?.hasLeadScannerLicense ?? false,
                            onChanged: (value) {
                                final BadgeData? current = ref.read(badgeProvider);
                                if (current != null) {
                                    current.hasLeadScannerLicense = value;
                                    ref.read(badgeProvider.notifier).update(current);
                                    setState(() {});
                                }
                            },
                        ),
                        textStyle: whiteTextStyle,
                    ),
                    if (user != null)
                        Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text("Saved State", style: whiteTextStyle.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    ...savedState.entries.map(
                                        (entry) => _buildLabeledValueRow(
                                            label: entry.key,
                                            value: entry.value,
                                            valueFlex: 7,
                                            ellipsizeValue: true,
                                            textStyle: whiteTextStyle,
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ToggleButtons(
                        isSelected: themeSelection,
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        borderWidth: 1.2,
                        constraints: const BoxConstraints(minHeight: 40, minWidth: 72),
                        onPressed: (index) {
                            ref.read(appThemeModeProvider.notifier).state = themeOptions[index];
                            setState(() {});
                        },
                        children: [
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text("Light", style: whiteTextStyle),
                            ),
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text("Dark", style: whiteTextStyle),
                            ),
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text("System", style: whiteTextStyle),
                            ),
                        ],
                    ),
                    const SizedBox(height: 60),
                ];

                return Theme(
                    data: dialogTheme,
                    child: AlertDialog(
                        contentPadding:  EdgeInsets.zero,
                        insetPadding:    const EdgeInsets.all(16),
                        shape:           RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(width: 2),
                        ),
                        content: DefaultTextStyle.merge(
                            style: whiteTextStyle,
                            child: SizedBox(
                                width: double.maxFinite,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: DecoratedBox(
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                colors: [
                                                    scheme.onSurface.withOpacity(0.45),
                                                    scheme.secondary.withOpacity(0.22),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                            ),
                                        ),
                                        child: SizedBox(
                                            height: 550,
                                            child: Stack(
                                                children: [
                                                    Positioned.fill(
                                                        child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 14),
                                                            child: ListView(
                                                                children: [
                                                                    Padding(
                                                                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                                                                        child: Text(
                                                                            "Debug Menu",
                                                                            style: dialogTheme.textTheme.headlineMedium?.copyWith(
                                                                                fontWeight: FontWeight.w700,
                                                                                shadows: whiteTextStyle.shadows,
                                                                            ) ??
                                                                                whiteTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
                                                                        ),
                                                                    ),
                                                                    ...buildRows().nonNulls,
                                                                ],
                                                            ),
                                                        ),
                                                    ),
                                                    IgnorePointer(
                                                        child: Align(
                                                            alignment: Alignment.topCenter,
                                                            child: Container(
                                                                height: 32,
                                                                decoration: BoxDecoration(
                                                                    gradient: LinearGradient(
                                                                        begin: Alignment.topCenter,
                                                                        end: Alignment.bottomCenter,
                                                                        colors: [
                                                                            blendedDialogColor,
                                                                            blendedDialogColor.withOpacity(0),
                                                                        ],
                                                                    ),
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                    IgnorePointer(
                                                        child: Align(
                                                            alignment: Alignment.bottomCenter,
                                                            child: Container(
                                                                height: 40,
                                                                decoration: BoxDecoration(
                                                                    gradient: LinearGradient(
                                                                        begin: Alignment.bottomCenter,
                                                                        end: Alignment.topCenter,
                                                                        colors: [
                                                                            blendedDialogColor,
                                                                            blendedDialogColor.withOpacity(0),
                                                                        ],
                                                                    ),
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                );
            },
        );
    }
}

/* ======================================================================================================================
 * MARK: Debug Menu Toggle
 * ------------------------------------------------------------------------------------------------------------------ */
class DebugMenuToggle extends StatelessWidget {
    static const Key rootKey = Key("debug_menu_toggle_button");

    DebugMenuToggle({ super.key });

    @override
    Widget build(BuildContext context) {
        return Container(
            alignment: AlignmentDirectional.centerEnd,
            height:    50,
            child:     IconButton(
                key:       rootKey,
                onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => DebugMenu(),
                    );
                },
                icon:      Container(
                    decoration: BoxDecoration(
                        color:        BeColorSwatch.magenta.color,
                        borderRadius: BorderRadius.circular(fullRadius),
                    ),
                    width:  16,
                    height: 16,
                ),
            ),
        );
    }
}
