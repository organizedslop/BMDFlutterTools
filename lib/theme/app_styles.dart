/*
 * App Styles
 *
 * Shared styling constants and helpers used throughout the app.
 */

import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/shapes/gradient_shape_border.dart";
import "package:bmd_flutter_tools/theme/slide_transitions.dart";
import "package:flutter/material.dart";
import "package:flutter_sficon/flutter_sficon.dart";

Color mutedTextColor(BuildContext context, {double opacity = 0.72}) {
    final base = Theme.of(context).colorScheme.onSurface;
    final clamped = opacity.clamp(0.0, 1.0);
    return base.withOpacity(clamped.toDouble());
}

Color primaryTextColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface;

const Duration buttonOverlayFadeDuration = Duration(milliseconds: 140);

const double fullRadius   = 999.0;
const double largeRadius  =  16.0;
const double mediumRadius =  12.0;
const double smallRadius  =   4.0;

const double bevelSize = 1.2;

final ShapeDecoration fullRadiusBeveledDecoration = ShapeDecoration(
    shape: GradientBorderShape(
        borderRadius: BorderRadius.circular(fullRadius),
        borderWidth: bevelSize,
        gradient: LinearGradient(
            begin: const Alignment(-0.075, -0.75),
            end: const Alignment(0.02, 1),
            colors: [
                BeColorSwatch.white.withAlpha(180),
                BeColorSwatch.white.withAlpha(0),
                BeColorSwatch.white.withAlpha(0),
                BeColorSwatch.white.withAlpha(100),
            ],
            stops: const [0, 0.4, 0.6, 1],
        ),
    ),
);

final ShapeDecoration beveledDecoration = ShapeDecoration(
    shape: GradientBorderShape(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderWidth: bevelSize,
        gradient: LinearGradient(
            begin: const Alignment(-0.075, -0.75),
            end: const Alignment(0.02, 1),
            colors: [
                BeColorSwatch.white.withAlpha(180),
                BeColorSwatch.white.withAlpha(0),
                BeColorSwatch.white.withAlpha(0),
                BeColorSwatch.white.withAlpha(100),
            ],
            stops: const [0, 0.4, 0.6, 1],
        ),
    ),
);

final BoxDecoration hardEdgeDecoration = BoxDecoration(
    border: Border.all(
        width: 0.333,
        color: BeColorSwatch.navy.withAlpha(60),
        strokeAlign: BorderSide.strokeAlignOutside,
    ),
    borderRadius: BorderRadius.circular(mediumRadius),
);

final Padding gfieldDropDownIcon = const Padding(
    padding: EdgeInsets.only(top: 2),
    child: SFIcon(
        SFIcons.sf_chevron_down,
        color: BeColorSwatch.blue,
        fontSize: 16,
        fontWeight: FontWeight.bold,
    ),
);

final TextStyle gfieldHintStyle = TextStyle(
    color: beColorScheme.text.tertiary,
    fontWeight: FontWeight.normal,
);

final EdgeInsets gfieldHorizontalPadding = const EdgeInsets.symmetric(horizontal: 10);

const double gfieldRoundedBorderWidth = 1.5;

final OutlineInputBorder gfieldRoundedBorder = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(mediumRadius)),
    borderSide: BorderSide(
        color: beColorScheme.text.quaternary,
        width: gfieldRoundedBorderWidth,
    ),
);

final EdgeInsets gfieldVerticalPadding = const EdgeInsets.only(top: 8, bottom: 16);

final BoxDecoration gfieldBoxDecoration = BoxDecoration(
    border: Border.fromBorderSide(gfieldRoundedBorder.borderSide),
    borderRadius: gfieldRoundedBorder.borderRadius,
);

final InputDecoration gfieldInputDecoration = InputDecoration(
    enabledBorder: gfieldRoundedBorder,
    errorBorder: gfieldRoundedBorder.copyWith(
        borderSide: gfieldRoundedBorder.borderSide.copyWith(
            color: BeColorSwatch.red,
            width: gfieldRoundedBorderWidth,
        ),
    ),
    fillColor: BeColorSwatch.offWhite,
    filled: true,
    focusedBorder: gfieldRoundedBorder.copyWith(
        borderSide: gfieldRoundedBorder.borderSide.copyWith(
            width: gfieldRoundedBorderWidth + 0.5,
            color: BeColorSwatch.blue,
        ),
    ),
    focusedErrorBorder: gfieldRoundedBorder.copyWith(
        borderSide: gfieldRoundedBorder.borderSide.copyWith(
            width: gfieldRoundedBorderWidth + 0.5,
            color: BeColorSwatch.red,
        ),
    ),
    border: gfieldRoundedBorder,
    contentPadding: gfieldHorizontalPadding,
);

