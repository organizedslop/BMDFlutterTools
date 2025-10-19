/* -----------------------------------------------------------------------------------------------------------------
 * MARK: Seminar Session Card
 * ---------------------------------------------------------------------------------------------------------------- */
import 'dart:convert';

import 'package:bmd_flutter_tools/controllers/api_client.dart';
import 'package:bmd_flutter_tools/controllers/app_database.dart';
import 'package:bmd_flutter_tools/data/model/data__badge.dart';
import 'package:bmd_flutter_tools/data/model/data__seminar.dart';
import 'package:bmd_flutter_tools/data/model/data__seminar_session.dart';
import 'package:bmd_flutter_tools/data/model/enum__location_encoding.dart';
import 'package:bmd_flutter_tools/main.dart';
import 'package:bmd_flutter_tools/utilities/utilities__theme.dart';
import 'package:bmd_flutter_tools/controllers/global_state.dart';
import "package:flutter/material.dart";
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sficon/flutter_sficon.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:bmd_flutter_tools/widgets/components/component__booth_tag.dart';

class SeminarSessionCard extends ConsumerWidget {
  final SeminarSessionData seminarSession;
  final SeminarData        seminar;
  final String? presenterBoothNumber; // NEW
  final VoidCallback? onRegistrationChanged; // NEW
  bool tint = false;

  SeminarSessionCard({
    super.key,
    required this.seminarSession,
    required this.seminar,
    this.presenterBoothNumber, // NEW
    this.onRegistrationChanged, // NEW
    tint,
  }) : this.tint = tint ?? false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(badgeProvider);
    final isRegistered = badge != null && badge.seminarSessionsIds.contains(seminarSession.id);

    final boothNum = presenterBoothNumber?.trim();

