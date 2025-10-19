/*
 * Quick Navigation Bar
 *
 * Created by:  Blake Davis
 * Description: A widget which serves as the app's bottom navigation menu
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/debug/debug_text.dart";
import "package:bmd_flutter_tools/widgets/utilities/no_scale_wrapper.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";




/* ======================================================================================================================
 * MARK: Quick Navigation Bar
 * ------------------------------------------------------------------------------------------------------------------ */
class QuickNavigationBar extends ConsumerStatefulWidget {


    QuickNavigationBar({ super.key });


    @override
    ConsumerState<QuickNavigationBar> createState() => _QuickNavigationBarState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _QuickNavigationBarState extends ConsumerState<QuickNavigationBar> with RouteAware {


    String? _currentRouteName;

    bool _routerListenerAttached = false;

    late final RouterDelegate<Object> _routerDelegate;

    late final VoidCallback _routerListener;



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();
    }


    @override
    void didChangeDependencies() {
        super.didChangeDependencies();

        final modalRoute = ModalRoute.of(context)!;
        routeObserver.subscribe(this, modalRoute);
    }

    @override
    void dispose() {
        routeObserver.unsubscribe(this);

        super.dispose();
    }



    @override
    void didPush() => _updateCurrentRoute();

    @override
    void didPopNext() => _updateCurrentRoute();

    void _updateCurrentRoute() {
        final route = ModalRoute.of(context);
        setState(() {
            _currentRouteName = route?.settings.name;
        });
    }



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * MARK: Navigation Items by Role
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
         *
         *  { "<label>": { "route":      <route_name>,
         *                 "unselected": <unselected_icon>,
         *                 "selected":   <selected_icon>    } }
         */
        late final Map<String, Map<String, dynamic>> exhibitorItems = {
            "Dashboard": { "route":  "show",                   "unselected": SFIcons.sf_gauge_open_with_lines_needle_33percent,     "selected": SFIcons.sf_gauge_open_with_lines_needle_33percent                  },
            "My Badge":  { "route":  "user profile",           "unselected": SFIcons.sf_person_crop_circle,                         "selected": SFIcons.sf_person_crop_circle_fill     },
            "My Leads":  { "route":  "connections",            "unselected": SFIcons.sf_person_2,                                   "selected": SFIcons.sf_person_2_fill               },
        };

        final Map<String, Map<String, dynamic>> attendeeItems = {
            "Dashboard": { "route":  "show",                   "unselected": SFIcons.sf_gauge_open_with_lines_needle_33percent,     "selected": SFIcons.sf_gauge_open_with_lines_needle_33percent                  },
            "My Badge":  { "route":  "user profile",           "unselected": SFIcons.sf_person_crop_circle,     "selected": SFIcons.sf_person_crop_circle_fill     },
            "Seminars":  { "route":  "seminars list",          "unselected": SFIcons.sf_calendar,               "selected": SFIcons.sf_calendar                    },
        };

        late final Map<String, Map<String, dynamic>> adminItems = {
            "Dashboard": { "route":  "show",                   "unselected": SFIcons.sf_gauge_open_with_lines_needle_33percent,             "selected": SFIcons.sf_gauge_open_with_lines_needle_33percent                  },
            "My Badge":  { "route":  "user profile",           "unselected": SFIcons.sf_person_crop_circle,     "selected": SFIcons.sf_person_crop_circle_fill     },
            "My Leads":  { "route":  "connections",            "unselected": SFIcons.sf_person_2,               "selected": SFIcons.sf_person_2_fill               },
        };


        // Determine which nav items to display (admin, attendee, or exhibitor)
        final userMode = (ref.read(badgeProvider)?.isExhibitor ?? false) ? UserMode.exhibitor : UserMode.attendee;
        // Construct menu items list from map
        Map<String, Map<String, dynamic>> menuItemsMap = {};
        List<Widget> menuItemsList = [];

        switch (userMode) {
            case UserMode.admin:     menuItemsMap = adminItems;
            case UserMode.attendee:  menuItemsMap = attendeeItems;
            case UserMode.exhibitor: menuItemsMap = exhibitorItems;
        }

        for (String label in menuItemsMap.keys) {
            final item      = menuItemsMap[label]!;
            final routeName = item["route"] as String?;
            final bool isSelected = _currentRouteName == routeName;

            menuItemsList.add(
                GestureDetector(
                    key:   Key("bottom_navigation_bar__${label.toLowerCase().replaceAll(r' ', '_')}_button"),
                    onTap: () async {
                        if (routeName == null || isSelected) return;

                        if (routeName != "show") {
                            // Reset the stack to just the "show" route
                            context.goNamed("show");

                            // Then push the desired tab
                            context.pushNamed(routeName);
                        } else {
                            // If tapping "Show" itself, simply go to it
                            context.goNamed("show");
                        }
                    },
                    child: Column(mainAxisSize: MainAxisSize.min,
                        children: [
                            Container(
                                constraints: const BoxConstraints(
                                    minHeight:  20,
                                    maxHeight:  64,
                                ),
                                child: FittedBox(
                                    fit:   BoxFit.contain,
                                    child: SFIcon(isSelected ? menuItemsMap[label]!["selected"]! : menuItemsMap[label]!["unselected"]!,
                                        fontSize:   beTextTheme.headingPrimary.fontSize,
                                        fontWeight: FontWeight.w500,
                                        color:      isSelected ? BeColorSwatch.blue : Colors.grey[600]
                                    )
                                )
                            ),
                            if (textScaleFactor <= 1.667)
                                NoScale(child: Text(label.toUpperCase(), style: beTextTheme.captionPrimary.merge(TextStyle(color: isSelected ? BeColorSwatch.blue : Colors.grey[600])))),
                        ]
                    )
                ),
            );
        }




        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * MARK: Output
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
        return Stack(
            children: [
                Container(
                    decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 0.5)),
                        color:  beColorScheme.background.secondary
                    ),
                    child: Padding(padding: EdgeInsets.only(top: 12, bottom: 24),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment:  MainAxisAlignment.spaceEvenly,
                            children: menuItemsList
                        )
                    )
                ),

                // DEBUG: Current route name
                if (ref.watch(isDebuggingProvider))
                     DebugText(_currentRouteName ?? "null")
            ]
        );
    }
}
