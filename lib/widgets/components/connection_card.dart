import "dart:convert";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:intl/intl.dart";




/* ======================================================================================================================
 * MARK: Connection Card
 * ------------------------------------------------------------------------------------------------------------------ */
class ConnectionCard extends ConsumerWidget {

    final BadgeData? badge;

    final bool showDivider;

    final VoidCallback? onRefresh;

    final ConnectionData connection;

    final UserData? user;


    const ConnectionCard({ super.key,
                   required this.connection,
                            this.user,
                            this.badge,
                            this.onRefresh,
                                 showDivider,

    })  :   this.showDivider = showDivider ?? true;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context, WidgetRef ref) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);

        final textTheme   = beTextTheme;
        final colorScheme = beColorScheme;

        return Container(
            decoration: BoxDecoration(color: BeColorSwatch.offWhite),
            child: Stack(
                children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child:   InkWell(
                            onTap: () async {
                                final shouldRefresh = await appRouter.pushNamed("connection info",
                                    pathParameters: {
                                        "connection": json.encode(connection.toJson(destination: LocationEncoding.database)),
                                    },
                                    extra: {
                                        "badge": badge,
                                        "user":  user
                                    }
                                );
                                // If detail screen popped with true, invoke the callback
                                if (shouldRefresh == true && onRefresh != null) {
                                onRefresh!();
                                }
                            },
                            splashFactory: NoSplash.splashFactory,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    if (ref.read(isDebuggingProvider))
                                        Text(
                                            connection.id,
                                            style: beTextTheme.captionPrimary
                                                .merge(TextStyle(color: beColorScheme.text.debug)),
                                        ),
                                    Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                                        children: [
                                            /*
                                            * Categories
                                            */
                                            if (connection.dateSynced != null && connection.legacyBadgeId == null)
                                                Flexible(
                                                    child: Text(
                                                        (connection.badgeCompanyCategories.isNotEmpty
                                                            ? connection.badgeCompanyCategories
                                                            : ["No categories"])
                                                            .join(", "),
                                                        overflow: TextOverflow.ellipsis,
                                                        style:    textTheme.captionPrimary,
                                                    )
                                                )
                                            else Spacer(),

                                            /*
                                            * Date
                                            */
                                            Builder(builder: (_) {
                                                DateTime? createdAt;
                                                if (connection.dateCreated != null) {
                                                    createdAt = DateTime.tryParse(connection.dateCreated!);
                                                }
                                                final bool isRecent = createdAt != null &&
                                                    DateTime.now().difference(createdAt) <= const Duration(hours: 1);

                                                return Text(
                                                    createdAt != null
                                                        ? DateFormat.jm().format(createdAt)
                                                        : "Unknown date",
                                                    style: isRecent
                                                        ? textTheme.captionPrimary.merge(
                                                            const TextStyle(color: BeColorSwatch.blue))
                                                        : textTheme.captionPrimary,
                                                );
                                            }),
                                        ],
                                    ),
                                    Builder(
                                        builder: (_) {
                                            final bool stackVertically = textScaleFactor > 1.35;

                                            final Widget detailsColumn = Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                    /*
                                                    * Name
                                                    */
                                                    Text(
                                                        (connection.dateSynced != null)
                                                            ? (connection.badgeUserName ?? "Unknown name")
                                                            : "Lead pending syncing",
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style:    textTheme.headingTertiary,
                                                    ),

                                                    /*
                                                    * Title and company
                                                    */
                                                    Text(
                                                        (connection.dateSynced != null)
                                                            ? (connection.badgeCompanyName ?? "Unknown company")
                                                            : "Pending",
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style:    textTheme.bodySecondary,
                                                    ),
                                                ],
                                            );

                                            final Widget ratingRow = Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                    ...(List<Widget>.generate(5, (index) {
                                                        final ratingValue = connection.rating ?? 0.0;

                                                        return Padding(
                                                            padding: const EdgeInsets.only(right: 2),
                                                            child:   SFIcon(
                                                                index < ratingValue ? SFIcons.sf_star_fill : SFIcons.sf_star,
                                                                color:    BeColorSwatch.gray,
                                                                fontSize: 16,
                                                            ),
                                                        );
                                                    })),
                                                    Padding(
                                                        padding: const EdgeInsets.only(top: 6, bottom: 6, left: 16),
                                                        child:   SFIcon(
                                                            SFIcons.sf_chevron_right,
                                                            fontSize:   textTheme.bodyPrimary.fontSize,
                                                            fontWeight: textTheme.bodyPrimary.fontWeight,
                                                            color:      colorScheme.text.accent,
                                                        ),
                                                    ),
                                                ],
                                            );

                                            if (stackVertically) {
                                                return Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                        detailsColumn,
                                                        const SizedBox(height: 8),
                                                        ratingRow,
                                                    ],
                                                );
                                            }

                                            return Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                    Expanded(child: detailsColumn),
                                                    ratingRow,
                                                ],
                                            );
                                        },
                                    ),

                                    const SizedBox(height: 12),

                                    if (showDivider) const Divider(
                                        color:  BeColorSwatch.gray,
                                        height: 0,
                                    )
                                ]
                            )
                        )
                    ),
                    if (connection.dateSynced == null)
                        Container(
                            margin:  EdgeInsets.only(top: 4, left: 2),
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                spacing:  6,
                                children: [
                                    SFIcon(SFIcons.sf_icloud_slash, fontSize: 15, fontWeight: FontWeight.bold, color: BeColorSwatch.orange),
                                    Text("Waiting for network...", style: Theme.of(context).textTheme.labelSmall!.copyWith(color: BeColorSwatch.orange, height: 0))
                                ]
                            )
                        )
                    else if (connection.legacyBadgeId != null)
                        Container(
                            margin:  EdgeInsets.only(top: 4, left: 2),
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                spacing:  5,
                                children: [
                                    SFIcon(SFIcons.sf_clock, fontSize: 14, fontWeight: FontWeight.bold, color: BeColorSwatch.purple),
                                    Text("Legacy badge", style: Theme.of(context).textTheme.labelSmall!.copyWith(color: BeColorSwatch.purple, height: 0))
                                ]
                            )
                        )
                ]
            )
        );
    }
}