    return Container(
      decoration: BoxDecoration(color: tint ? BeColorSwatch.offWhite : BeColorSwatch.white),
      child: InkWell(
          onTap: () {
            context.pushNamed(
              "seminar_info",
              pathParameters: {
                "seminarSession": json.encode(
                  seminarSession.toJson(
                    destination: LocationEncoding.database,
                  ),
                ),
              },
              queryParameters: {
                if (boothNum != null && boothNum.isNotEmpty) "presenterBoothNumber": boothNum!,
              },
            );
          },
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.only(top: 28, right: 6, bottom: 0, left: 6),
                child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Presenter photos as a vertical column of CircleAvatars
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
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
                                radius: 40,
                                backgroundImage: AssetImage('assets/images/placeholder--user-profile-picture.png'),
                                backgroundColor: Colors.transparent,
                              ),
                            );
                          }

                          // Otherwise, render overlapping avatars — one per presenter
                          const double avatarRadius = 40;
                          const double overlap = 14; // how much each avatar overlaps the previous one (smaller = more overlap)

                          // Compute the total height needed to stack N avatars with overlap
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

                      const SizedBox(width: 16),

                      // Text content: title, time, presenter
                      Expanded(
                        child: Column(
                          mainAxisAlignment:  MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Session title (bold, largest)
                            Text(
                              seminar.title,
                              maxLines:  2,
                              overflow:  TextOverflow.ellipsis,
                              softWrap:  true,
                              textAlign: TextAlign.left,
                              style:     Theme.of(context).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
                            ),

                            // Time range (smaller font) with "Registered" label if registered
                            Wrap(
                              children:     [
                                Text(
                                  () {
                                    final start = DateTime.parse(seminarSession.start);
                                    final end   = DateTime.parse(seminarSession.end);

                                    // If the seminar is featured, include the session date before the time range.
                                    if (seminar.isFeatured == true) {
                                      final dateStr  = DateFormat("EEE, MMM d").format(start);
                                      final timeStr  = "${DateFormat("h:mm a").format(start)} - ${DateFormat("h:mm a").format(end)}";
                                      return "$dateStr | $timeStr";
                                    }

                                    // Non-featured sessions keep the original (time-only) format.
                                    return "${DateFormat("h:mm a").format(start)} - ${DateFormat("h:mm a").format(end)}";
                                  }(),
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: BeColorSwatch.darkGray),
                                ),

                                if (seminarSession.roomNumber != null && seminarSession.roomNumber!.trim().isNotEmpty)
                                  Text(
                                    (() {
                                      final rn = seminarSession.roomNumber!.trim();
                                      return " | " + (rn.toLowerCase() == "exhibit hall" ? rn : "Room $rn");
                                    })(),
                                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: BeColorSwatch.darkGray),
                                  ),
                                ]
                            ),

                            const SizedBox(height: 10),

                            // Presenter names & titles (each presenter's title directly under their name)
                            if (seminarSession.presenters.isEmpty)
                              Text(
                                "Presenter TBA",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize! + 2,
                                      fontWeight: FontWeight.bold,
                                    ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final presenter in seminarSession.presenters) ...[
                                    // Name
                                    Text(
                                      presenter.name.full,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize! + 2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    // Title (if any)
                                    if ((presenter.title ?? "").trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Text(
                                          presenter.title!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(height: 0.85),
                                        ),
                                      )
                                    else
                                      const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                            // End presenter names & titles

                            if (seminarSession.presenters.length > 1) const SizedBox(height: 6),

                            if ((seminarSession.presenters
                                    .map((p) => p.companyName?.trim())
                                    .where((name) => name != null && name.isNotEmpty)
                                    .toSet()
                                    .isNotEmpty) ||
                                (presenterBoothNumber != null && presenterBoothNumber!.trim().isNotEmpty))
                            Wrap(
                                spacing: 6,
                                children: [
                                  if (presenterBoothNumber != null && presenterBoothNumber!.trim().isNotEmpty)
                                    BoothTag(boothNumber: presenterBoothNumber!, small: true),
                                  if (seminarSession.presenters
                                      .map((p) => p.companyName?.trim())
                                      .where((name) => name != null && name.isNotEmpty)
                                      .isNotEmpty)
                                    Text(
                                      seminarSession.presenters
                                          .map((p) => p.companyName?.trim())
                                          .where((name) => name != null && name.isNotEmpty)
                                          .cast<String>()
                                          .toSet()
                                          .join(", "),
                                      softWrap: true,
                                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                ],
                            ),

                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ],
                  ),

                if (seminarSession.seminar.description != null)
                    Html(
                        data: (seminarSession.seminar.description!.length > 300)
                            ? (seminarSession.seminar.description!.substring(0, 300) + "...")
                            : seminarSession.seminar.description!
                    ),

              // "More info" and Register/Cancel registration button area
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 12, bottom: 36, left: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Register button (only if not registered)
                    if (!isRegistered)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (badge != null) ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BeColorSwatch.red,
                              disabledBackgroundColor: BeColorSwatch.gray,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: const Size(1, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: badge == null
                                ? null
                                : () async {
                                    // Toggle registration logic (copy from SeminarInfo)
                                    final bool value = true;
                                    // Check for time conflicts (not implemented here for brevity)
                                    // Proceed with registration
                                    final badgeNow = ref.read(badgeProvider);
                                    if (badgeNow == null) return;
                                    final updatedIds = List<String>.from(badgeNow.seminarSessionsIds);
                                    if (!updatedIds.contains(seminarSession.id)) {
                                      updatedIds.add(seminarSession.id);
                                      ApiClient.instance.registerBadgeForSeminarSession(
                                        badgeId: badgeNow.id,
                                        seminarSessionId: seminarSession.id,
                                      );
                                    }
                                    // Create a **new** BadgeData instance so Provider listeners rebuild.
                                    final BadgeData updatedBadge = BadgeData.fromJson(badgeNow.toJson(destination: LocationEncoding.database), source: LocationEncoding.database);
                                    updatedBadge.seminarSessionsIds = updatedIds;
                                    ref.read(badgeProvider.notifier).update(updatedBadge);
                                    await AppDatabase.instance.write(updatedBadge);

                                    // Notify parent list to rebuild immediately (e.g., to update counts or filters)
                                    onRegistrationChanged?.call();

                                    if (context.mounted) {
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
                                  },
                            child: const Text(
                              "Register for this seminar",
                              style: TextStyle(
                                color: BeColorSwatch.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (badge == null) ...[
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                "Register for the show to enable registering for seminars!",
                                softWrap: true,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(color: BeColorSwatch.red),
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (!isRegistered) const SizedBox(width: 12),
                    // Registered indicator (icon and text) just before "More info"
                    if (isRegistered)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          SFIcon(
            SFIcons.sf_checkmark_circle_fill,
            color: BeColorSwatch.green,
            fontSize: 16,
          ),
          const SizedBox(width: 4),
          Text(
            "You are registered",
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: BeColorSwatch.green,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
      const SizedBox(height: 4), // spacing between text and button
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: BeColorSwatch.red, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: badge == null
              ? null
              : () async {
                  // unregister logic...
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Text(
              "Cancel registration",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: BeColorSwatch.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    ],
  ),
                    // Expanded to push "More info" to the end
                    Expanded(child: Container()),
                    // "More info" button (always)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BeColorSwatch.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(1, 36), // avoid infinite width in Row
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        context.pushNamed(
                          "seminar_info",
                          pathParameters: {
                            "seminarSession": json.encode(
                              seminarSession.toJson(
                                destination: LocationEncoding.database,
                              ),
                            ),
                          },
                          queryParameters: {
                            if (boothNum != null && boothNum.isNotEmpty) "presenterBoothNumber": boothNum!,
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          "More info",
                          style: const TextStyle(
                            color: BeColorSwatch.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
              ),

              // Featured star badge in the top-right corner
              if (seminar.isFeatured == true)
                Positioned(
                  top: 6,
                  left: 5,
                  child: SFIcon(
                        SFIcons.sf_star_fill,
                        color: BeColorSwatch.orange,
                        fontSize: 22,
                    ),
                ),
                // Top-right category ribbon (matches SeminarInfo styling)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                        maxWidth: 260, // or whatever upper bound you want
                    ),
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
                        color: BeColorSwatch.darkBlue,
                    ),
                    height: 22,
                    padding: const EdgeInsets.only(top: 2, right: 10, bottom: 0, left: 12),
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
                )
            ],
          ),
        ),
    );
  }
}
