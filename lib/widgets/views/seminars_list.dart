/*
 * Seminars List
 *
 * Created by:  Blake Davis
 * Description: Seminars list view
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__seminar.dart";
import "package:bmd_flutter_tools/data/model/data__seminar_session.dart";
import "package:bmd_flutter_tools/data/model/data__exhibitor.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/components/foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/components/animated_expand.dart";
import "package:bmd_flutter_tools/widgets/components/updating_indicator.dart";
import "package:bmd_flutter_tools/widgets/navigation/bottom_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/panels/seminar_session_card.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";
import "package:flutter/cupertino.dart";




/* =====================================================================================================================
 * MARK: Seminars List
 * ------------------------------------------------------------------------------------------------------------------ */
 class SeminarsList extends ConsumerStatefulWidget {

    static const Key rootKey = Key("seminars_list__root");

    final String? showId,
                  title;


    SeminarsList({ super.key,
                    this.showId,
                         title   }

    )   :   this.title = title ?? "Keynotes & Seminars";


    @override
    ConsumerState<SeminarsList> createState() => _SeminarsListState();
}




/* =====================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _SeminarsListState extends ConsumerState<SeminarsList> {

    // Simple in-memory cache so when navigating away and back we can paint immediately
    // without waiting for the async DB read. Keyed by showId.
    static final Map<String, List<SeminarSessionData>> _cacheByShow = {};

    AppDatabase appDatabase = AppDatabase.instance;

    bool _loadingDb  = false; // DB loading flag is only informational; we avoid gating UI on it to prevent flashes
    bool _loadingApi = false;

    bool isFetchingFromApi      = false,
         isFetchingFromDatabase = false,
         refresh                = false,
         showFeatured           = true,
         showFullSchedule       = true;

    // The authoritative list we render from
    List<SeminarSessionData> _allSessions = [];

    List<SeminarSessionData> _allSeminarSessions = [],
                             _mySeminarSessions  = [];

    List<String>  hiddenCategoryIds = [],
                  _lastIds          = [];
    List<DateTime> hiddenDates      = [];

    // Cache resolved presenter booth numbers per company+show to avoid repeated DB hits
    final Map<String, String?> _presenterBoothCache = {};


Future<String?> _resolvePresenterBoothNumber({
  required String showId,
  String? companyId,
}) async {
  logPrint("🔄 Resolving booth for company ID ${companyId}...");
  try {
    if (companyId == null || companyId.trim().isEmpty) {
      return null; // no company to resolve
    }

    final cacheKey = "$companyId|$showId";
    // if (_presenterBoothCache.containsKey(cacheKey)) {
    //   final cached = _presenterBoothCache[cacheKey];
    //   return (cached == null || cached.isEmpty) ? null : cached;
    // }

    // ---- 1) First DB read
    final rows = await appDatabase.read(
      tableName: ExhibitorDataInfo.tableName,
      whereAsMap: {
        ExhibitorDataInfo.companyId.columnName: companyId,
        ExhibitorDataInfo.showId.columnName: showId,
      },
    );
    logPrint("ℹ️  seminars_list: booth: initial exhibitor rows=${rows.length}");

    List<ExhibitorData> exhibitors = <ExhibitorData>[];
    if (rows is List) {
      if (rows.isNotEmpty && rows.first is ExhibitorData) {
        exhibitors = rows.cast<ExhibitorData>();
      } else {
        for (final r in rows) {
          if (r is Map) {
            try {
              exhibitors.add(
                ExhibitorData.fromJson(
                  Map<String, dynamic>.from(r as Map),
                  source: LocationEncoding.database,
                ),
              );
            } catch (_) {}
          }
        }
      }
    }

    // Helper to attempt booth resolution from a list
    String? _firstBooth(List<ExhibitorData> list) {
      for (final ex in list) {
        logPrint("ℹ️  seminars_list: booth: exhibitor ${ex.id} booths=${ex.booths.length}");
        for (final b in ex.booths) {
          final n = (b.number).trim();
          if (n.isNotEmpty) return n;
        }
      }
      return null;
    }

    // ---- 2) If none from DB, try API company fetch (to hydrate exhibitor links), then re-read
    if (exhibitors.isEmpty) {
      logPrint("🔄 seminars_list: booth: no exhibitor rows for companyId=$companyId showId=$showId – trying API company fetch");
      try {
        await ApiClient.instance.getCompanyById(companyId);
      } catch (e) {
        logPrint("❌ seminars_list: booth: API company fetch failed: $e");
      }

      final rows2 = await appDatabase.read(
        tableName: ExhibitorDataInfo.tableName,
        whereAsMap: {
          ExhibitorDataInfo.companyId.columnName: companyId,
          ExhibitorDataInfo.showId.columnName: showId,
        },
      );
      logPrint("ℹ️  seminars_list: booth: post-company-fetch exhibitor rows=${rows2.length}");

      exhibitors = <ExhibitorData>[];
      if (rows2 is List) {
        if (rows2.isNotEmpty && rows2.first is ExhibitorData) {
          exhibitors = rows2.cast<ExhibitorData>();
        } else {
          for (final r in rows2) {
            if (r is Map) {
              try {
                exhibitors.add(
                  ExhibitorData.fromJson(
                    Map<String, dynamic>.from(r as Map),
                    source: LocationEncoding.database,
                  ),
                );
              } catch (_) {}
            }
          }
        }
      }
    }

    // ---- 3) If we have exhibitors but **no booth numbers**, call exhibitors API for this show to hydrate booths, then re-read once.
    final existingBooth = _firstBooth(exhibitors);
    if (existingBooth == null) {
      logPrint("🔄 seminars_list: booth: exhibitors exist but have 0 booth numbers – fetching exhibitors for show $showId");
      try {
        // Pull fresh exhibitors for this show; ApiClient should upsert into DB
        final _ = await ApiClient.instance.getExhibitors(showId: showId);
        logPrint("✅ seminars_list: booth: fetched exhibitors for show; re-reading from DB");
      } catch (e) {
        logPrint("❌ seminars_list: booth: getExhibitors(showId) failed: $e");
      }

      final rows3 = await appDatabase.read(
        tableName: ExhibitorDataInfo.tableName,
        whereAsMap: {
          ExhibitorDataInfo.companyId.columnName: companyId,
          ExhibitorDataInfo.showId.columnName: showId,
        },
      );
      logPrint("ℹ️  seminars_list: booth: post-exhibitors-fetch exhibitor rows=${rows3.length}");

      exhibitors = <ExhibitorData>[];
      if (rows3 is List) {
        if (rows3.isNotEmpty && rows3.first is ExhibitorData) {
          exhibitors = rows3.cast<ExhibitorData>();
        } else {
          for (final r in rows3) {
            if (r is Map) {
              try {
                exhibitors.add(
                  ExhibitorData.fromJson(
                    Map<String, dynamic>.from(r as Map),
                    source: LocationEncoding.database,
                  ),
                );
              } catch (_) {}
            }
          }
        }
      }
    }

    // ---- 4) Resolve booth number
    final boothNum = _firstBooth(exhibitors);
    if (boothNum != null) {
      _presenterBoothCache[cacheKey] = boothNum;
      logPrint("✅ seminars_list: booth: resolved booth=$boothNum for companyId=$companyId showId=$showId");
      return boothNum;
    }

    // Cache miss
    _presenterBoothCache[cacheKey] = '';
    return null;

  } catch (e) {
    logPrint("❌ seminars_list: booth: error while resolving booth: $e");
    return null;
  }
}

Future<String?> _resolveAnyPresenterBoothNumber(SeminarSessionData session) async {
  if (session.presenters.isEmpty) return null;
  for (final sp in session.presenters) {
    final cid = sp.companyId?.trim();
    if (cid == null || cid.isEmpty) continue;
    final n = await _resolvePresenterBoothNumber(showId: session.showId, companyId: cid);
    if (n != null && n.trim().isNotEmpty) return n.trim();
  }
  return null;
}




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        showSystemUiOverlays();

        // Paint from in-memory cache immediately if we have it for this show
        final String? showId = ref.read(showProvider)?.id;
        final cached = (showId != null) ? _cacheByShow[showId] : null;
        if (cached != null && cached.isNotEmpty) {
            // Set synchronously so build can use it on first frame
            _allSessions = List<SeminarSessionData>.from(cached);
        }

        // Then load DB (fast) and refresh from API (slower)
        _loadFromDb().then((_) => _refreshFromApi());
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Get Seminar Session Card
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Widget _getSeminarSessionCard(
        BuildContext context,
        SeminarSessionData seminarSession,
        SeminarData seminar,
        int index,
    ) {
      return FutureBuilder<String?>(
        future: _resolveAnyPresenterBoothNumber(seminarSession),
        builder: (context, snap) {
          return SeminarSessionCard(
            seminarSession: seminarSession,
            seminar:        seminar,
            tint:           !index.isEven,
            presenterBoothNumber: (snap.connectionState == ConnectionState.done && (snap.data ?? '').trim().isNotEmpty)
                ? snap.data!.trim()
                : null,
          );
        },
      );
    }





    Future<void> _refreshFromApi() async {
        final showId = ref.read(showProvider)?.id;
        if (showId == null) return;

        if (mounted) setState(() => _loadingApi = true);

        try {
            final fresh = await ApiClient.instance.getSeminars(showId: showId);

            if (!mounted) return;
            setState(() {
                _allSessions = fresh; // replace, don't merge
                _loadingApi  = false;
            });
            // Update in-memory cache for instant paint on return
            if (showId != null) {
                _cacheByShow[showId] = List<SeminarSessionData>.from(fresh);
            }

            // persist to DB for offline
            await appDatabase.write(fresh);
        } catch (_) {
            if (mounted) setState(() => _loadingApi = false);
        }
    }




    Future<void> _loadFromDb() async {
        final showId = ref.read(showProvider)?.id;
        if (showId == null) {
            // Don't wipe the current list if we momentarily don't have a showId.
            return;
        }

        if (mounted) setState(() { _loadingDb = true; });
        try {
            final rows = await appDatabase.read(
                tableName: SeminarSessionDataInfo.tableName,
                whereAsMap: { SeminarSessionDataInfo.showId.columnName: showId },
            );

            // Be resilient to whatever the DB helper returns (typed list or dynamic).
            final List<SeminarSessionData> local = () {
                if (rows is List<SeminarSessionData>) {
                    return rows;
                }
                if (rows is List) {
                    return rows.whereType<SeminarSessionData>().toList();
                }
                return const <SeminarSessionData>[];
            }();

            if (local.isNotEmpty) {
                if (mounted) setState(() { _allSessions = local; });
                // Update cache so a future mount paints immediately
                _cacheByShow[showId] = List<SeminarSessionData>.from(local);
            } else {
                // Preserve whatever is currently on screen instead of blanking the list.
                // (No setState here on purpose.)
            }
        } catch (e) {
            // Log and preserve existing list on any read/parse error.
            // beLog("SeminarsList", "DB read failed: $e");
        } finally {
            if (mounted) setState(() { _loadingDb = false; });
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);

        /*
         * "Interested in presenting?" button
         */
        final ElevatedButton interestedInPresentingBanner = ElevatedButton(
            key:        const Key("seminars_list__present_button"),
            onPressed:  () {
                context.pushNamed(
                    "web view",
                    pathParameters: {
                        "title": "Presenting",
                        "url":   "https://buildexpo.app/mobile/presenting-simple",
                    }
                );
            },
            style: ButtonStyle(
                backgroundBuilder: (context, states, child) => DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [
                                BeColorSwatch.darkBlue,
                                BeColorSwatch.blue,
                            ],
                        ),
                    ),
                    child: child,
                ),
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all(RoundedRectangleBorder()),
            ),
            child: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child:   Row(
                    spacing:  14,
                    children: [
                        SFIcon(
                            SFIcons.sf_music_microphone,
                            color:    BeColorSwatch.white,
                            fontSize: 24
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing:  3,
                            children: [
                                Text("Interested in presenting?", style: TextTheme.of(context).headlineSmall!.copyWith(color: BeColorSwatch.white, height: 0.925)),
                                Text("Tap to learn more",         style: Theme.of(context).textTheme.labelSmall!.copyWith(color: BeColorSwatch.white, height: 1))
                            ]
                        )
                    ]
                )
            )
        );

        // Watch the Badge Provider
        final BadgeData? badge = ref.watch(badgeProvider);

        // If the Badge's SeminarSession IDs changed, update local state; the visible list
        // is derived from `_allSessions` + `badge` in build. We optionally refresh the DB
        // without blocking UI (spinner only shows if list is empty).
        if (badge != null && !const ListEquality().equals(_lastIds, badge.seminarSessionsIds)) {
            setState(() {
                _lastIds = List.from(badge.seminarSessionsIds);
            });
            // Refresh local cache silently; UI won't show a big spinner unless empty.
            _loadFromDb();
        }


        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * MARK: Scaffold
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
        return Scaffold(
            appBar:               PrimaryNavigationBar(title: widget.title, subtitle: ref.watch(showProvider)?.title),
            bottomNavigationBar:  QuickNavigationBar(),
            floatingActionButton: (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false) ? FloatingScannerButton() : null,
            key:                  SeminarsList.rootKey,
            body: (() {
                    // Show the large loading indicator ONLY if we have nothing local to show yet.
                    if (_allSessions.isEmpty && (_loadingDb || _loadingApi)) {
                        return Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    const CircularProgressIndicator(color: BeColorSwatch.navy, padding: EdgeInsets.only(bottom: 8)),
                                    Text("Loading seminar sessions...", style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: BeColorSwatch.darkGray)),
                                    const SizedBox(height: 16),
                                ],
                            ),
                        );
                    }

                    // At this point we DO have rows locally. Render immediately from DB,
                    // while API refresh continues in the background.
                    final List<SeminarSessionData> allSeminars = List<SeminarSessionData>.from(_allSessions);
                    // Keep cache fresh while we’re mounted
                    final currentShowId = ref.read(showProvider)?.id;
                    if (currentShowId != null) {
                        _cacheByShow[currentShowId] = List<SeminarSessionData>.from(allSeminars);
                    }

                    final badge = ref.watch(badgeProvider);
                    final Set<String> myIds = badge?.seminarSessionsIds.toSet() ?? const <String>{};
                    final List<SeminarSessionData> mySeminars = allSeminars.where((s) => myIds.contains(s.id)).toList();

                    // Helper to truncate to local date
                    DateTime _dateOnly(String iso) {
                        final dt = DateTime.parse(iso);
                        return DateTime(dt.year, dt.month, dt.day);
                    }

                    // Build maps by date
                    final Map<DateTime, List<SeminarSessionData>> allByDate = {};
                    for (final ss in allSeminars) {
                        final d = _dateOnly(ss.start);
                        (allByDate[d] ??= []).add(ss);
                    }

                    final Map<DateTime, List<SeminarSessionData>> mineByDate = {};
                    for (final ss in mySeminars) {
                        final d = _dateOnly(ss.start);
                        (mineByDate[d] ??= []).add(ss);
                    }

                    final sessionsByDate = showFullSchedule ? allByDate : mineByDate;

                    return Stack(
                        children: [
                            RefreshIndicator.adaptive(
                                onRefresh: () async { _refreshFromApi(); },
                                child: ListView(
                                    children: () {
                                        final output = <Widget>[

                                            // Full schedule / my schedule toggle
        Padding(
                                                padding: const EdgeInsets.only(top: 18, right: 24, bottom: 10, left: 24),
                                                child: LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    return SingleChildScrollView(
                                                      scrollDirection: Axis.horizontal,
                                                      child: ConstrainedBox(
                                                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                                        child: Align(
                                                          alignment: Alignment.center,
                                                          child: SizedBox(
                                                            height: 44,
                                                            child: CupertinoSlidingSegmentedControl<String>(
                                                              key: const Key("seminars_list__schedule_toggle_button"),
                                                              padding: EdgeInsets.zero,
                                                              groupValue: showFullSchedule ? "all" : "mine",
                                                              children: <String, Widget>{
                                                                "all": FittedBox(
                                                                  fit: BoxFit.scaleDown,
                                                                  child: Padding(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                                                    child: Text.rich(
                                                                      TextSpan(
                                                                        style: TextStyle(color: showFullSchedule ? BeColorSwatch.blue : BeColorSwatch.darkGray,),
                                                                        children: [
                                                                          const TextSpan(text: "All seminars "),
                                                                          if (textScaleFactor < 1.5)
                                                                            TextSpan(
                                                                                text: "(${allSeminars.length})",
                                                                                style: TextStyle(color: showFullSchedule ? BeColorSwatch.blue : BeColorSwatch.darkGray),
                                                                            ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                "mine": FittedBox(
                                                                  fit: BoxFit.scaleDown,
                                                                  child: Padding(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                                                    child: Text.rich(
                                                                      TextSpan(
                                                                        style: TextStyle(color: showFullSchedule ? BeColorSwatch.darkGray : BeColorSwatch.blue,
                                                                            ),
                                                                        children: [
                                                                          const TextSpan(text: "My seminars "),
                                                                          if (textScaleFactor < 1.5)
                                                                            TextSpan(
                                                                                text: "(${mySeminars.length})",
                                                                                style: TextStyle(color: showFullSchedule ? BeColorSwatch.darkGray : BeColorSwatch.blue),
                                                                            ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              },
                                                              onValueChanged: (String? value) {
                                                                if (value == null) return;
                                                                setState(() => showFullSchedule = value == "all");
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ),
                                        ];

                                        /*
                                         * Updating indicator
                                         */
                                        if (_loadingApi && _allSessions.isNotEmpty) {
                                            output.addAll([
                                                const UpdatingIndicator(),
                                                const SizedBox(height: 10)
                                            ]);

                                        } else {
                                            output.add(const SizedBox(height: 24));
                                        }

                                        // Featured Keynotes section (above date groups)
                                        final Map<DateTime, List<SeminarSessionData>> featuredSource = showFullSchedule ? allByDate : mineByDate;

                                        final List<SeminarSessionData> featuredSessions = [
                                            for (final list in featuredSource.values) ...list
                                        ].where((ss) => (ss.seminar.isFeatured ?? false)).toList();

                                        final seen = <String>{};
                                        final uniqueFeatured = <SeminarSessionData>[];
                                        for (final ss in featuredSessions) {
                                            if (seen.add(ss.id)) uniqueFeatured.add(ss);
                                        }

                                        // If DB has no rows (and API is done/failed), show the empty state.
                                        if (_allSessions.isEmpty) {
                                            output.add(
                                                Container(
                                                    alignment: AlignmentDirectional.center,
                                                    padding: const EdgeInsets.symmetric(horizontal: 36),
                                                    child: const Text(
                                                        "No seminar sessions have been added for this show. Check back soon!",
                                                        textAlign: TextAlign.center,
                                                    ),
                                                )
                                            );
                                        }

                                        if (showFullSchedule && uniqueFeatured.isNotEmpty) {
                                            output.add(
                                                InkWell(
                                                    onTap: () => setState(() => showFeatured = !showFeatured),
                                                    child: Container(
                                                        decoration: const BoxDecoration(
                                                            border: Border(top: BorderSide(), bottom: BorderSide()),
                                                        ),
                                                        padding: const EdgeInsets.only(top: 10, right: 16, bottom: 10, left: 4),
                                                        child: Row(
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                                Text(
                                                                    'Featured Keynotes',
                                                                    style: Theme.of(context).textTheme.headlineMedium!,
                                                                ),
                                                                Text(
                                                                    '  (${uniqueFeatured.length})',
                                                                    style: Theme.of(context).textTheme.bodySmall!,
                                                                ),
                                                                const Spacer(),
                                                                if (textScaleFactor < 1.35)
                                                                    Text(
                                                                        showFeatured ? 'Hide' : 'Show',
                                                                        style: Theme.of(context).textTheme.labelSmall!,
                                                                    ),
                                                            ],
                                                        ),
                                                    ),
                                                ),
                                            );

                                            output.add(
                                                AnimatedExpand(
                                                    expanded: showFeatured,
                                                    childKey: "featured",
                                                    child: () {
                                                      uniqueFeatured.sort((a, b) {
                                                          final t = DateTime.parse(a.start).compareTo(DateTime.parse(b.start));
                                                          return t != 0 ? t : a.seminar.title.compareTo(b.seminar.title);
                                                      });
                                                      return Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          for (int i = 0; i < uniqueFeatured.length; i++) ...[
                                                            _getSeminarSessionCard(context, uniqueFeatured[i], uniqueFeatured[i].seminar, i),
                                                            if (i != uniqueFeatured.length - 1)
                                                              const Divider(height: 0, indent: 6),
                                                          ],
                                                        ],
                                                      );
                                                    }(),
                                                ),
                                            );
                                        }

                                        // Date groups
                                        final dates = sessionsByDate.keys.toList()..sort();
                                        for (final date in dates) {
                                            final isHidden = hiddenDates.contains(date);

                                            output.add(
                                                InkWell(
                                                    onTap: () {
                                                        setState(() {
                                                            if (hiddenDates.contains(date)) {
                                                                hiddenDates.remove(date);
                                                            } else {
                                                                hiddenDates.add(date);
                                                            }
                                                        });
                                                    },
                                                    child: Container(
                                                        decoration: const BoxDecoration(
                                                            border: Border(bottom: BorderSide()),
                                                        ),
                                                        padding: const EdgeInsets.only(top: 10, right: 16, bottom: 10, left: 4),
                                                        child: Row(
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                                Text(
                                                                    DateFormat('EEEE,  MMMM d').format(date),
                                                                    style: Theme.of(context).textTheme.headlineMedium!,
                                                                ),
                                                                Text(
                                                                    "  (${sessionsByDate[date]?.length ?? 0})",
                                                                    style: Theme.of(context).textTheme.bodySmall!,
                                                                ),
                                                                const Spacer(),
                                                                if (textScaleFactor < 1.35)
                                                                    Text(
                                                                        isHidden ? "Show" : "Hide",
                                                                        style: Theme.of(context).textTheme.labelSmall!,
                                                                    ),
                                                            ],
                                                        ),
                                                    ),
                                                ),
                                            );

                                            output.add(
                                                AnimatedExpand(
                                                    expanded: !isHidden,
                                                    childKey: "date-${date.toIso8601String()}",
                                                    child: Builder(
                                                      builder: (context) {
                                                        final sessions = [...?sessionsByDate[date]];
                                                        sessions.sort((a, b) => a.seminar.title.compareTo(b.seminar.title));
                                                        sessions.sort((a, b) => DateTime.parse(a.start).compareTo(DateTime.parse(b.start)));

                                                        return Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            for (int i = 0; i < sessions.length; i++) ...[
                                                              _getSeminarSessionCard(context, sessions[i], sessions[i].seminar, i),
                                                              if (i != sessions.length - 1)
                                                                const Divider(height: 0, indent: 6, endIndent: 6),
                                                            ],
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                ),
                                            );
                                        }

                                        output.add(const SizedBox(height: 128));
                                        return output;
                                    }(),
                                ),
                            ),

                            // Bottom gradient + banner
                            Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    clipBehavior: Clip.none,
                                    children: [
                                        Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                                height: 96,
                                                decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                        begin: Alignment.center,
                                                        end: Alignment.topCenter,
                                                        colors: [
                                                            BeColorSwatch.white,
                                                            BeColorSwatch.white.withAlpha(0),
                                                        ],
                                                    ),
                                                ),
                                            ),
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.only(bottom: 0),
                                            child: interestedInPresentingBanner,
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    );
                }
            )()
        );
    }
}