Widget formFieldLabel({
    required String labelText,
    int fieldId = 0,
    bool isRequired = false,
    bool isValid = true,
}) {
    if (labelText == "") {
        return const SizedBox.shrink();
    }

    return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
                TextSpan(
                    children: [
                        TextSpan(
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

Widget formFieldDescription({
    required String descriptionText,
    int fieldId = 0,
    bool isRequired = false,
}) {
    if (descriptionText == "") {
        return const SizedBox.shrink();
    }

    return Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 8),
        child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
                RichText(
                    text: TextSpan(
                        style: beTextTheme.headingPrimary.merge(const TextStyle(fontSize: 28)),
                        children: [
                            TextSpan(
                                text: descriptionText + (isRequired ? '\u2060' : ''),
                            ),
                            if (isRequired)
                                TextSpan(
                                    text: '*',
                                    style: beTextTheme.headingPrimary.merge(
                                        TextStyle(
                                            color: beColorScheme.text.accent2,
                                            height: 0.75,
                                        ),
                                    ),
                                ),
                        ],
                    ),
                ),
            ],
        ),
    );
}

final Color appAccentColor = BeColorSwatch.blue;

final ColorScheme appColorSchemeLight = ColorScheme.light(
    brightness:               Brightness.light,
    primary:                  BeColorSwatch.blue,
    onPrimary:                BeColorSwatch.white,
    primaryContainer:         BeColorSwatch.lighterBlue,
    onPrimaryContainer:       BeColorSwatch.navy,
    primaryFixed:             BeColorSwatch.lighterBlue,
    primaryFixedDim:          BeColorSwatch.lightBlue,
    onPrimaryFixed:           BeColorSwatch.navy,
    onPrimaryFixedVariant:    BeColorSwatch.darkBlue,
    secondary:                BeColorSwatch.green,
    onSecondary:              BeColorSwatch.white,
    secondaryContainer:       BeColorSwatch.lightGray,
    onSecondaryContainer:     BeColorSwatch.green,
    secondaryFixed:           BeColorSwatch.green,
    secondaryFixedDim:        BeColorSwatch.darkGray,
    onSecondaryFixed:         BeColorSwatch.white,
    onSecondaryFixedVariant:  BeColorSwatch.navy,
    tertiary:                 BeColorSwatch.orange,
    onTertiary:               BeColorSwatch.navy,
    tertiaryContainer:        BeColorSwatch.yellow,
    onTertiaryContainer:      BeColorSwatch.navy,
    tertiaryFixed:            BeColorSwatch.yellow,
    tertiaryFixedDim:         BeColorSwatch.orange,
    onTertiaryFixed:          BeColorSwatch.navy,
    onTertiaryFixedVariant:   BeColorSwatch.darkBlue,
    error:                    BeColorSwatch.red,
    onError:                  BeColorSwatch.white,
    errorContainer:           BeColorSwatch.lighterGray,
    onErrorContainer:         BeColorSwatch.red,
    surface:                  BeColorSwatch.white,
    onSurface:                BeColorSwatch.black,
    surfaceVariant:           BeColorSwatch.lighterGray,
    onSurfaceVariant:         BeColorSwatch.darkGray,
    surfaceTint:              Colors.transparent,
    surfaceDim:               BeColorSwatch.offWhite,
    surfaceBright:            BeColorSwatch.white,
    surfaceContainerLowest:   BeColorSwatch.white,
    surfaceContainerLow:      BeColorSwatch.offWhite,
    surfaceContainer:         BeColorSwatch.white,
    surfaceContainerHigh:     BeColorSwatch.lighterGray,
    surfaceContainerHighest:  BeColorSwatch.lightGray,
    background:               BeColorSwatch.offWhite,
    onBackground:             BeColorSwatch.navy,
    outline:                  BeColorSwatch.lightGray,
    outlineVariant:           BeColorSwatch.lighterGray,
    shadow:                   BeColorSwatch.black,
    scrim:                    BeColorSwatch.black,
    inverseSurface:           BeColorSwatch.navy,
    onInverseSurface:         BeColorSwatch.offWhite,
    inversePrimary:           BeColorSwatch.lightBlue,
);

