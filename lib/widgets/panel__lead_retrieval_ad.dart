import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:url_launcher/url_launcher.dart";
import "package:bmd_flutter_tools/controllers/api_client.dart";

/* ======================================================================================================================
 * MARK: Lead Retrieval Ad
 * ------------------------------------------------------------------------------------------------------------------ */
class LeadRetrievalAd extends ConsumerStatefulWidget {
  double height = 285;

  final VoidCallback? onRefreshStart;
  final VoidCallback? onRefreshEnd;
  final VoidCallback? onPurchaseFlowStarted; // parent will refresh on resume

  LeadRetrievalAd({
    super.key,
    this.onRefreshStart,
    this.onRefreshEnd,
    this.onPurchaseFlowStarted,
  });

  @override
  ConsumerState<LeadRetrievalAd> createState() => _LeadRetrievalAdState();
}

class _LeadRetrievalAdState extends ConsumerState<LeadRetrievalAd> {
  @override
  Widget build(BuildContext context) {
    // Read the current show from provider (for banner)
    final show = ref.watch(showProvider);
    final String? bannerUrl = show?.banner;

    return Container(
        decoration: hardEdgeDecoration,
        child: Container(
            foregroundDecoration: beveledDecoration,
        child: InkWell(
      onTap: () async {
        final isDev = ref.read(isDevelopmentProvider);
        final base = ref.read(
          isDev ? developmentSiteBaseUrlProvider : productionSiteBaseUrlProvider,
        );

        final companyId       = ref.read(companyProvider)?.id ?? '';
        final exhibitorShowId = ref.read(badgeProvider)?.exhibitorShowId ?? '';

        if (companyId.isEmpty || exhibitorShowId.isEmpty) {
          logPrint("❌ LeadScan | Missing companyId or exhibitorShowId — cannot build URL.");
          return;
        }

        // Normalize host + scheme
        Uri baseUri;
        try {
          final parsed = Uri.parse(base);
          baseUri = parsed.hasScheme
              ? parsed
              : (isDev ? Uri.http(base, '') : Uri.https(base, ''));
        } catch (_) {
          baseUri = isDev ? Uri.http(base, '') : Uri.https(base, '');
        }

        // Ask API for a short-lived panel token instead of using access_token
        final panelToken = await ApiClient.instance.fetchPanelToken();

        if (panelToken == null || panelToken.isEmpty) {
          logPrint("❌ LeadScan | Failed to fetch panel token; aborting.");
          return;
        }

        // Build the target route robustly
        final path = "panel/accept-token";
        final qp = <String, String>{
          "redirect": "/exhibit/$companyId/purchase-lead-scanning?exhibitorShow=$exhibitorShowId&pass_session=1",
          "token": panelToken,
        };

        final url = baseUri.replace(path: path, queryParameters: qp);
        logPrint("🔄 LeadScan | Launching: $url");

        final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!ok) {
          logPrint("❌ LeadScan | launchUrl returned false.");
        } else {
          // Tell parent we launched the purchase flow; parent will refresh on resume
          widget.onPurchaseFlowStarted?.call();
          // Optionally show spinner immediately
          widget.onRefreshStart?.call();
        }
      },
      child: Container(
        alignment: AlignmentDirectional.topStart,
        height: widget.height,
        child: Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            // Background gradient layer
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(mediumRadius)),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFd17c58),
                    Color(0xFFf5a678),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Optional banner image overlay

            if (bannerUrl != null && bannerUrl.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(mediumRadius)),
                  child: ShaderMask(
                    shaderCallback: (Rect rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        BeColorSwatch.orange,
                        BeColorSwatch.orange,
                      ],
                    ).createShader(rect),
                    blendMode: BlendMode.overlay,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0, // R'
                        0.2126, 0.7152, 0.0722, 0, 0, // G'
                        0.2126, 0.7152, 0.0722, 0, 0, // B'
                        0,      0,      0,      1, 0, // A
                      ]),
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) =>
                              Image.asset("assets/images/showroom-floor.jpg", fit: BoxFit.cover),
                          loadingBuilder: (context, child, progress) =>
                              progress == null ? child : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom red fade
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(mediumRadius)),
                gradient: LinearGradient(
                  colors: [
                    BeColorSwatch.red,
                    BeColorSwatch.red.withAlpha(0),
                  ],
                  stops: const [0, 0.85],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

            // Feature image with shader mask
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(mediumRadius)),
                color: Colors.transparent,
              ),
              padding: const EdgeInsets.only(top: 24, left: 52, right: 52),
              child: ShaderMask(
                shaderCallback: (Rect rect) {
                  return LinearGradient(
                    colors: [
                      BeColorSwatch.red,
                      BeColorSwatch.red.withAlpha(120),
                      BeColorSwatch.red.withAlpha(60),
                      const Color(0xFFd17c58).withAlpha(0),
                    ],
                    stops: const [0.45, 0.65, 0.75, 1],
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                  ).createShader(rect);
                },
                blendMode: BlendMode.srcATop,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    "assets/images/ad-lead-retrieval-features.png",
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),

            // CTA text
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Get lead scanning today!",
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                          color: BeColorSwatch.white,
                        ),
                  ),
                  Text(
                    "Maximize your exhibit potential!",
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: BeColorSwatch.white,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ))
    );
  }
}