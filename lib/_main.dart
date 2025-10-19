/*
* Main
*
* Created by:  Blake Davis
* Description: Build Expo USA app main
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "package:bmd_flutter_tools/theme/blurred_splash_factory.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/widgets/shapes/shape__gradient_border.dart";
import "package:flutter/foundation.dart";
import "firebase_options.dart";
import "package:bmd_flutter_tools/services/analytics_service.dart";
import "package:bmd_flutter_tools/controllers/deep_link_service.dart";
import "package:bmd_flutter_tools/controllers/notifications_service.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/services/connection_retry_service.dart";
import "package:bmd_flutter_tools/theme/slide_transitions.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/modal__invite_guests.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";
import "package:permission_handler/permission_handler.dart";
import "package:sentry_flutter/sentry_flutter.dart";

final providerContainer = ProviderContainer();
const Duration buttonOverlayFadeDuration = Duration(milliseconds: 140);

// TODO: These buttons should be moved to their own file
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* "Invite guests" button
* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
Container inviteGuestsButton(BuildContext context) {
    final TextScaler textScaler = MediaQuery.of(context).textScaler;
    final double textScaleFactor = textScaler.scale(1.0);

    return Container(
        decoration: hardEdgeDecoration,
        child: ElevatedButton(
            key: Key("invite_guests_button"),
            onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                        return InviteModal(text: "Invite a staff members");
                    },
                );
            },
            style: elevatedButtonStyleAlt.copyWith(
                backgroundBuilder: (context, states, child) {
                    final bool isPressed = states.contains(WidgetState.pressed);
                    final bool isHovered = states.contains(WidgetState.hovered);
                    final bool isFocused = states.contains(WidgetState.focused);

                    final bool overlayVisible = isPressed || isHovered || isFocused;
                    final double overlayStrength = isPressed ? 0.30 : 0.14;

                    return DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                    BeColorSwatch.darkBlue,
                                    BeColorSwatch.blue,
                                ],
                            ),
                            borderRadius: BorderRadius.circular(mediumRadius),
                        ),
                        child: DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: beveledDecoration,
                            child: Stack(
                                fit: StackFit.passthrough,
                                children: [
                                    if (child != null) child!,
                                    Positioned.fill(
                                        child: IgnorePointer(
                                            child: AnimatedOpacity(
                                                opacity: overlayVisible ? 1 : 0,
                                                duration: buttonOverlayFadeDuration,
                                                curve: Curves.easeOutCubic,
                                                child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                        color: BeColorSwatch.white.withOpacity(
                                                            overlayVisible ? overlayStrength : 0,
                                                        ),
                                                        borderRadius: BorderRadius.circular(mediumRadius),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    );
                },
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(mediumRadius)),
                ),
            ),
            child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                    spacing: 14,
                    children: [
                        SFIcon(
                            SFIcons.sf_person_3_fill,
                            color: BeColorSwatch.white,
                            fontSize: 28,
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    (textScaleFactor > 1.2) ? "Invite guests!" : "Invite guests to attend!",
                                    style: TextTheme.of(context)
                                        .headlineMedium!
                                        .copyWith(color: BeColorSwatch.white),
                                ),
                                Text(
                                    "Tap to send an invite",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(color: BeColorSwatch.white),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        ),
    );
}

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* "Register for shows" button
* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
Container registerForShowsButton(BuildContext context) {

    final TextScaler textScaler = MediaQuery.of(context).textScaler;
    final double textScaleFactor = textScaler.scale(1.0);

    return Container(
        decoration: hardEdgeDecoration,
        child: ElevatedButton(
            key: Key("register_for_shows_ad_button"),
            onPressed: () {
                context.pushNamed("all shows");
            },
            style: ButtonStyle(
                backgroundBuilder: (context, states, child) {
                    final bool isPressed = states.contains(WidgetState.pressed);
                    final bool isHovered = states.contains(WidgetState.hovered);
                    final bool isFocused = states.contains(WidgetState.focused);

                    final bool overlayVisible = isPressed || isHovered || isFocused;
                    final double overlayStrength = isPressed ? 0.30 : 0.14;

                    return DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                    BeColorSwatch.red,
                                    BeColorSwatch.orange,
                                ],
                            ),
                            borderRadius: BorderRadius.circular(mediumRadius),
                        ),
                        child: DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: beveledDecoration,
                            child: Stack(
                                fit: StackFit.passthrough,
                                children: [
                                    if (child != null) child!,
                                    Positioned.fill(
                                        child: IgnorePointer(
                                            child: AnimatedOpacity(
                                                opacity: overlayVisible ? 1 : 0,
                                                duration: buttonOverlayFadeDuration,
                                                curve: Curves.easeOutCubic,
                                                child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                        color: BeColorSwatch.white.withOpacity(
                                                            overlayVisible ? overlayStrength : 0,
                                                        ),
                                                        borderRadius: BorderRadius.circular(mediumRadius),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    );
                },
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(mediumRadius)),
                ),
            ),
            child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                    spacing: 14,
                    children: [
                        SFIcon(
                            SFIcons.sf_person_text_rectangle_fill,
                            color: BeColorSwatch.white,
                            fontSize: 28,
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    (textScaleFactor > 1.35) ? "Register for shows!" : "Register for more shows!",
                                    style: TextTheme.of(context)
                                        .headlineMedium!
                                        .copyWith(color: BeColorSwatch.white),
                                ),
                                Text(
                                    "Tap to see upcoming shows.",
                                    style: TextStyle(color: BeColorSwatch.white),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        ),
    );
}

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* "Interested in exhibiting?" button
* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
Container interestedInExhibitingButton(BuildContext context) {
    final baseUrl = providerContainer.read(
        kDebugMode ? developmentSiteBaseUrlProvider : productionSiteBaseUrlProvider,
    );
    final currentProtocol = providerContainer.read(protocolProvider);
    final dynamicUrl = "$currentProtocol$baseUrl/mobile/exhibiting";

    return Container(
        decoration: hardEdgeDecoration,
        child: ElevatedButton(
            onPressed: () {
                context.pushNamed("web view", pathParameters: {
                    "title": "Why Exhibit?",
                    "url": dynamicUrl,
                });
            },
            style: ButtonStyle(
                backgroundBuilder: (context, states, child) {
                    final bool isPressed = states.contains(WidgetState.pressed);
                    final bool isHovered = states.contains(WidgetState.hovered);
                    final bool isFocused = states.contains(WidgetState.focused);

                    final bool overlayVisible = isPressed || isHovered || isFocused;
                    final double overlayStrength = isPressed ? 0.30 : 0.14;

                    return DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                    BeColorSwatch.red,
                                    BeColorSwatch.orange,
                                ],
                            ),
                            borderRadius: BorderRadius.circular(mediumRadius),
                        ),
                        child: DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: beveledDecoration,
                            child: Stack(
                                fit: StackFit.passthrough,
                                children: [
                                    if (child != null) child!,
                                    Positioned.fill(
                                        child: IgnorePointer(
                                            child: AnimatedOpacity(
                                                opacity: overlayVisible ? 1 : 0,
                                                duration: buttonOverlayFadeDuration,
                                                curve: Curves.easeOutCubic,
                                                child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                        color: BeColorSwatch.white.withOpacity(
                                                            overlayVisible ? overlayStrength : 0,
                                                        ),
                                                        borderRadius: BorderRadius.circular(mediumRadius),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    );
                },
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(mediumRadius)),
                ),
            ),
            child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                    spacing: 14,
                    children: [
                        SFIcon(
                            SFIcons.sf_star_fill,
                            color: BeColorSwatch.white,
                            fontSize: 28,
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    "Interested in exhibiting?",
                                    style: TextTheme.of(context)
                                        .headlineMedium!
                                        .copyWith(color: BeColorSwatch.white),
                                ),
                                Text(
                                    "Tap to learn more.",
                                    style: TextStyle(color: BeColorSwatch.white),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        ),
    );
}

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* "Interested in presenting" button
* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
Container interestedInPresentingButton(BuildContext context) {
    final baseUrl = providerContainer.read(
        kDebugMode ? developmentSiteBaseUrlProvider : productionSiteBaseUrlProvider,
    );
    final currentProtocol = providerContainer.read(protocolProvider);
    final dynamicUrl = "$currentProtocol$baseUrl/mobile/presenting-simple";

    return Container(
        decoration: hardEdgeDecoration,
        child: ElevatedButton(
            onPressed: () {
                context.pushNamed("web view", pathParameters: {
                    "title": "Presenting",
                    "url": dynamicUrl,
                });
            },
            style: ButtonStyle(
                backgroundBuilder: (context, states, child) {
                    final bool isPressed = states.contains(WidgetState.pressed);
                    final bool isHovered = states.contains(WidgetState.hovered);
                    final bool isFocused = states.contains(WidgetState.focused);

                    final bool overlayVisible = isPressed || isHovered || isFocused;
                    final double overlayStrength = isPressed ? 0.30 : 0.14;

                    return DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                    BeColorSwatch.darkBlue,
                                    BeColorSwatch.blue,
                                ],
                            ),
                            borderRadius: BorderRadius.circular(mediumRadius),
                        ),
                        child: DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: beveledDecoration,
                            child: Stack(
                                fit: StackFit.passthrough,
                                children: [
                                    if (child != null) child!,
                                    Positioned.fill(
                                        child: IgnorePointer(
                                            child: AnimatedOpacity(
                                                opacity: overlayVisible ? 1 : 0,
                                                duration: buttonOverlayFadeDuration,
                                                curve: Curves.easeOutCubic,
                                                child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                        color: BeColorSwatch.white.withOpacity(
                                                            overlayVisible ? overlayStrength : 0,
                                                        ),
                                                        borderRadius: BorderRadius.circular(mediumRadius),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    );
                },
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(mediumRadius)),
                ),
            ),
            child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                    spacing: 14,
                    children: [
                        SFIcon(
                            SFIcons.sf_music_microphone,
                            color: BeColorSwatch.white,
                            fontSize: 28,
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    "Interested in presenting?",
                                    style: TextTheme.of(context)
                                        .headlineMedium!
                                        .copyWith(color: BeColorSwatch.white),
                                ),
                                Text(
                                    "Tap to learn more",
                                    style: TextStyle(color: BeColorSwatch.white),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        ),
    );
}

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* "Become a sponsor" button
* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
Container sponsorButton(BuildContext context) {
    final baseUrl = providerContainer.read(
        kDebugMode ? developmentSiteBaseUrlProvider : productionSiteBaseUrlProvider,
    );
    final currentProtocol = providerContainer.read(protocolProvider);
    final dynamicUrl = "$currentProtocol$baseUrl/mobile/sponsoring";

    return Container(
        decoration: hardEdgeDecoration,
        child: ElevatedButton(
            onPressed: () {
                context.pushNamed("web view", pathParameters: {
                    "title": "Sponsoring",
                    "url": dynamicUrl,
                });
            },
            style: ButtonStyle(
                backgroundBuilder: (context, states, child) {
                    final bool isPressed = states.contains(WidgetState.pressed);
                    final bool isHovered = states.contains(WidgetState.hovered);
                    final bool isFocused = states.contains(WidgetState.focused);

                    final bool overlayVisible = isPressed || isHovered || isFocused;
                    final double overlayStrength = isPressed ? 0.30 : 0.14;

                    return DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                    BeColorSwatch.darkBlue,
                                    BeColorSwatch.blue,
                                ],
                            ),
                            borderRadius: BorderRadius.circular(mediumRadius),
                        ),
                        child: DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: beveledDecoration,
                            child: Stack(
                                fit: StackFit.passthrough,
                                children: [
                                    if (child != null) child!,
                                    Positioned.fill(
                                        child: IgnorePointer(
                                            child: AnimatedOpacity(
                                                opacity: overlayVisible ? 1 : 0,
                                                duration: buttonOverlayFadeDuration,
                                                curve: Curves.easeOutCubic,
                                                child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                        color: BeColorSwatch.white.withOpacity(
                                                            overlayVisible ? overlayStrength : 0,
                                                        ),
                                                        borderRadius: BorderRadius.circular(mediumRadius),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    );
                },
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(mediumRadius)),
                ),
            ),
            child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                    spacing: 14,
                    children: [
                        SFIcon(
                            SFIcons.sf_star_fill,
                            color: BeColorSwatch.white,
                            fontSize: 28,
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    "Become a sponsor!",
                                    style: TextTheme.of(context)
                                        .headlineMedium!
                                        .copyWith(color: BeColorSwatch.white),
                                ),
                                Text(
                                    "Tap to learn more",
                                    style: TextStyle(color: BeColorSwatch.white),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        ),
    );
}

/* =====================================================================================================================
 * MARK: Field Formatting
 * ------------------------------------------------------------------------------------------------------------------ */

