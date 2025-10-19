/*
 * Show Card
 *
 * Created by:  Blake Davis
 * Description: Widget for displaying show info and thumbnails
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__company.dart";
import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:bmd_flutter_tools/widgets/utilities/no_scale_wrapper.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

/* ======================================================================================================================
 * MARK: Show Card
 * ------------------------------------------------------------------------------------------------------------------ */
class ShowCard extends ConsumerStatefulWidget {

    final BadgeData? badge;
    final ShowData   show;
    final String     url;

    const ShowCard({
        super.key,
        required this.show,
        required this.badge,
        required this.url,
    });

    @override
    ConsumerState<ShowCard> createState() => _ShowCardState();
}

/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _ShowCardState extends ConsumerState<ShowCard> {

    final AppDatabase appDatabase = AppDatabase.instance;

    @override
    Widget build(BuildContext context) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);

        final AppDatabase appDatabase = AppDatabase.instance;
        final CompanyData? currentCompany = ref.watch(companyProvider);
        final ShowData show = widget.show;

        Future<BadgeData?> _badgeFromDb() async {
            try {
                // Prefer a badge scoped to this show AND current company
                if (currentCompany?.id != null && currentCompany!.id.isNotEmpty) {
                    final list = await appDatabase.readBadges(
                        where: "${BadgeDataInfo.showId.columnName} = ? AND ${BadgeDataInfo.companyId.columnName} = ?",
                        whereArgs: [show.id, currentCompany.id],
                    );
                    if (list.isNotEmpty) return list.first;
                }
                // Fallback: any badge for this show (DB is per-user in this app)
                final list = await appDatabase.readBadges(
                    where: "${BadgeDataInfo.showId.columnName} = ?",
                    whereArgs: [show.id],
                );
                if (list.isNotEmpty) return list.first;
            } catch (_) {}
            // Last resort: whatever parent passed in (may be null)
            return widget.badge;
        }

        return FutureBuilder<BadgeData?>(
            future:  _badgeFromDb(),
            builder: (context, snapshot) {

                final BadgeData? effectiveBadge = snapshot.data ?? widget.badge;

                // Banner image (safe fallback to asset)
                final String headerImageUrl = (show.banner != null && (Uri.parse(show.banner!)).isAbsolute)
                    ? show.banner!
                    : "";

                final List<Shadow> titleShadows = [
                    Shadow(color: BeColorSwatch.navy.color, offset: const Offset(0, 1), blurRadius: 50),
                    Shadow(color: BeColorSwatch.navy.color.withAlpha(100), offset: const Offset(0, 1), blurRadius: 20),
                ];

                final String formattedDates =
                        show.dates.dates.map((d) => d.toString(includeTimes: false)).join(", ");

                final List<Widget> subtitleRow = [
                    Text(
                        formattedDates,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium!.merge(
                            TextStyle(
                                color:      BeColorSwatch.white.color,
                                fontWeight: FontWeight.w900,
                                height:     0,
                                overflow:   TextOverflow.ellipsis,
                                shadows:    titleShadows,
                            ),
                        ),
                    ),
                ];

                final List<Widget> thirdRow = [];

                if (effectiveBadge?.type != null && effectiveBadge!.type!.isNotEmpty) {
                    final labels = <String>[
                        if (effectiveBadge.isExhibitor) "exhibitor",
                        if (effectiveBadge.isPresenter) "presenter",
                        if (effectiveBadge.isSponsor)   "sponsor",
                    ];
                    if (labels.isEmpty) labels.add(effectiveBadge.type!);

                    thirdRow.add(
                        Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: BeColorSwatch.white.color),
                                borderRadius: BorderRadius.circular(4),
                            ),
                            margin: const EdgeInsets.only(right: 8, top: 1.5),
                            padding: const EdgeInsets.only(top: 0, right: 4, bottom: 2, left: 4),
                            child: Text(
                                labels.join(", "),
                                style: Theme.of(context).textTheme.labelSmall!.merge(
                                    TextStyle(
                                        color:      BeColorSwatch.white.color,
                                        fontWeight: FontWeight.w400,
                                        height:     0,
                                        overflow:   TextOverflow.ellipsis,
                                        shadows:    titleShadows,
                                    )
                                )
                            )
                        )
                    );
                }

                if (effectiveBadge != null && (currentCompany?.name.isNotEmpty ?? false)) {
                    thirdRow.add(
                        Text(
                            currentCompany!.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                            style: Theme.of(context).textTheme.bodySmall!.merge(
                                TextStyle(
                                    color:      BeColorSwatch.white.color,
                                    fontWeight: FontWeight.w400,
                                    height:     0,
                                    shadows:    titleShadows,
                                )
                            )
                        )
                    );
                }

                thirdRow.addAll([
                    Spacer(),
                    if (textScaleFactor <= 1.5)
                        Text(
                            "More info",
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                color:         BeColorSwatch.lighterGray.color,
                                fontWeight:    FontWeight.bold,
                                letterSpacing: 0.2,
                                overflow:      TextOverflow.ellipsis,
                                shadows:       titleShadows,
                            )
                        )
                ]);

                return GestureDetector(
                    onTap: () async {
                        // Update current show
                        ref.read(showProvider.notifier).update(show);
                        // Use the latest DB-backed badge for navigation context
                        final latest = await _badgeFromDb();
                        ref.read(badgeProvider.notifier).update(latest);
                        appRouter.pushNamed(widget.url);
                    },
                    child: Container(
                        decoration: hardEdgeDecoration,
                        child: Container(
                            foregroundDecoration: beveledDecoration,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(mediumRadius),
                                child: Stack(
                                    alignment: AlignmentDirectional.centerStart,
                                    children: [
                                        Positioned.fill(
                                            child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                            Colors.white.withOpacity(0.15),
                                                            Colors.transparent,
                                                            Colors.black.withOpacity(0.2),
                                                        ],
                                                        stops: const [0.0, 0.55, 1.0],
                                                    ),
                                                ),
                                            ),
                                        ),
                                        Positioned.fill(
                                            child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                    Container(
                                                        color: BeColorSwatch.navy.color,
                                                        child: Transform.scale(
                                                            scale: 1.25,
                                                            alignment: Alignment.bottomLeft,
                                                            child: Image.asset(
                                                                "assets/images/show-banner-placeholder.png",
                                                                fit: BoxFit.cover,
                                                            ),
                                                        ),
                                                    ),
                                                    // Optional network image
                                                    if (headerImageUrl.isNotEmpty)
                                                        Image.network(
                                                            headerImageUrl,
                                                            fit: BoxFit.cover,
                                                            color: BeColorSwatch.darkBlue.color.withAlpha(50),
                                                            colorBlendMode: BlendMode.multiply,
                                                            loadingBuilder: (ctx, child, progress) =>
                                                                    progress == null ? child : const SizedBox.shrink(),
                                                            errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                                                        ),
                                                    // Gradient overlay
                                                    Container(
                                                        decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                                begin: Alignment.bottomLeft,
                                                                end: Alignment.topRight,
                                                                colors: [BeColorSwatch.navy.color, Colors.transparent],
                                                            ),
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.only(top: 10, right: 14, bottom: 14, left: 14),
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    if (ref.read(isDebuggingProvider))
                                                        NoScale(
                                                            child: Text(
                                                                effectiveBadge?.id ?? "",
                                                                style: beTextTheme.captionPrimary
                                                                        .merge(TextStyle(color: beColorScheme.text.debug)),
                                                            )
                                                        ),

                                                    Text(
                                                        // TODO: This should be handled server-side
                                                        show.title.replaceAll("Build Expo", "").replaceAll("  ", " ").toUpperCase(),
                                                        style: beTextTheme.headingPrimary.merge(
                                                            TextStyle(
                                                                color:    BeColorSwatch.white.color,
                                                                fontSize: 28,
                                                                height:   0,
                                                                overflow: TextOverflow.ellipsis,
                                                                shadows:  titleShadows,
                                                            ),
                                                        ),
                                                    ),

                                                    const SizedBox(height: 1),

                                                    Row(children: subtitleRow),

                                                    const SizedBox(height: 4),

                                                    Row(children: thirdRow),
                                                ]
                                            )
                                        )
                                    ]
                                )
                            )
                        )
                    )
                );
            }
        );
    }
}
