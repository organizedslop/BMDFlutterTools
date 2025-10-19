/**
 * Created by:  Blake Davis
 * Description: Contains the Method Channel class
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/utilities/utilities__print.dart";

import "package:flutter/services.dart";




/* =====================================================================================================================
 * MARK: Method Channel Class
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
class VerificationMethodChannel {

    static MethodChannel methodChannel = const MethodChannel("icmMethodChannel");


    static Future<String> sna({ required String phoneNumber }) async {

        try {
            logPrint("📱 Invoking native code...");

            final result = await methodChannel.invokeMethod<String>("sna", { "phoneNumber": phoneNumber });

            return result!;


        } on PlatformException catch(error) {

            logPrint("❌ ${error.message ?? "Unknown SNA platform error"}");
            return "";
        }

    }
}