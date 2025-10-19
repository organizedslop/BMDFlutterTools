/*
 *  Navigation Menu
 *
 * Created by:  Blake Davis
 * Description: Navigation menu
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_info.dart" as appInfo;
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/widgets/navigation/navigation_link.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/utilities/tool__no_scale_wrapper.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";




/* ======================================================================================================================
 * MARK: Navigation Menu
 * ------------------------------------------------------------------------------------------------------------------ */
class NavigationMenu extends ConsumerWidget {

    final storage = FlutterSecureStorage();


    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Navigation Header
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    DrawerHeader navigationHeader(BuildContext context) {
        return DrawerHeader(
            padding:    EdgeInsets.zero,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment:  MainAxisAlignment.center,
                children: [
                    Flexible(
                        child: Image.asset(
                            "./assets/images/build-expo-usa-logo-horizontal.png",
                            fit: BoxFit.fill
                        ),
                    ),
                    // Title removed
                ]
            )
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context, WidgetRef ref) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);

        return FutureBuilder(
            future:  (() async => await storage.read(key: "username"))(),
            builder: (BuildContext context, AsyncSnapshot<String?> username) {
                return Drawer(
                    width:     300,
                    elevation: 3,
                    child: Padding(
                        padding: EdgeInsets.only(left: 4, right: 2),
                        child:   Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment:  MainAxisAlignment.start,
                            mainAxisSize:       MainAxisSize.max,
                            children: [
                                SizedBox(height: 120, child: navigationHeader(context)),

                                NavigationLink(
                                    leading: const NoScale(child: SFIcon(SFIcons.sf_house)),
                                    title:   "Home",
                                    url:     "/home",
                                    action:  () {
                                        context.go("home");
                                    }
                                ),

                                NavigationLink(
                                    leading: const NoScale(child: SFIcon(SFIcons.sf_person_crop_circle)),
                                    title:   "My Badge",
                                    url:     "/user_profile",
                                ),

                                NavigationLink(
                                    leading: const NoScale(child: SFIcon(SFIcons.sf_bell)),
                                    title:   "Notifications",
                                    url:     "/notifications",
                                ),

                                NavigationLink(
                                    leading: const NoScale(child: SFIcon(SFIcons.sf_list_bullet)),
                                    title:   (textScaleFactor > 1.667) ? "Registrations" : "My Registrations",
                                    url:     "/my_registrations",
                                ),

                                NavigationLink(
                                    leading: const NoScale(child: SFIcon(SFIcons.sf_globe_americas_fill)),
                                    title:   "All Shows",
                                    url:     "/all_shows",
                                ),

                                NavigationLink(
                                    leading: const NoScale(child: SFIcon(SFIcons.sf_phone)),
                                    title:   (textScaleFactor > 1.5) ? "Contact" : "Contact Build Expo",
                                    url:     "/contact_us",
                                ),

                                NavigationLink(
                                    leading: const NoScale(child: SFIcon(SFIcons.sf_gear)),
                                    title:   (textScaleFactor > 1.667) ? "Settings" : "Account Settings",
                                    url:     "/user_settings",
                                ),

                                NavigationLink(
                                    leading: const NoScale(child: SFIcon(SFIcons.sf_rectangle_portrait_and_arrow_forward)),
                                    title:   "Sign out",
                                    url:     "/signin",
                                    action: () async {
                                        logPrint("🔄 Signing out...");

                                        // TODO: This code is largely duplicated on user_menu.dart - move to a central location for easy reuse

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
                                        // appRouter.goNamed("signin");
                                    }
                                ),

                                Expanded(
                                    child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child:     Padding(
                                            padding: EdgeInsets.only(bottom: 24),
                                            child:   NoScale(
                                                child: Text(
                                                    "© 2009-${DateTime.now().year}\n International Conference Management, Inc.",
                                                    style: beTextTheme.bodyTertiary.merge(TextStyle(color: BeColorSwatch.darkGray.withAlpha(250), fontWeight: FontWeight.w600)),
                                                    textAlign: TextAlign.center
                                                )
                                            )
                                        )
                                    )
                                )
                            ]
                        )
                    )
                );
            },
        );
    }
}