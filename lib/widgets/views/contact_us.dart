import "dart:io";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_sficon/flutter_sficon.dart";
import "package:url_launcher/url_launcher.dart";

class ContactUs extends StatelessWidget {
  static const Key rootKey = Key("contact_us__root");

  static const String _email = "info@bmd_flutter_tools.com";
  static const String _phoneDisplay = "(512) 249-5303";
  static const String _phoneLink = "+15122495303";
  static const String _address =
      "13740 Research Blvd., Building I Austin, TX 78750";

  const ContactUs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

        final TextScaler textScaler  = MediaQuery.of(context).textScaler;
        final double textScaleFactor = textScaler.scale(1.0);

    return Scaffold(
      appBar: PrimaryNavigationBar(title: "Contact Us"),
      key: ContactUs.rootKey,
      body: Container(
        color: beColorScheme.background.tertiary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Contact Build Expo USA",
                style: beTextTheme.headingSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                "We're here to answer any questions you may have about your account or our events!",
                style: beTextTheme.bodyPrimary,
              ),
              const SizedBox(height: 24),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildContactTile(
                    context: context,
                    label: "Email",
                    value: _email,
                    onLaunch: () => _launchUri(
                      context,
                      Uri(scheme: "mailto", path: _email),
                    ),
                    copyMessage: "Copied email address to clipboard.",
                    openIcon: SFIcons.sf_envelope,
                    openLabel: "Email",
                    copyLabel: (textScaleFactor > 1.35) ? "Copy" : "Copy email address",
                  ),
                  _buildContactTile(
                    context: context,
                    label: "Phone",
                    value: _phoneDisplay,
                    onLaunch: () => _launchUri(
                      context,
                      Uri(scheme: "tel", path: _phoneLink),
                    ),
                    copyMessage: "Copied phone number to clipboard.",
                    openIcon: SFIcons.sf_phone,
                    openLabel: "Call",
                    copyLabel: (textScaleFactor > 1.35) ? "Copy" : "Copy phone number",
                  ),
                  _buildContactTile(
                    context: context,
                    label: "Address",
                    value: _address,
                    onLaunch: () => _launchUri(context, _mapUri()),
                    copyMessage: "Copied address to clipboard.",
                    isLast: true,
                    openIcon: SFIcons.sf_map,
                    openLabel: "Get directions",
                    copyLabel: (textScaleFactor > 1.35) ? "Copy" : "Copy address",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required BuildContext context,
    required String label,
    required String value,
    required Future<void> Function() onLaunch,
    required String copyMessage,
    bool isLast = false,
    IconData? openIcon,
    String openLabel = "Open",
    String copyLabel = "Copy",
  }) {
    final textStyle = beTextTheme.bodyPrimary;

    return Padding(
      padding: EdgeInsets.only(
        left: beDimensions.insetListHorizontalMargin,
        right: beDimensions.insetListHorizontalMargin,
        bottom: isLast ? 0 : beDimensions.insetListGroupSpacing,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: beDimensions.insetListGroupHorizontalPadding,
          vertical: beDimensions.insetListItemPadding + 4,
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(value, style: textStyle),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => onLaunch(),
                  icon: SFIcon(
                    openIcon ?? SFIcons.sf_square_and_arrow_up,
                    fontSize: 20,
                  ),
                  label: Text(
                    openLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () =>
                      _copyToClipboard(context, value, copyMessage),
                  icon: const SFIcon(
                    SFIcons.sf_rectangle_portrait_on_rectangle_portrait,
                    fontSize: 20,
                  ),
                  label: Text(
                    copyLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to open link.", textAlign: TextAlign.center),
        ),
      );
    }
  }

  static Uri _mapUri() {
    final query = Uri.encodeComponent(_address);

    if (Platform.isIOS) {
      return Uri.parse("maps://?q=$query");
    }
    if (Platform.isAndroid) {
      return Uri.parse("geo:0,0?q=$query");
    }
    return Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
  }

  Future<void> _copyToClipboard(
      BuildContext context, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
