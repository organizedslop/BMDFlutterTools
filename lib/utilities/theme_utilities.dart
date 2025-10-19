/*
 * Theme Utilities
 *
 * Created by:  Blake Davis
 * Description: Utilities for managing app-wide constants for colors, dimensions, and text
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:flutter/material.dart";




/* ======================================================================================================================
 * MARK: Dimensions
 * ------------------------------------------------------------------------------------------------------------------ */
class BEDimensions {

    final double insetListGroupCornerRadius,
                 insetListHorizontalMargin,
                 insetListGroupSpacing,
                 insetListItemPadding,
                 insetListGroupHorizontalPadding,
                 insetListGroupVerticalPadding,
                 insetListTitleLeadingMargin;

    BEDimensions({ required this.insetListGroupCornerRadius,
                   required this.insetListHorizontalMargin,
                   required this.insetListGroupSpacing,
                   required this.insetListItemPadding,
                   required this.insetListGroupHorizontalPadding,
                   required this.insetListGroupVerticalPadding,
                   required this.insetListTitleLeadingMargin
    });
}

final BEDimensions beDimensions = BEDimensions(
    insetListGroupCornerRadius:      10,
    insetListHorizontalMargin:       12,
    insetListGroupSpacing:           16,
    insetListItemPadding:             6,
    insetListGroupHorizontalPadding: 10,
    insetListGroupVerticalPadding:   10,
    insetListTitleLeadingMargin:      8
);




/* ======================================================================================================================
 * MARK: Text
 * ------------------------------------------------------------------------------------------------------------------ */
class BETextTheme {
    final TextStyle titleLarge;
    final TextStyle titlePrimary;
    final TextStyle titleSecondary;

    final TextStyle headingPrimary;
    final TextStyle headingSecondary;
    final TextStyle headingTertiary;

    final TextStyle bodyPrimary;
    final TextStyle bodySecondary;
    final TextStyle bodyTertiary;

    final TextStyle captionPrimary;
    final TextStyle captionSecondary;

    BETextTheme({ required this.titleLarge,
                  required this.titlePrimary,
                  required this.titleSecondary,
                  required this.headingPrimary,
                  required this.headingSecondary,
                  required this.headingTertiary,
                  required this.bodyPrimary,
                  required this.bodySecondary,
                  required this.bodyTertiary,
                  required this.captionPrimary,
                  required this.captionSecondary });
}

final BETextTheme beTextTheme = BETextTheme(
    titleLarge:         TextStyle(  fontFamily: "tungsten",
                                    fontSize:   48,
                                    // fontWeight: FontWeight.w800,
                                    color:      beColorScheme.text.primary),
    titlePrimary:       TextStyle(  fontFamily: "tungsten",
                                    fontSize:   32,
                                    // fontWeight: FontWeight.w800,
                                    color:      beColorScheme.text.primary),
    titleSecondary:     TextStyle(  fontFamily: "tungsten",
                                    fontSize:   26,
                                    // fontWeight: FontWeight.w800,
                                    color:      beColorScheme.text.primary),
    headingPrimary:     TextStyle(  fontFamily: "lato",
                                    fontSize:   24,
                                    fontWeight: FontWeight.w800,
                                    color:      beColorScheme.text.primary),
    headingSecondary:   TextStyle(  fontFamily: "lato",
                                    fontSize:   20,
                                    fontWeight: FontWeight.w800,
                                    color:      beColorScheme.text.primary),
    headingTertiary:    TextStyle(  fontFamily: "lato",
                                    fontSize:   18,
                                    fontWeight: FontWeight.w800,
                                    color:      beColorScheme.text.primary),
    bodyPrimary:        TextStyle(  fontFamily: "lato",
                                    fontSize:   16,
                                    fontWeight: FontWeight.normal,
                                    color: beColorScheme.text.primary),
    bodySecondary:      TextStyle(  fontFamily: "lato",
                                    fontSize:   14,
                                    fontWeight: FontWeight.normal,
                                    color:      beColorScheme.text.primary),
    bodyTertiary:       TextStyle(  fontFamily: "lato",
                                    fontSize:   12,
                                    fontWeight: FontWeight.normal,
                                    color:      beColorScheme.text.primary),
    captionPrimary:     TextStyle(  fontFamily: "lato",
                                    fontSize:   12,
                                    fontWeight: FontWeight.w600,
                                    color:      beColorScheme.text.tertiary),
    captionSecondary:   TextStyle(  fontFamily: "lato",
                                    fontSize:   8,
                                    fontWeight: FontWeight.w600,
                                    color:      beColorScheme.text.tertiary),
);




