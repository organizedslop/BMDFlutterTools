import 'dart:async';
import 'package:bmd_flutter_tools/controllers/global_state.dart';
import 'package:bmd_flutter_tools/theme/app_styles.dart';
import 'package:bmd_flutter_tools/utilities/theme_utilities.dart';
import 'package:bmd_flutter_tools/widgets/components/foating_scanner_button.dart';
import 'package:bmd_flutter_tools/widgets/navigation/bottom_navigation_bar.dart';
import 'package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:bmd_flutter_tools/controllers/api_client.dart';
import 'package:bmd_flutter_tools/controllers/app_database.dart';
import 'package:bmd_flutter_tools/data/model/data__notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NotificationsList extends ConsumerStatefulWidget {
  const NotificationsList({super.key});

  @override
  ConsumerState<NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends ConsumerState<NotificationsList> {
  final _db = AppDatabase.instance;
  final _api = ApiClient.instance;

  List<NotificationData> _items = <NotificationData>[];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadFromDb();
    // Fire and forget; we keep cached items visible while refreshing
    unawaited(_fetchFromApi());
  }

  Future<void> _loadFromDb() async {
    try {
      // Read all notifications from local DB newest → oldest
      final rows = await _db.read(
        tableName: NotificationDataInfo.tableName,
      );

      final list = rows
          .whereType<Map<String, dynamic>>()
          .map((m) => NotificationData.fromJson(m))
          .toList();

      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Keep showing a loader while we fall back to the API fetch.
          // Avoid showing a failure message during initial bootstrap.
          _items = const [];
          _error = null;
          _loading = true;
        });
      }
    }
  }

  Future<void> _fetchFromApi({bool unreadOnly = false}) async {
    if (mounted) setState(() => _refreshing = true);

    try {
      // Grab current user id from global state (same style used in ApiClient)
      final userId = ref.read(userProvider)?.id;

      if (userId == null || userId.isEmpty) {
        throw Exception('No current user id.');
      }

      final fetched =
          await _api.getNotificationsByUserId(userId: userId, unreadOnly: unreadOnly);

      // _api already writes to DB; we still setState so UI updates immediately.
      if (mounted) {
        setState(() {
          // Ensure newest → oldest
          _items = List<NotificationData>.from(fetched)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Only show an error if we truly have nothing to show.
          if (_items.isEmpty) {
            _error = 'Unable to refresh notifications.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
          // Network attempt finished; stop the initial loader.
          _loading = false;
        });
      }
    }
  }


Future<void> _markAsRead(NotificationData n) async {
  // Already read? Skip.
  if (n.readAt != null && n.readAt!.isNotEmpty) return;

  final now = DateTime.now().toUtc();
  final nowIso = now.toIso8601String();

  // Build an updated instance (use copyWith if your model has it)
  final updated = NotificationData(
    id:         n.id,
    type:       n.type,
    title:      n.title,
    body:       n.body,
    actionUrl:  n.actionUrl,
    data:       n.data,
    readAt:     nowIso,
    createdAt:  n.createdAt,
    updatedAt:  nowIso,
  );

  // 1) Optimistic local write (AppDatabase.write uses INSERT OR REPLACE)
  await _db.write(updated);

  if (!mounted) return;

  // Update local list so UI reflects the change immediately
  setState(() {
    final i = _items.indexWhere((x) => x.id == n.id);
    if (i != -1) _items[i] = updated;
  });

  // 2) Persist to API (best-effort); if it fails we leave the optimistic state and log
  try {
    final userId = ref.read(userProvider)?.id;
    if (userId != null && userId.isNotEmpty) {
      final serverUpdated = await _api.setNotificationReadAt(
        userId:         userId,
        notificationId: n.id,
        readAt:         now,
      );

      // If server returns a canonical object, persist & reflect it
      if (serverUpdated != null) {
        await _db.write(serverUpdated);
        if (!mounted) return;
        setState(() {
          final i = _items.indexWhere((x) => x.id == n.id);
          if (i != -1) _items[i] = serverUpdated;
        });
      }
    }
  } catch (e) {
    // Optionally surface a toast/snackbar in debug builds; otherwise silent
    debugPrint('Failed to sync readAt to API for notification ${n.id}: $e');
  }
}



  Future<void> _onPullRefresh() => _fetchFromApi();

  String _formatWhen(String iso) {
    // Safe formatting; if parsing fails, show raw
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat.yMMMd().add_jm().format(dt);
    } catch (_) {
      return iso;
    }
  }

