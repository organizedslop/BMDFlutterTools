/*
 * User Data
 *
 * Created by:  Blake Davis
 * Description: User data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/data__address.dart";
import "package:bmd_flutter_tools/data/model/data__badge.dart";
import "package:bmd_flutter_tools/data/model/data__company.dart";
import "package:bmd_flutter_tools/data/model/data__company_user.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/data/model/data__name.dart";
import "package:bmd_flutter_tools/data/model/data__phone.dart";
import "package:bmd_flutter_tools/data/model/data__qr_code.dart";
import "package:bmd_flutter_tools/data/model/data__software_license.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";
import "package:collection/collection.dart";




/* ======================================================================================================================
 * MARK: User Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class UserData {

    String id;

    AddressData address;

    List<BadgeData> badges;

    List<CompanyData> companies;

    List<CompanyUserData> companyUsers;

    List<SoftwareLicenseData> licenses;

    List<String> userRoles;

    NameData name;

    PhoneData phone;

    QrCodeData qrCode;

    String  email,
            interests,
            jobTitle,
            primaryContactMethod,
            profilePicture,
            purchasingRole,
            registrationType,
            status,
            username;

    String? legacyBarcode;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    UserData({  required this.id,

                required this.address,
                required this.badges,
                required this.companies,
                required this.companyUsers,
                required this.email,
                required this.interests,
                required this.jobTitle,
                         this.legacyBarcode,
                required this.licenses,
                required this.name,
                required this.phone,
                required this.primaryContactMethod,
                required this.profilePicture,
                required this.purchasingRole,
                required this.qrCode,
                required this.registrationType,
                required this.status,
                required this.userRoles,
                required this.username,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
                                 return other is UserData                                   &&
                                        other.id                    == id                   &&
                                        other.address               == address              &&
        DeepCollectionEquality().equals(other.badges,                  badges)              &&
        DeepCollectionEquality().equals(other.companies,               companies)           &&
        DeepCollectionEquality().equals(other.companyUsers,            companyUsers)        &&
                                        other.email                 == email                &&
                                        other.interests             == interests            &&
                                        other.jobTitle              == jobTitle             &&
                                        other.legacyBarcode         == legacyBarcode        &&
        DeepCollectionEquality().equals(other.licenses,                licenses)            &&
                                        other.name                  == name                 &&
                                        other.phone                 == phone                &&
                                        other.primaryContactMethod  == primaryContactMethod &&
                                        other.profilePicture        == profilePicture       &&
                                        other.purchasingRole        == purchasingRole       &&
                                        other.qrCode                == qrCode               &&
                                        other.registrationType      == registrationType     &&
                                        other.status                == status               &&
        DeepCollectionEquality().equals(other.userRoles,               userRoles)           &&
                                        other.username              == username;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
                        id,
                        address,
         Object.hashAll(badges),
         Object.hashAll(companies),
         Object.hashAll(companyUsers),
                        email,
                        interests,
                        jobTitle,
                        legacyBarcode,
         Object.hashAll(licenses),
                        name,
                        phone,
                        primaryContactMethod,
                        profilePicture,
                        purchasingRole,
                        qrCode,
                        registrationType,
                        status,
         Object.hashAll(userRoles),
                        username
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: UserData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  UserDataInfo.id                  .jsonName  :  UserDataInfo.id                  .columnName):               id,

            (apiOrDatabase  ?  UserDataInfo.address             .jsonName  :  UserDataInfo.address             .columnName):   json.encode(address               .toJson(destination: destination)),
            (apiOrDatabase  ?  UserDataInfo.badges              .jsonName  :  UserDataInfo.badges              .columnName):   json.encode(badges                .map((registration) { return registration.toJson(destination: destination); }).toList()),
            (apiOrDatabase  ?  UserDataInfo.companies           .jsonName  :  UserDataInfo.companies           .columnName):   json.encode(companies             .map((company) { return company.toJson(destination: destination); }).toList()),
            (apiOrDatabase  ?  UserDataInfo.companyUsers        .jsonName  :  UserDataInfo.companyUsers        .columnName):   json.encode(companyUsers          .map((companyUser) { return companyUser.toJson(destination: destination); }).toList()),
            (apiOrDatabase  ?  UserDataInfo.email               .jsonName  :  UserDataInfo.email               .columnName):               email,
            (apiOrDatabase  ?  UserDataInfo.interests           .jsonName  :  UserDataInfo.interests           .columnName):               interests,
            (apiOrDatabase  ?  UserDataInfo.jobTitle            .jsonName  :  UserDataInfo.jobTitle            .columnName):               jobTitle,
            (apiOrDatabase  ?  UserDataInfo.legacyBarcode       .jsonName  :  UserDataInfo.legacyBarcode       .columnName):               legacyBarcode,
            (apiOrDatabase  ?  UserDataInfo.licenses            .jsonName  :  UserDataInfo.licenses            .columnName):   json.encode(licenses              .map((license) { return license.toJson(destination: destination); }).toList()),
            (apiOrDatabase  ?  UserDataInfo.name                .jsonName  :  UserDataInfo.name                .columnName):   json.encode(name                  .toJson(destination: destination)),
            (apiOrDatabase  ?  UserDataInfo.phone               .jsonName  :  UserDataInfo.phone               .columnName):   json.encode(phone                 .toJson(destination: destination)),
            (apiOrDatabase  ?  UserDataInfo.primaryContactMethod.jsonName  :  UserDataInfo.primaryContactMethod.columnName):               primaryContactMethod,
            (apiOrDatabase  ?  UserDataInfo.profilePicture      .jsonName  :  UserDataInfo.profilePicture      .columnName):               profilePicture,
            (apiOrDatabase  ?  UserDataInfo.purchasingRole      .jsonName  :  UserDataInfo.purchasingRole      .columnName):               purchasingRole,
            (apiOrDatabase  ?  UserDataInfo.qrCode              .jsonName  :  UserDataInfo.qrCode              .columnName):   json.encode(qrCode                .toJson(destination: destination)),
            (apiOrDatabase  ?  UserDataInfo.registrationType    .jsonName  :  UserDataInfo.registrationType    .columnName):               registrationType,
            (apiOrDatabase  ?  UserDataInfo.status              .jsonName  :  UserDataInfo.status              .columnName):               status,
            (apiOrDatabase  ?  UserDataInfo.userRoles           .jsonName  :  UserDataInfo.userRoles           .columnName):   json.encode(userRoles),
            (apiOrDatabase  ?  UserDataInfo.username            .jsonName  :  UserDataInfo.username            .columnName):               username,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> UserData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory UserData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions).
        final bool apiOrDatabase = (source == LocationEncoding.api);


        // Determine if the JSON data is a string or a map. Otherwise, throw an error.
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return UserData.empty(); }
        }


        return UserData(
            id:                             jsonAsMap[apiOrDatabase  ?  UserDataInfo.id                  .jsonName  :            UserDataInfo.id                  .columnName]     as String,

            address:   AddressData.fromJson(jsonAsMap[apiOrDatabase  ?  UserDataInfo.address             .jsonName  :            UserDataInfo.address             .columnName],   source: source),
            email:                          jsonAsMap[apiOrDatabase  ?  UserDataInfo.email               .jsonName  :            UserDataInfo.email               .columnName]    as String,
            interests:                      jsonAsMap[apiOrDatabase  ?  UserDataInfo.interests           .jsonName  :            UserDataInfo.interests           .columnName]    as String,
            jobTitle:              "",//         jsonAsMap[apiOrDatabase  ?  UserDataInfo.jobTitle            .jsonName  :            UserDataInfo.jobTitle            .columnName]    as String,
            legacyBarcode:                  jsonAsMap[apiOrDatabase  ?  UserDataInfo.legacyBarcode       .jsonName  :            UserDataInfo.legacyBarcode       .columnName]    as String?,
            name:      NameData   .fromJson(jsonAsMap[apiOrDatabase  ?  UserDataInfo.name                .jsonName  :            UserDataInfo.name                .columnName],   source: source),
            phone:     PhoneData  .fromJson(jsonAsMap[apiOrDatabase  ?  UserDataInfo.phone               .jsonName  :            UserDataInfo.phone               .columnName],   source: source),
            primaryContactMethod:           jsonAsMap[apiOrDatabase  ?  UserDataInfo.primaryContactMethod.jsonName  :            UserDataInfo.primaryContactMethod.columnName]    as String,
            purchasingRole:                 jsonAsMap[apiOrDatabase  ?  UserDataInfo.purchasingRole      .jsonName  :            UserDataInfo.purchasingRole      .columnName]    as String,
            qrCode:    QrCodeData.empty(), // QrCodeData .fromJson(jsonAsMap[apiOrDatabase  ?  UserDataInfo.qrCode              .jsonName  :            UserDataInfo.qrCode              .columnName],   source: source),
            registrationType:               jsonAsMap[apiOrDatabase  ?  UserDataInfo.registrationType    .jsonName  :            UserDataInfo.registrationType    .columnName]    as String,
            status:                         jsonAsMap[apiOrDatabase  ?  UserDataInfo.status              .jsonName  :            UserDataInfo.status              .columnName]    as String,
            username:                       jsonAsMap[apiOrDatabase  ?  UserDataInfo.username            .jsonName  :            UserDataInfo.username            .columnName]    as String,


            licenses: <SoftwareLicenseData>[],
            //  apiOrDatabase  ?  () {
            //     return <SoftwareLicenseData>[...(jsonAsMap[UserDataInfo.licenses.jsonName].map((license) => SoftwareLicenseData.fromJson(license, source: LocationEncoding.api)).toList())];
            // }()  :  () {
            //     List<dynamic> licensesAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[UserDataInfo.licenses.columnName]);
            //     return <SoftwareLicenseData>[...licensesAsDynamicList.map((license) => SoftwareLicenseData.fromJson(license, source: LocationEncoding.database))];
            // }(),


            profilePicture: "", // apiOrDatabase  ?  () {
            //     Map<String, dynamic> profilePicturesAsMap = jsonAsMap[UserDataInfo.profilePicture.jsonName];
            //     String largestPictureKey = profilePicturesAsMap.keys.toList().sorted().last.toString();

            //     String largestPictureUrl = profilePicturesAsMap[largestPictureKey].toString();

            //     largestPictureUrl = "https://www." + largestPictureUrl.replaceAll(RegExp(r"((http|https)\:(\/\/))|(\/*www\.)"), "");

            //     return largestPictureUrl;
            // }()  :  () {
            //     return jsonAsMap[UserDataInfo.profilePicture.columnName];
            // }(),


            badges: apiOrDatabase  ?  () {
                return <BadgeData>[...(jsonAsMap[UserDataInfo.badges.jsonName].map((registration) { return BadgeData.fromJson(registration, source: LocationEncoding.api); }).toList())];
            }()  :  () {
                List<dynamic> badgesAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[UserDataInfo.badges.columnName]);
                return <BadgeData>[...badgesAsDynamicList.map((registration) => BadgeData.fromJson(registration, source: LocationEncoding.database))];
            }(),


            companies: apiOrDatabase  ?  () {
                return <CompanyData>[...(jsonAsMap[UserDataInfo.companies.jsonName].map((company) { return CompanyData.fromJson(company, source: LocationEncoding.api); }).toList())];
            }()  :  () {
                List<dynamic> companiesAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[UserDataInfo.companies.columnName]);
                return <CompanyData>[...companiesAsDynamicList.map((company) => CompanyData.fromJson(company, source: LocationEncoding.database))];
            }(),


            companyUsers: apiOrDatabase  ?  () {
                return <CompanyUserData>[...(jsonAsMap[UserDataInfo.companyUsers.jsonName].map((companyUser) { return CompanyUserData.fromJson(companyUser, source: LocationEncoding.api); }).toList())];
            }()  :  () {
                List<dynamic> companyUsersAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[UserDataInfo.companyUsers.columnName]);
                return <CompanyUserData>[...companyUsersAsDynamicList.map((companyUser) => CompanyUserData.fromJson(companyUser, source: LocationEncoding.database))];

            }(),


            userRoles: [], // apiOrDatabase  ?  () {
            //     return <String>[...(jsonAsMap[UserDataInfo.userRoles.jsonName].map((role) => role.toString()).toList())];
            // }()  :  () {
            //     List<dynamic> userRolesAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[UserDataInfo.userRoles.columnName]);
            //     return userRolesAsDynamicList.map((role) => role.toString()).toList();
            // }()
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty UserData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory UserData.empty() {
        return UserData(
            id:                   "",
            address:              AddressData.empty(),
            badges:               <BadgeData>[],
            companies:            <CompanyData>[],
            companyUsers:         <CompanyUserData>[],
            email:                "",
            interests:            "",
            jobTitle:             "",
            licenses:             <SoftwareLicenseData>[],
            name:                 NameData.empty(),
            phone:                PhoneData.empty(),
            profilePicture:       "",
            primaryContactMethod: "email",
            purchasingRole:       "",
            qrCode:               QrCodeData.empty(),
            registrationType:     "",
            status:               "",
            userRoles:            <String>[],
            username:             ""
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Return a copy of the UserData object
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    UserData copy({
        String?                     id,

        AddressData?                address,
        List<BadgeData>?            badges,
        List<CompanyData>?          companies,
        List<CompanyUserData>?      companyUsers,
        String?                     email,
        String?                     interests,
        String?                     jobTitle,
        String?                     legacyBarcode,
        List<SoftwareLicenseData>?  licenses,
        NameData?                   name,
        PhoneData?                  phone,
        String?                     primaryContactMethod,
        String?                     profilePicture,
        String?                     purchasingRole,
        QrCodeData?                 qrCode,
        String?                     registrationType,
        String?                     status,
        List<String>?               userRoles,
        String?                     username           }) =>

        UserData(id:                   id                   ?? this.id,
                 address:              address              ?? this.address,
                 badges:               badges               ?? this.badges,
                 companies:            companies            ?? this.companies,
                 companyUsers:         companyUsers         ?? this.companyUsers,
                 email:                email                ?? this.email,
                 interests:            interests            ?? this.interests,
                 jobTitle:             jobTitle             ?? this.jobTitle,
                 legacyBarcode:        legacyBarcode        ?? this.legacyBarcode,
                 licenses:             licenses             ?? this.licenses,
                 name:                 name                 ?? this.name,
                 phone:                phone                ?? this.phone,
                 primaryContactMethod: primaryContactMethod ?? this.primaryContactMethod,
                 profilePicture:       profilePicture       ?? this.profilePicture,
                 purchasingRole:       purchasingRole       ?? this.purchasingRole,
                 qrCode:               qrCode               ?? this.qrCode,
                 registrationType:     registrationType     ?? this.registrationType,
                 status:               status               ?? this.status,
                 userRoles:            userRoles            ?? this.userRoles,
                 username:             username             ?? this.username,
        );
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum UserDataInfo {

    /* Property        | Column name              | JSON name                 | Display name              | Column type
     * ----------------|--------------------------|---------------------------|---------------------------|---------- */
    id(                  "id",                      "id",                       "ID",                       idType  ),
    address(             "address",                 "address",                  "Address",                  blobType),
    badges(              "badges",                  "badges",                   "Badges",                   blobType),
    companies(           "companies",               "companies",                "Companies",                blobType),
    companyUsers(        "company_users",           "company_users",            "Company Users",            "TEXT NOT NULL"),
    email(               "email",                   "user_email",               "Email",                    textType),
    interests(           "interests",               "interests",                "Interests",                textType),
    jobTitle(            "job_title",               "job_title",                "Title",                    textType),
    legacyBarcode(       "legacy_barcode",          "legacy_barcode",           "Legacy Barcode",           "TEXT"),
    licenses(            "licenses",                "licenses",                 "Licenses",                 blobType),
    name(                "name",                    "full_name",                "Name",                     blobType),
    phone(               "phone",                   "phone",                    "Phone",                    blobType),
    primaryContactMethod("primary_contact_method",  "primary_contact_method",   "Primary Contact Method",   textType),
    profilePicture(      "profile_picture",         "avatar_urls",              "Profile Picture",          blobType),
    purchasingRole(      "purchasing_role",         "purchasing_role",          "Purchasing Role",          textType),
    qrCode(              "qr_code",                 "qr_code",                  "QR Code",                  blobType),
    registrationType(    "registration_type",       "registration_type",        "Registration Type",        textType),
    status(              "status",                  "status",                   "Status",                   textType),
    userRoles(           "user_roles",              "user_roles",               "Roles",                    blobType),
    username(            "username",                "slug",                     "Username",                 textType);


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    static const String blobType = "BLOB NOT NULL";
    static const String idType   = "TEXT PRIMARY KEY";
    static const String intType  = "INTEGER NOT NULL";
    static const String textType = "TEXT NOT NULL";


    const UserDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return UserDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return UserDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return UserDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => UserData;
    static String get objectTypeName => "user";
    static String get tableName      => "users";

    static String get tableBuilder {

        final columns = UserDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}
