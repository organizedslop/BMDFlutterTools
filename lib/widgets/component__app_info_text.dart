import "dart:io";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";


class AppInfoText extends StatelessWidget {

    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Positioned(
            left:   0,
            right:  0,
            bottom: Platform.isIOS ? 20 : 10,
            child:  FutureBuilder<PackageInfo>(
                future:  PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                    final version = snapshot.data?.version     ?? '';
                    final build   = snapshot.data?.buildNumber ?? '';
                    if (version.isEmpty && build.isEmpty)
                        return const SizedBox.shrink();
                    final label = (version.isNotEmpty && build.isNotEmpty)
                        ? 'v$version ($build) beta'
                        : (version.isNotEmpty
                            ? 'v$version beta'
                            : 'beta build $build');
                    return Text(
                        label,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: BeColorSwatch.gray,
                            ),
                    );
                },
            ),
        );
    }
}