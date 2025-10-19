/*
 * My Registrations
 *
 * Created by:  Blake Davis
 * Description:
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__company.dart";
import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/views/view__badge_scanner.dart";
import "package:bmd_flutter_tools/widgets/navigation_bar__primary.dart";
import "package:bmd_flutter_tools/widgets/navigation_menu.dart";
import "package:bmd_flutter_tools/widgets/component__show_card.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";




/* ======================================================================================================================
 * MARK: My Registrations List
 * ------------------------------------------------------------------------------------------------------------------ */
class MyRegistrationsList extends ConsumerStatefulWidget {

    final BadgeScanner barcodeScanner = BadgeScanner();

    final bool isNewSignup,
               showAll;

    static const Key rootKey = Key("all_shows_list__root");

    final String title;


    MyRegistrationsList({ super.key,
                    this.isNewSignup = false,
           required this.title,
                    this.showAll     = false
    });


    @override
    ConsumerState<MyRegistrationsList> createState() => _MyRegistrationsListState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _MyRegistrationsListState extends ConsumerState<MyRegistrationsList> {

    AppDatabase appDatabase = AppDatabase.instance;

    bool refresh = false;

    double offset = 0.0;

    ScrollController _scrollController = ScrollController();

    // DB-first, API-next state (mirrors ExhibitorsList)
    bool _loadingRegsDb  = false;
    bool _loadingRegsApi = false;
    List<ShowData> _registeredShows = <ShowData>[];
    List<ShowData> _registeredShowsSource = <ShowData>[];
    List<ShowData> _allShows        = <ShowData>[];

    bool _includePastRegistrations = false;


    // --- Helper: Deduplicate by id ---
    List<ShowData> _dedupeById(List<ShowData> items) {
        final seen = <String>{};
        final result = <ShowData>[];
        for (final s in items) {
            final id = s.id;
            if (id.isEmpty) continue;
            if (seen.add(id)) result.add(s);
        }
        return result;
    }

    List<ShowData> _sortByStartAsc(List<ShowData> shows) {
        shows.sort((a, b) => (a.dates.dates.firstOrNull?.start ?? 0)
            .compareTo(b.dates.dates.firstOrNull?.start ?? 0));
        return shows;
    }

    List<ShowData> _sortPastDesc(List<ShowData> shows) {
        shows.sort((a, b) => (b.dates.dates.firstOrNull?.start ?? 0)
            .compareTo(a.dates.dates.firstOrNull?.start ?? 0));
        return shows;
    }

    List<ShowData> _filterRegistered(List<ShowData> shows) {
        final deduped = _dedupeById(List<ShowData>.from(shows));
        final nowSecs = DateTime.now().millisecondsSinceEpoch / 1000;
        final upcoming = _onlyUpcomingSorted(List<ShowData>.from(deduped));
        if (!_includePastRegistrations) {
            return upcoming;
        }
        final past = _sortPastDesc(
            deduped.where((s) => (s.dates.dates.lastOrNull?.end ?? 0) < nowSecs).toList(),
        );
        return [...upcoming, ...past];
    }

    // --- Helper: Filter/sort only upcoming shows ---
    List<ShowData> _onlyUpcomingSorted(List<ShowData> shows) {
        final nowSecs = DateTime.now().millisecondsSinceEpoch / 1000;
        final list = shows
            .where((s) => (s.dates.dates.lastOrNull?.end ?? 0) >= nowSecs)
            .toList();
        list.sort((a, b) => (a.dates.dates.firstOrNull?.start ?? 0)
            .compareTo(b.dates.dates.firstOrNull?.start ?? 0));
        return list;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        showSystemUiOverlays();

        // Kick off DB-first hydration
        _hydrateFromDb();

        // Schedule provider resets and an API refresh after the first frame
        WidgetsBinding.instance.addPostFrameCallback((_) async {

            // If none is selected, choose the User's alphabetically first Company
            CompanyData? newCompanyState;
            final user = ref.read(userProvider);
            if (ref.read(companyProvider) == null) {
                final sortedCompanies = (user?.companies ?? [])
                    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                newCompanyState = sortedCompanies.firstOrNull;
                ref.read(companyProvider.notifier).update(newCompanyState);
            }

            // Persist state snapshot
            saveStateToDatabase();

            // Now refresh from API (will update the two sections independently)
            _refreshFromApi();
        });
    }
    // --- DB First (fast) ---
    Future<void> _hydrateFromDb() async {
        setState(() {
            _loadingRegsDb = true;
        });

        // Load all shows from DB
        final allFromDb = await appDatabase.readShows();
        final sortedAll = _sortByStartAsc(List<ShowData>.from(allFromDb));

        // Load registered shows for current company from DB using badges in DB
        final currentUser = ref.read(userProvider);
        final currentCompanyId = ref.read(companyProvider)?.id;
        List<ShowData> registeredFromDb = [];
        if (currentUser != null && currentCompanyId != null) {
            final badgesInDb = await appDatabase.readBadges(
              where: "${BadgeDataInfo.userId.columnName} = ? AND ${BadgeDataInfo.companyId.columnName} = ?",
              whereArgs: [currentUser.id, currentCompanyId],
            );
            final regShowIds = badgesInDb.map((b) => b.showId).toSet();
            if (regShowIds.isNotEmpty) {
                registeredFromDb = await appDatabase.readShows(
                  where: "${ShowDataInfo.id.columnName} IN (${regShowIds.map((id) => "'$id'").join(',')})",
                );
                registeredFromDb = _sortByStartAsc(registeredFromDb);
            }
        }

        if (!mounted) return;
        setState(() {
            _allShows        = _onlyUpcomingSorted(_dedupeById(sortedAll));
            _registeredShowsSource = _sortByStartAsc(_dedupeById(registeredFromDb));
            _registeredShows = _filterRegistered(_registeredShowsSource);
            _loadingRegsDb   = false;
        });
    }

    // --- API Next (fresh) ---
    Future<void> _refreshFromApi() async {
        // Refresh Registrations
        setState(() => _loadingRegsApi = true);
        final regs = await getRegisteredShows();
        if (mounted) {
            setState(() {
                _registeredShows = _onlyUpcomingSorted(_dedupeById(regs));
                _loadingRegsApi  = false;
            });
        }
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
     * MARK: Get the User's Registered Shows
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<List<ShowData>> getRegisteredShows() async {

        // Read the current user from the provider
        final currentUser = ref.read(userProvider);

        if (currentUser == null) {
            logPrint("❌ User is null.");
            return [];
        }

        // Fetch the Badges for this user and write them to the database
        logPrint("🔄 Fetching latest badges for user ${currentUser.id}...");
        final badges = await ApiClient.instance.getBadges(userId: currentUser.id);

        if (badges.isNotEmpty) {
            await appDatabase.write(badges);

            // Update in-memory user state
            ref.read(userProvider.notifier).setBadges(badges);
        } else {
            logPrint("⚠️  No new badges returned; using existing badge data");
        }

        // Determine which show IDs this user is registered for
        final registeredShowIds = badges
            .where((badge) => badge.companyId == ref.read(companyProvider)?.id)
            .map((badge)   => badge.showId)
            .toList();

        // Load those shows from the database
        List<ShowData> shows = [];
        if (registeredShowIds.isNotEmpty) {
            shows = await appDatabase.readShows(
                where: "${ShowDataInfo.id.columnName} IN (${registeredShowIds.map((id) => "'$id'").join(',')})"
            );

            // For any missing shows, fetch from API
            final missingIds = registeredShowIds.where((id) => !shows.map((s) => s.id).contains(id)).toList();
            if (missingIds.isNotEmpty) {
                logPrint("🔄 Fetching missing shows from API (IDs: $missingIds)...");
                final showsFromApi = await ApiClient.instance.getShows(ids: missingIds);
                shows.addAll(showsFromApi);
            }
        }
        return _dedupeById(shows);
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Get the Show Cards
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    List<Widget> getShowCards({ required String sectionTitle, required List<ShowData> shows, required List<BadgeData> badges }) {

        return shows.isEmpty ? [] : [

            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child:   Text(sectionTitle, style: beTextTheme.headingPrimary)
            ),

            ...shows.map((show) {
                BadgeData? badge = badges.firstWhereOrNull((badge) => (badge.showId == show.id) && (badge.companyId == ref.read(companyProvider)?.id));

                return Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child:   ShowCard(
                        show:  show,
                        url:   "show",
                        badge: badge
                    )
                );
            })
        ];
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {
      final user = ref.watch(userProvider);

      return Scaffold(
        appBar: PrimaryNavigationBar(isHome: true, showMenu: true),
        drawer: NavigationMenu(),
        key: MyRegistrationsList.rootKey,
        body: Container(
          color: beColorScheme.background.tertiary,
          child: RefreshIndicator.adaptive(
            onRefresh: () async { _refreshFromApi(); },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              children: [
                const SizedBox(height: 42),

                // Company selector (if user belongs to >= 1 companies)
                if ((user?.companies ?? []).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: DropdownButton<String>(
                      value: user!.companies
                          .firstWhereOrNull((c) => c.id == ref.watch(companyProvider)?.id)
                          ?.id,
                      isExpanded: true,
                      items: user.companies
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (id) {
                        final selected = user.companies.firstWhere((c) => c.id == id);
                        ref.read(companyProvider.notifier).update(selected);
                        _hydrateFromDb();
                        _refreshFromApi();
                      },
                    ),
                  ),

                // --- My Registrations section ---
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 6),
                  child: Text("My Registrations", style: beTextTheme.headingPrimary),
                ),

                Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
                    child:   const Text("Tap a show to view and edit your registration", style: TextStyle(color: BeColorSwatch.darkGray)),
                ),

                const SizedBox(height: 12),

                Builder(
                  builder: (context) {
                    final shows = _registeredShows;
                    final isLoading = _loadingRegsDb || _loadingRegsApi;
                    if (isLoading && shows.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    const CircularProgressIndicator(color: BeColorSwatch.navy, padding: EdgeInsets.only(bottom: 8)),
                                    Text("Loading your registrations...", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: BeColorSwatch.darkGray)),
                                    const SizedBox(height: 16),
                                ]
                            )
                        ),
                      );
                    }
                    if (shows.isEmpty) {
                      final company = ref.watch(companyProvider);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Center(
                          heightFactor: 1.5,
                          child: Text(
                            company != null
                                ? 'You have no upcoming shows for ${company.name}.'
                                : 'You are not registered for any shows.',
                          ),
                        ),
                      );
                    }
                    final badgeList = ref.watch(userProvider)?.badges ?? [];
                    final nowSecs = DateTime.now().millisecondsSinceEpoch / 1000;
                    final upcoming = shows
                        .where((s) => (s.dates.dates.lastOrNull?.end ?? 0) >= nowSecs)
                        .toList();
                    final past = shows
                        .where((s) => (s.dates.dates.lastOrNull?.end ?? 0) < nowSecs)
                        .toList();