const ColorScheme appColorSchemeDark = ColorScheme.dark(
    brightness:               Brightness.dark,
    primary:                  BeColorSwatch.blue,
    onPrimary:                BeColorSwatch.white,
    primaryContainer:         BeColorSwatch.darkBlue,
    onPrimaryContainer:       BeColorSwatch.lightBlue,
    primaryFixed:             BeColorSwatch.lightBlue,
    primaryFixedDim:          BeColorSwatch.blue,
    onPrimaryFixed:           BeColorSwatch.navy,
    onPrimaryFixedVariant:    BeColorSwatch.white,
    secondary:                BeColorSwatch.green,
    onSecondary:              BeColorSwatch.white,
    secondaryContainer:       BeColorSwatch.darkGray,
    onSecondaryContainer:     BeColorSwatch.green,
    secondaryFixed:           BeColorSwatch.green,
    secondaryFixedDim:        BeColorSwatch.darkGray,
    onSecondaryFixed:         BeColorSwatch.white,
    onSecondaryFixedVariant:  BeColorSwatch.navy,
    tertiary:                 BeColorSwatch.orange,
    onTertiary:               BeColorSwatch.navy,
    tertiaryContainer:        BeColorSwatch.darkGray,
    onTertiaryContainer:      BeColorSwatch.orange,
    tertiaryFixed:            BeColorSwatch.orange,
    tertiaryFixedDim:         BeColorSwatch.darkGray,
    onTertiaryFixed:          BeColorSwatch.navy,
    onTertiaryFixedVariant:   BeColorSwatch.offWhite,
    error:                    BeColorSwatch.red,
    onError:                  BeColorSwatch.white,
    errorContainer:           BeColorSwatch.darkGray,
    onErrorContainer:         BeColorSwatch.red,
    surface:                  BeColorSwatch.navy,
    onSurface:                BeColorSwatch.offWhite,
    surfaceVariant:           BeColorSwatch.darkGray,
    onSurfaceVariant:         BeColorSwatch.lightGray,
    surfaceTint:              Colors.transparent,
    surfaceDim:               BeColorSwatch.black,
    surfaceBright:            BeColorSwatch.darkGray,
    surfaceContainerLowest:   BeColorSwatch.black,
    surfaceContainerLow:      BeColorSwatch.navy,
    surfaceContainer:         BeColorSwatch.darkGray,
    surfaceContainerHigh:     BeColorSwatch.gray,
    surfaceContainerHighest:  BeColorSwatch.lightGray,
    background:               BeColorSwatch.navy,
    onBackground:             BeColorSwatch.offWhite,
    outline:                  BeColorSwatch.gray,
    outlineVariant:           BeColorSwatch.darkGray,
    shadow:                   BeColorSwatch.black,
    scrim:                    BeColorSwatch.black,
    inverseSurface:           BeColorSwatch.offWhite,
    onInverseSurface:         BeColorSwatch.navy,
    inversePrimary:           BeColorSwatch.lightBlue,
);

const SnackBarThemeData snackBarTheme = SnackBarThemeData(
    backgroundColor: BeColorSwatch.blue,
    behavior: SnackBarBehavior.fixed,
    contentTextStyle: TextStyle(
        color: BeColorSwatch.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
    ),
    elevation: 10,
);

final ButtonStyle roundElevatedButtonStyle = ButtonStyle(
    animationDuration: buttonOverlayFadeDuration,
    padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(
            horizontal: beTextTheme.headingPrimary.fontSize! * 1.2,
            vertical: beTextTheme.headingPrimary.fontSize! * 0.6,
        ),
    ),
    overlayColor: WidgetStateProperty.all(BeColorSwatch.white.withAlpha(60)),
    shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(fullRadius)),
    ),
    textStyle: WidgetStateProperty.all(
        beTextTheme.headingPrimary.merge(
            const TextStyle(color: BeColorSwatch.white),
        ),
    ),
);

final ButtonStyle elevatedButtonStyleAlt = ButtonStyle(
    animationDuration: buttonOverlayFadeDuration,
    alignment: AlignmentDirectional.centerStart,
    backgroundColor: WidgetStateProperty.all(BeColorSwatch.navy),
    minimumSize: WidgetStateProperty.all(const Size(double.infinity, 12)),
    overlayColor: WidgetStateProperty.all(BeColorSwatch.white.withAlpha(60)),
    shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(mediumRadius)),
    ),
    textStyle: WidgetStateProperty.all(beTextTheme.headingPrimary),
);