const double fullRadius   = 999.0;
const double largeRadius  =  16.0;
const double mediumRadius =  12.0;
const double smallRadius  =   4.0;

const double bevelSize = 1;

final fullRadiusBeveledDecoration = ShapeDecoration(
                shape: GradientBorderShape(
                                borderRadius: BorderRadius.circular(fullRadius),
                                borderWidth:  bevelSize,
        gradient: LinearGradient(
            begin:  Alignment(-0.075,-0.75),
            end:    Alignment(0.02,1),
            colors: [
                BeColorSwatch.white.withAlpha(180),
                BeColorSwatch.white.withAlpha(0),
                BeColorSwatch.white.withAlpha(0),
                BeColorSwatch.white.withAlpha(100),
            ],
            stops: [0, 0.4, 0.6, 1]
        ),
                ),
);

final beveledDecoration = ShapeDecoration(
                shape: GradientBorderShape(
                                borderRadius: BorderRadius.circular(mediumRadius),
        borderWidth:  bevelSize,
        gradient: LinearGradient(
            begin:  Alignment(-0.075,-0.75),
            end:    Alignment(0.02,1),
            colors: [
                BeColorSwatch.white.withAlpha(180),
                BeColorSwatch.white.withAlpha(0),
                BeColorSwatch.white.withAlpha(0),
                BeColorSwatch.white.withAlpha(100),
            ],
            stops: [0, 0.4, 0.6, 1]
        ),
    ),
);

