/*
 * Navigation Link
 *
 * Created by:  Blake Davis
 * Description: Navigation link
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";




/* ======================================================================================================================
 * MARK: Navigation Link
 * ------------------------------------------------------------------------------------------------------------------ */
class NavigationLink extends StatelessWidget {

    final Function? action;

    final String  title;

    final String? url;

    final Widget? leading;


    const NavigationLink({  this.leading,
                   required this.title,
                            this.url,
                            this.action    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        final state   = GoRouterState.of(context);
        final current = state.uri.toString();
        final target  = url != null ? (url!.startsWith('/') ? url! : '/$url') : null;

        final isActive = target != null && current.startsWith(target);

        Widget content = Row(
          children: [
            Container(
              alignment: AlignmentDirectional.center,
              height: 32,
              width: 32,
              child: leading ?? const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: beTextTheme.bodyPrimary,
            ),
          ],
        );

        if (isActive) {
          content = Container(
            decoration: BoxDecoration(
              color: BeColorSwatch.lightGray.withAlpha(185),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.only(top: 4, right: 8, bottom: 4, left: 8),
            child: content,
          );
        }

        return ListTile(
          title: content,
          onTap: () {
            if (action != null) {
              action!();
            }
            if (url != null) {
              // Only navigate if we're not already on this route (or a sub-route)
              if (!current.startsWith(target!)) {
                appRouter.push(target);
              } else {
                appRouter.pop();
              }
            }
          },
          contentPadding: EdgeInsets.only(right: 8, left: (isActive ? 4 : 12)),
        );
    }
}