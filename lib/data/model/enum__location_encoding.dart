/**
 *  Location Encoding
 *
 * Created by:  Blake Davis
 * Description: Location encoding enum
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 *
 *  Describes either the source or destination of a piece of data. Useful for indicating how to encode/decode data that
 *  can exist in multiple locations, which may differ in schema.
 */

enum LocationEncoding {
    api,
    database
}