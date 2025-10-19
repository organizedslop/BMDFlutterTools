/*
 * Single Show
 *
 * Created by:  Blake Davis
 * Description: Show view
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:io";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";
import "package:bmd_flutter_tools/widgets/component__foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/inset_list_section.dart";
import "package:bmd_flutter_tools/widgets/list_confirmation_item.dart";
import "package:bmd_flutter_tools/widgets/modal__message.dart";
import "package:bmd_flutter_tools/widgets/navigation_bar__primary.dart";
import "package:bmd_flutter_tools/widgets/navigation_bar__bottom.dart";
import "package:bmd_flutter_tools/widgets/panel__lead_retrieval_ad.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";
import "package:url_launcher/url_launcher.dart";




// TODO: Refactor this widget to not require an explicit showId -- should read from provider
/* ======================================================================================================================
 * MARK: Single Show
 * ------------------------------------------------------------------------------------------------------------------ */
class ShowInfo extends ConsumerStatefulWidget {

    static const Key rootKey = Key("show_info__root");

    final String showId,
                 title;


    ShowInfo({ super.key,
       required this.showId,
                     title   }

    )   :   this.title = title ?? "Show Details";



    @override
    ConsumerState<ShowInfo> createState() => _ShowInfoState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _ShowInfoState extends ConsumerState<ShowInfo> {

    AppDatabase appDatabase = AppDatabase.instance;

    bool isSubmitting = false;

    Map<String, String> localPaths = {};

    final ScrollController _scrollController = ScrollController();

    ShowData? show;

    BadgeData? registration;

    final TextEditingController _textEditingController = TextEditingController();

    UserData? user;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        refreshUser();

        super.initState();

        showSystemUiOverlays();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    dispose() {
        _scrollController.dispose();
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Display Coming Soon Modal
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    void showComingSoon() {
        showDialog(context: context, builder: (BuildContext context) => MessageModal(title: "Coming Soon", body: "This part of the app is under construction and will be available in a future update."));
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Display Modal
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    void showInviteModal() {
        showDialog(context: context, builder: (BuildContext context) {
            return Dialog(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child:   Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment:  MainAxisAlignment.center,
                        mainAxisSize:       MainAxisSize.min,
                        children:           [
                            Text("Invite a guest to register", style: beTextTheme.headingTertiary),
                            const SizedBox(height: 8),

                            formFieldLabel(labelText: "Email Address"),

                            TextFormField(
                                controller: _textEditingController,
                                decoration: gfieldInputDecoration.merge(InputDecoration(filled: true, fillColor: beColorScheme.background.secondary, hintText: "Email Address"))
                            ),
                            ListConfirmationItem(buttons: {

                                isSubmitting ? SizedBox(
                                    height: beTextTheme.headingSecondary.fontSize,
                                    width:  beTextTheme.headingSecondary.fontSize,
                                    child:  Center(child: CircularProgressIndicator())) :

                                Text("Confirm",
                                    style: beTextTheme.bodyPrimary.merge(
                                        (true /* _textEditingController.text.isNotEmpty */)  ?
                                            TextStyle(color: beColorScheme.text.accent,  fontWeight: FontWeight.bold)  :
                                            TextStyle(color: beColorScheme.text.tertiary)
                                    )):

                                () async { if (_textEditingController.text.isNotEmpty) {
                                        setState(() {
                                            isSubmitting = true;
                                        });

                                        // ApiClient - send invite

                                        if (context.mounted) {
                                            setState(() {
                                                isSubmitting = false;
                                            });
                                            appRouter.pop();
                                        }

                                        _textEditingController.clear();
                                    }
                                },

                                Text("Cancel", style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent))):
                                () {
                                    context.pop();
                                    _textEditingController.clear();
                                },
                            })
                        ]
                    )
                )
            );
        });
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Refresh User
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<void> refreshUser() async {
        final currentUserId = ref.read(userProvider)?.id;
        final users = await appDatabase.readUsers(
            where: "${UserDataInfo.id.columnName} = ?",
            whereArgs: [currentUserId.toString()],
        );

        final newUser = users.firstOrNull;

        // Prefer the badges table, which has the full, hydrated record.
        BadgeData? reg;
        if (newUser != null) {
            final dbBadges = await appDatabase.readBadges(
            where: "${BadgeDataInfo.userId.columnName} = ? AND ${BadgeDataInfo.showId.columnName} = ?",
            whereArgs: [newUser.id, widget.showId],
            );
            reg = dbBadges.firstOrNull;

            // Optional: if still null, fetch from API and write to DB
            if (reg == null) {
            final apiBadges = await ApiClient.instance.getBadges(userId: newUser.id);
            reg = apiBadges.firstOrNull;
            if (reg != null) {
                await appDatabase.write(
                    [reg],
                    table: BadgeDataInfo.tableName,
                );
            }
            }
        }

        if (!mounted) return;
        setState(() {
            user = newUser;
            registration = reg;
        });
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Refresh Shows
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<ShowData?> refreshShows() async {

        logPrint("🗄️  Getting show from database...");
        List<ShowData> shows = await appDatabase.readShows(where:"${ShowDataInfo.id.columnName} = ?", whereArgs: [widget.showId]);

        if (shows.isNotEmpty) {
            return shows.first;

        } else {
            shows = await ApiClient.instance.getShows(id: widget.showId);
            return shows.firstOrNull;
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);

        const double dividerHeight        = 28;
        const double dividerSpacingTop    = 32;
        const double dividerSpacingBottom =  6;


        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * MARK: Scaffold
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
        return Scaffold(
            appBar:               PrimaryNavigationBar(title: widget.title, subtitle: ref.read(showProvider)?.title),
            bottomNavigationBar:  QuickNavigationBar(),
            floatingActionButton: (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false) ? FloatingScannerButton() : null,
            key:                  ShowInfo.rootKey,

            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Widget Body
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            body: Container(
                color: beColorScheme.background.tertiary,
                child: FutureBuilder(
                    future: Future.wait([
                        refreshShows()
                    ]),
                    builder: (context, snapshot) {

                        // Display loading indicator
                        if (snapshot.connectionState != ConnectionState.done) {
                            return Center(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        const CircularProgressIndicator(color: BeColorSwatch.navy, padding: EdgeInsets.only(bottom: 8)),
                                        Text("Loading show info...", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: BeColorSwatch.darkGray)),
                                        SizedBox(height: 16),
                                    ]
                                )
                            );
                        }

                        // Display error message
                        if (snapshot.hasError) {
                            return Center(child: Text("Error: ${snapshot.error.toString()}", style: beTextTheme.bodyPrimary));
                        }

                        // Display not-found message
                        if (!snapshot.hasData) {
                            return Center(child: Text("Failed to get show info", style: beTextTheme.bodyPrimary));
                        }

                        ShowData? show = snapshot.data![0];


                        return ListView(
                            controller: _scrollController,
                            padding:    EdgeInsets.symmetric(horizontal: 6),
                            children: () {
                                if (show == null) {
                                    return [
                                        // No show found message
                                        InsetListSection(
                                            title:    "No show was found with the ID ${widget.showId}",
                                            children: [const SizedBox.shrink()]
                                        )
                                    ];
                                } else {
                                    return [
                                        const SizedBox(height: 24),

                                        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                         * MARK: Registration Info
                                         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
                                        ...(user == null
                                            ? [
                                                // No user
                                                Text("Error: No user found.", style: TextStyle(color: BeColorSwatch.red)),

                                            ]
                                            // No badge
                                            : registration == null
                                                ? [
                                                    Text("No registration info found.", style: TextStyle(color: BeColorSwatch.gray)),
                                                    ElevatedButton(
                                                        onPressed: () { showComingSoon(); },
                                                        style: elevatedButtonStyleAlt.copyWith(backgroundColor: WidgetStateProperty.all(BeColorSwatch.red)),
                                                        child: Padding(
                                                            padding: EdgeInsets.symmetric(vertical: 8),
                                                            child:   Text("Register now!")
                                                        )
                                                    )
                                                ]
                                                // Exhibitors
                                                : (registration!.isExhibitor)
                                                    ? [
                                                        Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 32),
                                                            child:   Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                    Text(
                                                                        (){
                                                                            final boothNumbers = registration?.booths.map((booth) => booth.number).toList() ?? [];
                                                                            return ((boothNumbers.length > 1) ? "Booths " : "Booth ") + (boothNumbers.isNotEmpty ? boothNumbers.join(", ") : "not assigned");
                                                                        }(),
                                                                        style: Theme.of(context).textTheme.titleLarge
                                                                    ),

                                                                    RichText(
                                                                        text: TextSpan(
                                                                            style:    Theme.of(context).textTheme.bodyMedium,
                                                                            children: [
                                                                                TextSpan(text: "Move-in: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                                                                (registration!.moveInStart != null && registration!.moveInEnd != null)
                                                                                    ? TextSpan(text: DateFormat("MMM d, yyyy '|' h:mm a").format(DateTime.parse(registration!.moveInStart!))
                                                                                        + " - "
                                                                                        + DateFormat("h:mm a").format(DateTime.parse(registration!.moveInEnd!))
                                                                                    )
                                                                                    : TextSpan(text: "Not scheduled")
                                                                            ]
                                                                        )
                                                                    ),

                                                                    RichText(
                                                                        text: TextSpan(
                                                                            style:    Theme.of(context).textTheme.bodyMedium,
                                                                            children: [
                                                                                TextSpan(text: "Move-out: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                                                                (registration!.moveInStart != null && registration!.moveInEnd != null)
                                                                                    ? TextSpan(text: DateFormat("MMM d, yyyy '|' h:mm a").format(DateTime.parse(show.moveOutStart!))
                                                                                        + " - "
                                                                                        + DateFormat("h:mm a").format(DateTime.parse(show.moveOutEnd!))
                                                                                    )
                                                                                    : TextSpan(text: "Not scheduled")
                                                                            ]
                                                                        )
                                                                    )
                                                                ]
                                                            )
                                                        ),

                                                        const SizedBox(height: 6),

                                                        TextButton.icon(
                                                            icon: SFIcon(
                                                                SFIcons.sf_phone,
                                                                color:    BeColorSwatch.blue,
                                                                fontSize: 20
                                                            ),
                                                            label:     Text("Call to schedule move-in/out", style: TextStyle(color: BeColorSwatch.blue, fontWeight: FontWeight.bold)),
                                                            onPressed: () async {
                                                                final uri = Uri(scheme: "tel", path: "+15122495303");
                                                                if (await canLaunchUrl(uri)) {
                                                                    await launchUrl(uri);
                                                                } else {
                                                                    showSnackBar(
                                                                        context: context,
                                                                        content: Text("Could not place call to (512) 249-5303", style: TextStyle(color: BeColorSwatch.red))
                                                                    );
                                                                }
                                                            }
                                                        )
                                                    ]

                                                    // Attendees
                                                    : [
                                                        TextButton.icon(
                                                            icon: SFIcon(
                                                                SFIcons.sf_checkmark_circle_fill,
                                                                color:      BeColorSwatch.green,
                                                                fontWeight: FontWeight.w100
                                                            ),
                                                            label: Text(
                                                                "You are registered to ${(registration?.isExhibitor == true)
                                                                    ? "exhibit"
                                                                    : (registration?.isPresenter == true)
                                                                        ? "present"
                                                                        : "attend"}",
                                                                style:     Theme.of(context).textTheme.headlineMedium!.copyWith(color: BeColorSwatch.green),
                                                                textAlign: TextAlign.center
                                                            ),
                                                            onPressed: null,
                                                        ),
                                                    ]
                                        ),


                                        const SizedBox(height: dividerSpacingTop),
                                        Divider(color:   BeColorSwatch.gray, height: dividerHeight),
                                        const SizedBox(height: dividerSpacingBottom),

                                        // Show info
                                        Column(
                                            children: [
                                                Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                                    child:   Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            Text(show.dates.toString(), style: Theme.of(context).textTheme.titleMedium),

                                                            RichText(
                                                                text: TextSpan(
                                                                    style:    Theme.of(context).textTheme.bodyMedium,
                                                                    children: [
                                                                        TextSpan(text: "Exhibit hours: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                                                        TextSpan(text: "10:00 AM - 3:00 PM"), // show.dates.dates[0].toString(includeDates: false)),
                                                                    ]
                                                                ),
                                                                textScaler: TextScaler.linear(textScaleFactor)
                                                            ),

                                                            RichText(
                                                                text: TextSpan(
                                                                    style:    Theme.of(context).textTheme.bodyMedium,
                                                                    children: [
                                                                        TextSpan(text: "Classes start: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                                                        TextSpan(text: "9:30 AM"), // DateFormat("hh:mm aaa").format(DateTime.fromMillisecondsSinceEpoch(show!.dates.dates[0].start * 1000).toUtc())),
                                                                    ]
                                                                ),
                                                                textScaler: TextScaler.linear(textScaleFactor)
                                                            ),

                                                            const SizedBox(height: 22),

                                                            Text(show.venue.name,       style: Theme.of(context).textTheme.titleMedium),
                                                            Text(show.venue.address.toString()),

                                                            const SizedBox(height: 6)
                                                        ]
                                                    )
                                                ),

                                                /*
                                                 * TODO: This chunk is copied from ShowHome - it should be broken out so it can be easily reused
                                                 */
                                                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                        Column(
                                                            spacing:  6,
                                                            children: [
                                                                TextButton.icon(
                                                                    icon: SFIcon(
                                                                        SFIcons.sf_map,
                                                                        color:    BeColorSwatch.blue,
                                                                        fontSize: 20
                                                                    ),
                                                                    label:     Text("Get directions", style: TextStyle(color: BeColorSwatch.blue, fontWeight: FontWeight.bold)),
                                                                    onPressed: () async {
                                                                        final address = show.venue.address.toString(includeCountry: true);
                                                                        final query   = Uri.encodeComponent(address);
                                                                        String url;

                                                                        if (Platform.isIOS) {
                                                                            url = "maps://?q=${query}";
                                                                        } else if (Platform.isAndroid) {
                                                                            url = "geo:0,0?q=${query}";
                                                                        } else {
                                                                            url = "https://www.google.com/maps/search/?api=1&query=${query}";
                                                                        }

                                                                        final uri = Uri.parse(url);

                                                                        if (await canLaunchUrl(uri)) {
                                                                            await launchUrl(
                                                                                uri,
                                                                                mode: LaunchMode.externalApplication,
                                                                            );
                                                                        } else {
                                                                            scaffoldMessengerKey.currentState?.showSnackBar(
                                                                                SnackBar(content: Text("Could not open maps for this address.")),
                                                                            );
                                                                        }
                                                                    }
                                                                ),

                                                                TextButton.icon(
                                                                    icon: SFIcon(
                                                                        SFIcons.sf_rectangle_portrait_on_rectangle_portrait,
                                                                        color:    BeColorSwatch.blue,
                                                                        fontSize: 20
                                                                    ),
                                                                    label:     Text("Copy address", style: TextStyle(color: BeColorSwatch.blue, fontWeight: FontWeight.bold)),
                                                                    onPressed: () async {
                                                                        final address = show.venue.address.toString();
                                                                        await Clipboard.setData(ClipboardData(text: address));
                                                                        scaffoldMessengerKey.currentState?.showSnackBar(
                                                                            SnackBar(content: Text("Copied address to clipboard."))
                                                                        );
                                                                    }
                                                                )
                                                            ]
                                                        ),
                                                        TextButton.icon(
                                                            icon: SFIcon(
                                                                SFIcons.sf_square_grid_2x2,
                                                                color:    BeColorSwatch.blue,
                                                                fontSize: 20
                                                            ),
                                                            label:     Text("View floorplan", style: TextStyle(color: BeColorSwatch.blue, fontWeight: FontWeight.bold)),
                                                            onPressed: () async {
                                                                // TODO: We should probably make floorplan optional within the ShowData model
                                                                if (show.floorplan != "") {
                                                                    context.pushNamed(
                                                                        "document reader",
                                                                        queryParameters: {
                                                                            "title":     "Floorplan",
                                                                            "assetPath": show.floorplan
                                                                        }
                                                                    );
                                                                } else {
                                                                    scaffoldMessengerKey.currentState?.showSnackBar(
                                                                        SnackBar(
                                                                            content: Text("This show's floorplan is coming soon!", textAlign: TextAlign.center),
                                                                            padding: EdgeInsets.all(16),
                                                                        )
                                                                    );
                                                                }
                                                            }
                                                        )
                                                    ]
                                                ),
                                                const SizedBox(height: 24),
                                            ]
                                        ),

                                        /*
                                         * Lead retrieval ad
                                         */
                                        if (!(ref.read(badgeProvider)?.hasLeadScannerLicense ?? false)) ...[const SizedBox(height: 12), LeadRetrievalAd()],

                                        const SizedBox(height: dividerSpacingTop),
                                        Divider(color:   BeColorSwatch.gray, height: dividerHeight),
                                        const SizedBox(height: dividerSpacingBottom),



                                        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                         * MARK: Section: FAQ
                                         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
                                        Padding(
                                            padding: EdgeInsets.only(right: 12, bottom: 4, left: 12,),
                                            child:   Text("FAQ", style: Theme.of(context).textTheme.headlineLarge!)
                                        ),

                                        Text("Attendee Lists", style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                                        Text("Build Expo has been informed that Exhibitors are being targeted by companies unaffiliated with Build Expo, offering an attendee list for the \“Build Expo shows\” and other variations on the name Build Expo. Please be aware that these companies have nothing to do with Build Expo. The attendee mailing list for the show is only available directly from Build Expo. If you are interested in purchasing the Build Expo Mailing List, please contact Amy Shoulders at 877.219.3976."),

                                        Divider(color: BeColorSwatch.gray, height: 48),

                                        Text("When can I set up my exhibit space?", style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                                        Text("Exhibitor move-in is the day before the event begins. You will be contacted by the Service Director approximately 30 days before the show to schedule a move-in time."),

                                        Divider(color: BeColorSwatch.gray, height: 48),

                                        Text("When can I begin to dismantle my exhibit space?", style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                                        Text("Dismantling of exhibit space is conducted strictly after 3pm on the last day of the event. Attempting to dismantle booths prior to the end of the show is not allowed and is a breach of contract."),

                                        Divider(color: BeColorSwatch.gray, height: 48),

                                        Text("When do I have to be moved out?", style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                                        Text("All exhibitors must be completely moved out by 5pm on the last day of the show."),

                                        Divider(color: BeColorSwatch.gray, height: 48),

                                        Text("When will I be able to order furnishings and electricity?", style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                                        Text("Approximately 30 days prior to the show, your exhibitor service manual will be emailed to the primary contact’s email on your booth contract. If the email on the booth contract is NOT the same email this information needs to go to, please contact us at 877.219.3976 to ensure the manual is sent to the appropriate party."),

                                        Divider(color: BeColorSwatch.gray, height: 48),

                                        Text("Where do I get show badges for my staff once I arrive at the show?", style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                                        Text("All badges for exhibitors will be picked up at the exhibitor services desk, which is located in the back of the convention hall by the loading dock doors. This desk is the same location that exhibitors will check-in for show move-in."),

                                        Divider(color: BeColorSwatch.gray, height: 48),

                                        Text("What are the exhibit hall hours?", style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                                        Text("Exhibitor move-in will be from 8:00 am - 4:00 pm the day before the event. The exhibit hall will open at 8:00 am each morning of the show."),

                                        Divider(color: BeColorSwatch.gray, height: 48),

                                        Text("Is there an official hotel for the Build Expo?", style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                                        Text("Local hotels can be found by clicking the \"Hotel & Travel\" page."),

                                        Divider(color: BeColorSwatch.gray, height: 48),

                                        Text("Do I have to pay for parking?", style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
                                        Text("Build Expo does not pay for parking nor does it reimburse for parking. Depending on the event location, you will have to pay for parking and those rates are set exclusively by the convention center."),


                                        const SizedBox(height: 128),

                                    ].nonNulls.toList();
                                }
                            }()
                        );
                    }
                )
            )
        );
    }
}