final hardEdgeDecoration = BoxDecoration(
    border: Border.all(width: 0.333, color: BeColorSwatch.navy.withAlpha(60), strokeAlign: BorderSide.strokeAlignOutside),
    borderRadius: BorderRadius.circular(mediumRadius)
);

final gfieldDropDownIcon = const Padding(
                padding: EdgeInsets.only(top: 2),
                child: SFIcon(SFIcons.sf_chevron_down,
                                color: BeColorSwatch.blue, fontSize: 16, fontWeight: FontWeight.bold));
final gfieldHintStyle = TextStyle(
                color: beColorScheme.text.tertiary, fontWeight: FontWeight.normal);
final gfieldHorizontalPadding = const EdgeInsets.symmetric(horizontal: 10);
const gfieldRoundedBorderWidth = 1.5;
final gfieldRoundedBorder = OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(mediumRadius)),
                borderSide: BorderSide(
                                color: beColorScheme.text.quaternary, width: gfieldRoundedBorderWidth));
final gfieldVerticalPadding = const EdgeInsets.only(top: 8, bottom: 16);

final BoxDecoration gfieldBoxDecoration = BoxDecoration(
        border: Border.fromBorderSide(gfieldRoundedBorder.borderSide),
        borderRadius: gfieldRoundedBorder.borderRadius,
);