                    final List<Widget> sectionChildren = [];

                    if (upcoming.isNotEmpty) {
                      sectionChildren.addAll(upcoming.map((show) {
                        final badge = badgeList.firstWhereOrNull((b) =>
                            (b.showId == show.id) && (b.companyId == ref.read(companyProvider)?.id));
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ShowCard(show: show, url: 'show', badge: badge),
                        );
                      }));
                    }

                    sectionChildren.add(
                        Padding(
                            padding: const EdgeInsets.only(top: 24, right: 6, bottom: 2, left: 6),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                    Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: Text(
                                            "Past registrations",
                                            style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: BeColorSwatch.black),
                                        )
                                    ),
                                    Spacer(),
                                    Text(
                                        "View",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall!
                                            .copyWith(color: BeColorSwatch.darkGray),
                                    ),
                                    Switch.adaptive(
                                        value: _includePastRegistrations,
                                        onChanged: (value) {
                                        setState(() {
                                            _includePastRegistrations = value;
                                            _registeredShows = _filterRegistered(_registeredShowsSource);
                                        });
                                        },
                                    ),
                                ],
                            ),
                        )
                    );

                    if (_includePastRegistrations && past.isNotEmpty) {
                      sectionChildren.addAll(past.map((show) {
                        final badge = badgeList.firstWhereOrNull((b) =>
                            (b.showId == show.id) && (b.companyId == ref.read(companyProvider)?.id));
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ShowCard(show: show, url: 'show', badge: badge),
                        );
                      }));
                    }

                    if (sectionChildren.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sectionChildren,
                    );
                  },
                ),

                const SizedBox(height: 150), // bottom spacer
              ],
            ),
          ),
        ),
      );
    }
}
