/*
 * Primary Navigation Bar
 *
 * Created by:  Blake Davis
 * Description: A widget which serves as the app's top navigation menu
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:io";
import "dart:ui";
import "package:auto_size_text/auto_size_text.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/widgets/modals/modal__debug_menu.dart";
import "package:bmd_flutter_tools/widgets/utilities/tool__no_scale_wrapper.dart";
import "package:bmd_flutter_tools/widgets/navigation/user_menu.dart";
import "package:bmd_flutter_tools/data/model/data__notification.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:go_router/go_router.dart";

/* ======================================================================================================================
 * MARK: Primary Navigation Bar
 * ------------------------------------------------------------------------------------------------------------------ */
class PrimaryNavigationBar extends ConsumerWidget
    implements PreferredSizeWidget {
  final bool isHome, showMenu, showOptions, showCancelAction;

  final Color? backgroundColor, iconColor;

  final Image? backgroundImage;

  final dynamic title;

  final String? pushReplacementNamedOnClose, subtitle;

  double height = Platform.isIOS
      ? 116
      : 84; // Must be at least 116 to prevent clipping the debug path label on iOS

  PrimaryNavigationBar(
      {super.key,
      this.backgroundColor,
      this.backgroundImage,
      this.iconColor,
      this.isHome = false,
      this.title = "",
      this.subtitle,
      this.showCancelAction = false,
      this.showOptions = true,
      this.showMenu = false,
      offset,
      maxOffset,
      this.pushReplacementNamedOnClose});

  @override
  Size get preferredSize => Size(double.infinity, height + 30);

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var currentPath = GoRouter.of(context).routeInformationProvider.value.uri;

    final List<Shadow> titleShadows = [
      Shadow(color: BeColorSwatch.navy, offset: Offset(0, 1), blurRadius: 50),
      Shadow(
          color: BeColorSwatch.navy.withAlpha(100),
          offset: Offset(0, 1),
          blurRadius: 20)
    ];

    final countAsync = ref.watch(notificationsCountProvider);

    Color resolvedIconColor() =>
        iconColor ?? (isHome ? BeColorSwatch.black : BeColorSwatch.white);

    void handleBackNavigation() {
      if (context.canPop()) {
        context.pop();
      } else {
        final user = ref.read(userProvider);
        appRouter.goNamed(user == null ? 'signin' : 'home');
      }
    }

    return SizedBox(
        height: height,
        child: Stack(
            children: [
          isHome
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [
                        BeColorSwatch.lighterGray,
                        BeColorSwatch.lighterGray.withAlpha(0),
                      ],
                    ),
                  ),
                  height: 75,
                  transform: Matrix4.translationValues(0, 80, 0),
                  width: double.infinity,
                  child: Image(
                      image: AssetImage(
                          "assets/images/build-expo-usa-logo-horizontal.png")))
              : null,
          ClipRect(
              child: SizedBox(
                  height: height,
                  child: AppBar(
                      centerTitle: false,
                      clipBehavior: Clip.none,
                      leading: showMenu
                          ? IconButton(
                              icon: Icon(Icons.menu,
                                  color: iconColor ??
                                      (isHome
                                          ? BeColorSwatch.black
                                          : BeColorSwatch.white)),
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                            )
                          : showCancelAction
                              ? TextButton(
                                  onPressed: handleBackNavigation,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    foregroundColor: resolvedIconColor(),
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: Text(
                                    "Cancel",
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    style:
                                        Theme.of(context).textTheme.labelSmall!.copyWith(color: BeColorSwatch.red),
                                  ),
                                )
                              : IconButton(
                                  icon: SFIcon(
                                    SFIcons.sf_chevron_left,
                                    color: resolvedIconColor(),
                                  ),
                                  onPressed: handleBackNavigation,
                                ),
                      surfaceTintColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      scrolledUnderElevation: 28,
                      elevation: 0,

                      // Set the status bar to a transparent background with dark icons
                      systemOverlayStyle: SystemUiOverlayStyle(
                          statusBarIconBrightness:
                              isHome ? Brightness.light : Brightness.dark,
                          statusBarColor: Colors.transparent),
                      flexibleSpace: Container(
                          decoration: BoxDecoration(
                                border: (isHome || backgroundColor != null) ? null : Border(bottom: BorderSide(color: BeColorSwatch.lightGray)),
                              color: (backgroundColor == null)
                                  ? null
                                  : backgroundColor,
                              image: (backgroundImage == null)
                                  ? null
                                  : DecorationImage(
                                      image: Image(
                                        color: BeColorSwatch.darkBlue
                                            .withAlpha(50),
                                        colorBlendMode: BlendMode.multiply,
                                        image: backgroundImage!.image,
                                      ).image,
                                      fit: BoxFit.cover))),
                      iconTheme: IconThemeData(
                          color: isHome
                              ? BeColorSwatch.black
                              : BeColorSwatch.white),
                      backgroundColor: isHome
                          ? Colors.transparent
                          : backgroundColor ?? BeColorSwatch.navy,
                      foregroundColor:
                          isHome ? BeColorSwatch.black : BeColorSwatch.white,

                      // Use the current path to determine which items to display
                      actions: (() {
                        if (showOptions) {
                          switch (currentPath.toString()) {
                            case "/register":
                              return <Widget>[];

                            case "/scanner":
                              return <Widget>[];

                            default:
                              return [
                                countAsync.when(
                                  data: (unread) =>
                                      _NotificationBell(unread: unread),
                                  loading: () => _NotificationBell(
                                      unread: 0), // No badge while loading
                                  error: (_, __) =>
                                      _NotificationBell(unread: 0), // Fail-safe
                                ),
                              ];
                          }
                        } else {
                          return <Widget>[];
                        }
                      })(),
                      title: Stack(
                          alignment: (subtitle != null)
                              ? AlignmentDirectional.bottomStart
                              : AlignmentDirectional.centerStart,
                          children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              // TODO: This chunk needs to be refactored -- it is no longer implemented in an easily usable way
                              (pushReplacementNamedOnClose != null)
                                  ? InkWell(
                                      onTap: () {
                                        appRouter.pushReplacementNamed(
                                            pushReplacementNamedOnClose!);
                                      },
                                      child: Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: SFIcon(SFIcons.sf_xmark,
                                              fontSize: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium!
                                                  .fontSize)))
                                  : const SizedBox.shrink(),

                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        (subtitle != null)
                                            ? AutoSizeText(subtitle!,
                                                minFontSize: 8,
                                                maxFontSize: 16,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                softWrap: true,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineLarge!
                                                    .copyWith(
                                                      color:
                                                          BeColorSwatch.white,
                                                      height: 0.95,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      shadows: titleShadows,
                                                    ))
                                            : null,
                                        AutoSizeText(title,
                                            minFontSize: 24,
                                            maxFontSize: 36,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            softWrap: true,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineLarge!
                                                .copyWith(
                                                  color: BeColorSwatch.white,
                                                  height: 0.95,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  shadows: titleShadows,
                                                ))
                                      ].nonNulls.toList()))
                            ]),
                            if (developmentFeaturesEnabled) DebugMenuToggle(),
                          ]))))
        ].nonNulls.toList()));
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        NoScale(
            child: IconButton(
          onPressed: () {
            final route = ModalRoute.of(context);

            // Only push the notifications list if it's not already on the stack
            if (route?.settings.name != "notifications") {
              appRouter.pushNamed("notifications");
            }
          },
          icon: SFIcon(
            SFIcons.sf_bell_fill,
            fontSize: Theme.of(context).textTheme.headlineMedium!.fontSize,
          ),
        ),
        ),
        if (unread > 0)
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: BeColorSwatch.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 99 ? "99+" : "$unread",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/* ======================================================================================================================
 * MARK: Rectangular Shape Clipper
 * ------------------------------------------------------------------------------------------------------------------ */
class RectangularShapeClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 100, size.width, size.height / 2);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return true;
  }
}
