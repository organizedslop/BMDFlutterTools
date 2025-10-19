/*
 * User Note Data
 *
 * Created by:  Blake Davis
 * Description: User note data model
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:convert";

import "package:bmd_flutter_tools/data/model/enum__location_encoding.dart";
import "package:bmd_flutter_tools/utilities/utilities__print.dart";




/* ======================================================================================================================
 * MARK: User Note Data Model
 * ------------------------------------------------------------------------------------------------------------------ */
class UserNoteData {

    String     id;

    String? dateDeleted,
            dateModified,
            slug;

    String  createdBy,
            dateCreated,
            noteBody,
            recipientId;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Constructor
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    UserNoteData({ required this.id,
                   required this.createdBy,
                   required this.dateCreated,
                            this.dateDeleted,
                            this.dateModified,
                   required this.noteBody,
                   required this.recipientId,
                            this.slug
    });




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: == Operator Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    bool operator ==(Object other) {
        return other is UserNoteData                &&
               other.id             == id           &&
               other.dateCreated    == dateCreated  &&
               other.dateDeleted    == dateDeleted  &&
               other.dateModified   == dateModified &&
               other.noteBody       == noteBody     &&
               other.recipientId    == recipientId  &&
               other.slug           == slug;
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: HashCode Override
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    int get hashCode => Object.hash(
        id,
        createdBy,
        dateCreated,
        dateDeleted,
        dateModified,
        noteBody,
        recipientId,
        slug,
    );




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: UserNoteData -> JSON
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Map<String, dynamic> toJson({ required LocationEncoding destination }) {

        // Create boolean value for the JSON's destination (to shorten ternary expressions)
        final bool apiOrDatabase = (destination == LocationEncoding.api);

        return {
            (apiOrDatabase  ?  UserNoteDataInfo.id          .jsonName  :  UserNoteDataInfo.id          .columnName):     id,

            (apiOrDatabase  ?  UserNoteDataInfo.createdBy   .jsonName  :  UserNoteDataInfo.createdBy   .columnName):     createdBy,
            (apiOrDatabase  ?  UserNoteDataInfo.dateCreated .jsonName  :  UserNoteDataInfo.dateCreated .columnName):     dateCreated,
            (apiOrDatabase  ?  UserNoteDataInfo.dateDeleted .jsonName  :  UserNoteDataInfo.dateDeleted .columnName):     dateDeleted,
            (apiOrDatabase  ?  UserNoteDataInfo.dateModified.jsonName  :  UserNoteDataInfo.dateModified.columnName):     dateModified,
            (apiOrDatabase  ?  UserNoteDataInfo.noteBody    .jsonName  :  UserNoteDataInfo.noteBody    .columnName):     noteBody,
            (apiOrDatabase  ?  UserNoteDataInfo.recipientId .jsonName  :  UserNoteDataInfo.recipientId .columnName):     recipientId,
            (apiOrDatabase  ?  UserNoteDataInfo.slug        .jsonName  :  UserNoteDataInfo.slug        .columnName):     slug,
        };
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: JSON -> UserNoteData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory UserNoteData.fromJson(dynamic jsonAsDynamic, { required LocationEncoding source, bool defaultOnFailure = true }) {

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
            if (defaultOnFailure) { return UserNoteData.empty(); }
        }

        return UserNoteData(
            id:             jsonAsMap[apiOrDatabase  ?  UserNoteDataInfo.id          .jsonName  :       UserNoteDataInfo.id          .columnName]    as String,

            createdBy:      jsonAsMap[apiOrDatabase  ?  UserNoteDataInfo.createdBy   .jsonName  :       UserNoteDataInfo.createdBy   .columnName]    as String,
            dateCreated:    jsonAsMap[apiOrDatabase  ?  UserNoteDataInfo.dateCreated .jsonName  :       UserNoteDataInfo.dateCreated .columnName]    as String,
            dateDeleted:    jsonAsMap[apiOrDatabase  ?  UserNoteDataInfo.dateDeleted .jsonName  :       UserNoteDataInfo.dateDeleted .columnName]    as String?,
            dateModified:   jsonAsMap[apiOrDatabase  ?  UserNoteDataInfo.dateModified.jsonName  :       UserNoteDataInfo.dateModified.columnName]    as String?,
            noteBody:       jsonAsMap[apiOrDatabase  ?  UserNoteDataInfo.noteBody    .jsonName  :       UserNoteDataInfo.noteBody    .columnName]    as String,
            recipientId:    jsonAsMap[apiOrDatabase  ?  UserNoteDataInfo.recipientId .jsonName  :       UserNoteDataInfo.recipientId .columnName]    as String,
            slug:           jsonAsMap[apiOrDatabase  ?  UserNoteDataInfo.slug        .jsonName  :       UserNoteDataInfo.slug        .columnName]    as String?,
        );
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Default/Empty UserNoteData
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    factory UserNoteData.empty() {
        return UserNoteData(
            id:          "",
            createdBy:   "",
            dateCreated: "",
            noteBody:    "",
            recipientId: "",
        );
    }
}




/* ======================================================================================================================
 * MARK: Object & Table Info
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
 enum UserNoteDataInfo {

    id(          "id",              "id",               "ID",               "TEXT PRIMARY KEY"),
    createdBy(   "created_by",      "user_id",          "Created by",       "TEXT NOT NULL"),
    dateCreated( "date_created",    "created_at",       "Date Created",     "TEXT NOT NULL"),
    dateDeleted( "date_deleted",    "deleted_at",       "Date Deleted",     "TEXT"),
    dateModified("date_modified",   "updated_at",       "Date Modified",    "TEXT"),
    noteBody(    "note_body",       "comment",          "Note Body",        "TEXT NOT NULL"),
    recipientId( "recipient_id",    "subject_id",       "Recipient ID",     "TEXT NOT NULL"),
    slug(        "slug",            "slug",             "Slug",             "TEXT");


    final String columnName;
    final String columnType;
    final String displayName;
    final String jsonName;

    static const String blobType = "BLOB NOT NULL";
    static const String idType   = "TEXT PRIMARY KEY";
    static const String textType = "TEXT NOT NULL";


    const UserNoteDataInfo(this.columnName, this.jsonName, this.displayName, this.columnType);


    static List<String> get columnNameValues {
        return UserNoteDataInfo.values.map((value) { return value.columnName; }).toList();
    }
    static List<String> get displayNameValues {
        return UserNoteDataInfo.values.map((value) { return value.displayName; }).toList();
    }
    static List<String> get jsonNameValues {
        return UserNoteDataInfo.values.map((value) { return value.jsonName; }).toList();
    }


    static Type   get objectType     => UserNoteData;
    static String get objectTypeName => "user_note";  // TODO: Change this to camelCase for consistency
    static String get tableName      => "user_notes";

    static String get tableBuilder {

        final columns = UserNoteDataInfo.values
            .map((e) => "${e.columnName} ${e.columnType}")
            .join(", ");

        return "CREATE TABLE IF NOT EXISTS $tableName ($columns)";
    }
}