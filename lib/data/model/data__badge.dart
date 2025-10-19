/*
 * Badge Data
 *
 * Created by:  Blake Davis
 * Description: Badge data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/data__address.dart";
import "package:bmd_flutter_tools/data/model/data__booth.dart";
import "package:bmd_flutter_tools/data/model/data__name.dart";
import "package:bmd_flutter_tools/data/model/data__phone.dart";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";
import "package:collection/collection.dart";




/* ======================================================================================================================
 * MARK: Badge Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
 class BadgeData {

    String id;

    AddressData? inviteAddress;

    bool hasLeadScannerLicense,
         isExhibitor,
         isPresenter,
         isSponsor;

    List<BoothData> booths;

    List<String> seminarSessionsIds;

    NameData?   inviteName;

    PhoneData? invitePhone;

    String  qrCodeUrl,
            showId;

    String? booth,
            companyId,
            dateCreated,
            dateModified,
            exhibitorShowId,
            inviteEmail,
            inviteJobTitle,
            moveInEnd,
            moveInStart,
            moveOut,
            salesPersonId,
            status,
            transactionId,
            type,
            userId;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    BadgeData({  required this.id,
                               booths,
                 required this.companyId,
                 required this.dateCreated,
                          this.dateModified,
                          this.exhibitorShowId,
                               hasLeadScannerLicense,
                          this.inviteAddress,
                          this.inviteEmail,
                          this.inviteName,
                          this.inviteJobTitle,
                          this.invitePhone,
                 required this.isExhibitor,
                 required this.isPresenter,
                 required this.isSponsor,
                          this.moveInEnd,
                          this.moveInStart,
                          this.moveOut,
                 required this.qrCodeUrl,
                          this.salesPersonId,
                 required this.seminarSessionsIds,
                 required this.showId,
                 required this.status,
                          this.transactionId,
                 required this.type,
                 required this.userId,

    })  :   this.booths = booths ?? [],
            this.hasLeadScannerLicense = hasLeadScannerLicense ?? false;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
                                 return other is BadgeData                                      &&
                                        other.id                      == id                     &&
        DeepCollectionEquality().equals(other.booths,                    booths)                &&
                                        other.companyId               == companyId              &&
                                        other.dateCreated             == dateCreated            &&
                                        other.dateModified            == dateModified           &&
                                        other.exhibitorShowId         == exhibitorShowId        &&
                                        other.hasLeadScannerLicense   == hasLeadScannerLicense  &&
                                        other.inviteAddress           == inviteAddress          &&
                                        other.inviteEmail             == inviteEmail            &&
                                        other.inviteName              == inviteName             &&
                                        other.inviteJobTitle          == inviteJobTitle         &&
                                        other.invitePhone             == invitePhone            &&
                                        other.isExhibitor             == isExhibitor            &&
                                        other.isPresenter             == isPresenter            &&
                                        other.isSponsor               == isSponsor              &&
                                        other.moveInEnd               == moveInEnd              &&
                                        other.moveInStart             == moveInStart            &&
                                        other.moveOut                 == moveOut                &&
                                        other.qrCodeUrl               == qrCodeUrl              &&
                                        other.salesPersonId           == salesPersonId          &&
        DeepCollectionEquality().equals(other.seminarSessionsIds,        seminarSessionsIds)    &&
                                        other.showId                  == showId                 &&
                                        other.status                  == status                 &&
                                        other.transactionId           == transactionId          &&
                                        other.type                    == type                   &&
                                        other.userId                  == userId;

    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        id,
        booths,
        companyId,
        dateCreated,
        dateModified,
        exhibitorShowId,
        hasLeadScannerLicense,
        [
            inviteAddress,
            inviteEmail,
            inviteName,
            inviteJobTitle,
            invitePhone,
        ],
        [
            isExhibitor,
            isPresenter,
            isSponsor,
        ],
        moveInEnd,
        moveInStart,
        moveOut,
        qrCodeUrl,
        seminarSessionsIds,
        showId,
        status,
        transactionId,
        type,
        userId
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Type Label
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    String get typeLabel {

        if (type?.toLowerCase() == "attendee") {
            return "Attendee";

        } else {
            String label = "";

            if (isExhibitor) {
                label += (label.isNotEmpty ? "/" : "") + "Exhibitor";
            }
            if (isPresenter) {
                label += (label.isNotEmpty ? "/" : "") + "Presenter";
            }
            if (isSponsor) {
                label += (label.isNotEmpty ? "/" : "") + "Sponsor";
            }
            return label;
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: BadgeData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  BadgeDataInfo.id                     .jsonName  :  BadgeDataInfo.id                      .columnName):     id,
            (apiOrDatabase  ?  BadgeDataInfo.booths                 .jsonName  :  BadgeDataInfo.booths                  .columnName):     json.encode(booths.map((booth) => booth.toJson(destination: destination)).toList()),
            (apiOrDatabase  ?  BadgeDataInfo.companyId              .jsonName  :  BadgeDataInfo.companyId               .columnName):     companyId,
            (apiOrDatabase  ?  BadgeDataInfo.dateCreated            .jsonName  :  BadgeDataInfo.dateCreated             .columnName):     dateCreated,
            (apiOrDatabase  ?  BadgeDataInfo.dateModified           .jsonName  :  BadgeDataInfo.dateModified            .columnName):     dateModified,
            (apiOrDatabase  ?  BadgeDataInfo.exhibitorShowId        .jsonName  :  BadgeDataInfo.exhibitorShowId         .columnName):     exhibitorShowId,
            (apiOrDatabase  ?  BadgeDataInfo.hasLeadScannerLicense  .jsonName  :  BadgeDataInfo.hasLeadScannerLicense   .columnName):     (apiOrDatabase ? hasLeadScannerLicense : hasLeadScannerLicense.toInt()),
            (apiOrDatabase  ?  BadgeDataInfo.inviteAddress          .jsonName  :  BadgeDataInfo.inviteAddress           .columnName):     json.encode(inviteAddress?.toJson(destination: destination)),
            (apiOrDatabase  ?  BadgeDataInfo.inviteEmail            .jsonName  :  BadgeDataInfo.inviteEmail             .columnName):     inviteEmail,
            (apiOrDatabase  ?  BadgeDataInfo.inviteJobTitle         .jsonName  :  BadgeDataInfo.inviteJobTitle          .columnName):     inviteJobTitle,
            (apiOrDatabase  ?  BadgeDataInfo.inviteName             .jsonName  :  BadgeDataInfo.inviteName              .columnName):     json.encode(inviteName?.toJson(destination: destination)),
            (apiOrDatabase  ?  BadgeDataInfo.invitePhone            .jsonName  :  BadgeDataInfo.invitePhone             .columnName):     json.encode(invitePhone?.toJson(destination: destination)),
            (apiOrDatabase  ?  BadgeDataInfo.isExhibitor            .jsonName  :  BadgeDataInfo.isExhibitor             .columnName):     (apiOrDatabase ? isExhibitor : isExhibitor.toInt()),
            (apiOrDatabase  ?  BadgeDataInfo.isPresenter            .jsonName  :  BadgeDataInfo.isPresenter             .columnName):     (apiOrDatabase ? isPresenter : isPresenter.toInt()),
            (apiOrDatabase  ?  BadgeDataInfo.isSponsor              .jsonName  :  BadgeDataInfo.isSponsor               .columnName):     (apiOrDatabase ? isSponsor   : isSponsor  .toInt()),
            (apiOrDatabase  ?  BadgeDataInfo.moveInEnd              .jsonName  :  BadgeDataInfo.moveInEnd               .columnName):     moveInEnd,
            (apiOrDatabase  ?  BadgeDataInfo.moveInStart            .jsonName  :  BadgeDataInfo.moveInStart             .columnName):     moveInStart,
            (apiOrDatabase  ?  BadgeDataInfo.moveOut                .jsonName  :  BadgeDataInfo.moveOut                 .columnName):     moveOut,
            (apiOrDatabase  ?  BadgeDataInfo.qrCodeUrl              .jsonName  :  BadgeDataInfo.qrCodeUrl               .columnName):     qrCodeUrl,
            (apiOrDatabase  ?  BadgeDataInfo.salesPersonId          .jsonName  :  BadgeDataInfo.salesPersonId           .columnName):     salesPersonId,
            (apiOrDatabase  ?  BadgeDataInfo.seminarSessionsIds     .jsonName  :  BadgeDataInfo.seminarSessionsIds      .columnName):     json.encode(seminarSessionsIds),
            (apiOrDatabase  ?  BadgeDataInfo.showId                 .jsonName  :  BadgeDataInfo.showId                  .columnName):     showId,
            (apiOrDatabase  ?  BadgeDataInfo.status                 .jsonName  :  BadgeDataInfo.status                  .columnName):     status,
            (apiOrDatabase  ?  BadgeDataInfo.transactionId          .jsonName  :  BadgeDataInfo.transactionId           .columnName):     transactionId,
            (apiOrDatabase  ?  BadgeDataInfo.type                   .jsonName  :  BadgeDataInfo.type                    .columnName):     type,
            (apiOrDatabase  ?  BadgeDataInfo.userId                 .jsonName  :  BadgeDataInfo.userId                  .columnName):     userId,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> BadgeData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory BadgeData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

        // Create boolean value for the JSON's source (to shorten ternary expressions)
        final bool apiOrDatabase = (source == LocationEncoding.api);

        // Determine if the JSON data is a string or a map. Otherwise, throw an error
        Map<String?, dynamic> jsonAsMap = {};

        if (jsonAsDynamic is String) {
            jsonAsMap = json.decode(jsonAsDynamic);

        } else if  (jsonAsDynamic is Map<String?, dynamic>) {
            jsonAsMap = jsonAsDynamic;

        } else {
            logPrint("❌ JSON data is invalid, null, or an unexpected type (${jsonAsDynamic.runtimeType}).");
            if (defaultOnFailure) { return BadgeData.empty(); }
        }

        return BadgeData(
            id:                                 jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.id                    .jsonName  :      BadgeDataInfo.id                      .columnName]    .toString(),
            companyId:                          jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.companyId             .jsonName  :      BadgeDataInfo.companyId               .columnName]    .toString(),
            dateCreated:                        jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.dateCreated           .jsonName  :      BadgeDataInfo.dateCreated             .columnName]    .toString(),
            dateModified:                       jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.dateModified          .jsonName  :      BadgeDataInfo.dateModified            .columnName]    .toString(),
            exhibitorShowId:                    jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.exhibitorShowId       .jsonName  :      BadgeDataInfo.exhibitorShowId         .columnName]    .toString(),
            hasLeadScannerLicense:             (jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.hasLeadScannerLicense .jsonName  :      BadgeDataInfo.hasLeadScannerLicense   .columnName]    == (apiOrDatabase ? true : 1)),
            inviteEmail:                        jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.inviteEmail           .jsonName  :      BadgeDataInfo.inviteEmail             .columnName]    .toString(),
            inviteJobTitle:                     jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.inviteJobTitle        .jsonName  :      BadgeDataInfo.inviteJobTitle          .columnName]    .toString(),
            inviteName:       NameData.fromJson(jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.inviteName            .jsonName  :      BadgeDataInfo.inviteName              .columnName],   source: source),
            invitePhone:     PhoneData.fromJson(jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.invitePhone           .jsonName  :      BadgeDataInfo.invitePhone             .columnName],   source: source),
            isExhibitor:                       (jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.isExhibitor           .jsonName  :      BadgeDataInfo.isExhibitor             .columnName]    == (apiOrDatabase ? true : 1)),
            isPresenter:                       (jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.isPresenter           .jsonName  :      BadgeDataInfo.isPresenter             .columnName]    == (apiOrDatabase ? true : 1)),
            isSponsor:                         (jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.isSponsor             .jsonName  :      BadgeDataInfo.isSponsor               .columnName]    == (apiOrDatabase ? true : 1)),
            moveInEnd:                          jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.moveInEnd             .jsonName  :      BadgeDataInfo.moveInEnd               .columnName]    as String?,
            moveInStart:                        jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.moveInStart           .jsonName  :      BadgeDataInfo.moveInStart             .columnName]    as String?,
            moveOut:                            jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.moveOut               .jsonName  :      BadgeDataInfo.moveOut                 .columnName]    .toString(),
            qrCodeUrl:                          jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.qrCodeUrl             .jsonName  :      BadgeDataInfo.qrCodeUrl               .columnName]    .toString(),
            salesPersonId:                      jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.salesPersonId         .jsonName  :      BadgeDataInfo.salesPersonId           .columnName]    .toString(),
            showId:                             jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.showId                .jsonName  :      BadgeDataInfo.showId                  .columnName]    .toString(),
            status:                             jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.status                .jsonName  :      BadgeDataInfo.status                  .columnName]    .toString(),
            transactionId:                      jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.transactionId         .jsonName  :      BadgeDataInfo.transactionId           .columnName]    .toString(),
            type:                               jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.type                  .jsonName  :      BadgeDataInfo.type                    .columnName]    .toString(),
            userId:                             jsonAsMap[apiOrDatabase  ?  BadgeDataInfo.userId                .jsonName  :      BadgeDataInfo.userId                  .columnName]    .toString(),

            booths: apiOrDatabase  ?  () {
                return <BoothData>[...(jsonAsMap[BadgeDataInfo.booths.jsonName].map((booth) { return BoothData.fromJson(booth, source: LocationEncoding.api); }).toList())];
            }()  :  () {
                List<dynamic> boothsAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[BadgeDataInfo.booths.columnName]);
                return <BoothData>[...boothsAsDynamicList.map((booth) => BoothData.fromJson(booth, source: LocationEncoding.database))];
            }(),

            inviteAddress:
                AddressData(
                    city:   jsonAsMap["invite_city"] ?? "",
                    state:  jsonAsMap["invite_state"] ?? "",
                    street: jsonAsMap["invite_street"] ?? "",
                    zip:    (jsonAsMap["invite_zip"] ?? "").toString()
                ),

            seminarSessionsIds: () {
                final key = apiOrDatabase
                    ? BadgeDataInfo.seminarSessionsIds.jsonName
                    : BadgeDataInfo.seminarSessionsIds.columnName;

                final raw = jsonAsMap[key];

                // API sends a real list → ["id1","id2"]
                if (raw is List) {
                    return raw.map((e) => e.toString()).toList();
                }

                // DB stores a JSON string → '["id1","id2"]'
                if (raw is String && raw.trim().isNotEmpty) {
                    try {
                        final decoded = json.decode(raw);
                        if (decoded is List) {
                            return decoded.map((e) => e.toString()).toList();
                        }
                    } catch (error) { logPrint("❌ ${error.toString()}"); }
                }

                return <String>[];
            }(),
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty BadgeData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory BadgeData.empty() {
        return BadgeData(
            id:                 "",
            companyId:          "",
            dateCreated:        "0",
            isExhibitor:        false,
            isPresenter:        false,
            isSponsor:          false,
            qrCodeUrl:          "",
            seminarSessionsIds: [],
            showId:             "",
            status:             "",
            type:               "attendee",
            userId:             "",
        );
    }
 }




/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum BadgeDataInfo {

    /* Property         | Column name               | JSON name                 | Display name              | Column type
     * -----------------|---------------------------|---------------------------|---------------------------|---------- */
    id(                   "id",                       "id",                       "ID",                       "TEXT PRIMARY KEY"),
    booths(               "booths",                   "booths",                   "Booths",                   "BLOB"),
    companyId(            "company_id",               "company_id",               "Company ID",               "TEXT NOT NULL"),
    dateCreated(          "date_created",             "created_at",               "Date Created",             "TEXT NOT NULL"),
    dateModified(         "date_modified",            "updated_at",               "Date Modified",            "TEXT NOT NULL"),
    exhibitorShowId(      "exhibitor_show_id",        "exhibitor_show_id",        "Exhibitor Show ID",        "TEXT"),
    hasLeadScannerLicense("has_lead_scanner_license", "has_lead_scanner_license", "Has Lead Scanner License", "INTEGER NOT NULL"),
    inviteAddress(        "invite_address",           "invite_address",           "Address",                  "BLOB"),
    inviteEmail(          "invite_email",             "invite_email",             "Email",                    "TEXT"),
    inviteJobTitle(       "invite_job_title",         "invite_job_title",         "Job Title",                "TEXT"),
    inviteName(           "invite_name",              "invite_name",              "Name",                     "BLOB"),
    invitePhone(          "invite_phone",             "invite_phone",             "Phone",                    "BLOB"),
    isExhibitor(          "is_exhibitor",             "is_exhibitor",             "Exhibitor",                "INTEGER NOT NULL"),
    isPresenter(          "is_presenter",             "is_presenter",             "Presenter",                "INTEGER NOT NULL"),
    isSponsor(            "is_sponsor",               "is_sponsor",               "Sponsor",                  "INTEGER NOT NULL"),
    moveInStart(          "move_in_start",            "move_in_start",            "Move In Start",            "TEXT"),
    moveInEnd(            "move_in_end",              "move_in_end",              "Move In End",              "TEXT"),
    moveOut(              "move_out",                 "move_out",                 "Move Out",                 "TEXT NOT NULL"),
    qrCodeUrl(            "qr_code_url",              "qr_code_image_path",       "QR Code URL",              "TEXT NOT NULL"),
    salesPersonId(        "sales_person_id",          "sales_person_id",          "Sales Person ID",          "TEXT NOT NULL"),
    seminarSessionsIds(   "seminar_sessions_ids",     "seminar_sessions_ids",     "Seminar Sessions IDs",     "BLOB NOT NULL"),
    showId(               "show_id",                  "show_id",                  "Show ID",                  "TEXT NOT NULL"),
    status(               "status",                   "badge_status",             "Status",                   "TEXT NOT NULL"),
    transactionId(        "transaction_id",           "transaction_id",           "Transaction ID",           "INTEGER NOT NULL"),
    type(                 "type",                     "badge_type",               "Type",                     "TEXT NOT NULL"),
    userId(               "user_id",                  "user_id",                  "User ID",                  "TEXT NOT NULL");


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;


    const BadgeDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return BadgeDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return BadgeDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return BadgeDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => BadgeData;
    static String get objectTypeName => "badge";
    static String get tableName      => "badges";

    static String get tableBuilder {

        final columns = BadgeDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}
