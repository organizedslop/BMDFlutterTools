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
class BeColorSwatch {

    const BeColorSwatch();

    static const Color black       = Color(0xff000000);
    static const Color lighterBlue = Color(0xffd9e7ff);
    static const Color lightBlue   = Color(0xff99c0ff);
    static const Color blue        = Color(0xff3478f6);
    static const Color darkBlue    = Color(0xff1c3579);
    static const Color darkGray    = Color(0xff58595b);
    static const Color gray        = Color(0xffa1a3a6);
    static const Color green       = Color(0xff20c94a);
    static const Color lightGray   = Color(0xffb1b3b6);
    static const Color lighterGray = Color(0xffeeecf0);
    static const Color magenta     = Color(0xffff00ff);
    static const Color navy        = Color(0xff000334);
    static const Color red         = Color(0xffda2228);
    static const Color offWhite    = Color(0xfffafafc);
    static const Color orange      = Color(0xffff9a42);
    static const Color purple      = Color(0xff796bd6);
    static const Color white       = Color(0xffffffff);
    static const Color yellow      = Color(0xffffcc00);
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
                unaccent = BeColorSwatch.gray,
                debug    = BeColorSwatch.magenta;


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
                    primary:    BeColorSwatch.black,
                    secondary:  BeColorSwatch.navy,
                    tertiary:   BeColorSwatch.gray,
                    quaternary: BeColorSwatch.lightGray,
                    inverse:    BeColorSwatch.white,
                    accent:     BeColorSwatch.blue,
                    accent2:    BeColorSwatch.red
                ),

    background: BEColorPalette(
                    primary:    BeColorSwatch.offWhite,
                    secondary:  BeColorSwatch.white,
                    tertiary:   BeColorSwatch.lighterGray,
                    quaternary: BeColorSwatch.lightGray,
                    inverse:    BeColorSwatch.navy,
                    accent:     BeColorSwatch.red,
                    accent2:    BeColorSwatch.blue
                )
);




final BEColorScheme beColorSchemeDark = BEColorScheme(
    text:       BEColorPalette(
                    primary:    BeColorSwatch.white,
                    secondary:  BeColorSwatch.gray,
                    tertiary:   BeColorSwatch.navy,
                    quaternary: BeColorSwatch.gray,
                    inverse:    BeColorSwatch.black,
                    accent:     BeColorSwatch.blue,
                    accent2:    BeColorSwatch.red
                ),

    background: BEColorPalette(
                    primary:    BeColorSwatch.navy,
                    secondary:  BeColorSwatch.black,
                    tertiary:   BeColorSwatch.gray,
                    quaternary: BeColorSwatch.navy,
                    inverse:    BeColorSwatch.offWhite,
                    accent:     BeColorSwatch.red,
                    accent2:    BeColorSwatch.blue
                )
);




final BEColorScheme beColorScheme = beColorSchemeLight;