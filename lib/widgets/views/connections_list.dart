/*
 * Leads List
 *
 * Created by:  Blake Davis
 * Description: A widget which displays a company's collected leads for a show.
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "dart:convert";
import "dart:collection";
import "dart:math" as math;
import "dart:ui";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/services/connection_retry_service.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import 'package:bmd_flutter_tools/utilities/print_utilities.dart';
import "package:bmd_flutter_tools/widgets/components/foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/components/animated_expand.dart";
import "package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/views/badge_scanner.dart";
import "package:bmd_flutter_tools/widgets/navigation/bottom_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/components/connection_card.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:intl/intl.dart";




/*
 * Holds both user and badge data for a connection
 */
class ExtraConnectionData {

    final BadgeData? badgeData;

    final UserData?  userData;


    ExtraConnectionData({
        this.userData,
        this.badgeData
    });
}




/* ======================================================================================================================
 * MARK: Leads List
 * ------------------------------------------------------------------------------------------------------------------ */
class LeadsList extends ConsumerStatefulWidget {

    final BadgeScanner barcodeScanner = BadgeScanner();

    static const Key rootKey = Key("connections_list__root");

    final String title;


    LeadsList({ super.key,
        required this.title });


    @override
    ConsumerState<LeadsList> createState() => _LeadsListState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _LeadsListState extends ConsumerState<LeadsList> with RouteAware {

    AppDatabase appDatabase = AppDatabase.instance;

    bool isFetchingFromDatabase = false,
         _loadingApi            = false;

    List<String> hiddenDates = [];

    Map<ConnectionData, ExtraConnectionData> _connections = {};

    Map<String, String> localPaths = {};

    String sortByValue = "user_name";

    // Caches for badge/user data
    final Map<String, BadgeData?> _badgeCache = {};
    final Map<String, UserData?> _userCache  = {};

    // In-flight guards / coalescing
    Future<void>? _refreshInFlight;
    final Map<String, Future<BadgeData?>> _badgeReq = {};
    final Map<String, Future<UserData?>>  _userReq  = {};
    Timer? _popDebounce;

    int _unsyncedCount = 0;
    ConnectionSyncSummary? _lastSyncSummary;
    bool _syncInProgress = false;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        showSystemUiOverlays();

        _loadConnections();

        // Kick off API refresh in parallel so we can show a spinner if DB has nothing yet
        _refreshConnections();
    }

    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        // Subscribe to the observer for this route.
        routeObserver.subscribe(this, ModalRoute.of(context)!);
    }

    // Called when a route above this one is popped and this becomes visible again.
    @override
    void didPopNext() {
        _popDebounce?.cancel();
        _popDebounce = Timer(const Duration(milliseconds: 150), () {
          _loadConnections();
          _refreshConnections();
        });
    }




    /* -----------------------------------------------------------------------------------------------------------------
     *  Refresh: DB-first, then API merge
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<void> _refreshConnections() async {
        // Prevent overlapping refreshes — coalesce to a single in-flight future
        if (_refreshInFlight != null) {
            return _refreshInFlight!;
        }

        final completer = Completer<void>();
        _refreshInFlight = completer.future;

        final companyId = ref.read(companyProvider)!.id;
        final showId    = ref.read(badgeProvider)!.showId;
        if (!mounted) {
            completer.complete();
            return;
        }

        ConnectionSyncSummary summary = ConnectionSyncSummary.empty;
        setState(() {
            _loadingApi = true;
            _syncInProgress = true;
        });

        try {
            summary = await ConnectionRetryService.instance.retryPendingConnections();
            if (summary.hasChanges && mounted) {
            final dbListAfterSync = await appDatabase.readConnections(
                where:     "${ConnectionDataInfo.companyId.columnName} = ? AND ${ConnectionDataInfo.showId.columnName} = ?",
                whereArgs: [companyId, showId],
            );
            if (mounted) {
                setState(() {
                _connections = {
                    for (final c in dbListAfterSync) c: ExtraConnectionData(userData: null, badgeData: null)
                };
                _unsyncedCount = _countUnsynced(_connections.keys);
                });
            }
            }
        } catch (error) {
            logPrint("❌  while syncing pending leads before refresh: $error");
        }

        try {
            // Kick off API request immediately
            final apiFuture = ApiClient.instance.getConnections(companyId: companyId, showId: showId);

            // If we currently have nothing on screen, try to prime from DB quickly
            if (_connections.isEmpty) {
            final dbList = await appDatabase.readConnections(
                where:     "${ConnectionDataInfo.companyId.columnName} = ? AND ${ConnectionDataInfo.showId.columnName} = ?",
                whereArgs: [companyId, showId],
            );
            if (!mounted) { completer.complete(); return; }
            if (dbList.isNotEmpty) {
                setState(() {
                _connections = { for (final c in dbList) c: ExtraConnectionData(userData: null, badgeData: null) };
                _unsyncedCount = _countUnsynced(_connections.keys);
                });
            }
            }

            // Wait for API list (connections only)
            final apiList = await apiFuture;
            if (!mounted) { completer.complete(); return; }

            // Merge API over whatever is currently visible (API wins)
            final Map<ConnectionData, ExtraConnectionData> mergedMap = {};

            // Add API entries first
            for (final c in apiList) {
            final existing = _connections.entries.firstWhereOrNull((e) => e.key.id == c.id)?.value;
            mergedMap[c] = existing ?? ExtraConnectionData(userData: null, badgeData: null);
            }
            // Then add any local-only entries that weren't in the API
            for (final entry in _connections.entries) {
            if (!mergedMap.keys.any((k) => k.id == entry.key.id)) {
                mergedMap[entry.key] = entry.value;
            }
            }

            setState(() {
            _connections = mergedMap;
            _unsyncedCount = _countUnsynced(mergedMap.keys);
            });

            // Build list of items needing enrichment only
            final allConns = mergedMap.entries
                .where((e) => e.value.badgeData == null || (e.key.badgeUserId != null && e.value.userData == null))
                .map((e) => e.key)
                .toList();

            if (allConns.isEmpty) return;

            final firstPage = allConns.take(20).toList();
            final rest      = allConns.skip(20).toList();

            await _enrichConnections(firstPage, concurrency: 4);

            if (mounted && rest.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
                await _enrichConnections(rest, concurrency: 4);
            });
            }
        } catch (_) {
            // swallow; UI already reflects best-known state
        } finally {
            if (mounted) {
            setState(() {
                _loadingApi = false;
                _syncInProgress = false;
                _lastSyncSummary = summary;
            });
            }
            completer.complete();
            _refreshInFlight = null;
        }
    }

    Future<void> _enrichConnections(List<ConnectionData> items, {int concurrency = 4}) async {
        if (items.isEmpty) return;
        final q = Queue<ConnectionData>()..addAll(items);
        int running = 0;
        final pendingPatches = <ConnectionData, ExtraConnectionData>{};
        DateTime lastFlush = DateTime.now();

        Future<void> launchNext() async {
            if (!mounted) return;
            if (q.isEmpty) return;

            final conn = q.removeFirst();
            running++;

            try {
            // Badge
            final badgeId = conn.badgeId;
            BadgeData? badge;
            if (badgeId != null) {
              badge = _badgeCache[badgeId];
              badge ??= await _getBadgeData(badgeId);
              _badgeCache[badgeId] = badge;
            }

            // User
            UserData? user;
            final userId = conn.badgeUserId;
            if (userId != null) {
                user = _userCache[userId] ?? await _getUserData(userId);
                _userCache[userId] = user;
            }

            pendingPatches[conn] = ExtraConnectionData(userData: user, badgeData: badge);

            final now = DateTime.now();
            final shouldFlush = now.difference(lastFlush).inMilliseconds >= 100 || q.isEmpty;

            if (shouldFlush && mounted) {
                setState(() {
                // Only patch keys still present
                for (final entry in pendingPatches.entries) {
                    final existingKey = _connections.keys.firstWhereOrNull((k) => k.id == entry.key.id);
                    if (existingKey != null) {
                    _connections[existingKey] = entry.value;
                    }
                }
                });
                pendingPatches.clear();
                lastFlush = now;
            }
            } finally {
            running--;
            if (q.isNotEmpty) {
                // keep the pool full
                await launchNext();
            }
            }
        }

        // Prime the pool
        final starters = math.min(concurrency, q.length);
        for (int i = 0; i < starters; i++) {
            await launchNext();
        }

        // Drain
        while (running > 0 || q.isNotEmpty) {
            await Future.delayed(const Duration(milliseconds: 30));
        }

        // Final flush
        if (pendingPatches.isNotEmpty && mounted) {
            setState(() {
            for (final entry in pendingPatches.entries) {
                final existingKey = _connections.keys.firstWhereOrNull((k) => k.id == entry.key.id);
                if (existingKey != null) {
                _connections[existingKey] = entry.value;
                }
            }
            });
            pendingPatches.clear();
        }
    }

    @override
    void didPush() {
        /* first time this route is shown */
    }

    @override
    void didPushNext() {
        /* another route was pushed on top */
    }



    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {
        _popDebounce?.cancel();
        routeObserver.unsubscribe(this);
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Load Connections
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<void> _loadConnections() async {
        final companyId = ref.read(companyProvider)!.id;
        final showId    = ref.read(badgeProvider)!.showId;

        setState(() {
            isFetchingFromDatabase = true;
        });

        // Only query the local DB
        final dbList = await appDatabase.readConnections(
            where: "${ConnectionDataInfo.companyId.columnName} = ? AND ${ConnectionDataInfo.showId.columnName} = ?",
            whereArgs: [companyId, showId],
        );

        // Build the map, with nulls for user/badge
        final Map<ConnectionData, ExtraConnectionData> localMap = {
            for (var conn in dbList) conn: ExtraConnectionData(userData: null, badgeData: null)
        };

        if (!mounted) return;
        setState(() {
          // Only replace what's on screen if the DB actually returned rows,
          // or if we currently have nothing to show.
          if (dbList.isNotEmpty || _connections.isEmpty) {
            _connections = localMap;
          }
          _unsyncedCount = _countUnsynced(_connections.keys);
          isFetchingFromDatabase = false;
        });
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * Get BadgeData by ID
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<BadgeData?> _getBadgeData(String? badgeId) async {
        if (badgeId == null) return null;
        final cached = _badgeCache[badgeId];
        if (cached != null) return cached;

        final pending = _badgeReq[badgeId];
        if (pending != null) return pending;

        final fut = () async {
          // Try the local SQLite database first
          final stored = await appDatabase.read(
              tableName:  BadgeDataInfo.tableName,
              whereAsMap: { BadgeDataInfo.id.columnName: badgeId },
          );
          if (stored != null && stored.isNotEmpty) {
              final val = stored.first as BadgeData;
              _badgeCache[badgeId] = val;
              return val;
          }
          // If not in database, fetch from the REST API
          final api = (await ApiClient.instance.getBadges(id: badgeId)).firstOrNull;
          if (api != null) _badgeCache[badgeId] = api;
          return api;
        }();

        _badgeReq[badgeId] = fut;
        final res = await fut;
        _badgeReq.remove(badgeId);
        return res;
    }

    int _countUnsynced(Iterable<ConnectionData> connections) {
      return connections.where((c) => (c.dateSynced == null || c.dateSynced!.isEmpty)).length;
    }

    Widget _buildSyncStatusBar() {
      final theme = Theme.of(context);
      final bool allSynced = _unsyncedCount == 0;
      final String statusText = _syncInProgress
          ? "Syncing leads…"
          : allSynced
              ? "All leads are synced"
              : "Unsynced leads: $_unsyncedCount";

      String? detailText;
      final summary = _lastSyncSummary;
      if (!_syncInProgress && summary != null && summary.attempts > 0) {
        final parts = <String>[];
        if (summary.successCount > 0) parts.add("${summary.successCount} synced");
        if (summary.incompleteCount > 0) parts.add("${summary.incompleteCount} incomplete");
        if (summary.failureCount > 0) parts.add("${summary.failureCount} failed");
        if (parts.isNotEmpty) {
          detailText = parts.join(", ");
        }
      }

      final Color iconColor = _syncInProgress
          ? BeColorSwatch.navy
          : allSynced
              ? BeColorSwatch.green
              : BeColorSwatch.navy;

      return ClipRect(
        child:
        //  BackdropFilter(
        //   filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        //   child:
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
              ],
              stops: [0.0, 0.12, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              color: Colors.white.withOpacity(0.15),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Material(
                    borderRadius: BorderRadius.circular(fullRadius),
                    color: Colors.white,
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_syncInProgress)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          else
                            SFIcon(
                              allSynced ? SFIcons.sf_checkmark_circle : SFIcons.sf_icloud_slash,
                              color: iconColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  statusText,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (detailText != null)
                                  Text(
                                    detailText,
                                    style: theme.textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // ),
      );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * Get UserData by ID
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<UserData?> _getUserData(String userId) async {
        final cached = _userCache[userId];
        if (cached != null) return cached;

        final pending = _userReq[userId];
        if (pending != null) return pending;

        final fut = () async {
          final stored = await appDatabase.read(
              tableName:  UserDataInfo.tableName,
              whereAsMap: { UserDataInfo.id.columnName: userId },
          );
          if (stored != null && stored.isNotEmpty) {
              final val = stored.first as UserData;
              _userCache[userId] = val;
              return val;
          }
          final api = await ApiClient.instance.getUser(id: userId);
          if (api != null) _userCache[userId] = api;
          return api;
        }();

        _userReq[userId] = fut;
        final res = await fut;
        _userReq.remove(userId);
        return res;
    }



    /* -----------------------------------------------------------------------------------------------------------------
     *  Fetch all Connections and their Badge and User data
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<Map<ConnectionData, ExtraConnectionData>> getConnectionsForCompany(String companyId) async {
        final showId = ref.read(badgeProvider)?.showId;
        if (showId == null) return {};

        // Run DB and API fetch in parallel
        final results = await Future.wait<List<ConnectionData>>([
            appDatabase.readConnections(
                where: "${ConnectionDataInfo.companyId.columnName} = ? AND ${ConnectionDataInfo.showId.columnName} = ?",
                whereArgs: [companyId, showId],
            ),
            ApiClient.instance.getConnections(companyId: companyId, showId: showId),
        ]);
        final dbList  = results[0];
        final apiList = results[1];

        // Merge with API taking precedence over local DB
        final seen = <String>{};
        final merged = <ConnectionData>[];
        // Add API entries first (latest from server)
        for (final conn in apiList) {
            if (seen.add(conn.id)) merged.add(conn);
        }
        // Then add any local-only entries
        for (final conn in dbList) {
            if (seen.add(conn.id)) merged.add(conn);
        }

        // Build the map with cached badge and user lookups
        final Map<ConnectionData, ExtraConnectionData> output = {};

        // Cache maps to avoid duplicate fetches
        final Map<String, BadgeData?> badgeCache = {};
        final Map<String, UserData?> userCache  = {};

        for (final conn in merged) {
            // Badge lookup
            final badgeId = conn.badgeId;
            BadgeData? badge;
            if (badgeId != null) {
                if (!badgeCache.containsKey(badgeId)) {
                    badgeCache[badgeId] = await _getBadgeData(badgeId);
                }
                badge = badgeCache[badgeId];
            }

            // User lookup (only if badgeUserId present)
            UserData? user;
            final userId = conn.badgeUserId;
            if (userId != null) {
                if (!userCache.containsKey(userId)) {
                    userCache[userId] = await _getUserData(userId);
                }
                user = userCache[userId];
            }

            // Only add if we found badge (or skip based on your logic)
            output[conn] = ExtraConnectionData(
                userData:  user,
                badgeData: badge,
            );
        }
        return output;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);


        return Scaffold(
            appBar:               PrimaryNavigationBar(title: widget.title, subtitle: ref.read(showProvider)?.title),
            bottomNavigationBar:  QuickNavigationBar(),
            floatingActionButton: (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false) ? FloatingScannerButton() : null,
            key:                  LeadsList.rootKey,

            body: !(ref.read(badgeProvider)?.hasLeadScannerLicense ?? false)
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: Container(color: beColorScheme.background.tertiary),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 16,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _buildSyncStatusBar(),
                          ),
                        ),
                      ),
                    ],
                  )
                : (() {
      // Group by date (keyed by DateTime, normalized to year/month/day)
      final Map<DateTime, Map<ConnectionData, ExtraConnectionData>> connectionsByDate = {};
      for (final entry in _connections.entries) {
        final connection = entry.key;
        final data = entry.value;
        DateTime rawDate = DateTime.tryParse(connection.dateCreated ?? "") ?? DateTime(0);
        // Drop time component
        final dateCreated = DateTime(rawDate.year, rawDate.month, rawDate.day);
        connectionsByDate.putIfAbsent(dateCreated, () => {});
        connectionsByDate[dateCreated]![connection] = data;
      }

      // Decide when to show full-screen loader vs. content
      final bool showFullscreenLoader = _connections.isEmpty && isFetchingFromDatabase;

      if (showFullscreenLoader) {
        return Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      "Loading leads...",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildSyncStatusBar(),
            ),
          ],
        );
      }

      // Empty state only when we truly have nothing and are not loading anything
      if (_connections.isEmpty && !isFetchingFromDatabase && !_loadingApi) {
        return Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Text(
                  "You have no leads.\nGo scan some badges!",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildSyncStatusBar(),
            ),
          ],
        );
      }



      final sortedDates = connectionsByDate.keys.toList()..sort((a, b) => b.compareTo(a));
      final List<Widget> listChildren = [];

      for (final date in sortedDates) {
        final dateAsString = DateFormat("EEEE, MMMM d").format(date);
        listChildren.add(
          InkWell(
            onTap: () {
              setState(() {
                if (hiddenDates.contains(dateAsString)) {
                  hiddenDates.remove(dateAsString);
                } else {
                  hiddenDates.add(dateAsString);
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: BeColorSwatch.lightGray)),
                color: BeColorSwatch.navy,
              ),
              padding: const EdgeInsets.only(top: 10, right: 16, bottom: 10, left: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateAsString,
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: BeColorSwatch.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "(${connectionsByDate[date]?.length ?? 0})",
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(color: BeColorSwatch.blue),
                  ),
                  const Spacer(),
                  if (textScaleFactor < 1.35)
                    Text(
                      "Toggle",
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(color: BeColorSwatch.blue),
                    ),
                ],
              ),
            ),
          ),
        );

        final connectionsForDate = connectionsByDate[date]!;
        final sortedConnections = connectionsForDate.keys.toList()
          ..sort((a, b) {
            DateTime parseDate(String? value) => DateTime.tryParse(value ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = parseDate(b.dateCreated);
            final aDate = parseDate(a.dateCreated);
            final d = bDate.compareTo(aDate);
            if (d != 0) return d;
            return (a.badgeUserName ?? '').compareTo(b.badgeUserName ?? '');
          });

        listChildren.add(
          AnimatedExpand(
            expanded: !hiddenDates.contains(dateAsString),
            childKey: 'date-' + dateAsString,
            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < sortedConnections.length; i++) ...[
                        InkWell(
                          onTap: () async {
                            final connection = sortedConnections[i];
                            final extras = connectionsForDate[connection];
                            await appRouter.pushNamed(
                              "connection info",
                              pathParameters: {
                                "connection": json.encode(connection.toJson(destination: LocationEncoding.database)),
                              },
                              extra: {
                                "badge": extras?.badgeData,
                                "user": extras?.userData,
                              },
                            );
                          },
                          child: ConnectionCard(
                            connection: sortedConnections[i],
                            showDivider: !(i == sortedConnections.length - 1),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        );

      }

      if (_loadingApi) {
        listChildren.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text("Updating…"),
              ],
            ),
          ),
        );
      }

      listChildren.add(const SizedBox(height: 128));

      final refreshableList = RefreshIndicator.adaptive(
        onRefresh: () async {
          await _refreshConnections();
        },
        child: ListView(children: listChildren),
      );
      return Stack(
        children: [
          Positioned.fill(child: refreshableList),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSyncStatusBar(),
          ),
        ],
      );
    })()
        );
    }
}
