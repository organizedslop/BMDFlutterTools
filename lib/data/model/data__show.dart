/*
 * Show Data Model
 *
 * Created by:  Blake Davis
 * Description: Show (expo) data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";
import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/data/model/data__event_time.dart";
import "package:bmd_flutter_tools/data/model/data__image.dart";
import "package:bmd_flutter_tools/data/model/data__venue.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";
import "package:collection/collection.dart";




/* ======================================================================================================================
 * MARK: Show Data Model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
class ShowData {

    String id;

    EventTimeData dates;

    List<String> classes;

    Map<String, Map<String, String>>? faqs;

    String  title;

    String? advertisingMediaKit,
            banner,
            boothGalleryUrl,
            customEmailCampaignUrl,
            customTicketsUrl,
            exhibitorServiceManual,
            floorplan,
            legacySeriesShortName,
            magazine,
            magazineThumbnailUrl,
            moveOutEnd,
            moveOutStart,
            showFlyer,
            socialMediaPromoUrl;

    VenueData venue;


    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    ShowData({  required this.id,
                         this.advertisingMediaKit,
                         this.banner,
                         this.boothGalleryUrl,
                required this.classes,
                         this.customEmailCampaignUrl,
                         this.customTicketsUrl,
                required this.dates,
                         this.exhibitorServiceManual,
                         this.faqs,
                         this.floorplan,
                         this.legacySeriesShortName,
                         this.magazine,
                         this.magazineThumbnailUrl,
                         this.moveOutEnd,
                         this.moveOutStart,
                         this.showFlyer,
                         this.socialMediaPromoUrl,
                required this.title,
                required this.venue,
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
                                 return other is ShowData                                           &&
                                        other.id                     == id                          &&
                                        other.advertisingMediaKit    == advertisingMediaKit         &&
                                        other.banner                 == banner                      &&
                                        other.boothGalleryUrl        == boothGalleryUrl             &&
        DeepCollectionEquality().equals(other.classes,                  classes)                    &&
                                        other.customEmailCampaignUrl == customEmailCampaignUrl      &&
                                        other.customTicketsUrl       == customTicketsUrl            &&
                                        other.dates                  == dates                       &&
                                        other.exhibitorServiceManual == exhibitorServiceManual      &&
        DeepCollectionEquality().equals(other.faqs,                     faqs)                       &&
                                        other.floorplan              == floorplan                   &&
                                        other.legacySeriesShortName  == legacySeriesShortName       &&
                                        other.magazine               == magazine                    &&
                                        other.magazineThumbnailUrl   == magazineThumbnailUrl        &&
                                        other.moveOutEnd             == moveOutEnd                  &&
                                        other.moveOutStart           == moveOutStart                &&
                                        other.showFlyer              == showFlyer                   &&
                                        other.socialMediaPromoUrl    == socialMediaPromoUrl         &&
                                        other.title                  == title                       &&
                                        other.venue                  == venue;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
                        id,
                        advertisingMediaKit,
                        banner,
                        boothGalleryUrl,
         Object.hashAll(classes),
                        customEmailCampaignUrl,
                        customTicketsUrl,
                        dates,
                        exhibitorServiceManual,
         DeepCollectionEquality().hash(faqs),
                        floorplan,
                        legacySeriesShortName,
                        magazine,
                        magazineThumbnailUrl,
                        moveOutEnd,
                        moveOutStart,
                        showFlyer,
                        socialMediaPromoUrl,
                        title,
                        venue,
    );








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: ShowData -> JSON
     */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {
        /**
         *  Create boolean value for the JSON's destination (to shorten ternary expressions).
         */
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  ShowDataInfo.id                      .jsonName  :  ShowDataInfo.id                       .columnName):                id,

            (apiOrDatabase  ?  ShowDataInfo.advertisingMediaKit     .jsonName  :  ShowDataInfo.advertisingMediaKit      .columnName):                advertisingMediaKit,
            (apiOrDatabase  ?  ShowDataInfo.banner                  .jsonName  :  ShowDataInfo.banner                   .columnName):                banner,
            (apiOrDatabase  ?  ShowDataInfo.boothGalleryUrl         .jsonName  :  ShowDataInfo.boothGalleryUrl          .columnName):                boothGalleryUrl,
            (apiOrDatabase  ?  ShowDataInfo.classes                 .jsonName  :  ShowDataInfo.classes                  .columnName):    json.encode(classes),
            (apiOrDatabase  ?  ShowDataInfo.customEmailCampaignUrl  .jsonName  :  ShowDataInfo.customEmailCampaignUrl   .columnName):                customEmailCampaignUrl,
            (apiOrDatabase  ?  ShowDataInfo.customTicketsUrl        .jsonName  :  ShowDataInfo.customTicketsUrl         .columnName):                customTicketsUrl,
            (apiOrDatabase  ?  ShowDataInfo.dates                   .jsonName  :  ShowDataInfo.dates                    .columnName):    json.encode(dates       .toJson(destination: destination)),
            (apiOrDatabase  ?  ShowDataInfo.exhibitorServiceManual  .jsonName  :  ShowDataInfo.exhibitorServiceManual   .columnName):                exhibitorServiceManual,
            (apiOrDatabase  ?  ShowDataInfo.faqs                    .jsonName  :  ShowDataInfo.faqs                     .columnName):    json.encode(faqs),
            (apiOrDatabase  ?  ShowDataInfo.floorplan               .jsonName  :  ShowDataInfo.floorplan                .columnName):                floorplan,
            (apiOrDatabase  ?  ShowDataInfo.legacySeriesShortName   .jsonName  :  ShowDataInfo.legacySeriesShortName    .columnName):                legacySeriesShortName,
            (apiOrDatabase  ?  ShowDataInfo.magazine                .jsonName  :  ShowDataInfo.magazine                 .columnName):                magazine,
            (apiOrDatabase  ?  ShowDataInfo.magazineThumbnailUrl    .jsonName  :  ShowDataInfo.magazineThumbnailUrl     .columnName):                magazineThumbnailUrl,
            (apiOrDatabase  ?  ShowDataInfo.moveOutEnd              .jsonName  :  ShowDataInfo.moveOutEnd               .columnName):                moveOutEnd,
            (apiOrDatabase  ?  ShowDataInfo.moveOutStart            .jsonName  :  ShowDataInfo.moveOutStart             .columnName):                moveOutStart,
            (apiOrDatabase  ?  ShowDataInfo.showFlyer               .jsonName  :  ShowDataInfo.showFlyer                .columnName):                showFlyer,
            (apiOrDatabase  ?  ShowDataInfo.socialMediaPromoUrl     .jsonName  :  ShowDataInfo.socialMediaPromoUrl      .columnName):                socialMediaPromoUrl,
            (apiOrDatabase  ?  ShowDataInfo.title                   .jsonName  :  ShowDataInfo.title                    .columnName):                title,
            (apiOrDatabase  ?  ShowDataInfo.venue                   .jsonName  :  ShowDataInfo.venue                    .columnName):    json.encode(venue       .toJson(destination: destination)),
        };
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * MARK: JSON -> ShowData
     */
    factory ShowData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {
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
            if (defaultOnFailure) { return ShowData.empty(); }
        }


        return ShowData(
            id:                             jsonAsMap[apiOrDatabase  ?  ShowDataInfo.id                     .jsonName  :      ShowDataInfo.id                       .columnName]    as String,

            advertisingMediaKit:            jsonAsMap[apiOrDatabase  ?  ShowDataInfo.advertisingMediaKit    .jsonName  :      ShowDataInfo.advertisingMediaKit      .columnName]    as String?,
            banner:                         jsonAsMap[apiOrDatabase  ?  ShowDataInfo.banner                 .jsonName  :      ShowDataInfo.banner                   .columnName]    as String?,
            boothGalleryUrl:                jsonAsMap[apiOrDatabase  ?  ShowDataInfo.boothGalleryUrl        .jsonName  :      ShowDataInfo.boothGalleryUrl          .columnName]    as String?,
            customEmailCampaignUrl:         jsonAsMap[apiOrDatabase  ?  ShowDataInfo.customEmailCampaignUrl .jsonName  :      ShowDataInfo.customEmailCampaignUrl   .columnName]    as String?,
            customTicketsUrl:               jsonAsMap[apiOrDatabase  ?  ShowDataInfo.customTicketsUrl       .jsonName  :      ShowDataInfo.customTicketsUrl         .columnName]    as String?,
            dates:   EventTimeData.fromJson(jsonAsMap[apiOrDatabase  ?  ShowDataInfo.dates                  .jsonName  :      ShowDataInfo.dates                    .columnName],   source: source),
            exhibitorServiceManual:         jsonAsMap[apiOrDatabase  ?  ShowDataInfo.exhibitorServiceManual .jsonName  :      ShowDataInfo.exhibitorServiceManual   .columnName]    as String?,
            floorplan:                      jsonAsMap[apiOrDatabase  ?  ShowDataInfo.floorplan              .jsonName  :      ShowDataInfo.floorplan                .columnName]    as String?,
            legacySeriesShortName:          jsonAsMap[apiOrDatabase  ?  ShowDataInfo.legacySeriesShortName  .jsonName  :      ShowDataInfo.legacySeriesShortName    .columnName]    as String?,
            magazine:                       jsonAsMap[apiOrDatabase  ?  ShowDataInfo.magazine               .jsonName  :      ShowDataInfo.magazine                 .columnName]    as String?,
            magazineThumbnailUrl:           jsonAsMap[apiOrDatabase  ?  ShowDataInfo.magazineThumbnailUrl   .jsonName  :      ShowDataInfo.magazineThumbnailUrl     .columnName]    as String?,
            moveOutEnd:                     jsonAsMap[apiOrDatabase  ?  ShowDataInfo.moveOutEnd             .jsonName  :      ShowDataInfo.moveOutEnd               .columnName]    as String?,
            moveOutStart:                   jsonAsMap[apiOrDatabase  ?  ShowDataInfo.moveOutStart           .jsonName  :      ShowDataInfo.moveOutStart             .columnName]    as String?,
            showFlyer:                      jsonAsMap[apiOrDatabase  ?  ShowDataInfo.showFlyer              .jsonName  :      ShowDataInfo.showFlyer                .columnName]    as String?,
            socialMediaPromoUrl:            jsonAsMap[apiOrDatabase  ?  ShowDataInfo.socialMediaPromoUrl    .jsonName  :      ShowDataInfo.socialMediaPromoUrl      .columnName]    as String?,
            title:                          jsonAsMap[apiOrDatabase  ?  ShowDataInfo.title                  .jsonName  :      ShowDataInfo.title                    .columnName]    as String,
            venue:       VenueData.fromJson(jsonAsMap[apiOrDatabase  ?  ShowDataInfo.venue                  .jsonName  :      ShowDataInfo.venue                    .columnName],   source: source),
            classes: <String>[],
            //  apiOrDatabase  ?  () {
            //     return <String>[...(jsonAsMap[ShowDataInfo.classes.jsonName].map((classId) => classId.toString()).toList())];
            // }()  :  () {
            //     List<dynamic> classesAsDynamicList = json.decodeTo(List.empty, dataAsString: jsonAsMap[ShowDataInfo.classes.columnName]);
            //     return classesAsDynamicList.map((classId) => classId.toString()).toList();
            // }(),
            faqs: <String, Map<String, String>>{} //(() {
            //     final raw = jsonAsMap[apiOrDatabase ? ShowDataInfo.faqs.jsonName : ShowDataInfo.faqs.columnName];
            //     if (raw == null) {
            //         return null;
            //     }
            //     final Map<String, dynamic> decoded = raw is String ? json.decode(raw) as Map<String, dynamic> : raw as Map<String, dynamic>;

            //     return decoded.map((k, v) => MapEntry(k, (v as Map).map((kk, vv) => MapEntry(kk as String, vv as String))));
            // })(),
        );
    }








    /* -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     *   MARK: Default/Empty ShowData
     */
    factory ShowData.empty() {
        return ShowData(
            id:         "",
            classes:    <String>[],
            dates:      EventTimeData.empty(),
            title:      "",
            venue:      VenueData.empty(),
        );
    }
}








