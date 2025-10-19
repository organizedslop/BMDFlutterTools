/*
 * Connections Options Menu
 *
 * Created by:  Blake Davis
 * Description: Modal connections options menu widget
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/inset_list_section.dart";
import "package:bmd_flutter_tools/widgets/list_action_item.dart";
import "package:bmd_flutter_tools/widgets/list_link_item.dart";

import "package:flutter/material.dart";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:flutter_sficon/flutter_sficon.dart";

import "package:go_router/go_router.dart";




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
                child:  InsetListSection(
                    padding:        const EdgeInsets.all(0),
                    showBackground: false,
                    children:       [

                        Row(mainAxisAlignment: MainAxisAlignment.center,
                            children:          [Text("Lead Retrieval Options", style: beTextTheme.headingSecondary)],
                        ),

                        ListActionItem(
                            action: () {},
                            label: Expanded(
                                child: Row(
                                    children: [
                                        Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child:   SFIcon(SFIcons.sf_square_and_arrow_up,
                                                fontSize:   beTextTheme.bodyPrimary.fontSize,
                                                fontWeight: beTextTheme.bodyPrimary.fontWeight,
                                                color:      beColorScheme.text.accent)),
                                        Text("Export leads list", style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent))),
                                    ]
                                )
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),

                        ListLinkItem(
                            action:       () { appRouter.pushNamed("user settings"); },
                            padding:      EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            primaryLabel: Row(
                                children: [
                                    Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child:   SFIcon(SFIcons.sf_square_and_pencil,
                                            fontSize:   beTextTheme.bodyPrimary.fontSize,
                                            fontWeight: beTextTheme.bodyPrimary.fontWeight,
                                            color:      beColorScheme.text.accent)),
                                    Text("Manage licenses", style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent))),
                                ]
                            ),
                        ),

                        ListLinkItem(
                            action:       () {},
                            padding:      EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            primaryLabel: Row(
                                children: [
                                    Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child:   SFIcon(SFIcons.sf_person_badge_plus,
                                            fontSize:   beTextTheme.bodyPrimary.fontSize,
                                            fontWeight: beTextTheme.bodyPrimary.fontWeight,
                                            color:      beColorScheme.text.accent)),
                                    Text("Get more user licenses", style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent))),
                                ]
                            )
                        ),

                        ListLinkItem(
                            action:       () {},
                            padding:      EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            primaryLabel: Row(
                                children: [
                                    Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child:   SFIcon(SFIcons.sf_document,
                                            fontSize:   beTextTheme.bodyPrimary.fontSize,
                                            fontWeight: beTextTheme.bodyPrimary.fontWeight,
                                            color:      beColorScheme.text.accent)),
                                    Text("Get the full attendee list", style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent))),
                                ]
                            )
                        ),

                        ListActionItem(label: Text("Done", style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent))),
                            action: () {}
                        )
                    ]
                )
            )
        );
    }
}