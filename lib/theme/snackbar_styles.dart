
import 'package:bmd_flutter_tools/theme/app_styles.dart';
import 'package:bmd_flutter_tools/utilities/utilities__theme.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/*
 * MARK: Show SnackBar
 */
void showSnackBar({
    Color backgroundColor = BeColorSwatch.white,
    required BuildContext context,
    required Widget content,
}) {
    if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                content: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        border: Border.all(color: BeColorSwatch.gray, width: 0.5),
                        borderRadius: BorderRadius.circular(mediumRadius),
                        color: BeColorSwatch.white,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    width: double.infinity,
                    child: content,
                ),
            ),
        );
    }
}