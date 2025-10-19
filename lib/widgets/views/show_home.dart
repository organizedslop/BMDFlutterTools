/*
 * Single Show
 *
 * Created by:  Blake Davis
 * Description: Widget for displaying a single show's information
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:io";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import 'package:bmd_flutter_tools/data/model/data__company.dart';
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/forms/invite_team_member.dart";
import "package:bmd_flutter_tools/widgets/components/foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/components/updating_indicator.dart";
import "package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/navigation/bottom_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/navigation/navigation_menu.dart";
import "package:bmd_flutter_tools/widgets/panels/lead_retrieval_ad.dart";
import "package:bmd_flutter_tools/widgets/panels/magazine_ad.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_carousel_widget/flutter_carousel_widget.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";
import "package:url_launcher/url_launcher.dart";




/* ======================================================================================================================
 * MARK: Single Show
 * ------------------------------------------------------------------------------------------------------------------ */
class ShowHome extends ConsumerStatefulWidget {

    static const Key rootKey = Key("show_home__root");

    final String title;

    final String? headerImageUrl;

    ShowHome({
        super.key,
        this.headerImageUrl,
        title,
    }) : this.title = title ?? "Show Dashboard";

    @override
    ConsumerState<ShowHome> createState() => _ShowHomeState();
}


/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _ShowHomeState extends ConsumerState<ShowHome> with WidgetsBindingObserver {
    AppDatabase appDatabase = AppDatabase.instance;

    bool _awaitingLeadPurchaseReturn = false,
        _isBadgeRefreshing = false,
        isSubmitting       = false;

  /*
     * Used to determine if a user is registered for the show.
     * That way we can optimistically set it to true while waiting
     * for the API call to complete.
     */
    bool isRegistered = false;

  late CompanyData? company;

  EdgeInsets showHomeLinkPadding =
          EdgeInsets.only(top: 20, right: 16, bottom: 24, left: 16),
      showHomeLinkMargin = EdgeInsets.only(bottom: 16);

  Map<String, String> localPaths = {};

  ScrollController _scrollController = ScrollController();

  UserData? user;

  late final Future<List<dynamic>> _initialLoadFuture;

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  void initState() {
    super.initState();

    showSystemUiOverlays();
    WidgetsBinding.instance.addObserver(this);

    _initialLoadFuture = Future.wait([
      refreshShows(),
    ]);

    // Defer any provider reads until after the element is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final initialBadge = ref.read(badgeProvider);
      logPrint("ℹ️  Badge ID: ${initialBadge?.id ?? "null"}");
      logPrint(
          "ℹ️  hasLeadScannerLicense: ${initialBadge?.hasLeadScannerLicense ?? "false"}");

      company = ref.read(companyProvider);
      isRegistered = initialBadge !=
          null; // optimistic flag remains, but UI will also react to provider

      // Kicks the DB-backed user refresh; it doesn't use watch.
      refreshUser();

      final currCompany = company;
      final currShow = ref.read(showProvider);
      if (currCompany != null && currShow != null) {
        refreshConnectionsInBackground(currCompany.id, currShow.id).then((_) {
          // If this widget was disposed during the async call, avoid using `ref`
          if (!mounted) return;
          try {
            providerContainer.refresh(connectionsProvider(
                ConnectionsRequest(currCompany.id, currShow.id)));
          } catch (_) {}
        });
      }
    });
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Refresh User
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  refreshUser() {
    final currentUserId = ref.read(userProvider)?.id;

    appDatabase.readUsers(
        where: "${UserDataInfo.id.columnName} = ?",
        whereArgs: [currentUserId.toString()]).then((value) {
      setState(() {
        final UserData? newUser = value.firstOrNull;
        user = newUser;

        refreshShows();
      });
    });
  }

  Future<void> _refreshBadgesAndUserAfterReturn(
      {Duration waitBefore = const Duration(milliseconds: 800)}) async {
    try {
      final badgeNotifier = ref.read(badgeProvider.notifier);
      final userNotifier = ref.read(userProvider.notifier);

      final String? currentBadgeId = ref.read(badgeProvider)?.id;
      final String? inferredUserId = ref.read(badgeProvider)?.userId;
      final String? userId = ref.read(userProvider)?.id;
      final String? companyId = ref.read(companyProvider)?.id;

      final String? effectiveUserId = (userId != null && userId.isNotEmpty)
          ? userId
          : ((inferredUserId != null && inferredUserId.isNotEmpty)
              ? inferredUserId
              : null);
      if (effectiveUserId == null) return;

      if (waitBefore.inMicroseconds > 0) {
        await Future.delayed(waitBefore);
      }
      final badges =
          await ApiClient.instance.getBadges(userId: effectiveUserId);
      if (!mounted) return;

      final bool hadLicenseBefore =
          ref.read(badgeProvider)?.hasLeadScannerLicense ?? false;

      dynamic matched;
      if (currentBadgeId != null && currentBadgeId.isNotEmpty) {
        for (final b in badges) {
          try {
            if (b.id == currentBadgeId) {
              matched = b;
              break;
            }
          } catch (_) {}
        }
      }

      if (matched != null) {
        logPrint(
            "🔄 ShowHome | Updating badge ${matched.id} hasLeadScannerLicense=${matched.hasLeadScannerLicense}");
        badgeNotifier.update(matched);
        if (!hadLicenseBefore && (matched.hasLeadScannerLicense == true)) {
          if (mounted) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(
                  content: Text("Lead retrieval is activated!",)),
            );
          }
        }
      }

      if (companyId != null && companyId.isNotEmpty) {
        await ApiClient.instance.getCompanyById(companyId);
      }

      try {
        final refreshedUser = await ApiClient.instance.getUser();
        if (mounted && refreshedUser != null)
          userNotifier.update(refreshedUser);
      } catch (_) {}
    } catch (e) {
      logPrint("❌ ShowHome | Error refreshing after return: $e");
    } finally {
      if (mounted) setState(() => _isBadgeRefreshing = false);
    }
  }

  Future<void> _handlePullToRefresh() async {
    if (_isBadgeRefreshing) {
      return;
    }

    if (ref.read(badgeProvider) == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _isBadgeRefreshing = true;
      });
    }

    await _refreshBadgesAndUserAfterReturn(waitBefore: Duration.zero);
  }

  Widget _buildShowBannerHeader(BuildContext context, ShowData show) {
    final theme = Theme.of(context);
    final String headerImageCandidate = widget.headerImageUrl?.trim() ?? "";
    final String bannerCandidate = show.banner?.trim() ?? "";
    final String rawBannerUrl = headerImageCandidate.isNotEmpty
        ? headerImageCandidate
        : bannerCandidate;

    final Uri? bannerUri =
        (rawBannerUrl.isNotEmpty) ? Uri.tryParse(rawBannerUrl) : null;
    final bool hasBanner =
        bannerUri != null && bannerUri.hasScheme && bannerUri.host.isNotEmpty;
    final String bannerUrl = hasBanner ? rawBannerUrl : "";

    return AspectRatio(
        aspectRatio: 4.5 / 1,
        child: Stack(fit: StackFit.expand, children: [
          if (bannerUrl.isEmpty)
            Container(
                child: Transform.scale(
                    scale: 1.25,
                    alignment: Alignment.bottomLeft,
                    child: Image.asset(
                      "assets/images/show-banner-placeholder.png",
                      fit: BoxFit.cover,
                    ))),
          if (bannerUrl.isNotEmpty)
            Image.network(
              bannerUrl,
              fit: BoxFit.cover,
              colorBlendMode: BlendMode.multiply,
              loadingBuilder: (context, child, progress) =>
                  (progress == null) ? child : const SizedBox.shrink(),
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topCenter,
                      colors: [
                BeColorSwatch.navy.withAlpha(200),
                BeColorSwatch.navy.withAlpha(120),
                BeColorSwatch.navy.withAlpha(60),
                BeColorSwatch.navy.withAlpha(0),
              ]))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    show.title,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 28,
                        ) ??
                        const TextStyle(
                          fontSize:   28,
                          fontWeight: FontWeight.bold,
                        ),
                  ))),
        ]));
  }