final InputDecoration gfieldInputDecoration = InputDecoration(
                enabledBorder: gfieldRoundedBorder,
                errorBorder: gfieldRoundedBorder.copyWith(
                                borderSide: gfieldRoundedBorder.borderSide.copyWith(
                                                color: BeColorSwatch.red, width: gfieldRoundedBorderWidth)),
                fillColor: BeColorSwatch.offWhite,
                filled: true,
                focusedBorder: gfieldRoundedBorder.copyWith(
                                borderSide: gfieldRoundedBorder.borderSide.copyWith(
                                                width: gfieldRoundedBorderWidth + 0.5, color: BeColorSwatch.blue)),
                focusedErrorBorder: gfieldRoundedBorder.copyWith(
                                borderSide: gfieldRoundedBorder.borderSide.copyWith(
                                                width: gfieldRoundedBorderWidth + 0.5, color: BeColorSwatch.red)),
                border: gfieldRoundedBorder,
                contentPadding: gfieldHorizontalPadding);

Widget formFieldLabel(
                {required String labelText,
                int fieldId = 0,
                bool isRequired = false,
                bool isValid = true}) {
        // Don't add padding to the field if the label text is an empty string
        if (labelText == "") {
                return const SizedBox.shrink();
        } else {
                return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text.rich(
                                        TextSpan(
                                                children: [
                                                        TextSpan(
                                                                // Append WORD JOINER to glue next span's asterisk to this text
                                                                text: labelText.trimRight() + (isRequired ? '\u2060' : ''),
                                                                style: beTextTheme.bodyPrimary.merge(
                                                                        TextStyle(
                                                                                color: isValid ? null : BeColorSwatch.red,
                                                                                fontWeight: FontWeight.bold,
                                                                        ),
                                                                ),
                                                        ),
                                                        if (isRequired)
                                                                TextSpan(
                                                                        // Asterisk immediately after WORD JOINER prevents wrapping
                                                                        text: '*',
                                                                        style: beTextTheme.headingSecondary.merge(
                                                                                const TextStyle(
                                                                                        color: BeColorSwatch.red,
                                                                                        height: 0.75,
                                                                                ),
                                                                        ),
                                                                ),
                                                ],
                                        ),
                                        textAlign: TextAlign.start,
                                ),
                        ),
                );
        }
}

