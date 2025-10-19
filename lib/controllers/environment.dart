/*
 * Environment
 *
 * Created by:  Blake Davis
 * Description: Environment variables
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";




/* =====================================================================================================================
 * MARK: Development/Production Master Switch
 * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
 * Only set to "true" used to create a release build with development features enabled (for TestFlight)
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
const developmentFeaturesEnabled = true ? true : kDebugMode;




/* =====================================================================================================================
 * MARK: Responsive
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
class Responsive {

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 730;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1190 &&
      MediaQuery.of(context).size.width >= 730;

  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1190;
}




/* =====================================================================================================================
 * MARK: Show System Overlays (Clock, Network, Battery, etc.)
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
void showSystemUiOverlays() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
}