// 6) Add lifecycle hook
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingLeadPurchaseReturn) {
      _awaitingLeadPurchaseReturn = false;
      _refreshBadgesAndUserAfterReturn();
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Refresh Shows
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<ShowData?> refreshShows() async {
    logPrint("🗄️  Getting show from database...");

    final String? showId = ref.read(showProvider)?.id;
    if (showId == null) return null;

    List<ShowData> shows = await appDatabase.readShows(
      where: "${ShowDataInfo.id.columnName} = ?",
      whereArgs: [showId],
    );

    if (shows.isNotEmpty) {
      return shows.first;
    } else {
      shows = await ApiClient.instance.getShows(id: showId);
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

    const double dividerHeight = 28;
    const double dividerSpacingTop = 32;
    const double dividerSpacingBottom = 6;

    final currentBadge = ref.watch(badgeProvider);
    final currentCompany = ref.watch(companyProvider);
    final currentShow = ref.watch(showProvider);

    final bool effectiveRegistered = (currentBadge != null) || isRegistered;

    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * MARK: Scaffold
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
    return Scaffold(
        appBar: PrimaryNavigationBar(
            title: widget.title, subtitle: currentShow?.title, showMenu: true),
        bottomNavigationBar: QuickNavigationBar(),
        drawer: NavigationMenu(),
        floatingActionButton: (currentBadge?.hasLeadScannerLicense ?? false)
            ? FloatingScannerButton()
            : null,
        key: ShowHome.rootKey,

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Widget Body
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
        body: FutureBuilder(
            future: _initialLoadFuture,
            builder: (context, snapshot) {
              // Display loading indicator
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(
                      padding: EdgeInsets.only(bottom: 8)),
                  Text("Loading show info...",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!),
                  const SizedBox(height: 16),
                ]));
              }

              // Display error message
              if (snapshot.hasError) {
                return Center(
                    child: Text("Error: ${snapshot.error.toString()}",
                        style: beTextTheme.bodyPrimary));
              }

              // Display not-found message
              if (!snapshot.hasData) {
                return Center(
                    child: Text("Failed to get show info",
                        style: beTextTheme.bodyPrimary));
              }

              // Ensure a show is selected before building the detail UI
              if (currentShow == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No show selected yet. Please choose a show from All Shows.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }

              // Local alias for legacy references below; provider-backed.
              final show = currentShow;

              return RefreshIndicator.adaptive(
                  onRefresh: _handlePullToRefresh,
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: () {
                      return [
                        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                             * MARK: Section: Show Info
                                             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
                        _buildShowBannerHeader(context, show),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),

                                  Center(
                                      child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 32/textScaleFactor),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // TODO: This chunk is reused on ShowInfo - break this out into its own widget for easy reuse

                                                Text(
                                                    currentShow.dates
                                                        .toString(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium),

                                                RichText(
                                                    text: TextSpan(
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                        children: [
                                                      TextSpan(
                                                          text:
                                                              "Exhibit hours: ",
                                                          style: TextStyle(fontWeight:FontWeight.bold)),
                                                      TextSpan(
                                                          text:
                                                              "10:00 AM - 3:00 PM"), // show.dates.dates[0].toString(includeDates: false)),
                                                    ]),
                                                    textScaler: TextScaler.linear(textScaleFactor)),

                                                RichText(
                                                    text: TextSpan(
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                        children: [
                                                      TextSpan(
                                                          text:
                                                              "Classes start: ",
                                                          style: TextStyle(fontWeight:FontWeight.bold)),
                                                      TextSpan(
                                                          text:
                                                              "9:30 AM"), // DateFormat("hh:mm aaa").format(DateTime.fromMillisecondsSinceEpoch(show.dates.dates[0].start * 1000).toUtc())),
                                                    ]),
                                                    textScaler: TextScaler.linear(textScaleFactor)),

                                                const SizedBox(height: 22),

                                                Text(currentShow.venue.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium),
                                                Text(currentShow.venue.address
                                                    .toString()),

                                                const SizedBox(height: 6)
                                              ]))),

                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(spacing: 6, children: [
                                          TextButton.icon(
                                            icon: SFIcon(SFIcons.sf_map,
                                                fontSize: 20),
                                            label: Text("Get directions",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            onPressed: () async {
                                              final address = currentShow
                                                  .venue.address
                                                  .toString(
                                                      includeCountry: true);
                                              final query =
                                                  Uri.encodeComponent(address);
                                              String url;

                                              if (Platform.isIOS) {
                                                url = "maps://?q=${query}";
                                              } else if (Platform.isAndroid) {
                                                url = "geo:0,0?q=${query}";
                                              } else {
                                                url =
                                                    "https://www.google.com/maps/search/?api=1&query=${query}";
                                              }

                                              final uri = Uri.parse(url);

                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(
                                                  uri,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              } else {
                                                scaffoldMessengerKey
                                                    .currentState
                                                    ?.showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          "Could not open maps for this address.")),
                                                );
                                              }
                                            },
                                          ),
                                          TextButton.icon(
                                            icon: SFIcon(
                                                SFIcons
                                                    .sf_rectangle_portrait_on_rectangle_portrait,
                                                fontSize: 20),
                                            label: Text("Copy address",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            onPressed: () async {
                                              final address = currentShow
                                                  .venue.address
                                                  .toString();
                                              await Clipboard.setData(
                                                  ClipboardData(text: address));
                                              scaffoldMessengerKey.currentState
                                                  ?.showSnackBar(SnackBar(
                                                      content: Text(
                                                          "Copied address to clipboard.")));
                                            },
                                          ),
                                        ]),
                                        TextButton.icon(
                                            icon: SFIcon(
                                                SFIcons.sf_square_grid_2x2,
                                                fontSize: 20),
                                            label: Text((textScaleFactor > 1.35) ? "Floorplan" : "View floorplan",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            onPressed: () async {
                                              if (currentShow
                                                      .floorplan?.isNotEmpty ??
                                                  false) {
                                                context.pushNamed(
                                                    "document reader",
                                                    queryParameters: {
                                                      "title": "Floorplan",
                                                      "assetPath":
                                                          currentShow.floorplan
                                                    });
                                              } else {
                                                scaffoldMessengerKey
                                                    .currentState
                                                    ?.showSnackBar(SnackBar(
                                                  content: Text(
                                                      "This show's floorplan is coming soon!",
                                                      textAlign:
                                                          TextAlign.center),
                                                  padding: EdgeInsets.all(16),
                                                ));
                                              }
                                            }),
                                      ]),

                                  const SizedBox(height: dividerSpacingTop),
                                  Divider(
                                      height: dividerHeight),
                                  const SizedBox(height: dividerSpacingBottom),

                                  if (_isBadgeRefreshing &&
                                      currentBadge != null) ...[
                                    const SizedBox(height: 8),
                                    const UpdatingIndicator(
                                        label: "Updating your badge…"),
                                    const SizedBox(height: 8),
                                    Divider(
                                        height: dividerHeight),
                                    const SizedBox(
                                        height: dividerSpacingBottom),
                                  ],

                                  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                             * MARK: Section: Registration Info
                                             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                  ...(user == null
                                      /*
                                                 * If there is no user...
                                                 */
                                      ? <Widget>[
                                          Center(
                                              child: Text("Error: No user found.")),
                                        ]

                                      /*
                                                 * If the user is registered...
                                                 */
                                      : (effectiveRegistered)
                                          ? <Widget>[
                                              if (currentBadge == null) ...[
                                                const SizedBox(height: 4),
                                                const UpdatingIndicator(
                                                    label:
                                                        "Finalizing your registration…"),
                                                const SizedBox(height: 8),
                                              ] else ...[
                                                Center(
                                                    child: TextButton.icon(
                                                  icon: SFIcon(
                                                    SFIcons
                                                        .sf_checkmark_circle_fill,
                                                    fontWeight: FontWeight.w100,
                                                  ),
                                                  label: Text(((textScaleFactor > 1.35) ? "R" : "You are r") + "egistered to ${(currentBadge.isExhibitor == true) ? "exhibit" : (currentBadge.isPresenter == true) ? "present" : "attend"}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineMedium!,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  onPressed: null,
                                                ))
                                              ],
                                              // Exhibitor booth & move-in/out info (mirrors ShowInfo)
                                              if (effectiveRegistered &&
                                                  (currentBadge != null) &&
                                                  currentBadge.isExhibitor)
                                                Center(
                                                    child: Padding(
                                                        padding: EdgeInsets.only(top: 12, right: 32/textScaleFactor, left: 32/textScaleFactor),
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Builder(builder:
                                                                  (context) {
                                                                return Text(() {
                                                                  final boothNumbers = currentBadge
                                                                      .booths
                                                                      .map((booth) =>
                                                                          booth
                                                                              .number)
                                                                      .toList();
                                                                  return ((boothNumbers.length >
                                                                              1)
                                                                          ? "Booths "
                                                                          : "Booth ") +
                                                                      (boothNumbers
                                                                              .isNotEmpty
                                                                          ? boothNumbers
                                                                              .join(", ")
                                                                          : "not assigned");
                                                                }(),
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .titleMedium);
                                                              }),
                                                              RichText(
                                                                  text: TextSpan(
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .bodyMedium,
                                                                      children: [
                                                                    const TextSpan(
                                                                        text:
                                                                            "Move-in: ",
                                                                        style: TextStyle(fontWeight:FontWeight.bold)),

                                                                    if (currentBadge.moveInStart !=
                                                                            null &&
                                                                        currentBadge.moveInEnd !=
                                                                            null)
                                                                      TextSpan(
                                                                        text: DateFormat("MMM d, yyyy '|' h:mm a").format(DateTime.parse(currentBadge.moveInStart!)) +
                                                                            " - " +
                                                                            DateFormat("h:mm a").format(DateTime.parse(currentBadge.moveInEnd!)),
                                                                      )
                                                                    else
                                                                      const TextSpan(
                                                                          text:
                                                                              "Not scheduled"),
                                                                  ]),
                                                                  textScaler: TextScaler.linear(textScaleFactor)),
                                                              RichText(
                                                                  text: TextSpan(
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .bodyMedium,
                                                                      children: [
                                                                    const TextSpan(
                                                                        text:
                                                                            "Move-out: ",
                                                                        style: TextStyle(fontWeight:FontWeight.bold)),

                                                                    if (show.moveOutStart !=
                                                                            null &&
                                                                        show.moveOutEnd !=
                                                                            null)
                                                                      TextSpan(
                                                                        text: DateFormat("MMM d, yyyy '|' h:mm a").format(DateTime.parse(show.moveOutStart!)) +
                                                                            " - " +
                                                                            DateFormat("h:mm a").format(DateTime.parse(show.moveOutEnd!)),
                                                                      )
                                                                    else
                                                                      const TextSpan(
                                                                          text:
                                                                              "Not scheduled"),
                                                                  ]),
                                                                  textScaler: TextScaler.linear(textScaleFactor)),
                                                              const SizedBox(
                                                                  height: 6),
                                                              Align(
                                                                  alignment:
                                                                      AlignmentDirectional
                                                                          .center,
                                                                  child: TextButton
                                                                      .icon(
                                                                          icon: SFIcon(
                                                                              SFIcons.sf_phone,
                                                                              fontSize: 20),
                                                                          label: Text((textScaleFactor > 1.35) ? "Call to schedule" : "Call to schedule move-in/out", style: TextStyle(fontWeight: FontWeight.bold)),
                                                                          onPressed: () async {
                                                                            final uri =
                                                                                Uri(scheme: "tel", path: "+15122495303");
                                                                            if (await canLaunchUrl(uri)) {
                                                                              await launchUrl(uri);
                                                                            } else {
                                                                              showSnackBar(context: context, content: Text("Could not place call to (512) 249-5303",));
                                                                            }
                                                                          })),
                                                              const SizedBox(
                                                                  height: 20),
                                                            ])))
                                              else
                                                const SizedBox(height: 20),
                                            ]

                                          /*
                                                 * If the user is not registered...
                                                 */
                                          : <Widget>[
                                              Center(
                                                  child: Text(
                                                      "You are not registered",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineMedium!,
                                                      textAlign:
                                                          TextAlign.center)),
                                              const SizedBox(height: 20),
                                              Builder(builder: (context) {
                                                final bool canRegister =
                                                    currentCompany != null &&
                                                        !isSubmitting;

                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    ElevatedButton(
                                                        key: const Key(
                                                            "show_home__register_button"),
                                                        onPressed: canRegister
                                                            ? () async {
                                                                setState(() {
                                                                  isRegistered =
                                                                      true;
                                                                  isSubmitting =
                                                                      true;
                                                                  _isBadgeRefreshing =
                                                                      true;
                                                                });

                                                                if (currentShow !=
                                                                    null) {
                                                                  if (currentCompany !=
                                                                      null) {
                                                                    /*
                                                                 *  Make the API call to register for the Show
                                                                 */
                                                                    BadgeData?
                                                                        badge =
                                                                        (await ApiClient.instance.registerForShow(
                                                                      companyId:
                                                                          currentCompany
                                                                              .id,
                                                                      showId:
                                                                          currentShow
                                                                              .id,
                                                                    ))
                                                                            .firstOrNull;

                                                                    /*
                                                                 *  If the response contained a Badge, update the Badge provider
                                                                 */
                                                                    if (badge !=
                                                                        null) {
                                                                      ref
                                                                          .read(badgeProvider
                                                                              .notifier)
                                                                          .update(
                                                                              badge);

                                                                      // Update the User
                                                                      UserData?
                                                                          user =
                                                                          await ApiClient
                                                                              .instance
                                                                              .getUser();

                                                                      if (user !=
                                                                          null) {
                                                                        ref.read(userProvider.notifier).update(
                                                                            user);
                                                                      }
                                                                      if (context
                                                                          .mounted) {
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                              content: Text("You are registered!")),
                                                                        );
                                                                      }
                                                                      // Turn off refreshing if badge is now present
                                                                      if (ref.read(badgeProvider) !=
                                                                              null &&
                                                                          mounted) {
                                                                        setState(
                                                                            () {
                                                                          _isBadgeRefreshing =
                                                                              false;
                                                                        });
                                                                      }
                                                                    } else {
                                                                      logPrint(
                                                                          "⚠️  badge is null");
                                                                      if (mounted) {
                                                                        setState(
                                                                            () {
                                                                          _isBadgeRefreshing =
                                                                              false;
                                                                        });
                                                                      }
                                                                    }
                                                                  } else {
                                                                    logPrint(
                                                                        "⚠️  currentCompany is null");
                                                                    if (mounted) {
                                                                      setState(
                                                                          () {
                                                                        _isBadgeRefreshing =
                                                                            false;
                                                                      });
                                                                    }
                                                                  }
                                                                } else {
                                                                  logPrint(
                                                                      "⚠️  current show is null");
                                                                  if (mounted) {
                                                                    setState(
                                                                        () {
                                                                      _isBadgeRefreshing =
                                                                          false;
                                                                    });
                                                                  }
                                                                }

                                                                setState(() {
                                                                  isSubmitting =
                                                                      false;
                                                                });
                                                              }
                                                            : null,
                                                        style: elevatedButtonStyleAlt.copyWith(
                                                            backgroundColor: WidgetStateProperty
                                                                .all(canRegister
                                                                    ? BeColorSwatch
                                                                        .red
                                                                    : BeColorSwatch
                                                                        .gray)),
                                                        child: Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        8),
                                                            child: Text("Register now!"))),
                                                    if (!canRegister)
                                                      Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 2, bottom: 5),
                                                          child: Text(
                                                            'Create a company profile to register to attend.',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall,
                                                          )),
                                                  ],
                                                );
                                              }),
                                              const SizedBox(height: 12),
                                            ]),

                                  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                             * MARK: Registration Info / Show Details Button
                                             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
                                  // if (currentBadge?.isExhibitor ?? false) ...[
                                  //     ElevatedButton(
                                  //         key:        const Key("show_home__show_info_button"),
                                  //         onPressed:  () { context.pushNamed("show info", pathParameters: { "showId": show!.id }); },
                                  //         style:      elevatedButtonStyleAlt,
                                  //         child:      Padding(
                                  //             padding:  EdgeInsets.symmetric(vertical: 8),
                                  //             child:    Text("View your registration info")
                                  //         )
                                  //     ),
                                  //     const SizedBox(height: 12),
                                  // ],

                                  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                             * MARK: Lead Retrieval Ad
                                             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
                                  ...(() {
                                    final isExhibitor =
                                        currentBadge?.isExhibitor ?? false;
                                    final hasLead =
                                        currentBadge?.hasLeadScannerLicense ??
                                            false;

                                    if (currentBadge == null ||
                                        !isExhibitor ||
                                        hasLead) return <Widget>[];

                                    return <Widget>[
                                      LeadRetrievalAd(
                                        onPurchaseFlowStarted: () {
                                          _awaitingLeadPurchaseReturn = true;
                                          setState(
                                              () => _isBadgeRefreshing = true);
                                        },
                                        onRefreshStart: () => setState(
                                            () => _isBadgeRefreshing = true),
                                        onRefreshEnd: () => setState(
                                            () => _isBadgeRefreshing = false),
                                      ),
                                      const SizedBox(height: 12),
                                    ];
                                  }()),

                                  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                             * MARK: Upload Marketing Materials Button
                                             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                  if (currentBadge?.isExhibitor ?? false) ...[
                                    Container(
                                        decoration: hardEdgeDecoration,
                                        child: Container(
                                            foregroundDecoration: beveledDecoration,
                                        child:ElevatedButton(
                                            key: const Key(
                                                "show_home__upload_marketing_materials_button"),
                                            onPressed: () async {
                                            /*
                                                            *  Go to the file-upload URL
                                                            */
                                            final url =
                                                "https://bmd_flutter_tools.com/upload-files/";

                                            if (url != null &&
                                                url != "" &&
                                                await canLaunchUrl(
                                                    Uri.parse(url))) {
                                                await launchUrl(
                                                Uri.parse(url),
                                                mode: LaunchMode
                                                    .externalApplication,
                                                );
                                            } else {
                                                scaffoldMessengerKey.currentState
                                                    ?.showSnackBar(SnackBar(
                                                content: Text(
                                                    "This show's custom tickets link is coming soon!",
                                                    textAlign: TextAlign.center),
                                                padding: EdgeInsets.all(16),
                                                ));
                                            }
                                            },
                                            style: elevatedButtonStyleAlt.copyWith(
                                                padding: WidgetStateProperty.all(
                                                    EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 32))),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                spacing: 3,
                                                children: [
                                                Text(
                                                    (textScaleFactor > 1.2) ? "Upload materials" : "Upload marketing materials"),
                                                Text(
                                                    "Upload logos, art, special requests, and other marketing materials",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            height: 0.975))
                                                ])
                                        ))),
                                    const SizedBox(height: 12)
                                  ],

                                  const SizedBox(height: dividerSpacingTop),
                                  Divider(
                                      height: dividerHeight),
                                  const SizedBox(height: dividerSpacingBottom),

                                  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                             * MARK: Section: Exhibitor Resources
                                             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
                                  ...(currentBadge?.isExhibitor ?? false
                                      ? [
                                          Padding(
                                              padding: EdgeInsets.only(
                                                right: 12,
                                                bottom: 4,
                                                left: 12,
                                              ),
                                              child: Text("Exhibitor Resources",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineLarge!)),

                                          /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                     * MARK: Social Media Promo Button
                                                     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
                                           Container(
                                                decoration: hardEdgeDecoration,
                                                child: Container(
                                                    foregroundDecoration: beveledDecoration,
                                                child: ElevatedButton(
                                              key: const Key(
                                                  "show_home__social_media_promo_button"),
                                              onPressed: () async {
                                                /*
                                                             *  Go to the social media promo URL, if it exists
                                                             */
                                                String url = show
                                                        .socialMediaPromoUrl ??
                                                    ((ref.read(isDevelopmentProvider)
                                                            ? ref.read(
                                                                developmentSiteBaseUrlProvider)
                                                            : ref.read(
                                                                productionSiteBaseUrlProvider)) +
                                                        "/share");

                                                String? companyName = ref
                                                    .read(companyProvider)
                                                    ?.name;
                                                String? boothNumbers = ref
                                                    .read(badgeProvider)
                                                    ?.booths
                                                    .map(
                                                        (booth) => booth.number)
                                                    .join(", ");
                                                String? email = ref
                                                    .read(userProvider)
                                                    ?.email;
                                                String? website = ref
                                                    .read(companyProvider)
                                                    ?.website;
                                                String? seriesShortName = ref
                                                    .read(showProvider)
                                                    ?.legacySeriesShortName;

                                                String query = "?";
                                                /*
                                                             * NOTE: All parameters except "show" are different on the "/share" page only
                                                             */
                                                if (seriesShortName != null ||
                                                    seriesShortName != "") {
                                                  query +=
                                                      "show=${seriesShortName}";
                                                }
                                                if (email != null ||
                                                    email != "") {
                                                  query +=
                                                      "&EMAIL_ADDRESS=${email}";
                                                }
                                                if (companyName != null ||
                                                    companyName != "") {
                                                  query +=
                                                      "&COMPANY=${companyName}";
                                                }
                                                if (boothNumbers != null ||
                                                    boothNumbers != "") {
                                                  query +=
                                                      "&BOOTH=${boothNumbers}";
                                                }
                                                if (website != null ||
                                                    website != "") {
                                                  query +=
                                                      "&WEBSITE=${website}";
                                                }

                                                url += Uri.encodeFull(query);

                                                if (await canLaunchUrl(
                                                    Uri.parse(url))) {
                                                  await launchUrl(
                                                    Uri.parse(url),
                                                    mode: LaunchMode
                                                        .externalApplication,
                                                  );
                                                } else {
                                                  scaffoldMessengerKey
                                                      .currentState
                                                      ?.showSnackBar(SnackBar(
                                                    content: Text(
                                                        "This show's custom email campaign link is coming soon!",
                                                        textAlign:
                                                            TextAlign.center),
                                                    padding: EdgeInsets.all(16),
                                                  ));
                                                }
                                              },
                                              style: elevatedButtonStyleAlt
                                                  .copyWith(
                                                      padding:
                                                          WidgetStateProperty
                                                              .all(EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8))),
                                              child:
                                                  Row(spacing: 12, children: [
                                                Image.asset(
                                                    "assets/images/icon--exhibitor-resources--social.png",
                                                    width: 48,
                                                    height: 48),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text("Social media promo",
                                                          style: TextStyle(
                                                              height: 0.875))
                                                    ])
                                              ])))
                                              ),

                                          const SizedBox(height: 12),

                                          /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                     * MARK: Custom Email Campaign Button
                                                     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                        Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child: ElevatedButton(
                                              key: const Key(
                                                  "show_home__custom_email_campaign_button"),
                                              onPressed: () async {
                                                /*
                                                             *  Go to the custom email campaign URL, if it exists
                                                             */
                                                String? url =
                                                    show.customEmailCampaignUrl;

                                                if (url != null && url != "") {
                                                  String? companyName = ref
                                                      .read(companyProvider)
                                                      ?.name;
                                                  String? boothNumbers = ref
                                                      .read(badgeProvider)
                                                      ?.booths
                                                      .map((booth) =>
                                                          booth.number)
                                                      .join(", ");
                                                  String? email = ref
                                                      .read(userProvider)
                                                      ?.email;

                                                  String query = "";

                                                  if (email != null) {
                                                    query += "&email=${email}";
                                                  }
                                                  if (companyName != null &&
                                                      boothNumbers != null) {
                                                    query +=
                                                        "&company=${companyName}&booth=${boothNumbers}";
                                                  }
                                                  url += Uri.encodeFull(query);

                                                  if (await canLaunchUrl(
                                                      Uri.parse(url))) {
                                                    await launchUrl(
                                                      Uri.parse(url),
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  } else {
                                                    scaffoldMessengerKey
                                                        .currentState
                                                        ?.showSnackBar(SnackBar(
                                                      content: Text(
                                                          "This show's custom email campaign link is coming soon!",
                                                          textAlign:
                                                              TextAlign.center),
                                                      padding:
                                                          EdgeInsets.all(16),
                                                    ));
                                                  }
                                                } else {
                                                  scaffoldMessengerKey
                                                      .currentState
                                                      ?.showSnackBar(SnackBar(
                                                    content: Text(
                                                        "This show's custom email campaign link is coming soon!",
                                                        textAlign:
                                                            TextAlign.center),
                                                    padding: EdgeInsets.all(16),
                                                  ));
                                                }
                                              },
                                              style: elevatedButtonStyleAlt
                                                  .copyWith(
                                                      padding:
                                                          WidgetStateProperty
                                                              .all(EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8))),
                                              child:
                                                  Row(spacing: 12, children: [
                                                Image.asset(
                                                    "assets/images/icon--exhibitor-resources--mail.png",
                                                    width: 48,
                                                    height: 48),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                          "Custom"
                                                              .toUpperCase(),
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .labelSmall!),
                                                      Text("Email campaign",
                                                          style: TextStyle(
                                                              height: 0.875))
                                                    ])
                                              ])))),
                                          const SizedBox(height: 12),

                                          /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                     * MARK: Custom Tickets Button
                                                     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                                                      Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child: ElevatedButton(
                                              key: const Key(
                                                  "show_home__custom_tickets_button"),
                                              onPressed: () async {
                                                /*
                                                             *  Go to the custom tickets URL, if it exists
                                                             */
                                                String? url =
                                                    show.customTicketsUrl;

                                                if (url != null && url != "") {
                                                  String? companyName = ref
                                                      .read(companyProvider)
                                                      ?.name;
                                                  String? boothNumbers = ref
                                                      .read(badgeProvider)
                                                      ?.booths
                                                      .map((booth) =>
                                                          booth.number)
                                                      .join(", ");
                                                  String? email = ref
                                                      .read(userProvider)
                                                      ?.email;

                                                  String query = "";

                                                  if (email != null) {
                                                    query += "&email=${email}";
                                                  }
                                                  if (companyName != null &&
                                                      boothNumbers != null) {
                                                    query +=
                                                        "&company=${companyName}&booth=${boothNumbers}";
                                                  }
                                                  url += Uri.encodeFull(query);

                                                  if (await canLaunchUrl(
                                                      Uri.parse(url))) {
                                                    await launchUrl(
                                                      Uri.parse(url),
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  } else {
                                                    scaffoldMessengerKey
                                                        .currentState
                                                        ?.showSnackBar(SnackBar(
                                                      content: Text(
                                                          "This show's custom tickets link is coming soon!",
                                                          textAlign:
                                                              TextAlign.center),
                                                      padding:
                                                          EdgeInsets.all(16),
                                                    ));
                                                  }
                                                } else {
                                                  scaffoldMessengerKey
                                                      .currentState
                                                      ?.showSnackBar(SnackBar(
                                                    content: Text(
                                                        "This show's custom tickets link is coming soon!",
                                                        textAlign:
                                                            TextAlign.center),
                                                    padding: EdgeInsets.all(16),
                                                  ));
                                                }
                                              },
                                              style: elevatedButtonStyleAlt
                                                  .copyWith(
                                                      padding:
                                                          WidgetStateProperty
                                                              .all(EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8))),
                                              child:
                                                  Row(spacing: 12, children: [
                                                Image.asset(
                                                    "assets/images/icon--exhibitor-resources--ticket.png",
                                                    width: 48,
                                                    height: 48),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text("Custom tickets",
                                                          style: TextStyle(
                                                              height: 0.875))
                                                    ])
                                              ])))),
                                          const SizedBox(height: 12),

                                          /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                     * MARK: Booth Photos Button
                                                     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                                                      Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child: ElevatedButton(
                                              key: const Key(
                                                  "show_home__booth_photos_button"),
                                              onPressed: () {
                                                /*
                                                             *  Open the booth photos
                                                             */
                                                context.pushNamed(
                                                    "document reader",
                                                    queryParameters: {
                                                      "title": "Booth Photos",
                                                      "assetPath":
                                                          "assets/pdfs/booth-photos--2025-001.pdf"
                                                    });
                                              },
                                              style: elevatedButtonStyleAlt
                                                  .copyWith(
                                                      padding:
                                                          WidgetStateProperty
                                                              .all(EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8))),
                                              child:
                                                  Row(spacing: 12, children: [
                                                Image.asset(
                                                    "assets/images/icon--exhibitor-resources--photo.png",
                                                    width: 48,
                                                    height: 48),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                          "View the"
                                                              .toUpperCase(),
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .labelSmall!),
                                                      Text("Booth photos",
                                                          style: TextStyle(
                                                              height: 0.875))
                                                    ])
                                              ])))),
                                          const SizedBox(height: 12),

                                          /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                     * MARK: Exhibitor Planner Button
                                                     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                                                     Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child:  ElevatedButton(
                                              key: const Key(
                                                  "show_home__exhibitor_planner_button"),
                                              onPressed: () {
                                                /*
                                                             *  Open the exhibitor planner, if it exists
                                                             *
                                                             *  TODO: Refactor this to remove the hardcoded link once exhibitorPlanner is added to the Show model
                                                             */
                                                if (true) {
                                                  // (show.exhibitorPlanner != null) {
                                                  context.pushNamed(
                                                      "document reader",
                                                      queryParameters: {
                                                        "title":
                                                            "Exhibitor Planner",
                                                        "assetPath":
                                                            "https://bmd_flutter_tools.com/wp-content/uploads/2020/12/BuildExpoEventPlanner.pdf"
                                                      });
                                                } else {
                                                  scaffoldMessengerKey
                                                      .currentState
                                                      ?.showSnackBar(SnackBar(
                                                    content: Text(
                                                        "This show's exhibitor planner is coming soon!",
                                                        textAlign:
                                                            TextAlign.center),
                                                    padding: EdgeInsets.all(16),
                                                  ));
                                                }
                                              },
                                              style: elevatedButtonStyleAlt
                                                  .copyWith(
                                                      padding:
                                                          WidgetStateProperty
                                                              .all(EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8))),
                                              child:
                                                  Row(spacing: 12, children: [
                                                Image.asset(
                                                    "assets/images/icon--exhibitor-resources--checklist.png",
                                                    width: 48,
                                                    height: 48),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                          "View the"
                                                              .toUpperCase(),
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .labelSmall!),
                                                      Text("Exhibitor planner",
                                                          style: TextStyle(
                                                              height: 0.875))
                                                    ])
                                              ])))),
                                          const SizedBox(height: 12),

                                          /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                     * MARK: Show Flyer Button
                                                     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                                                     Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child:  ElevatedButton(
                                              key: const Key(
                                                  "show_home__show_flyer_button"),
                                              onPressed: () {
                                                /*
                                                             *  Open the show flyer, if it exists
                                                             */
                                                if (show.showFlyer != null &&
                                                    show.showFlyer != "") {
                                                  context.pushNamed(
                                                      "document reader",
                                                      queryParameters: {
                                                        "title": "Show Flyer",
                                                        "assetPath":
                                                            show.showFlyer
                                                      });
                                                } else {
                                                  scaffoldMessengerKey
                                                      .currentState
                                                      ?.showSnackBar(SnackBar(
                                                    content: Text(
                                                        "This show's flyer is coming soon!",
                                                        textAlign:
                                                            TextAlign.center),
                                                    padding: EdgeInsets.all(16),
                                                  ));
                                                }
                                              },
                                              style: elevatedButtonStyleAlt
                                                  .copyWith(
                                                      padding:
                                                          WidgetStateProperty
                                                              .all(EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8))),
                                              child:
                                                  Row(spacing: 12, children: [
                                                Image.asset(
                                                    "assets/images/icon--exhibitor-resources--flyer.png",
                                                    width: 48,
                                                    height: 48),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                          "View the"
                                                              .toUpperCase(),
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .labelSmall!),
                                                      Text("Show flyer",
                                                          style: TextStyle(
                                                              height: 0.875))
                                                    ])
                                              ])))),
                                          const SizedBox(height: 12),

                                          /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                     * MARK: Exhibitor Service Manual Button
                                                     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                                                      Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child: ElevatedButton(
                                              key: const Key(
                                                  "show_home__exhibitor_service_manual_button"),
                                              onPressed: () {
                                                /*
                                                             *  Open the exhibitor service manual, if it exists
                                                             */
                                                if (show.exhibitorServiceManual !=
                                                        null &&
                                                    show.exhibitorServiceManual !=
                                                        "") {
                                                  context.pushNamed(
                                                      "document reader",
                                                      queryParameters: {
                                                        "title":
                                                            "Exhibitor Service Manual",
                                                        "assetPath": show
                                                            .exhibitorServiceManual
                                                      });
                                                } else {
                                                  scaffoldMessengerKey
                                                      .currentState
                                                      ?.showSnackBar(SnackBar(
                                                    content: Text(
                                                        "This show's exhibitor service manual is coming soon!",
                                                        textAlign:
                                                            TextAlign.center),
                                                    padding: EdgeInsets.all(16),
                                                  ));
                                                }
                                              },
                                              style: elevatedButtonStyleAlt
                                                  .copyWith(
                                                      padding:
                                                          WidgetStateProperty
                                                              .all(EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8))),
                                              child:
                                                  Row(spacing: 12, children: [
                                                Image.asset(
                                                    "assets/images/icon--exhibitor-resources--document.png",
                                                    width: 48,
                                                    height: 48),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                          ((textScaleFactor > 1.1) ? "View the exhibitor" : "View the")
                                                              .toUpperCase(),
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .labelSmall!),
                                                        Text((textScaleFactor > 1.1) ? "Service manual" : "Exhibitor service manual",
                                                            style:    TextStyle(height: 0.875)
                                                        )
                                                    ])
                                              ])))),
                                          const SizedBox(height: 12),

                                          /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                     * MARK: Advertising Media Kit Button
                                                     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                                                      Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child: ElevatedButton(
                                              key: const Key(
                                                  "show_home__advertising_media_kit_button"),
                                              onPressed: () {
                                                if (show.advertisingMediaKit !=
                                                        null &&
                                                    show.advertisingMediaKit !=
                                                        "") {
                                                  context.pushNamed(
                                                      "document reader",
                                                      queryParameters: {
                                                        "title":
                                                            "Advertising Media Kit",
                                                        "assetPath": show
                                                            .advertisingMediaKit
                                                      });
                                                } else {
                                                  scaffoldMessengerKey
                                                      .currentState
                                                      ?.showSnackBar(SnackBar(
                                                    content: Text(
                                                        "This show's advertising media kit is coming soon!",
                                                        textAlign:
                                                            TextAlign.center),
                                                    padding: EdgeInsets.all(16),
                                                  ));
                                                }
                                              },
                                              style: elevatedButtonStyleAlt
                                                  .copyWith(
                                                      padding:
                                                          WidgetStateProperty
                                                              .all(EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8))),
                                              child:
                                                  Row(spacing: 12, children: [
                                                Image.asset(
                                                    "assets/images/icon--exhibitor-resources--chart.png",
                                                    width: 48,
                                                    height: 48),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                          ((textScaleFactor > 1.35) ? "View the advertising" : "View the")
                                                              .toUpperCase(),
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .labelSmall!),
                                                      Text(
                                                          (textScaleFactor > 1.35) ? "Media kit" : "Advertising media kit",
                                                          style: TextStyle(
                                                              height: 0.875))
                                                    ])
                                              ])))),
                                          const SizedBox(height: 12),

                                          /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                     * MARK: Invite Staff Members Button
                                                     * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                                                      Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child: ElevatedButton(
                                              key: const Key(
                                                  "show_home__invite_button"),
                                              onPressed: () {
                                                showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return InviteTeamMemberForm();
                                                    });
                                              },
                                              style: elevatedButtonStyleAlt
                                                  .copyWith(
                                                      padding:
                                                          WidgetStateProperty
                                                              .all(EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          8))),
                                              child:
                                                  Row(spacing: 12, children: [
                                                Image.asset(
                                                    "assets/images/icon--exhibitor-resources--badge.png",
                                                    width: 48,
                                                    height: 48),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                          "Get additional"
                                                              .toUpperCase(),
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .labelSmall!),
                                                      Text("Exhibitor badges",
                                                          style: TextStyle(
                                                              height: 0.875))
                                                    ])
                                              ]))))
                                        ]

                                      /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                                 * MARK: Section: Attendee Resources
                                                 * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                      : [
                                          Padding(
                                              padding: EdgeInsets.only(
                                                right: 12,
                                                bottom: 4,
                                                left: 12,
                                              ),
                                              child: Text("Resources",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineLarge!)),
                                        ]),


                                  const SizedBox(height: dividerSpacingTop),
                                  Divider(
                                      height: dividerHeight),
                                  const SizedBox(height: dividerSpacingBottom),

                                  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                             * MARK: Section: Seminars List & "Interested in Presenting?" Buttons
                                             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                  Padding(
                                      padding: EdgeInsets.only(
                                        right: 12,
                                        bottom: 4,
                                        left: 12,
                                      ),
                                      child: Text("Keynotes & Seminars",
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge!)),

                                                              Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child: ElevatedButton(
                                      key: Key(
                                          "show_home__seminars_list_button"),
                                      onPressed: () {
                                        context.pushNamed("seminars list");
                                      },
                                      style: elevatedButtonStyleAlt,
                                      child: Padding(
                                          padding:
                                              EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                              (textScaleFactor > 1.1) ? "Complementary classes" : "View complementary classes"))),
                                        )),
                                  const SizedBox(height: 12),

                                  const SizedBox(height: dividerSpacingTop),
                                  Divider(
                                      height: dividerHeight),
                                  const SizedBox(height: dividerSpacingBottom),

                                  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                             * MARK: Section: Magazine Ad
                                             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                  MagazineAd(show: show),

                                  const SizedBox(height: dividerSpacingTop),
                                  Divider(
                                      height: dividerHeight),
                                  const SizedBox(height: dividerSpacingBottom),

                                  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                             * MARK: Section: Exhibiting Companies Button
                                             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                  Padding(
                                      padding: EdgeInsets.only(
                                        right: 12,
                                        bottom: 4,
                                        left: 12,
                                      ),
                                      child: Text("Exhibitors",
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge!)),

                                                              Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child: ElevatedButton(
                                      key: Key(
                                          "show_home__exhibitors_list_button"),
                                      onPressed: () {
                                        context.pushNamed("exhibitors list");
                                      },
                                      style: elevatedButtonStyleAlt,
                                      child: Padding(
                                          padding:
                                              EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                              (textScaleFactor > 1.2) ? "Exhibiting companies" : "View exhibiting companies"))))),



                                  const SizedBox(height: dividerSpacingTop),
                                  Divider(
                                      height: dividerHeight),
                                  const SizedBox(height: dividerSpacingBottom),

                                  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                                             * MARK: Section: Sponsors
                                             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -    */
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text("Sponsored by",
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge!)),
                                ])),
                        FlutterCarousel(
                            options: FlutterCarouselOptions(
                                autoPlay: true,
                                autoPlayCurve: Curves.linear,
                                autoPlayInterval: const Duration(seconds: 5),
                                autoPlayAnimationDuration: const Duration(seconds: 5),
                                enableInfiniteScroll: true,
                                height: 140,
                                pageSnapping: false,
                                showIndicator: false),
                            items: [
                              Image.asset(
                                  "assets/images/sponsor-logo--build-expo-usa.png"),
                              Image.asset(
                                  "assets/images/sponsor-logo--alltek-construction.png"),
                              Image.asset(
                                  "assets/images/sponsor-logo--construction-monthly.png"),
                            ]),

                        /*
                                             * Spacer to improve scrolling feel
                                             */
                        const SizedBox(height: 108)
                      ].nonNulls.toList();
                    }(),
                  ));
            }));
  }
}