/* -----------------------------------------------------------------------------------------------------------------
* MARK: GField Description Widget
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
Widget formFieldDescription(
                {required String descriptionText,
                int fieldId = 0,
                bool isRequired = false}) {
        // Don't add padding to the field if the label text is an empty string
        if (descriptionText == "") {
                return const SizedBox.shrink();
        } else {
                return Padding(
                                padding: EdgeInsets.only(left: 6, bottom: 8),
                                child: Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                        RichText(
                                                                        text: TextSpan(
                                                                                        style: beTextTheme.headingPrimary
                                                                                                        .merge(TextStyle(fontSize: 28)),
                                                                                        children: [
                                                                                                // Append WORD JOINER to glue the following asterisk
                                                                                                TextSpan(
                                                                                                                text:
                                                                                                                                descriptionText + (isRequired ? '\u2060' : '')),

                                                                                                if (isRequired)
                                                                                                        TextSpan(
                                                                                                                text: '*',
                                                                                                                style: beTextTheme.headingPrimary.merge(
                                                                                                                        TextStyle(
                                                                                                                                        color: beColorScheme.text.accent2,
                                                                                                                                        height: 0.75),
                                                                                                                ),
                                                                                                        ),

                                                                                                // ref.read(isDebuggingProvider) ? TextSpan(text: " ${fieldId.toString()}", style: beTextTheme.captionSecondary.merge(TextStyle(color: BeColorSwatch.magenta))) : null
                                                                                        ].nonNulls.toList()))
                                                ].nonNulls.toList()));
        }
}

final Color appAccentColor = BeColorSwatch.blue;

final ColorScheme appColorSchemeLight = ColorScheme.light(
        brightness: Brightness.light,
        error: BeColorSwatch.red,
        errorContainer: BeColorSwatch.lighterGray,
        inversePrimary: BeColorSwatch.white,
        inverseSurface: BeColorSwatch.navy,
        onError: BeColorSwatch.white,
        onErrorContainer: BeColorSwatch.red,
        onInverseSurface: BeColorSwatch.white,
        onPrimary: BeColorSwatch.white,
        onPrimaryContainer: BeColorSwatch.black,
        onSecondaryContainer: BeColorSwatch.black,
        onSecondary: BeColorSwatch.black,
        primary: BeColorSwatch.darkBlue,
        primaryContainer: BeColorSwatch.lightGray,
        // secondary:              BeColorSwatch.red,
        secondaryContainer: BeColorSwatch.lighterGray,
        shadow: BeColorSwatch.lightGray,

        surface: BeColorSwatch.lighterGray,
        surfaceTint: Colors.transparent,
        onSurface: BeColorSwatch.black,
        surfaceContainer: BeColorSwatch.white,
        surfaceContainerHigh: BeColorSwatch.offWhite,
        surfaceContainerLow: BeColorSwatch.lighterGray,
        surfaceContainerLowest: BeColorSwatch.lightGray,
);

const ColorScheme appColorSchemeDark = ColorScheme.dark(
        brightness: Brightness.dark,
        primary: Color(0xff1c3579),
        onPrimary: Color(0xffffffff),
        primaryContainer: Color(0xff1c3579),
        onPrimaryContainer: Color(0xffece8f5),
        secondary: Color(0xff1a3a6e),
        onSecondary: Color(0xff9c9c9c),
        secondaryContainer: Color(0xff4a4458),
        onSecondaryContainer: Color(0xffebeaed),
        tertiary: Color(0xff818181),
        onTertiary: Color(0xff141213),
        tertiaryContainer: Color(0xff633b48),
        onTertiaryContainer: Color(0xffefe9eb),
        error: Color(0xffcf6679),
        onError: Color(0xff141211),
        errorContainer: Color(0xff93000a),
        onErrorContainer: Color(0xfff6dfe1),
        surface: Color(0xff1a191d),
        onSurface: Color(0xffedeced),
        onSurfaceVariant: Color(0xffe1e1e1),
        outline: Color(0xff7d767d),
        outlineVariant: Color(0xff2e2c2e),
        shadow: Color(0xff000000),
        scrim: Color(0xff000000),
        inverseSurface: Color(0xfffcfbff),
        onInverseSurface: Color(0xff131314),
        inversePrimary: Color(0xff685f77),
        surfaceTint: Color(0xff00060b),
);

/*
 * MARK: Show SnackBar
 */
