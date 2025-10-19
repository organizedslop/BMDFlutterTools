/*
 * Magazine Ad Panel
 *
 * Created by:  Blake Davis
 * Description:
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/data/model/data__show.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";




/* ======================================================================================================================
 * MARK: Magazine Ad
 * ------------------------------------------------------------------------------------------------------------------ */
class MagazineAd extends StatelessWidget {

    final ShowData show;

    const MagazineAd({
                super.key,
        required this.show
    });


    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text("Sponsored by", style: Theme.of(context).textTheme.labelMedium!.copyWith(color: BeColorSwatch.gray)),
                    Text("Construction Monthly Magazine, ${show.title.replaceAll("Build Expo", "").replaceAll("  ", " ")} edition", style: Theme.of(context).textTheme.headlineLarge!),

                    const SizedBox(height: 16),

                    InkWell(
                        onTap: () async {
                            final rawUrl = show.magazine;
                            Uri uri;
                            // Try parsing the URL
                            try {
                                uri = Uri.parse(rawUrl!);
                            } catch (error) {
                                // For malformed URLs, show "coming soon" message
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final messenger = scaffoldMessengerKey.currentState;
                                  if (messenger == null) return;
                                  messenger.hideCurrentSnackBar();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text("This show's magazine is coming soon!", textAlign: TextAlign.center),
                                      padding: EdgeInsets.all(16),
                                    ),
                                  );
                                });
                                return;
                            }
                            // Validate scheme and host
                            if (!(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final messenger = scaffoldMessengerKey.currentState;
                                  if (messenger == null) return;
                                  messenger.hideCurrentSnackBar();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text("This show's magazine is coming soon!", textAlign: TextAlign.center),
                                      padding: EdgeInsets.all(16),
                                    ),
                                  );
                                });
                                return;
                            }
                            // Attempt to launch
                            try {
                                if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.inAppWebView);
                                } else {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      final messenger = scaffoldMessengerKey.currentState;
                                      if (messenger == null) return;
                                      messenger.hideCurrentSnackBar();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text("This show's magazine is coming soon!", textAlign: TextAlign.center),
                                          padding: EdgeInsets.all(16),
                                        ),
                                      );
                                    });
                                }
                            } catch (_) {
                                // Any unexpected error launching URL
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final messenger = scaffoldMessengerKey.currentState;
                                  if (messenger == null) return;
                                  messenger.hideCurrentSnackBar();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text("This show's magazine is coming soon!", textAlign: TextAlign.center),
                                      padding: EdgeInsets.all(16),
                                    ),
                                  );
                                });
                            }
                        },
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing:  10,
                            children: [
                                Image.network(
                                  show.magazineThumbnailUrl ?? "",
                                  height: 300,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  // Show a placeholder immediately until the first image frame is available
                                  frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
                                    if (wasSynchronouslyLoaded || frame != null) return child;
                                        return Image.asset(
                                            "assets/images/sample--construction-monthly-cover.jpg",
                                            height: 300,
                                            width: double.infinity,
                                            fit: BoxFit.contain,
                                        );
                                  },
                                  // While bytes are loading, optionally show a percentage if we can compute it
                                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;

                                    return Image.asset(
                                      "assets/images/sample--construction-monthly-cover.jpg",
                                      height: 300,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                    );
                                  },
                                  errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                    return Image.asset(
                                      "assets/images/sample--construction-monthly-cover.jpg",
                                      height: 300,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                    );
                                  },
                                ),
                                Text("Tap to read", style: Theme.of(context).textTheme.labelMedium!.copyWith(color: appAccentColor)),
                            ]
                        )
                    )
                ]
            )
        );
    }
}