/* ======================================================================================================================
 * MARK: Object & Table Info
 * ------------------------------------------------------------------------------------------------------------------ */
enum ShowDataInfo {

    /* Property          | Column name                | JSON name                 | Display name               | Column type
     * ------------------|----------------------------|---------------------------|----------------------------|---------- */
    id(                    "id",                        "id",                       "ID",                        "TEXT PRIMARY KEY"),
    advertisingMediaKit(   "advertising_media_kit",     "advertising_media_kit",    "Advertising Media Kit",     "TEXT"),
    banner(                "banner",                    "banner",                   "Banner",                    "TEXT"),
    boothGalleryUrl(       "booth_gallery_url",         "booth_gallery_url",        "Booth Gallery URL",         "TEXT"),
    classes(               "classes",                   "classes",                  "Classes",                   "BLOB NOT NULL"),
    customEmailCampaignUrl("custom_email_campaign_url", "custom_email_campaign_url","Custom Email Campaign URL", "TEXT"),
    customTicketsUrl(      "custom_tickets_url",        "custom_tickets_url",       "Custom Tickets URL",        "TEXT"),
    dates(                 "dates",                     "dates",                    "Dates",                     "BLOB NOT NULL"),
    exhibitorServiceManual("exhibitor_service_manual",  "exhibitor_service_manual", "Exhibitor Service Manual",  "TEXT"),
    faqs(                  "faqs",                      "faqs",                     "FAQs",                      "BLOB"),
    floorplan(             "floorplan",                 "floorplan",                "Floorplan",                 "TEXT"),
    legacySeriesShortName( "legacy_series_short_name",  "legacy_series_short_name", "LegacySeriesShortName",     "TEXT"),
    magazine(              "magazine",                  "magazine",                 "Magazine",                  "TEXT"),
    magazineThumbnailUrl(  "magazine_thumbnail_url",    "magazine_thumbnail_url",   "Magazine Thumbnail URL",    "TEXT"),
    moveOutEnd(            "move_out_end",              "move_out_end",             "Move Out End",              "TEXT"),
    moveOutStart(          "move_out_start",            "move_out_start",           "Move Out Start",            "TEXT"),
    showFlyer(             "show_flyer",                "show_flyer",               "Show Flyer",                "TEXT"),
    socialMediaPromoUrl(   "social_media_promo_url",    "social_media_promo_url",   "Social Media Promo URL",    "TEXT"),
    title(                 "title",                     "title",                    "Title",                     "TEXT NOT NULL"),
    venue(                 "venue",                     "venue",                    "Venue",                     "BLOB NOT NULL");


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    const ShowDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return ShowDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return ShowDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return ShowDataInfo.values.map((value) { return value.jsonName; }).toList();
    }

    static Type   get objectType     => ShowData;
    static String get objectTypeName => "show";
    static String get tableName      => "shows";

    static String get tableBuilder {

        final columns = ShowDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}