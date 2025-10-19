/*
 * Account Settings
 *
 * Created by:  Blake Davis
 * Description: A widget which allows users to manage their account information
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__software_license.dart";
import "package:bmd_flutter_tools/data/model/data__user.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";
import "package:bmd_flutter_tools/widgets/modals/loading.dart";
import "package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/navigation/bottom_navigation_bar.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";

/* ======================================================================================================================
 * MARK: User Settings
 * ------------------------------------------------------------------------------------------------------------------ */
class UserSettings extends ConsumerStatefulWidget {
  static const Key rootKey = Key("user_settings__root");

  final List<SoftwareLicenseData> licenses = [];

  final String title;

  /*
     * Each MapEntry is structured like so:
     * {
     *     licenseId: {
     *         "user":  TextEditingController(),
     *         "owner": TextEditingController()
     *     }
     * }
     */
  final Map<int, Map<String, TextEditingController>> textEditingControllers =
      {};

  UserSettings({super.key, required this.title});

  @override
  ConsumerState<UserSettings> createState() => _UserSettingsState();
}

/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _UserSettingsState extends ConsumerState<UserSettings> {
  AppDatabase appDatabase = AppDatabase.instance;

  final TextEditingController emailOrPhoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _deletePasswordVisible = false;

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  void initState() {
    super.initState();

    showSystemUiOverlays();

    // Schedule provider updates after build to avoid modifying during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: This is improper - it conflicts with the current implementation of state management elsewhere in the app

      // Reset the badgeProvider because this page does not exist within the context of a Badge
      // ref.read(badgeProvider.notifier).reset();

      // Reset the companyProvider because this page does not exist within the context of a Company
      // ref.read(companyProvider.notifier).reset();

      // Reset the showProvider because this page does not exist within the context of a Show
      // ref.read(showProvider.notifier).reset();
    });

    // Get the licenses from the global user state
    List<SoftwareLicenseData> licenses = ref.read(userProvider)?.licenses ?? [];
    widget.licenses.addAll(licenses);

    // Create TextEditingControllers for each applicable license
    for (var license in licenses) {
      widget.textEditingControllers.addEntries([
        MapEntry(license.id,
            {"user": TextEditingController(), "owner": TextEditingController()})
      ]);
    }
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  void dispose() {
    super.dispose();
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Get User & Owner Info
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  Future<List<UserData>> getUserAndOwnerInfo() async {
    if (widget.licenses.isEmpty) {
      logPrint("⚠️  No licenses were found in the global state.");
      return [];
    }

    // Get a list of the user IDs to retrieve, removing duplicates
    Set<int> userIds = {};

    for (var license in widget.licenses) {
      userIds.addAll([license.userId, license.ownerId]);
    }

    // Check the database for the users
    List<UserData> usersFromDatabase = await appDatabase.readUsers(
        where:
            "${UserDataInfo.id.columnName} IN (${List.filled(userIds.length, "?").join(",")})",
        whereArgs: userIds.map((userId) => userId.toString()).toList());

    // Check the API for the remaining users if the users from the database does not contain all of the users used in the licenses
    List<UserData> usersFromApi = [];

    if (usersFromDatabase.length != userIds.length) {
      for (var userId in userIds) {
        if (usersFromDatabase.any((user) => user.id == userId)) {
          continue;
        } else {
          // TODO: Temporarily disabled while refactoring
          // UserData? user = await ApiClient.instance.getUser(id: userId);
          // if (user != null) {
          //     usersFromApi.add(user);
          // }
        }
      }
    }
    List<UserData> allUsers = usersFromDatabase + usersFromApi;

    for (var license in widget.licenses) {
      widget.textEditingControllers[license.id]!["user"]!.text = allUsers
              .firstWhereOrNull((user) => user.id == license.userId)
              ?.email ??
          "";
      widget.textEditingControllers[license.id]!["owner"]!.text = allUsers
              .firstWhereOrNull((user) => user.id == license.ownerId)
              ?.email ??
          "";
    }

    return allUsers;
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
        appBar: PrimaryNavigationBar(title: widget.title),
        bottomNavigationBar: QuickNavigationBar(),
        key: UserSettings.rootKey,

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Widget Body
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
        body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            children: [
              // Spacer
              const SizedBox(height: 48),

              /*
               *  Delete account button
               */
              ElevatedButton(
                  key: const Key("user_home__delete_account_button"),
                  style: elevatedButtonStyleAlt.copyWith(
                    backgroundColor: WidgetStateProperty.all(BeColorSwatch.red),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text("Delete my account"),
                  ),
                  onPressed: () {
                    final rootContext = context;
                    var passwordVisible = _deletePasswordVisible;
                    showModalBottomSheet<void>(
                        context: rootContext,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (sheetContext) {
                          return StatefulBuilder(
                              builder: (context, modalSetState) {
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(sheetContext)
                                      .viewInsets
                                      .bottom),
                              child: SafeArea(
                                top: false,
                                bottom: false,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: beColorScheme.background.primary,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(24)),
                                  ),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 44,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: BeColorSwatch.lightGray,
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          "Submit Account Deletion Request",
                                          style: beTextTheme.headingSecondary,
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          "WARNING: This will submit a request to PERMANENTLY delete your account. Deleted accounts cannot be recovered. If you wish to continue, enter your account credentials.",
                                          style: const TextStyle(
                                              color: BeColorSwatch.red,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 18),
                                        formFieldLabel(
                                            labelText: "Email Address"),
                                        TextFormField(
                                          controller: emailOrPhoneController,
                                          cursorHeight: 25,
                                          decoration:
                                              gfieldInputDecoration.merge(
                                            InputDecoration(
                                              filled: true,
                                              fillColor: beColorScheme
                                                  .background.secondary,
                                              hintText: "Email Address",
                                              hintStyle: gfieldHintStyle,
                                            ),
                                          ),
                                          enableSuggestions: false,
                                          strutStyle:
                                              const StrutStyle(height: 2),
                                        ),
                                        const SizedBox(height: 16),
                                        formFieldLabel(labelText: "Password"),
                                        TextFormField(
                                          controller: passwordController,
                                          cursorHeight: 25,
                                          decoration:
                                              gfieldInputDecoration.merge(
                                            InputDecoration(
                                              filled: true,
                                              fillColor: beColorScheme
                                                  .background.secondary,
                                              hintText: "Password",
                                              hintStyle: gfieldHintStyle,
                                              suffixIcon: IconButton(
                                                splashRadius: 20,
                                                icon: SFIcon(
                                                  passwordVisible
                                                      ? SFIcons.sf_eye
                                                      : SFIcons.sf_eye_slash,
                                                  fontSize: 16,
                                                      color: BeColorSwatch
                                                          .darkGray
                                                          .withAlpha(175),
                                                ),
                                                style: ButtonStyle(
                                                        splashFactory: NoSplash
                                                            .splashFactory),
                                                onPressed: () {
                                                  modalSetState(() {
                                                    passwordVisible =
                                                        !passwordVisible;
                                                  });
                                                  setState(() {
                                                    _deletePasswordVisible =
                                                        passwordVisible;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          enableSuggestions: false,
                                          obscureText: !passwordVisible,
                                          strutStyle:
                                              const StrutStyle(height: 2),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(sheetContext)
                                                    .pop();
                                              },
                                              child: Text("Cancel",
                                                  style: beTextTheme.bodyPrimary
                                                      .copyWith(
                                                          color: BeColorSwatch
                                                              .blue,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 12),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    BeColorSwatch.red,
                                              ),
                                              onPressed: () {
                                                Navigator.of(sheetContext)
                                                    .pop();

                                                showDialog(
                                                    context: rootContext,
                                                    builder:
                                                        (BuildContext context) {
                                                      return LoadingModal(
                                                          text:
                                                              "Submitting your account deletion request... Your personal information will be removed from our system in accordance with our privacy policy. You will be redirected to the sign-in form in a few seconds.");
                                                    });
                                                ApiClient.instance
                                                    .requestAccountDeletion();

                                                Future.delayed(
                                                    const Duration(seconds: 4),
                                                    () async {
                                                  if (rootContext.mounted) {
                                                    rootContext.pop();
                                                  }

                                                  ref.invalidate(userProvider);
                                                  ref.invalidate(badgeProvider);
                                                  ref.invalidate(
                                                      companyProvider);
                                                  ref.invalidate(showProvider);

                                                  await ApiClient.instance
                                                      .logout();

                                                  appRouter.goNamed("signin");
                                                });
                                              },
                                              child: Text("Confirm",
                                                  style: beTextTheme.bodyPrimary
                                                      .copyWith(
                                                          color: BeColorSwatch
                                                              .white,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 36),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          });
                        });
                  }),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  "This will submit a request to permanently delete your account. Deleted accounts cannot be recovered.",
                  style: beTextTheme.bodyPrimary.copyWith(
                    color: BeColorSwatch.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            ]));
  }
}
