/*
 * Seminar Info
 *
 * Created by:  Blake Davis
 * Description: Seminar info view
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__seminar.dart";
import "package:bmd_flutter_tools/data/model/data__seminar_session.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/components/foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/navigation/bottom_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/components/booth_tag.dart";
import "package:float_column/float_column.dart";
import "package:flutter/material.dart";
import "package:flutter_html/flutter_html.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:html/parser.dart";
import "package:intl/intl.dart";




/* ======================================================================================================================
 * MARK: Seminar Info
 * ------------------------------------------------------------------------------------------------------------------ */
class SeminarInfo extends ConsumerStatefulWidget {

    static const Key rootKey = Key("seminar_info__root");

    final SeminarSessionData seminarSession;
    final String? presenterBoothNumber;

    SeminarInfo({ super.key,
        required this.seminarSession,
        this.presenterBoothNumber,
    });

    @override
    ConsumerState<SeminarInfo> createState() => _SeminarInfoState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _SeminarInfoState extends ConsumerState<SeminarInfo> {

    AppDatabase appDatabase = AppDatabase.instance;

    bool isRegistered = false,
         refresh      = false;

    late final SeminarData seminar;
    late final SeminarSessionData seminarSession;
    late final String? presenterBoothNumber;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        seminarSession = widget.seminarSession;
        seminar        = widget.seminarSession.seminar;
        presenterBoothNumber = widget.presenterBoothNumber;

        // Determine initial registration state from the current badge
        final badge = ref.read(badgeProvider);
        if (badge != null) {
          isRegistered = badge.seminarSessionsIds.contains(seminarSession.id);
        }

        showSystemUiOverlays();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {
        super.dispose();
    }


    /// Returns a list of registered sessions that overlap with [newStart]-[newEnd]
    /// on the same calendar day (excluding the current [seminarSession]).
    Future<List<SeminarSessionData>> _findTimeConflicts(DateTime newStart, DateTime newEnd) async {
      try {
        final badge = ref.read(badgeProvider);
        if (badge == null) return const [];

        // Exclude the current session ID (user may be toggling it)
        final otherIds = badge.seminarSessionsIds
            .where((id) => id != seminarSession.id)
            .toList();

        if (otherIds.isEmpty) return const [];

        // Read those sessions from the database
        final List<dynamic>? raw = await appDatabase.readSeminarSessionsByIds(otherIds);
        if (raw == null || raw.isEmpty) return const [];

        final List<SeminarSessionData> conflicts = [];

        for (final s in raw.cast<SeminarSessionData>()) {
          final os = DateTime.parse(s.start);
          final oe = DateTime.parse(s.end);

          final sameDay = os.year == newStart.year &&
              os.month == newStart.month &&
              os.day == newStart.day;

          if (!sameDay) continue;

          final overlaps = newStart.isBefore(oe) && os.isBefore(newEnd);
          if (overlaps) {
            conflicts.add(s);
          }
        }
        return conflicts;
      } catch (_) {
        // On any error, fail safe to "no conflict"
        return const [];
      }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * MARK: Scaffold
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
        return Scaffold(
            appBar:               PrimaryNavigationBar(title: "Seminar Info", subtitle: ref.read(showProvider)?.title),
            bottomNavigationBar:  QuickNavigationBar(),
            floatingActionButton: (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false) ? FloatingScannerButton() : null,
            key:                  SeminarInfo.rootKey,

            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Widget Body
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            body: RefreshIndicator.adaptive(
                onRefresh: () async { setState(() { refresh = !refresh; }); },
                child: SingleChildScrollView(
                    child: Padding(
                        padding:  EdgeInsets.only(top: 0, right: 8, bottom: 44, left: 8),
                        child:    Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:           <Widget>[

                                // Seminar title
                                Padding(
                                    padding: EdgeInsets.only(top: 16, right: 10, bottom: 6, left: 10),
                                    child: Text(parseFragment(seminar.title).text ?? "Untitled", style: beTextTheme.headingSecondary),
                                ),

                                // Seminar times and register button
                                Padding(
                                    padding: EdgeInsets.only(top: 12, bottom: 12),
                                    child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            color:   BeColorSwatch.white,
                                        ),
                                        padding: EdgeInsets.all(12),
                                    child: () {
                                        var output = [];
                                        DateTime start = DateTime.parse(seminarSession.start);
                                        DateTime end   = DateTime.parse(seminarSession.end);

                                        output.add(
                                            Row(crossAxisAlignment: CrossAxisAlignment.center,
                                                mainAxisAlignment:  MainAxisAlignment.center,
                                                children: [
                                                    Flexible(child:
                                                        Wrap(children: [
                                                            Text(
                                                                "${DateFormat("EEE, MMM d, y  |  h:mm a").format(start)} - ${DateFormat("h:mm a").format(end)}",
                                                                softWrap: true,                                                                )
                                                        ]),
                                                    ),
                                                ]
                                            )
                                        );

                                        return Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                                ...output,

                                                // Show room number if present, prepending "Room " unless "Exhibit Hall"
                                                if (seminarSession.roomNumber != null && seminarSession.roomNumber!.trim().isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 6),
                                                    child: Text(
                                                      (() {
                                                        final rn = seminarSession.roomNumber!.trim();
                                                        return rn.toLowerCase() == "exhibit hall"
                                                            ? rn
                                                            : "Room $rn";
                                                      })(),
                                                      style: Theme.of(context).textTheme.bodyMedium,
                                                    ),
                                                  ),

                                                const SizedBox(height: 12),

                                                if (!isRegistered)
                                                  ElevatedButton(
                                                    key:   const Key("seminar_info__registration_button"),
                                                    style: elevatedButtonStyleAlt.copyWith(
                                                      backgroundColor: WidgetStateProperty.all((ref.read(badgeProvider) != null) ? BeColorSwatch.red : BeColorSwatch.gray),
                                                    ),
                                                    onPressed: () async {
                                                        if (ref.read(badgeProvider) != null) {
                                                            // Tapping toggles registration to true
                                                            final bool value = true;

                                                            // If attempting to register, check for conflicts first.
                                                            final start     = DateTime.parse(seminarSession.start);
                                                            final end       = DateTime.parse(seminarSession.end);
                                                            final conflicts = await _findTimeConflicts(start, end);

                                                            if (conflicts.isNotEmpty) {
                                                                final proceed = await showDialog<bool>(
                                                                context: context,
                                                                builder: (ctx) {
                                                                    final conflictWidgets = conflicts.map((s) {
                                                                    final title = (s.seminar.title.isNotEmpty)
                                                                        ? s.seminar.title
                                                                        : "Untitled session";
                                                                    final st = DateTime.parse(s.start);
                                                                    final et = DateTime.parse(s.end);
                                                                    final timeStr = "${DateFormat("EEE, MMM d").format(st)}  "
                                                                        "${DateFormat("h:mm a").format(st)} - ${DateFormat("h:mm a").format(et)}";
                                                                    return Padding(
                                                                        padding: const EdgeInsets.only(bottom: 6.0),
                                                                        child: Text("• $title\n  $timeStr"),
                                                                    );
                                                                    }).toList();

                                                                    return AlertDialog(
                                                                    title: const Text("Schedule Conflict"),
                                                                    content: SingleChildScrollView(
                                                                        child: ListBody(
                                                                        children: [
                                                                            const Text(
                                                                            "You are already registered for the following overlapping session(s):",
                                                                            ),
                                                                            const SizedBox(height: 8),
                                                                            ...conflictWidgets,
                                                                            const SizedBox(height: 8),
                                                                            const Text(
                                                                            "Do you want to continue and register for this session as well?",
                                                                            ),
                                                                        ],
                                                                        ),
                                                                    ),
                                                                    actions: [
                                                                        TextButton(
                                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                                        child: const Text("Cancel"),
                                                                        ),
                                                                        FilledButton(
                                                                        onPressed: () => Navigator.of(ctx).pop(true),
                                                                        child: const Text("Continue"),
                                                                        ),
                                                                    ],
                                                                    );
                                                                },
                                                                );

                                                                if (proceed != true) {
                                                                return; // user canceled
                                                                }
                                                            }

                                                            if (mounted) setState(() => isRegistered = value);

                                                            final badge = ref.read(badgeProvider);
                                                            if (badge == null) return;

                                                            final updatedIds = List<String>.from(badge.seminarSessionsIds);
                                                            if (!updatedIds.contains(seminarSession.id)) {
                                                                updatedIds.add(seminarSession.id);
                                                                ApiClient.instance.registerBadgeForSeminarSession(
                                                                badgeId: badge.id,
                                                                seminarSessionId: seminarSession.id,
                                                                );
                                                            }

                                                            // Build and persist updated badge
                                                            BadgeData updatedBadge = badge;
                                                            updatedBadge.seminarSessionsIds = updatedIds;
                                                            ref.read(badgeProvider.notifier).update(updatedBadge);
                                                            await appDatabase.write(updatedBadge);

                                                            if (mounted) {
                                                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(
                                                                    backgroundColor: BeColorSwatch.green,
                                                                    content: Text(
                                                                    "You are registered for this seminar!",
                                                                    style: TextStyle(color: BeColorSwatch.white),
                                                                    ),
                                                                ),
                                                                );
                                                            }
                                                        }
                                                    },
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                                      child: Text(
                                                        "Register for this seminar",
                                                        style: TextStyle(color: BeColorSwatch.white),
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  // Registered indicator + Cancel button (same formatting as SeminarSessionCard)
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const SFIcon(
                                                            SFIcons.sf_checkmark_circle_fill,
                                                            color: BeColorSwatch.green,
                                                            fontSize: 20,
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            "You are registered",
                                                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                                  color: BeColorSwatch.green,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: BeColorSwatch.red, width: 1.5),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: InkWell(
                                                          borderRadius: BorderRadius.circular(8),
                                                          onTap: () async {
                                                            // Toggle to false (unregister)
                                                            if (mounted) setState(() => isRegistered = false);

                                                            final badge = ref.read(badgeProvider);
                                                            if (badge == null) return;
                                                            final updatedIds = List<String>.from(badge.seminarSessionsIds)..remove(seminarSession.id);

                                                            ApiClient.instance.unregisterBadgeForSeminarSession(
                                                              badgeId: badge.id,
                                                              seminarSessionId: seminarSession.id,
                                                            );

                                                            BadgeData updatedBadge = badge;
                                                            updatedBadge.seminarSessionsIds = updatedIds;
                                                            ref.read(badgeProvider.notifier).update(updatedBadge);
                                                            await appDatabase.write(updatedBadge);
                                                          },
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                                            child: Text(
                                                              "Cancel registration",
                                                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                                                    color: BeColorSwatch.red,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                if (ref.read(badgeProvider) == null)
                                                    Padding(
                                                        padding: EdgeInsets.only(top: 4, right: 8, bottom: 0, left: 8),
                                                        child:   Text("Register for the show to enable registering for seminars!", style: Theme.of(context).textTheme.bodySmall!.copyWith(color: BeColorSwatch.red))
                                                    )
                                            ]
                                        );
                                    }(),
                                    ),
                                ),

                                // Speaker and seminar info
                                Stack(
                                  alignment: AlignmentDirectional.topEnd,
                                  children: [
                                    // Main card content container
                                    Container(
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: BeColorSwatch.white),
                                      margin: EdgeInsets.only(bottom: 12),
                                      padding: EdgeInsets.only(top: 16, right: 12, bottom: 48, left: 12),
                                      child: Column(
                                        spacing: 6,
                                        children: [
                                          // Speaker info
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            spacing: 16,
                                            children: [
                                              // Overlapping vertical column of presenter avatars (mirrors SeminarSessionCard)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8, left: 6),
                                                child: () {
                                                  final presenters = seminarSession.presenters;

                                                  // When there are no presenters, show a single placeholder avatar
                                                  if (presenters.isEmpty) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: Colors.white, width: 2),
                                                      ),
                                                      child: const CircleAvatar(
                                                        radius: 44,
                                                        backgroundImage: AssetImage('assets/images/placeholder--user-profile-picture.png'),
                                                        backgroundColor: Colors.transparent,
                                                      ),
                                                    );
                                                  }

                                                  const double avatarRadius = 44; // slightly larger on detail page
                                                  const double overlap = 16; // how much each avatar overlaps the previous one

                                                  final int n = presenters.length;
                                                  final double stackHeight = (n <= 1)
                                                      ? avatarRadius * 2
                                                      : avatarRadius * 2 + (n - 1) * ((avatarRadius * 2) - overlap);

                                                  return SizedBox(
                                                    width: avatarRadius * 2,
                                                    height: stackHeight,
                                                    child: Stack(
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        // Render from last to first so the first presenter appears "on top"
                                                        for (int i = presenters.length - 1; i >= 0; i--)
                                                          Positioned(
                                                            top: i * ((avatarRadius * 2) - overlap),
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                border: Border.all(color: Colors.white, width: 2),
                                                              ),
                                                              child: CircleAvatar(
                                                                radius: avatarRadius,
                                                                backgroundImage: const AssetImage('assets/images/placeholder--user-profile-picture.png'),
                                                                foregroundImage: (presenters[i].photoUrl != null && presenters[i].photoUrl!.trim().isNotEmpty)
                                                                    ? NetworkImage(presenters[i].photoUrl!)
                                                                    : null,
                                                                backgroundColor: Colors.transparent,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }(),
                                              ),
                                              // Text content: presenter names + titles
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    // Presenters
                                                    if (seminarSession.presenters.isEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 12),
                                                        child: Text(
                                                          'Presenter TBA',
                                                          overflow: TextOverflow.ellipsis,
                                                          style: beTextTheme.headingSecondary.merge(const TextStyle(height: 2)),
                                                        ),
                                                      )
                                                    else
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            SizedBox(height: 8),

                                                          for (final presenter in seminarSession.presenters) ...[
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 12),
                                                              child: Text(
                                                                presenter.name.full,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: beTextTheme.headingSecondary,
                                                              ),
                                                            ),
                                                            if ((presenter.title ?? '').trim().isNotEmpty)
                                                              Padding(
                                                                padding: const EdgeInsets.only(bottom: 4),
                                                                child: Text(presenter.title!),
                                                              )
                                                            else
                                                              const SizedBox(height: 4),
                                                          ],
                                                        ],
                                                      ),

                                                    // Company names and booth tag (moved under presenter names/titles)
                                                    const SizedBox(height: 8),

                                                    Builder(
                                                      builder: (context) {
                                                        final companies = seminarSession.presenters
                                                            .map((p) => (p.companyName ?? '').trim())
                                                            .where((name) => name.isNotEmpty)
                                                            .toSet()
                                                            .toList();

                                                        final hasBooth = presenterBoothNumber != null && presenterBoothNumber!.trim().isNotEmpty;

                                                        if (companies.isEmpty && !hasBooth) return const SizedBox.shrink();

                                                        return Wrap(
                                                          spacing: 6,
                                                          runSpacing: 4,
                                                          crossAxisAlignment: WrapCrossAlignment.center,
                                                          children: [
                                                            if (hasBooth)
                                                              BoothTag(boothNumber: presenterBoothNumber!, small: true),
                                                            if (companies.isNotEmpty)
                                                              Text(
                                                                companies.join(', '),
                                                                softWrap: true,
                                                                style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
                                                              ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          FloatColumn(
                                            children: () {
                                              // When the seminar has no description
                                              if (seminar.description == null ||
                                                  seminar.description!
                                                      .trim()
                                                      .isEmpty) {
                                                return [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .all(12),
                                                    child: Text(
                                                      "No description",
                                                      style: beTextTheme
                                                          .bodyPrimary
                                                          .merge(
                                                        const TextStyle(
                                                            fontStyle:
                                                                FontStyle
                                                                    .italic),
                                                      ),
                                                    ),
                                                  ),
                                                ];
                                              }

                                              // Render the entire HTML description
                                              return [
                                                Html(
                                                  data: seminar
                                                      .description!,
                                                  style: {
                                                    // Optional global styling overrides
                                                  },
                                                ),
                                              ];
                                            }(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Top-left featured star + optional BoothTag
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (seminar.isFeatured == true)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 7, top: 6, right: 4),
                                              child: SFIcon(
                                                SFIcons.sf_star_fill,
                                                color: BeColorSwatch.orange,
                                                fontSize: 22,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Top-right category ribbon (unchanged)
                                    Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                        maxWidth: 260, // or whatever upper bound you want
                    ),
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), topRight: Radius.circular(12)),
                        color: BeColorSwatch.darkBlue,
                    ),
                    height: 22,
                    padding: const EdgeInsets.only(top: 2, right: 12, bottom: 0, left: 12),
                    child: Text(
                        ((seminar.categories.isNotEmpty
                                ? seminar.categories.map((c) => c.name)
                                : ["Uncategorized"]))
                            .join(" / ")
                            .toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                        color: BeColorSwatch.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        ),
                    ),
                    )
                ),
                                  ]
                                ),


                                // Target audience
                                (seminar.targetAudience == null) ? const SizedBox.shrink() :
                                    Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            Text(
                                                "for ${seminar.targetAudience!}",
                                                softWrap:  true,
                                                style:     TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center
                                            ),
                                        ]
                                    )

                                //Text(seminar.id.toString(), style: beTextTheme.captionPrimary.merge(TextStyle(color: beColorScheme.text.debug))) : SizedBox.shrink(),
                            ]
                        )
                    )
                )
            )
        );
    }
}
