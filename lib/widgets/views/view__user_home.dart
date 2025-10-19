/*
 * User Home View
 *
 * Created by:  Blake Davis
 * Description:
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/theme/app_styles.dart" hide hardEdgeDecoration;
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__company_user.dart";
import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/data/model/data__company.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart" hide elevatedButtonStyleAlt, beveledDecoration;
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/components/component__app_info_text.dart";
import "package:bmd_flutter_tools/widgets/components/component__foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/components/component__updating_indicator.dart";
import "package:bmd_flutter_tools/widgets/navigation/navigation_bar__primary.dart";
import "package:bmd_flutter_tools/widgets/navigation/navigation_menu.dart";
import "package:bmd_flutter_tools/widgets/panels/panel__lead_retrieval_ad.dart";
import "package:bmd_flutter_tools/widgets/components/component__show_card.dart";
import "package:bmd_flutter_tools/widgets/utilities/tool__no_scale_wrapper.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";




/* ======================================================================================================================
 * MARK: User Home View
 * ------------------------------------------------------------------------------------------------------------------ */
class UserHome extends ConsumerStatefulWidget {

    static const Key rootKey = Key("user_home__root");

    final String title;


    UserHome({  super.key,
        required this.title
    });


    @override
    ConsumerState<UserHome> createState() => _UserHomeListState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _UserHomeListState extends ConsumerState<UserHome> with WidgetsBindingObserver {

    AppDatabase appDatabase = AppDatabase.instance;

    bool _awaitingLeadPurchaseReturn = false;

    bool _loadingDb = true;
    bool _loadingApi = false;

    /// Shows (upcoming only) for the current user/company
    List<ShowData> _upcomingShows = [];

    /// Simple toggle to trigger RefreshIndicator without changing logic
    bool _refreshTick = false;

    final ScrollController _scrollController = ScrollController();

    /// DB-derived badges keyed by showId for the current user/company
    Map<String, BadgeData?> _badgesByShow = {};




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
      super.initState();
      showSystemUiOverlays();
        WidgetsBinding.instance.addObserver(this);

      // DB-first render, then refresh from API.
      _loadFromDb().then((_) {
        if (mounted) _refreshFromApi();
      });
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      _scrollController.dispose();
      super.dispose();
    }







  Future<void> _refreshBadgesAndUserAfterReturn() async {
    try {
      final badgeNotifier = ref.read(badgeProvider.notifier);
      final userNotifier  = ref.read(userProvider.notifier);

      final String? currentBadgeId = ref.read(badgeProvider)?.id;
      final String? inferredUserId = ref.read(badgeProvider)?.userId;
      final String? userId         = ref.read(userProvider)?.id;
      final String? companyId      = ref.read(companyProvider)?.id;

      final String? effectiveUserId = (userId != null && userId.isNotEmpty)
          ? userId
          : ((inferredUserId != null && inferredUserId.isNotEmpty) ? inferredUserId : null);
      if (effectiveUserId == null) return;

      await Future.delayed(const Duration(milliseconds: 800));
      final badges = await ApiClient.instance.getBadges(userId: effectiveUserId);
      if (!mounted) return;

      final bool hadLicenseBefore = ref.read(badgeProvider)?.hasLeadScannerLicense ?? false;

      dynamic matched;
      if (currentBadgeId != null && currentBadgeId.isNotEmpty) {
        for (final b in badges) {
          try { if (b.id == currentBadgeId) { matched = b; break; } } catch (_) {}
        }
      }

      if (matched != null) {
        logPrint("🔄 UserHome | Updating badge ${matched.id} hasLeadScannerLicense=${matched.hasLeadScannerLicense}");
        badgeNotifier.update(matched);
        if (!hadLicenseBefore && (matched.hasLeadScannerLicense == true)) {
          if (mounted) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(
                backgroundColor: BeColorSwatch.green,
                content: Text("Lead retrieval is activated!", style: TextStyle(color: BeColorSwatch.white))
                ),            );
          }
        }
      }

