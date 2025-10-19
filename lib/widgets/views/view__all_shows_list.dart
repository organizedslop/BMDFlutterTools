/*
 * All Shows List View
 *
 * Created by:  Blake Davis
 * Description: A widget which displays a list of the user's registrations and other upcoming shows.
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__company.dart";
import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/components/component__updating_indicator.dart";
import "package:bmd_flutter_tools/widgets/navigation/navigation_bar__primary.dart";
import "package:bmd_flutter_tools/widgets/navigation/navigation_menu.dart";
import "package:bmd_flutter_tools/widgets/components/component__show_card.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";




/* ======================================================================================================================
 * MARK: All Shows List
 * ------------------------------------------------------------------------------------------------------------------ */
class AllShowsList extends ConsumerStatefulWidget {

    final bool isNewSignup,
               showAll;

    static const Key rootKey = Key("all_shows_list__root");

    final String title;


    AllShowsList({ super.key,
                    this.isNewSignup = false,
           required this.title,
                    this.showAll     = false
    });


    @override
    ConsumerState<AllShowsList> createState() => _AllShowsListState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _AllShowsListState extends ConsumerState<AllShowsList> {

    AppDatabase appDatabase = AppDatabase.instance;

    bool refresh = false;
    bool _includePastShows = false;

    double offset = 0.0;

    ScrollController _scrollController = ScrollController();

    // DB-first, API-next state (mirrors ExhibitorsList)
    bool _loadingAllDb   = false;
    bool _loadingAllApi  = false;
    List<ShowData> _allShows        = <ShowData>[];
    List<ShowData> _allShowsSource  = <ShowData>[];


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

    List<ShowData> _filterShows(List<ShowData> shows) {
        final deduped = _dedupeById(List<ShowData>.from(shows));
        final nowSecs = DateTime.now().millisecondsSinceEpoch / 1000;
        if (!_includePastShows) {
            return _onlyUpcomingSorted(deduped);
        }

        final upcoming = _onlyUpcomingSorted(List<ShowData>.from(deduped));
        final past = _sortPastDesc(
            deduped.where((s) => (s.dates.dates.lastOrNull?.end ?? 0) < nowSecs).toList(),
        );
        return [...upcoming, ...past];
    }

    void _applyFilters() {
        setState(() {
            _allShows = _filterShows(_allShowsSource);
        });
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

        // Schedule API refresh after the first frame
        WidgetsBinding.instance.addPostFrameCallback((_) async {
            _refreshFromApi();
        });
    }
    // --- DB First (fast) ---
    Future<void> _hydrateFromDb() async {
        setState(() {
            _loadingAllDb  = true;
        });

        // Load ALL upcoming shows from DB
        final allFromDb = await appDatabase.readShows();
        if (!mounted) return;
        setState(() {
            _allShowsSource  = _sortByStartAsc(_dedupeById(allFromDb));
            _allShows        = _filterShows(_allShowsSource);
            _loadingAllDb    = false;
        });
    }

    // --- API Next (fresh) ---
    Future<void> _refreshFromApi() async {
      setState(() => _loadingAllApi = true);
      try {
        // Refresh shows first
        final all = await getAllShows();

        if (mounted) {
          setState(() {
            _allShowsSource = _sortByStartAsc(_dedupeById(all));
            _allShows = _filterShows(_allShowsSource);
          });
        }

        // In parallel or sequentially, refresh badges for the current user (writes to DB)
        await _refreshBadgesFromApi();

      } catch (e) {
        logPrint("❌ AllShowsList: API refresh failed: $e");
      } finally {
        if (mounted) setState(() => _loadingAllApi = false);
      }
    }

    Future<void> _refreshBadgesFromApi() async {
      try {
        final String? userId = ref.read(userProvider)?.id;
        if (userId == null || userId.isEmpty) return;
        // Fetch latest badges for this user; ApiClient writes them to the DB internally
        await ApiClient.instance.getBadges(userId: userId);
      } catch (e) {
        logPrint("❌ AllShowsList: badge refresh failed: $e");
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
     * MARK: Get All Upcoming Shows
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<List<ShowData>> getAllShows() async {
        logPrint("🔄 Getting all shows from the API...");

        return await ApiClient.instance.getShows();
    }








    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

      return Scaffold(
        appBar: PrimaryNavigationBar(isHome: true, showMenu: true),
        drawer: NavigationMenu(),
        key: AllShowsList.rootKey,
        body: Container(
          color: beColorScheme.background.tertiary,
          child: RefreshIndicator.adaptive(
            edgeOffset: 50,
            onRefresh:  () async { _refreshFromApi(); },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              children: [
                const SizedBox(height: 56),

                // --- All upcoming Build Expo shows section ---
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Text(
                    "Upcoming shows",
                    style: beTextTheme.headingPrimary,
                  ),
                ),

                Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 10, right: 10),
                    child:   const Text("Tap a show to see more information and register to attend or exhibit!", style: TextStyle(color: BeColorSwatch.darkGray)),
                ),

                /*
                 * Updating indicator
                 */
                if (_loadingAllApi) ...[
                    const UpdatingIndicator(),
                    const SizedBox(height: 12),
                ],

                Builder(
                  builder: (context) {
                    final shows = _allShows;
                    final isLoading = _loadingAllDb || _loadingAllApi;
                    if (isLoading && shows.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    const CircularProgressIndicator(color: BeColorSwatch.navy, padding: EdgeInsets.only(bottom: 8)),
                                    Text("Loading shows...", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: BeColorSwatch.darkGray)),
                                    SizedBox(height: 16),
                                ]
                            )
                        )
                      );
                    }
                    if (shows.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final nowSecs = DateTime.now().millisecondsSinceEpoch / 1000;
                    final upcoming = shows
                        .where((s) => (s.dates.dates.lastOrNull?.end ?? 0) >= nowSecs)
                        .toList();
                    final past = shows
                        .where((s) => (s.dates.dates.lastOrNull?.end ?? 0) < nowSecs)
                        .toList();

                    final List<Widget> children = [];

                    if (upcoming.isNotEmpty) {
                      children.addAll(upcoming.map((show) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShowCard(show: show, url: 'show', badge: null),
                          )));
                    }

                    children.add(
                        Padding(
                            padding: const EdgeInsets.only(top: 24, right: 10, bottom: 2, left: 10),
                            child:   Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.end,
                                spacing:  4,
                                children: [
                                    Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: Text(
                                            "Past shows",
                                            style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: BeColorSwatch.black),
                                        )
                                    ),
                                    Spacer(),
                                    Text(
                                        "View",
                                        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: BeColorSwatch.darkGray),
                                    ),
                                    Switch.adaptive(
                                        value: _includePastShows,
                                        onChanged: (value) {
                                        setState(() {
                                            _includePastShows = value;
                                            _allShows = _filterShows(_allShowsSource);
                                        });
                                        },
                                    ),
                                ],
                            ),
                        )
                    );

                    if (_includePastShows && past.isNotEmpty) {
                      children.addAll(past.map((show) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShowCard(show: show, url: 'show', badge: null),
                          )));
                    }

                    if (children.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
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
