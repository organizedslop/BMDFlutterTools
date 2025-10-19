/*
 * IceCRM Response Data
 *
 * Created by:  Blake Davis
 * Description: IceCRM REST API response data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:meta/meta.dart";




/* ======================================================================================================================
 * MARK: IceCRM Response Data Model
 * ---------------------------------------------------------------------------------------------------------------------
 * Base wrapper for every response coming from the IceCRM REST API.
 *
 * Example 404 payload:
 * ```json
 * {
 *   "data": [],
 *   "error": true,
 *   "messages": [
 *     "No badge was found with the ID 114c1ae9-7aae-4af6-bc51-56770a8380a4"
 *   ],
 *   "status": 404
 * }
 * ```
* ------------------------------------------------------------------------------------------------------------------- */
@immutable
class IceCrmResponseData<T> {

    // May be `null` on error responses or when the backend returns an empty list
    final T? data;

    // Whether the request failed (`true`) or succeeded (`false`)
    final bool error;

    // Human-readable messages (can be empty)
    final List<String> messages;

    // HTTP-style status code (e.g. 200, 404, 500)
    final int status;

    // `true` when `status` is 2xx and `error == false`.
    bool get isSuccess => !error && (status ~/ 100 == 2);




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    const IceCrmResponseData({
        required this.data,
        required this.error,
        required this.messages,
        required this.status,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> IceCrmResponseData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * @param dataParser: A function that converts `json['data']` into type `T`. For simple primitives you can pass `(d) => d as MyType`
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory IceCrmResponseData.fromJson(Map<String, dynamic> json, { required T Function(dynamic raw) dataParser }) {

        return IceCrmResponseData<T>(
            data:      json.containsKey('data') ? dataParser(json['data']) : null,
            error:     json['error']    as bool? ?? false,
            messages: (json['messages'] as List<dynamic>? ?? []).map((m) => m.toString()).toList(),
            status:    json['status']   as int? ?? 0,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: IceCrmResponseData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required dynamic Function(T? data) dataEncoder }) {
        return {
            'data':     dataEncoder(data),
            'error':    error,
            'messages': messages,
            'status':   status,
        };
    }

    @override
    String toString() => 'IceCrmResponseData<$T>(status=$status, error=$error, messages=$messages, data=$data)';
}