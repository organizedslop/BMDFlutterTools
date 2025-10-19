/**
 *  Address Data Model
 *
 * Created by:  Blake Davis
 * Description: Address data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";


import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";

import "package:bmd_flutter_tools/utilities/utilities__print.dart";








/* =====================================================================================================================
 * MARK: Address Data Model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
class AddressData {

    String  city,
            country,
            state,
            street,
            street2,
            zip;




    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: Constructor
     */
    AddressData({   required this.city,
                                  country,
                    required this.state,
                    required this.street,
                                  street2,
                    required this.zip

    })   :  this.country = country ?? "United States",
            this.street2 = street2 ?? "";








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: == Operator Override
     */
    @override
    bool operator ==(Object other) {
        return other is AddressData  &&
            other.city    == city    &&
            other.country == country &&
            other.state   == state   &&
            other.street  == street  &&
            other.street2 == street2 &&
            other.zip     == zip;
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: HashCode Override
     */
    @override
    int get hashCode => Object.hash(city, country, state, street, street2, zip);








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: AddressData -> String
     */
    @override
    String toString({ bool includeCountry = false }) {
        return "${street} ${street2} ${city}, ${state} ${zip} ${includeCountry ? country : ""}".trim().replaceAll(r"\s+", " ");
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: AddressData -> JSON
     */
    Map<String, String> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions).
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  AddressDataInfo.city      .jsonName  :  AddressDataInfo.city      .columnName):    city,
            (apiOrDatabase  ?  AddressDataInfo.country   .jsonName  :  AddressDataInfo.country   .columnName):    country,
            (apiOrDatabase  ?  AddressDataInfo.state     .jsonName  :  AddressDataInfo.state     .columnName):    state,
            (apiOrDatabase  ?  AddressDataInfo.street    .jsonName  :  AddressDataInfo.street    .columnName):    street,
            (apiOrDatabase  ?  AddressDataInfo.street2   .jsonName  :  AddressDataInfo.street2   .columnName):    street2,
            (apiOrDatabase  ?  AddressDataInfo.zip       .jsonName  :  AddressDataInfo.zip       .columnName):    zip
        };
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: JSON -> AddressData
     */
    factory AddressData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {
        /**
         *  Create boolean value for the JSON's source (to shorten ternary expressions).
         */
        final bool apiOrDatabase = (source == LocationEncoding.api);


        /**
         *  Determine if the JSON data is a string or a map. Otherwise, throw an error.
         */
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return AddressData.empty(); }
        }




        return AddressData(
            city:       jsonAsMap[apiOrDatabase  ?  AddressDataInfo.city      .jsonName  :  AddressDataInfo.city      .columnName]    as String,
            country:    jsonAsMap[apiOrDatabase  ?  AddressDataInfo.country   .jsonName  :  AddressDataInfo.country   .columnName]    as String?,
            state:      jsonAsMap[apiOrDatabase  ?  AddressDataInfo.state     .jsonName  :  AddressDataInfo.state     .columnName]    as String,
            street:     jsonAsMap[apiOrDatabase  ?  AddressDataInfo.street    .jsonName  :  AddressDataInfo.street    .columnName]    as String,
            street2:    jsonAsMap[apiOrDatabase  ?  AddressDataInfo.street2   .jsonName  :  AddressDataInfo.street2   .columnName]    as String?,
            zip:        jsonAsMap[apiOrDatabase  ?  AddressDataInfo.zip       .jsonName  :  AddressDataInfo.zip       .columnName]    as String
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Default/Empty AddressData
     */
    factory AddressData.empty() {
        return AddressData(city: "", country: "", state: "", street: "", street2: "", zip: "");
    }
}








/* =====================================================================================================================
 * MARK: Object & Table Info
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
enum AddressDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    city(                "city",                    "city",                     "City",                     "TEXT NOT NULL",      "3"),
    country(             "country",                 "country",                  "Country",                  "TEXT NOT NULL",      "6"),
    state(               "state",                   "state",                    "State",                    "TEXT NOT NULL",      "4"),
    street(              "street",                  "address",                  "Street Address",           "TEXT NOT NULL",      "1"),
    street2(             "street_2",                "address2",                 "Street Address 2",         "TEXT NOT NULL",      "2"),
    zip(                 "zip",                     "zip",                      "ZIP Code",                 "TEXT NOT NULL",      "5");


    final String  columnName;
    final String  columnType;
    final String  displayName;
    final String? gformSubfieldId;
    final String  jsonName;


    const AddressDataInfo(this.columnName, this.jsonName, this.columnType, this.displayName, this.gformSubfieldId);


    static List<String> get columnNameValues {
        return AddressDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return AddressDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static Map<String, String?> get gformSubfieldIds {
        return { for (var value in AddressDataInfo.values) value.columnName: value.gformSubfieldId };
    }
    static List<String> get jsonNameValues {
        return AddressDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => AddressData;
    static String get objectTypeName => "address";
}