      if (companyId != null && companyId.isNotEmpty) {
        await ApiClient.instance.getCompanyById(companyId);
      }

      try {
        final refreshedUser = await ApiClient.instance.getUser(getAdditionalData: true);
        if (mounted && refreshedUser != null) {
          userNotifier.update(refreshedUser);

          final currentCompany = ref.read(companyProvider);
          if (currentCompany == null && refreshedUser.companies.isNotEmpty) {
            final sortedCompanies = [...refreshedUser.companies]
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            ref.read(companyProvider.notifier).update(sortedCompanies.first);
          }
        }
      } catch (_) {}

    } catch (e) {
      logPrint("❌ UserHome | Error refreshing after return: $e");
    } finally {
      if (mounted) setState(() => _loadingApi = false);
    }
  }

// 6) Add lifecycle hook
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingLeadPurchaseReturn) {
      _awaitingLeadPurchaseReturn = false;
      _refreshBadgesAndUserAfterReturn();
    }
  }







    /// Collect all show IDs for this user+company.
    Future<List<String>> _userShowIds() async {
        final u = ref.read(userProvider);
        if (u == null) return [];
        final companyId = ref.read(companyProvider)?.id;
        if (companyId == null || companyId.isEmpty) return [];

        // Read badges for this user+company from the local DB
        final badges = await appDatabase.readBadges(
            where: "${BadgeDataInfo.userId.columnName} = ? AND ${BadgeDataInfo.companyId.columnName} = ?",
            whereArgs: [u.id, companyId],
        );

        // Populate the in-memory map for fast lookups in build()
        final map = <String, BadgeData?>{};
        for (final b in badges) {
            map[b.showId] = b;
        }
        _badgesByShow = map;

        return badges.map((b) => b.showId).toList();
    }

    /// Filter to upcoming by the show dates.
    List<ShowData> _filterUpcoming(List<ShowData> shows) {
      final nowSec = DateTime.now().millisecondsSinceEpoch / 1000;
      return shows
          .where((s) => (s.dates.dates.lastOrNull?.end ?? 0) >= nowSec)
          .toList()
        ..sort((a, b) => (a.dates.dates.firstOrNull?.start ?? 0)
            .compareTo(b.dates.dates.firstOrNull?.start ?? 0));
    }

    Future<void> _refreshBadgesFromApi() async {
        try {
            final String? userId = ref.read(userProvider)?.id;
            if (userId == null || userId.isEmpty) return;
            // Fetches and (per your ApiClient) writes badges to the local DB
            await ApiClient.instance.getBadges(userId: userId);
        } catch (e) {
            logPrint("❌ UserHome: badge refresh failed: $e");
        }
    }

    Future<void> _loadFromDb() async {
      setState(() => _loadingDb = true);
      try {
        final ids = await _userShowIds();
        if (ids.isEmpty) {
          setState(() {
            _upcomingShows = [];
            _loadingDb = false;
          });
          return;
        }
        final whereIn = "${ShowDataInfo.id.columnName} IN (${ids.map((id) => "'$id'").join(',')})";
        final dbShows = await appDatabase.readShows(where: whereIn);
        setState(() {
          _upcomingShows = _filterUpcoming(dbShows);
          _loadingDb = false;
        });
      } catch (_) {
        setState(() {
          _upcomingShows = [];
          _loadingDb = false;
        });
      }
    }

  Future<void> _refreshFromApi() async {
  setState(() => _loadingApi = true);
  try {
    // 1) Determine the user’s relevant show IDs from DB-backed badges
    final ids = await _userShowIds();
    if (ids.isEmpty) {
      setState(() => _loadingApi = false);
      return;
    }

    // 2) Refresh badges from API so DB reflects any new server-side badges
    await _refreshBadgesFromApi();

    // 3) Refresh shows (details) from API and persist for offline
    final apiShows = await ApiClient.instance.getShows(ids: ids);
    await appDatabase.write(apiShows);

    // 4) Rebuild the badges map from DB (after the API call above)
    try {
      final u = ref.read(userProvider);
      final companyId = ref.read(companyProvider)?.id;
      if (u != null && companyId != null && companyId.isNotEmpty) {
        final badges = await appDatabase.readBadges(
          where: "${BadgeDataInfo.userId.columnName} = ? AND ${BadgeDataInfo.companyId.columnName} = ?",
          whereArgs: [u.id, companyId],
        );
        final map = <String, BadgeData?>{};
        for (final b in badges) { map[b.showId] = b; }
        _badgesByShow = map;
      } else {
        _badgesByShow = {};
      }
    } catch (_) {}

    // 5) Replace in-memory shows with canonical, upcoming-only list
    if (mounted) {
      setState(() {
        _upcomingShows = _filterUpcoming(apiShows);
        _loadingApi = false;
      });
    }
  } catch (e) {
    logPrint("❌ UserHome: API refresh failed: $e");
    if (mounted) setState(() => _loadingApi = false);
  }
}




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);

        // Listen to company changes (must be inside build for Consumer* widgets)
        ref.listen<CompanyData?>(companyProvider, (prev, next) {
          if (!mounted) return;
          // Only react on actual change and valid next
          if (next == null || next.id == prev?.id) return;
          // Ensure we have a user and that user has badges for this company
          final u = ref.read(userProvider);
          if (u == null) return;
          final hasBadgesForCompany = u.badges.any((b) => b.companyId == next.id);
          if (!hasBadgesForCompany) return;
          // DB-first, then refresh from API
          _loadFromDb().then((_) {
            if (mounted) _refreshFromApi();
          });
        });
        final user = ref.watch(userProvider);
        return Scaffold(
            appBar:               PrimaryNavigationBar(isHome: true, showMenu: true),
            drawer:               NavigationMenu(),
            floatingActionButton: (ref.watch(badgeProvider)?.hasLeadScannerLicense ?? false) ? FloatingScannerButton() : null,
            key:                  UserHome.rootKey,
            body: () {
                // While waiting on DB, or when API is loading and we have no data yet, show full-screen loader
                if (_loadingDb || (_loadingApi && _upcomingShows.isEmpty)) {
                return Center(
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                        CircularProgressIndicator(color: BeColorSwatch.navy, padding: EdgeInsets.only(bottom: 8)),
                        SizedBox(height: 8),
                        Text("Loading home page..."),
                        SizedBox(height: 16),
                    ],
                    ),
                );
                }

                // Determine next upcoming show/badge from current in-memory list.
                final List<ShowData> upcomingShows = _upcomingShows;
                String? nextUpcomingShowId = upcomingShows.isNotEmpty ? upcomingShows.first.id : null;
                BadgeData? nextUpcomingShowBadge;
                if (user != null && nextUpcomingShowId != null) {
                  BadgeData? nextUpcomingShowBadge;
                        if (nextUpcomingShowId != null) {
                        nextUpcomingShowBadge = _badgesByShow[nextUpcomingShowId];
                        }
                }
                final currentBadge = ref.watch(badgeProvider);

                // Keep the provider-update post-frame using _upcomingShows.
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
                  final u = ref.read(userProvider);
                  // 1) Ensure company set
                  if (ref.read(companyProvider) == null) {
                    final sortedCompanies = (u?.companies ?? [])..sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                    final CompanyData? newCompanyState = sortedCompanies.firstOrNull;
                    if (newCompanyState != null) {
                      ref.read(companyProvider.notifier).update(newCompanyState);
                      final List<CompanyUserData>? companyUsers = await appDatabase.read(
                        tableName: CompanyUserDataInfo.tableName,
                        whereAsMap: {
                          CompanyUserDataInfo.companyId.columnName: newCompanyState.id,
                          CompanyUserDataInfo.userId.columnName: u!.id,
                        },
                      );
                      if (companyUsers != null && companyUsers.isNotEmpty) {
                        ref.read(companyUserProvider.notifier).update(companyUsers[0]);
                      }
                    }
                  }

                  // 2) Desired home show/badge
                  final CompanyData? currentCompany = ref.read(companyProvider);
                  ShowData? desiredShow = upcomingShows.isNotEmpty ? upcomingShows.first : null;
                  BadgeData? desiredBadge;
                  if (u != null && desiredShow != null && currentCompany != null) {
                    desiredBadge = u.badges.firstWhereOrNull(
                      (b) => b.showId == desiredShow.id && b.companyId == currentCompany.id,
                    );
                  }

                  final ShowData? currentShow = ref.read(showProvider);
                  if (desiredShow != null && (currentShow == null || currentShow.id != desiredShow.id)) {
                    ref.read(showProvider.notifier).update(desiredShow);
                  }

                  final BadgeData? currentBadge = ref.read(badgeProvider);
                  if (desiredBadge != null && (currentBadge == null || currentBadge.id != desiredBadge.id)) {
                    ref.read(badgeProvider.notifier).update(desiredBadge);
                  }

                  saveStateToDatabase();
                });

                // Normal body (same visual layout as before), but driven by _upcomingShows.
                return Stack(
                  children: [
                    RefreshIndicator.adaptive(
                      onRefresh: () async {
                        setState(() => _refreshTick = !_refreshTick);
                        _refreshFromApi();
                      },
                      child: ListView(
                        children: ([
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              children: [
                                const SizedBox(height: 56),
                                /*
                                 * Updating indicator
                                 */
                                if (_loadingApi && _upcomingShows.isNotEmpty) ...[
                                    const UpdatingIndicator(),
                                    const SizedBox(height: 16),
                                ],
                                if ((user?.companies ?? []).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                                    child: Builder(
                                      builder: (context) {
                                        final currentCompany = ref.watch(companyProvider);
                                        return DropdownButton<CompanyData>(
                                          key: const Key("user_home__company_selector"),
                                          isExpanded: true,
                                          value: user!.companies.firstWhereOrNull((c) => c.id == currentCompany?.id),
                                          hint: const Text("Select your company"),
                                          items: (user!.companies).map((company) {
                                            return DropdownMenuItem<CompanyData>(
                                              value: company,
                                              child: Text(company.name),
                                            );
                                          }).toList(),
                                          onChanged: (selectedCompany) async {
                                            if (selectedCompany != null) {
                                              ref.read(companyProvider.notifier).update(selectedCompany);
                                              CompanyUserData? newCompanyUserState = (await appDatabase.read(
                                                tableName: CompanyUserDataInfo.tableName,
                                                whereAsMap: {
                                                  CompanyUserDataInfo.companyId.columnName: selectedCompany.id,
                                                  CompanyUserDataInfo.userId.columnName: user.id
                                                },
                                              ))?.first;
                                              ref.read(companyUserProvider.notifier).update(newCompanyUserState);
                                              // After switching companies, reload shows for that company.
                                              await _loadFromDb();
                                              await _refreshFromApi();
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                (upcomingShows.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 18),
                                          Text(" Your next show is...", style: Theme.of(context).textTheme.headlineLarge),
                                          ShowCard(
                                            key: const Key("user_home__next_show_button"),
                                            show: upcomingShows[0],
                                            url: "show",
                                            badge: nextUpcomingShowBadge,
                                          ),
                                          const SizedBox(height: 12),
                                          ...(currentBadge?.isExhibitor ?? false)
                                              ? ((currentBadge?.hasLeadScannerLicense ?? false)
                                                  ? [
                                                      Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child: ElevatedButton(
                                                        key: const Key("user_home__connections_list_button"),
                                                        onPressed: () {
                                                          context.goNamed("show");
                                                          context.pushNamed("connections");
                                                        },
                                                        style: elevatedButtonStyleAlt.copyWith(
                                                          backgroundColor: WidgetStateProperty.all(BeColorSwatch.red),
                                                        ),
                                                        child: const Padding(
                                                          padding: EdgeInsets.symmetric(vertical: 8),
                                                          child: Text("View your leads list"),
                                                        ),
                                                      )))
                                                    ]
                                              : [
                                                    LeadRetrievalAd(
                                                        onPurchaseFlowStarted: () {
                                                            _awaitingLeadPurchaseReturn = true;
                                                            setState(() { _loadingApi = true; });
                                                        },
                                                        onRefreshStart: () => setState(() { _loadingApi = true; }),
                                                        onRefreshEnd:   () => setState(() { _loadingApi = false; }),
                                                        )
                                                        ])
                                              : [
                                                  Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child:ElevatedButton(
                                                    key: const Key("user_home__seminars_list_button"),
                                                    onPressed: () {
                                                      context.goNamed("show");
                                                      context.pushNamed("seminars list");
                                                    },
                                                    style: elevatedButtonStyleAlt.copyWith(
                                                      backgroundColor: WidgetStateProperty.all(BeColorSwatch.red),
                                                    ),
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(vertical: 8),
                                                      child: Text("View complementary classes"),
                                                    ),
                                                  )))
                                                ],
                                          const SizedBox(height: 12),
                                          Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child:ElevatedButton(
                                            onPressed: () {
                                              context.goNamed("show");
                                              context.pushNamed("user profile");
                                            },
                                            style: elevatedButtonStyleAlt.copyWith(
                                              backgroundColor: WidgetStateProperty.all(BeColorSwatch.red),
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 8),
                                              child: Text("View your badge"),
                                            ),
                                          ))),
                                          const SizedBox(height: 36),
                                        ],
                                      )
                                    : (_loadingApi
                                        ? const SizedBox.shrink()
                                        : Padding(
                                            padding: const EdgeInsets.only(left: 16, bottom: 48, right: 16),
                                            child: Center(
                                            heightFactor: 1.5,
                                            child: Text(
                                                ref.watch(companyProvider) != null
                                                    ? "You have no upcoming shows for ${ref.watch(companyProvider)!.name}."
                                                    : "You are not registered for any shows.",
                                            ),
                                            ),
                                        ))),
                                Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child:ElevatedButton(
                                  key: const Key("user_home__all_shows_button"),
                                  onPressed: () {
                                    context.push("/all_shows");
                                  },
                                  style: elevatedButtonStyleAlt,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child:   Text((textScaleFactor > 1.2) ? "All Build Expo shows" : "View all Build Expo shows"),
                                  ),
                                ))),
                                const SizedBox(height: 128),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),

                    // App version and build
                    AppInfoText(),

                    // Copyright info
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                            Container(
                                padding: const EdgeInsets.only(bottom: 24, top: 24),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                    BeColorSwatch.lighterGray.withAlpha(0),
                                    BeColorSwatch.lighterGray.withAlpha(200),
                                    BeColorSwatch.lighterGray.withAlpha(225),
                                    ],
                                    stops: const [0, 0.24, 0.33],
                                ),
                                ),
                                child: NoScale(
                                    child: Text(
                                        "© 2009-${DateTime.now().year}\n International Conference Management, Inc.",
                                        style: beTextTheme.bodyTertiary.merge(
                                            TextStyle(
                                            color: BeColorSwatch.darkGray.withAlpha(250),
                                            fontWeight: FontWeight.w600,
                                            ),
                                        ),
                                        textAlign: TextAlign.center,
                                    ),
                                ),
                            ),
                        ]
                        ),
                    ),
                  ],
                );
            }(),
        );
    }
}