/* ======================================================================================================================
 * MARK: Colors
 * ---------------------------------------------------------------------------------------------------------------------
 * MARK: Color Swatches
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
enum BeColorSwatch {
    white(          Color(0xffffffff)),
    offWhite(       Color(0xfffafafc)),
    lighterGray(    Color(0xffeeecf0)),
    lightGray(      Color(0xffb1b3b6)),
    gray(           Color(0xffa1a3a6)),
    darkGray(       Color(0xff58595b)),
    darkerGray(     Color(0xff3a3b3d)),
    lighterBlack(   Color(0xff272625)),
    lightBlack(     Color(0xff191919)),
    black(          Color(0xff000000)),
    lighterRed(     Color(0xffffb6b8)),
    lightRed(       Color(0xffff6a70)),
    red(            Color(0xffda2228)),
    darkRed(        Color(0xff940014)),
    darkerRed(      Color(0xff5a000c)),
    lighterOrange(  Color(0xffffe0bd)),
    lightOrange(    Color(0xffffb96f)),
    orange(         Color(0xffff9a42)),
    darkOrange(     Color(0xffcc6f15)),
    darkerOrange(   Color(0xff8a4700)),
    lighterYellow(  Color(0xfffff3b3)),
    lightYellow(    Color(0xffffdd55)),
    yellow(         Color(0xffffcc00)),
    darkYellow(     Color(0xffc7a000)),
    darkerYellow(   Color(0xff8f6e00)),
    lighterGreen(   Color(0xffa4f1b4)),
    lightGreen(     Color(0xff5fe279)),
    green(          Color(0xff20c94a)),
    darkGreen(      Color(0xff178236)),
    darkerGreen(    Color(0xff0e5223)),
    lighterBlue(    Color(0xffd9e7ff)),
    lightBlue(      Color(0xff99c0ff)),
    blue(           Color(0xff3478f6)),
    darkBlue(       Color(0xff1c3579)),
    darkerBlue(     Color(0xff111f4f)),
    lighterNavy(    Color(0xff3a4b7d)),
    lightNavy(      Color(0xff1b2559)),
    navy(           Color(0xff000334)),
    darkNavy(       Color(0xff00011f)),
    darkerNavy(     Color(0xff00000f)),
    lighterPurple(  Color(0xffd2ccfb)),
    lightPurple(    Color(0xffa297eb)),
    purple(         Color(0xff796bd6)),
    darkPurple(     Color(0xff4f3fa0)),
    darkerPurple(   Color(0xff2f246c)),
    lighterMagenta( Color(0xffffc2ff)),
    lightMagenta(   Color(0xffff66ff)),
    magenta(        Color(0xffff00ff)),
    darkMagenta(    Color(0xffb300b3)),
    darkerMagenta(  Color(0xff7a007a));

    const BeColorSwatch(this.color);

    final Color color;

    static Map<String, Color> get entries => {
        for (final swatch in BeColorSwatch.values) swatch.name: swatch.color,
    };
}

/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Color Palette
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
class BEColorPalette {
    final Color primary,
                secondary,
                tertiary,
                quaternary,
                inverse,
                accent,
                accent2,
                unaccent = BeColorSwatch.gray.color,
                debug    = BeColorSwatch.magenta.color;


    BEColorPalette({
        required this.primary,
        required this.secondary,
        required this.tertiary,
        required this.quaternary,
        required this.inverse,
        required this.accent,
        required this.accent2
    });
}




/* ---------------------------------------------------------------------------------------------------------------------
 * MARK: Color Scheme
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
class BEColorScheme {
    final BEColorPalette text;
    final BEColorPalette background;

    BEColorScheme({ required this.text, required this.background });
}




final BEColorScheme beColorSchemeLight = BEColorScheme(
    text:       BEColorPalette(
                    primary:    BeColorSwatch.black.color,
                    secondary:  BeColorSwatch.navy.color,
                    tertiary:   BeColorSwatch.gray.color,
                    quaternary: BeColorSwatch.lightGray.color,
                    inverse:    BeColorSwatch.white.color,
                    accent:     BeColorSwatch.blue.color,
                    accent2:    BeColorSwatch.red.color
                ),

    background: BEColorPalette(
                    primary:    BeColorSwatch.offWhite.color,
                    secondary:  BeColorSwatch.white.color,
                    tertiary:   BeColorSwatch.lighterGray.color,
                    quaternary: BeColorSwatch.lightGray.color,
                    inverse:    BeColorSwatch.navy.color,
                    accent:     BeColorSwatch.red.color,
                    accent2:    BeColorSwatch.blue.color
                )
);




final BEColorScheme beColorSchemeDark = BEColorScheme(
    text:       BEColorPalette(
                    primary:    BeColorSwatch.white.color,
                    secondary:  BeColorSwatch.gray.color,
                    tertiary:   BeColorSwatch.navy.color,
                    quaternary: BeColorSwatch.gray.color,
                    inverse:    BeColorSwatch.black.color,
                    accent:     BeColorSwatch.blue.color,
                    accent2:    BeColorSwatch.red.color
                ),

    background: BEColorPalette(
                    primary:    BeColorSwatch.navy.color,
                    secondary:  BeColorSwatch.black.color,
                    tertiary:   BeColorSwatch.gray.color,
                    quaternary: BeColorSwatch.navy.color,
                    inverse:    BeColorSwatch.offWhite.color,
                    accent:     BeColorSwatch.red.color,
                    accent2:    BeColorSwatch.blue.color
                )
);




final BEColorScheme beColorScheme = beColorSchemeLight;
