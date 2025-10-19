/*
 * User Menu
 *
 * Created by:  Blake Davis
 * Description: A widget for displaying user account options
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_sficon/flutter_sficon.dart";




/* ======================================================================================================================
 * MARK: User Menu
 * ------------------------------------------------------------------------------------------------------------------ */
class UserMenu extends StatelessWidget {

    final storage = FlutterSecureStorage();




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Consumer(
            key:     Key("primary_navigation_bar__user_account_button"),
            builder: (context, ref, child) {
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: PopupMenuButton<int>(
                        borderRadius: BorderRadius.circular(fullRadius),
                        position:     PopupMenuPosition.under,
                        shape:        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        tooltip:      "User Options",
                        onSelected:   (value) async {

                            switch (value) {
                                case 1:
                                    appRouter.pushNamed("user profile");

                                // Logout action
                                case 2:
                                    // TODO: Move all this invalidating to a function in global_state
                                    ref.invalidate(userProvider);
                                    ref.invalidate(badgeProvider);
                                    ref.invalidate(companyProvider);
                                    ref.invalidate(showProvider);

                                    /*
                                     * Wait for sign out to complete before navigating to sign in page, to
                                     * prevent the app from trying to automatically sign back in.
                                     */
                                    await ApiClient.instance.logout();

                                    // Use "go" to pop all pages on the stack
                                    appRouter.goNamed("signin");
                            }
                        },
                        itemBuilder: (context) {
                            return [
                                PopupMenuItem<int>(
                                    value: 1,
                                    child: Row(
                                        spacing:  8,
                                        children: [
                                            SFIcon(SFIcons.sf_person_crop_circle,
                                                fontSize: beTextTheme.headingSecondary.fontSize,
                                            ),
                                            Text("My Badge", style: beTextTheme.bodyPrimary)
                                        ]
                                    ),
                                ),
                                PopupMenuItem<int>(
                                    key:   Key("primary_navigation_bar__sign_out_button"),
                                    value: 2,
                                    child: Row(
                                        spacing:  8,
                                        children: [
                                            SFIcon(SFIcons.sf_rectangle_portrait_and_arrow_forward,
                                                fontSize: beTextTheme.headingSecondary.fontSize,
                                            ),
                                            Text("Sign Out", style: beTextTheme.bodyPrimary),
                                        ]
                                    )
                                )
                            ];
                        },
                        icon: SFIcon(
                            SFIcons.sf_person_crop_circle,
                          //  color:    BeColorSwatch.white.color,
                            fontSize: beTextTheme.headingPrimary.fontSize
                        )
                    )
                );
            }
        );
    }
}