Widget _buildNotificationDialog(NotificationData n) {
  final theme = Theme.of(context);
  // …this is your existing AlertDialog content, now reading n.readAt, etc.
  return AlertDialog(
    title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text(n.title.isNotEmpty ? n.title : 'Notification'),
                    const Spacer(),
                    Text(_formatWhen(n.createdAt), style: beTextTheme.captionPrimary),
                ]
            ),
            if (ref.read(isDebuggingProvider))
                Text(n.id, overflow: TextOverflow.ellipsis, style: beTextTheme.captionPrimary.copyWith(color: BeColorSwatch.magenta.color)),
        ]
    ),
    content: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (n.title.isEmpty) Text(n.title, style: TextStyle(fontWeight: FontWeight.bold)),
          if (n.body.isNotEmpty) Text(n.body),
          if (n.body.isEmpty && n.title.isEmpty) Text(n.type),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PrimaryNavigationBar(
        title: "Notifications",
        showMenu: false,
      ),
      bottomNavigationBar: QuickNavigationBar(),
      floatingActionButton: (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false) ? FloatingScannerButton() : null,
      body: _loading
          ? Center(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    const CircularProgressIndicator(padding: EdgeInsets.only(bottom: 8)),
                    Text("Loading notifications...", style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                ]
            )
        )
          : RefreshIndicator.adaptive(
              onRefresh: () async { _onPullRefresh(); },
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              _error ?? 'No notifications found.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount:        _items.length,
                      separatorBuilder: (_, __) => const Divider(endIndent: 8, height: 1, indent: 8),
                      itemBuilder:      (context, index) {
                        final n = _items[index];

                        final isUnread = n.readAt == null;
                        final title = (n.title.isNotEmpty ? n.title : 'Notification');
                        final body = n.body;

                        return Container(
                            foregroundDecoration: BoxDecoration(
                                color: (isUnread ? BeColorSwatch.blue.color.withAlpha(20) : null)
                            ),
                            padding:   EdgeInsets.only(top: 4, right: 8, bottom: 18, left: 8),
                            child:
                            GestureDetector(
                        onTap: () async {
                            await _markAsRead(n);

                            // Optionally show full details dialog
                            if (_items[index].title.isNotEmpty || _items[index].body.isNotEmpty) {
                                // showDialog(
                                // context: context,
                                //     builder: (_) => _buildNotificationDialog(_items[index]),
                                // );
                            }
                          },
                            child:
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                                isUnread
                                                    ? Container(
                                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(fullRadius)),
                                                        padding:    EdgeInsets.symmetric(horizontal: 5),
                                                        child:      Text("NEW", style: beTextTheme.captionPrimary)
                                                    )
                                                    : Container(
                                                        child:      Text("Read ${_formatWhen(n.readAt!)}", style: beTextTheme.captionPrimary)
                                                    ),
                                                const Spacer(),
                                                Text(
                                                    _formatWhen(n.createdAt),
                                                    style:     beTextTheme.captionPrimary,
                                                    textAlign: TextAlign.end,
                                                ),
                                            ]
                                        ),

                                        if (ref.read(isDebuggingProvider))
                                            Text(n.id, style: beTextTheme.captionPrimary.copyWith(color: BeColorSwatch.magenta.color)),

                                        if (title.isNotEmpty)
                                            Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:    theme.textTheme.bodyLarge!.copyWith(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                                            ),

                                        if (body.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                                body,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style:    TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)
                                            )
                                        ]
                        ])
                        )
                        );
                      },
                    ),
            ),
    );
  }
}