final CheckboxThemeData appCheckboxTheme = CheckboxThemeData(
    fillColor: WidgetStateProperty.fromMap({WidgetState.selected: appAccentColor}),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    shape: RoundedRectangleBorder(
        side: BorderSide(
            color: gfieldBoxDecoration.border!.top.color,
            width: (gfieldBoxDecoration.border!.top.width / 1.4),
        ),
        borderRadius: BorderRadius.circular(smallRadius),
    ),
    side: BorderSide(
        color: gfieldBoxDecoration.border!.top.color,
        width: (gfieldBoxDecoration.border!.top.width / 1.4),
    ),
    splashRadius: 0,
);

final InputDecorationTheme appInputDecorationTheme = InputDecorationTheme(
    border: gfieldRoundedBorder,
    contentPadding: gfieldHorizontalPadding,
    enabledBorder: gfieldRoundedBorder,
    fillColor: appColorSchemeLight.surfaceContainer,
    filled: true,
    focusedBorder: gfieldRoundedBorder.copyWith(
        borderSide: gfieldRoundedBorder.borderSide.copyWith(
            width: gfieldRoundedBorderWidth + 0.5,
            color: BeColorSwatch.blue,
        ),
    ),
);

final RadioThemeData appRadioTheme = RadioThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
            return appAccentColor;
        }
        return gfieldRoundedBorder.borderSide.color;
    }),
    splashRadius: 0,
);

final SwitchThemeData appSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.all(BeColorSwatch.offWhite),
    thumbIcon: WidgetStateProperty.all(
        Icon(Icons.circle, color: BeColorSwatch.offWhite),
    ),
    trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? appAccentColor
            : BeColorSwatch.lightGray,
    ),
    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    trackOutlineWidth: WidgetStateProperty.all(0.0),
);

final TextButtonThemeData appTextButtonTheme = TextButtonThemeData(
    style: ButtonStyle(
        animationDuration: buttonOverlayFadeDuration,
        overlayColor: WidgetStateProperty.all(BeColorSwatch.white.withAlpha(60)),
        splashFactory: NoSplash.splashFactory,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
                color: states.contains(WidgetState.pressed)
                    ? appAccentColor
                    : BeColorSwatch.gray,
                height: 0,
            ),
        ),
        visualDensity: VisualDensity.compact,
    ),
);

final ElevatedButtonThemeData appElevatedButtonTheme = ElevatedButtonThemeData(
    style: ButtonStyle(
        animationDuration: buttonOverlayFadeDuration,
        backgroundColor: WidgetStateProperty.all(appAccentColor),
        foregroundColor: WidgetStateProperty.all(BeColorSwatch.white),
        overlayColor: WidgetStateProperty.all(BeColorSwatch.white.withAlpha(60)),
        padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
                horizontal: (((beTextTheme.bodyPrimary.fontSize! / 2) + 2) * 2),
                vertical: ((beTextTheme.bodyPrimary.fontSize! / 2) + 2),
            ),
        ),
        splashFactory: NoSplash.splashFactory,
        textStyle: WidgetStateProperty.all(
            beTextTheme.bodyPrimary.merge(
                TextStyle(color: BeColorSwatch.white, fontWeight: FontWeight.bold),
            ),
        ),
    ),
);

final TextTheme appTextTheme = TextTheme(
    bodyLarge: beTextTheme.bodyPrimary,
    bodyMedium: beTextTheme.bodyPrimary,
    bodySmall: beTextTheme.bodySecondary,
    displayLarge: beTextTheme.titlePrimary,
    displayMedium: beTextTheme.titleSecondary,
    displaySmall: beTextTheme.titleSecondary,
    headlineLarge: beTextTheme.headingPrimary,
    headlineMedium: beTextTheme.headingSecondary,
    headlineSmall: beTextTheme.headingTertiary,
    labelLarge: beTextTheme.bodyPrimary.merge(TextStyle(fontWeight: FontWeight.bold)),
    labelMedium: beTextTheme.bodyPrimary.merge(TextStyle(fontWeight: FontWeight.bold)),
    labelSmall: beTextTheme.bodySecondary.merge(TextStyle(fontWeight: FontWeight.bold)),
    titleLarge: beTextTheme.headingPrimary,
    titleMedium: beTextTheme.headingSecondary,
    titleSmall: beTextTheme.headingTertiary,
);

const SlideTransitionsBuilder appSlideTransitionsBuilder = SlideTransitionsBuilder();
