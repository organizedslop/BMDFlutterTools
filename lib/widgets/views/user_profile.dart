/*
 * User Profile
 *
 * Created by:  Blake Davis
 * Description: A widget which displays a user's account info
 */

import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__connection.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/data/model/data__user_note.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:bmd_flutter_tools/widgets/components/foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/navigation/bottom_navigation_bar.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:qr_flutter/qr_flutter.dart";

/* ======================================================================================================================
 * MARK: User Profile
 * ------------------------------------------------------------------------------------------------------------------ */
class UserProfile extends ConsumerStatefulWidget {
  final BadgeData? badge;
  final ConnectionData? connection;
  static const Key rootKey = Key("user_profile__root");
  final String title;
  final UserData? user;

  UserProfile({
    super.key,
    required this.title,
    this.user,
    this.badge,
    this.connection,
  });

  @override
  ConsumerState<UserProfile> createState() => _UserProfileState();
}

/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _UserProfileState extends ConsumerState<UserProfile> {
  AppDatabase appDatabase = AppDatabase.instance;

  final storage = const FlutterSecureStorage();
  final TextEditingController newUserNoteController = TextEditingController();

  bool _loadingApi = false,
      isFetchingFromDatabase = false,
      isSubmittingNewUserNote = false;

  List<UserNoteData> _comments = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    showSystemUiOverlays();

    // When viewing a connection profile, keep existing "notes" behavior: DB first, then API.
    if (widget.connection != null) {
      setState(() => isFetchingFromDatabase = true);
      getCommentsForConnection(widget.connection!.id).then((comments) {
        logPrint("✅ Got comments from the database.");
        setState(() {
          _comments = comments;
          isFetchingFromDatabase = false;
          _loadingApi = true;
        });

        ApiClient.instance
            .getUserNotes(recipientId: widget.connection!.id)
            .then((commentsFromApi) async {
          final seenIds = <String>{};
          final allComments = <UserNoteData>[];

          for (final c in _comments) {
            if (seenIds.add(c.id)) allComments.add(c);
          }
          for (final c in commentsFromApi) {
            if (seenIds.add(c.id)) allComments.add(c);
          }

          logPrint("✅ Got comments from the API.");
          if (!mounted) return;
          setState(() {
            _comments = allComments;
            _loadingApi = false;
          });
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<UserNoteData>> getCommentsForConnection(String connectionId) async {
    final commentsFromDatabase = await appDatabase.read(
      tableName: UserNoteDataInfo.tableName,
      whereAsMap: {UserNoteDataInfo.recipientId.columnName: connectionId},
    );
    return commentsFromDatabase;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryNavigationBar(
        title: widget.title,
        subtitle: ref.read(showProvider)?.title,
      ),
      bottomNavigationBar: QuickNavigationBar(),
      floatingActionButton: (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false)
          ? const FloatingScannerButton()
          : null,
      key: UserProfile.rootKey,

      // BODY
      body: Container(
        child: (() {
          UserData? user;

          // Compute display values like before
          final Map<String, dynamic> profileData = {};

            user = ref.read(userProvider);

            profileData["address"] = user?.address.toString() ?? "No address";
            profileData["badgeType"] = user?.badges
                    .firstWhereOrNull((b) => b.id == ref.read(badgeProvider)?.id)
                    ?.typeLabel ??
                "No type";
            profileData["companyName"] =
                ref.read(companyProvider)?.name ?? "No company";
            profileData["email"] = user?.email ?? "No email";
            profileData["jobTitle"] = user?.companyUsers.firstWhereOrNull((cu) {
                  final companyId = ref.read(companyProvider)?.id;
                  return companyId != null && companyId == cu.companyId;
                })?.jobTitle ??
                "No title";
            profileData["name"] = user?.name.full ?? "No name";
            profileData["phone"] = user?.phone.primary ?? "No phone";
            profileData["companyCategories"] =
                (ref.read(companyProvider)?.categories ?? []).join(", ");

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading (avatar + name + role/company + categories)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Profile picture
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ClipOval(
                          child: Image.network(
                            Uri.parse(user?.profilePicture ?? "").toString(),
                            fit: BoxFit.cover,
                            height: 80,
                            width: 80,
                            errorBuilder: (context, exception, stackTrace) =>
                                SFIcon(
                              SFIcons.sf_person_crop_circle_fill,
                              fontSize: 72,
                              fontWeight: FontWeight.w500,
                            ),
                            frameBuilder:
                                (context, child, frame, wasSynchronouslyLoaded) =>
                                    child,
                            loadingBuilder: (context, child, loadingProgress) {
                              return (loadingProgress == null)
                                  ? child
                                  : const Center(child: CircularProgressIndicator());
                            },
                          ),
                        ),
                      ),

                      // Name / Job / Company / Categories
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: () {
                            final output = <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                spacing: 6,
                                children: [
                                  SelectableText(profileData["name"],
                                      style: beTextTheme.headingPrimary),
                                ],
                              ),
                                  if (ref.read(isDebuggingProvider))
                                    SelectableText(
                                      user?.id.toString() ?? "No ID",
                                      style: beTextTheme.captionPrimary.merge(
                                        TextStyle(
                                          color: beColorScheme.text.debug,
                                        )
                                      )
                                    ),
                            ];

                            final job = (profileData["jobTitle"] ?? "").toString();
                            final comp =
                                (profileData["companyName"] ?? "").toString();
                            if (job.isNotEmpty || comp.isNotEmpty) {
                              output.add(
                                Text(
                                  "${job}${(job.isNotEmpty && comp.isNotEmpty) ? " at " : ""}${comp}",
                                  style: beTextTheme.bodyPrimary,
                                  softWrap: true,
                                  textAlign: TextAlign.left,
                                ),
                              );
                            }

                            final cats =
                                (profileData["companyCategories"] ?? "") as String;
                            if (cats.isNotEmpty) {
                              output.add(
                                Text(
                                  cats,
                                  style: beTextTheme.bodyPrimary,
                                  softWrap: true,
                                  textAlign: TextAlign.left,
                                ),
                              );
                            }
                            return output;
                          }(),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                /*
                 * QR Code
                 */
                if (user != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child:   QrImageView(
                            data:                 user.id,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                            padding:              EdgeInsets.zero,
                            version:              QrVersions.auto,
                        ),
                    ),

                /*
                 * Badge UUID
                 */
                if (ref.read(isDebuggingProvider))
                    Center(
                        child: SelectableText(
                            ref.read(badgeProvider)?.id.toString() ?? "No badge ID",
                            style: beTextTheme.captionPrimary.merge(TextStyle(color: beColorScheme.text.debug))
                        )
                    ),

                const SizedBox(height: 22),

                // Contact & User info (ListTiles like ConnectionInfo)
                ListTile(
                  title: const Text("Email",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: SelectableText(profileData["email"]),
                ),
                ListTile(
                  title: const Text("Phone",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: SelectableText(profileData["phone"]),
                ),
                ListTile(
                  title: const Text("Job Title",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: SelectableText(((profileData["jobTitle"] ?? "No title")
                              .toString()
                              .isEmpty)
                      ? "No title"
                      : profileData["jobTitle"]),
                ),
                ListTile(
                  title: const Text("Company",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: SelectableText(profileData["companyName"]),
                ),
                ListTile(
                  title: const Text("Address",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: SelectableText(profileData["address"]),
                ),

                const SizedBox(height: 128),
              ],
            ),
          );
        })(),
      ),
    );
  }
}