/*
 * Connections Options Menu
 *
 * Created by:  Blake Davis
 * Description: Modal connections options menu widget
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";




/* ======================================================================================================================
 * MARK: Connections Options Menu
 * ------------------------------------------------------------------------------------------------------------------ */
class ConnectionsOptionsMenu extends ConsumerStatefulWidget {


    ConnectionsOptionsMenu({ super.key });


    @override
    ConsumerState<ConnectionsOptionsMenu> createState() => _ConnectionsOptionsMenuState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _ConnectionsOptionsMenuState extends ConsumerState<ConnectionsOptionsMenu> {

    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();
    }

    Widget _buildCenteredAction({
        required Widget child,
        required VoidCallback onTap,
        EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    }) {
        return InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            child: Padding(
                padding: padding,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Flexible(child: child)],
                ),
            ),
        );
    }

    Widget _buildLinkTile({
        required Widget label,
        required VoidCallback onTap,
        EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    }) {
        return InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            child: Padding(
                padding: padding,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        Expanded(child: label),
                        SFIcon(
                            SFIcons.sf_chevron_right,
                            fontSize: beTextTheme.bodyPrimary.fontSize,
                            fontWeight: FontWeight.w500,
                            color: beColorScheme.text.accent,
                        ),
                    ],
                ),
            ),
        );
    }



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content:        SizedBox(
                height: 400,
                width:  double.maxFinite,
                child:  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Text("Lead Retrieval Options", style: beTextTheme.headingSecondary)],
                        ),
                        const SizedBox(height: 12),
                        _buildCenteredAction(
                            onTap: () {},
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: SFIcon(
                                            SFIcons.sf_square_and_arrow_up,
                                            fontSize: beTextTheme.bodyPrimary.fontSize,
                                            fontWeight: beTextTheme.bodyPrimary.fontWeight,
                                            color: beColorScheme.text.accent,
                                        ),
                                    ),
                                    Text(
                                        "Export leads list",
                                        style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent)),
                                    ),
                                ],
                            ),
                        ),
                        _buildLinkTile(
                            onTap: () { appRouter.pushNamed("user settings"); },
                            label: Row(
                                children: [
                                    Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: SFIcon(
                                            SFIcons.sf_square_and_pencil,
                                            fontSize: beTextTheme.bodyPrimary.fontSize,
                                            fontWeight: beTextTheme.bodyPrimary.fontWeight,
                                            color: beColorScheme.text.accent,
                                        ),
                                    ),
                                    Text(
                                        "Manage licenses",
                                        style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent)),
                                    ),
                                ],
                            ),
                        ),
                        _buildLinkTile(
                            onTap: () {},
                            label: Row(
                                children: [
                                    Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: SFIcon(
                                            SFIcons.sf_person_badge_plus,
                                            fontSize: beTextTheme.bodyPrimary.fontSize,
                                            fontWeight: beTextTheme.bodyPrimary.fontWeight,
                                            color: beColorScheme.text.accent,
                                        ),
                                    ),
                                    Text(
                                        "Get more user licenses",
                                        style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent)),
                                    ),
                                ],
                            ),
                        ),
                        _buildLinkTile(
                            onTap: () {},
                            label: Row(
                                children: [
                                    Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: SFIcon(
                                            SFIcons.sf_document,
                                            fontSize: beTextTheme.bodyPrimary.fontSize,
                                            fontWeight: beTextTheme.bodyPrimary.fontWeight,
                                            color: beColorScheme.text.accent,
                                        ),
                                    ),
                                    Text(
                                        "Get the full attendee list",
                                        style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent)),
                                    ),
                                ],
                            ),
                        ),
                        _buildCenteredAction(
                            onTap: () {},
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                                "Done",
                                style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent)),
                            ),
                        ),
                    ],
                )
            )
        );
    }
}