void showSnackBar({
    Color backgroundColor = BeColorSwatch.white,
    required BuildContext context,
    required Widget content

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
                    child: content
                )
            )
        );
    }
}

/*
 * MARK: SnackBar Theme
 */
const SnackBarThemeData snackBarTheme = SnackBarThemeData(
    backgroundColor: BeColorSwatch.blue,
    behavior: SnackBarBehavior.fixed,
    contentTextStyle: TextStyle(color: BeColorSwatch.white, fontWeight: FontWeight.bold, fontSize: 16),
    elevation: 10,
);

/*
 * MARK: Round Elevated Button Style
 */
final roundElevatedButtonStyle = ButtonStyle(
                animationDuration: buttonOverlayFadeDuration,
                padding: WidgetStateProperty.all(
                                EdgeInsets.symmetric(
                                                horizontal: beTextTheme.headingPrimary.fontSize! * 1.2,
                                                vertical: beTextTheme.headingPrimary.fontSize! * 0.6
                                )
                ),
                overlayColor:    WidgetStateProperty.all(BeColorSwatch.white.withAlpha(60)),
                shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(fullRadius))
                ),
                textStyle: WidgetStateProperty.all(
                                beTextTheme.headingPrimary.merge(TextStyle(color: BeColorSwatch.white))
                )
);

