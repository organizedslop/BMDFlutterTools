/**
 * Created by:  Blake Davis
 * Description: Gravity Forms submission response
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";

import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";




/* =============================================================================
 * MARK: GForm Submission Response
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 */
class GFormSubmissionResponse {

    bool isValid;

    int pageNumber;
    int sourcePageNumber;

    String? confirmationMessage;
    String? confirmationType;

    Map<dynamic, dynamic> validationMessages;




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Constructor
     */
    GFormSubmissionResponse({
                      confirmationMessage,
                      confirmationType,
        required this.isValid,
        required this.pageNumber,
        required this.sourcePageNumber,
                      validationMessages

    }) :  this.validationMessages = (validationMessages is Map) ? validationMessages : {};








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: GFormSubmissionResponse -> JSON
     */
    Map<String, dynamic> toJson() {
        return {
            "confirmation_message": confirmationMessage ?? "",
            "confirmation_type":    confirmationType ?? "",
            "is_valid":             isValid.toString(),
            "page_number":          pageNumber,
            "source_page_number":   sourcePageNumber,
            "validation_messages":  json.encode(validationMessages),
        };
    }




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: JSON -> GFormSubmissionResponse
     */
    factory GFormSubmissionResponse.fromJson(dynamic jsonAsDynamic, { bool defaultOnFailure = true }) {

        // Determine if the JSON data is a string or a map. Otherwise, throw an error.
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
        logPrint("❌ Returning empty response");
        return GFormSubmissionResponse.empty();
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return GFormSubmissionResponse.empty(); }
        }

        return GFormSubmissionResponse(
            confirmationMessage: jsonAsMap["confirmation_message"]        as String?,
            confirmationType:    jsonAsMap["confirmation_type"]           as String?,
            isValid:             jsonAsMap["is_valid"]                    as bool,
            pageNumber:          jsonAsMap["page_number"]                 as int,
            sourcePageNumber:    jsonAsMap["source_page_number"]          as int,
            validationMessages:  jsonAsMap["validation_messages"] ?? {}   // as Map<String, dynamic>
        );
    }

    // TODO: Finish this section -- in the api client process the data
        // Use that data to create widgets to show as validation messages / to
        // determine that the submission was successful
        // On successful submissions go to a confirmation view.

        // Add a parameter to the field widgets to allow for messages to be passed in as args
        // Use the input id in the api response to determine where to pass the msgs







    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Default/Empty GFormSubmissionResponse
     */
    factory GFormSubmissionResponse.empty() {
        return GFormSubmissionResponse(isValid: false, confirmationMessage: null, confirmationType: null, pageNumber: 0, sourcePageNumber: 0);
    }
}