/*
 * MARK: Elevated Button Style
 */
final elevatedButtonStyleAlt = ButtonStyle(
                animationDuration: buttonOverlayFadeDuration,
                alignment: AlignmentDirectional.centerStart,
                backgroundColor: WidgetStateProperty.all(BeColorSwatch.navy),
                minimumSize: WidgetStateProperty.all(Size(double.infinity, 12)),
                overlayColor: WidgetStateProperty.all(BeColorSwatch.white.withAlpha(60)),
                shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(mediumRadius))),
                textStyle: WidgetStateProperty.all(beTextTheme.headingPrimary));

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
        logPrint("📈 Main: Firebase.initializeApp completed");

        logPrint("📈 Main: Initializing AnalyticsService");
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

        // Set the publishable key for Stripe (mandatory)
        // Stripe.publishableKey = "stripePublishableKey";

        await SystemChrome.setPreferredOrientations(
                        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

        final initialRoute = Uri.base.path;
        final queryParams = Uri.base.queryParameters;

        // Style the status bar for views that do not have an AppBar
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                        overlays: SystemUiOverlay.values);
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.dark,
        ));

        AppDatabase appDatabase = AppDatabase.instance;

        // Check for build-time changes to reset database if needed
        const MethodChannel _buildTimeChannel = MethodChannel('icmMethodChannel');
        final storage = FlutterSecureStorage();
        final String currentBuildTime =
                        await _buildTimeChannel.invokeMethod('getBuildTime') as String;
        final String? lastBuildTime = await storage.read(key: 'build_time');
        if (lastBuildTime != currentBuildTime) {
                // Build changed: destroy and recreate database
                await appDatabase.closeDatabase();
                await appDatabase.deleteDatabase();
                await appDatabase.reopen();
                await storage.write(
                                key: "build_time",
                                value: currentBuildTime,
                                iOptions: IOSOptions(
                                        // Update the value if it already exists
                                        accessibility: KeychainAccessibility.first_unlock,
                                        synchronizable: false,
                                ));
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
class App extends StatefulWidget {
        final String initialRoute;
        final Map<String, String> initialParams;

        const App(
                        {required this.initialRoute, required this.initialParams, super.key});

        @override
        State<App> createState() => _AppState();
}

/* ======================================================================================================================
* MARK: Widget State
* ------------------------------------------------------------------------------------------------------------------ */
class _AppState extends State<App> {
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

        // Theme
        ThemeMode themeMode = ThemeMode.light;
        ColorScheme? imageColorScheme = const ColorScheme.light();

        bool get useLightMode => switch (themeMode) {
                                ThemeMode.system =>
                                        View.of(context).platformDispatcher.platformBrightness ==
                                                        Brightness.light,
                                ThemeMode.light => true,
                                ThemeMode.dark => false
                        };

        void handleBrightnessChange(bool useLightMode) {
                setState(() {
                        themeMode = useLightMode ? ThemeMode.light : ThemeMode.dark;
                });
        }

        /* -----------------------------------------------------------------------------------------------------------------
* MARK: Build Widget
* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
        @override
        Widget build(BuildContext context) {
                final checkboxTheme = CheckboxThemeData(
                        fillColor:
                                        WidgetStateProperty.fromMap({WidgetState.selected: appAccentColor}),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                                        color: gfieldBoxDecoration.border!.top.color,
                                                        width: (gfieldBoxDecoration.border!.top.width / 1.4)),
                                        borderRadius: BorderRadius.circular(smallRadius)),
                        side: BorderSide(
                                        color: gfieldBoxDecoration.border!.top.color,
                                        width: (gfieldBoxDecoration.border!.top.width / 1.4)),
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
                                                        color: BeColorSwatch.blue)),
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
                                                Icon(Icons.circle, color: BeColorSwatch.offWhite)),
                                trackColor: WidgetStateProperty.resolveWith(
                                        (states) => states.contains(WidgetState.selected)
                                                        ? appAccentColor
                                                        : BeColorSwatch.lightGray,
                                ),
                                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                trackOutlineWidth: WidgetStateProperty.all(0.0));

                final textButtonTheme = TextButtonThemeData(
                    style: ButtonStyle(
                        animationDuration: buttonOverlayFadeDuration,
                        overlayColor:  WidgetStateProperty.all(BeColorSwatch.white.withAlpha(80)),
                        splashFactory: BlurredSplashFactory(),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle:     WidgetStateProperty.resolveWith(
                            (states) => TextStyle(
                                color: (states.contains(WidgetState.pressed)
                                    ? appAccentColor
                                    : BeColorSwatch.gray),
                                height: 0
                            )
                        ),
                        visualDensity: VisualDensity.compact
                    )
                );

                final elevatedButtonTheme = ElevatedButtonThemeData(
                    style: ButtonStyle(
                        animationDuration: buttonOverlayFadeDuration,
                        backgroundColor: WidgetStateProperty.all(appAccentColor),
                        foregroundColor: WidgetStateProperty.all(BeColorSwatch.white),
                        overlayColor: WidgetStateProperty.all(BeColorSwatch.white.withAlpha(80)),
                        padding:      WidgetStateProperty.all(
                            EdgeInsets.symmetric(
                                horizontal: (((beTextTheme.bodyPrimary.fontSize! / 2) + 2) * 2),
                                vertical: ((beTextTheme.bodyPrimary.fontSize! / 2) + 2)
                            )
                        ),
                        splashFactory: BlurredSplashFactory(),
                        textStyle:     WidgetStateProperty.all(
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
                                                dividerTheme: const DividerThemeData(
                                                                color: Colors
                                                                                .transparent), // Disable the divider below the navigation menu drawer header
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
                                                unselectedWidgetColor: appColorSchemeLight.surfaceContainer),

                                /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
* MARK: Dark Theme
*/
                                darkTheme: ThemeData(
                                        colorScheme: appColorSchemeDark,
                                        dividerTheme: const DividerThemeData(
                                                        color: Colors
                                                                        .transparent), // Disable the divider below the navigation menu drawer header
                                        scaffoldBackgroundColor: BeColorSwatch.black,
                                        textTheme: TextTheme(
                                                bodyLarge: beTextTheme.bodyPrimary,
                                                bodyMedium: beTextTheme.bodyPrimary,
                                                bodySmall: beTextTheme.bodySecondary,
                                                displayLarge: beTextTheme.titlePrimary,
                                                displayMedium: beTextTheme.titleSecondary,
                                                displaySmall: beTextTheme.titleSecondary,
                                                headlineLarge: beTextTheme.headingPrimary,
                                                headlineMedium: beTextTheme.headingSecondary,
                                                headlineSmall: beTextTheme.headingTertiary,
                                                labelLarge: beTextTheme.bodyPrimary,
                                                labelMedium: beTextTheme.bodyPrimary,
                                                labelSmall: beTextTheme.bodySecondary,
                                                titleLarge: beTextTheme.headingPrimary,
                                                titleMedium: beTextTheme.headingSecondary,
                                                titleSmall: beTextTheme.headingTertiary,
                                        ),
                                        snackBarTheme: snackBarTheme,
                                ));
        }
}
