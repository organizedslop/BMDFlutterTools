/*
 * User Note Panel
 *
 * Created by:  Blake Davis
 * Description: A widget for displaying and editing User Notes
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_database.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/data/model/data__user_note.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/utilities/theme_utilities.dart";
import "package:bmd_flutter_tools/widgets/components/gform_field.dart";
import "package:bmd_flutter_tools/services/connection_retry_service.dart";

import "package:flutter/material.dart";
import "package:flutter_sficon/flutter_sficon.dart";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";




/* ======================================================================================================================
 * MARK: User Note Panel
 * ------------------------------------------------------------------------------------------------------------------ */
class UserNotePanel extends ConsumerStatefulWidget {

    final UserNoteData userNote;

    final Function?    onDelete;


    const UserNotePanel({ super.key,
                  required this.userNote,
                           this.onDelete  });


    @override
    ConsumerState<UserNotePanel> createState() => _UserNoteState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _UserNoteState extends ConsumerState<UserNotePanel> {

    late TextEditingController textEditingController;

    bool isDeleting = false,
         isEditing  = false,
         isSaving   = false;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();
        textEditingController = TextEditingController(text: widget.userNote.noteBody);
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {
        textEditingController.dispose();
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        final isPendingSync = widget.userNote.slug == ConnectionRetryService.pendingConnectionNoteSlug;

        return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child:   Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: beColorScheme.background.secondary),
                child: Padding(
                    padding: EdgeInsets.only(top: 8, right: 12, bottom: 16, left: 12),
                    child:   Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                           Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                   Stack(
                                       children: [
                                           Text(DateFormat().format(DateTime.parse(widget.userNote.dateCreated)), style: beTextTheme.captionPrimary),
                                           (ref.read(isDebuggingProvider)) ? Transform.translate(
                                               offset: Offset(0, -10),
                                               child:  SelectableText(widget.userNote.id.toString(), style: beTextTheme.captionSecondary.merge(TextStyle(color: beColorScheme.text.debug))
                                           )) : null

                                       ].nonNulls.toList()
                                   ),
                                    if (isPendingSync)
                                      Row(
                                        spacing: 6,
                                        children: [
                                            SFIcon(
                                              SFIcons.sf_icloud_slash,
                                              color: BeColorSwatch.orange,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            Text(
                                              'Pending sync',
                                              style: beTextTheme.captionPrimary.copyWith(
                                                color: BeColorSwatch.orange,
                                                fontWeight: FontWeight.bold,
                                                height: 0,
                                              ),
                                            ),
                                          ],
                                        ),
                                    const SizedBox(width: 12),

                                    // Save button
                                    InkWell(
                                        onTap: () {
                                            setState(() {
                                                logPrint("🔄 Saving user note ${widget.userNote.id}...");

                                                isSaving  = true;
                                                isEditing = false;

                                                UserNoteData newUserNote = widget.userNote;
                                                newUserNote.noteBody     = textEditingController.text;

                                                AppDatabase.instance.write(newUserNote);
                                                ApiClient.instance.saveUserNote(userNote: newUserNote).then((_) {
                                                    setState(() {
                                                        isSaving = false;
                                                    });
                                                });
                                            });
                                        },
                                        child: (isDeleting || isEditing || isSaving) ? Row(
                                            children: [
                                                // Display a loading indicator if deleting or saving
                                                (isDeleting || isSaving) ? Padding(padding: EdgeInsets.only(right: 8), child: SizedBox(height: 16, width: 16, child: Center(child: CircularProgressIndicator(color: BeColorSwatch.gray, strokeWidth: 3.333)))) :
                                                                           const SizedBox.shrink(),

                                                // Show the appropriate message given the current action
                                                Text((isDeleting ? "Deleting..." :
                                                                   isSaving      ? "Saving..." :
                                                                                   "Save").toUpperCase(), style: beTextTheme.captionPrimary.merge(TextStyle(color: (isDeleting || isSaving) ? beColorScheme.text.tertiary : beColorScheme.text.accent)))
                                            ]
                                        ) : const SizedBox.shrink()
                                    ),

                                    // Edit/cancel button
                                    // (isDeleting || isSaving) ? null : InkWell(
                                    //     onTap: () {
                                    //         setState(() {
                                    //             final bool editingStatus = !isEditing;
                                    //             logPrint("${(editingStatus ? "Editing" : "Cancelled editing")} user note ${widget.userNote.id}.");
                                    //             isEditing = editingStatus;
                                    //         });
                                    //     },
                                    //     child: Text((isEditing ? "Cancel" : "Edit").toUpperCase(), style: beTextTheme.captionPrimary.merge(TextStyle(color: beColorScheme.text.accent))),
                                    // ),

                                    // Delete button
                                    (isDeleting || isSaving) ? null : InkWell(
                                        onTap: () {
                                            setState(() {
                                                logPrint("🔄 Deleting user note ${widget.userNote.id}...");

                                                isDeleting = true;
                                                isEditing  = false;

                                                ApiClient.instance.deleteUserNote(id: widget.userNote.id).then((_) {
                                                    setState(() {
                                                        isDeleting = false;
                                                    });

                                                    if (widget.onDelete != null) {
                                                        logPrint("ℹ️  Called onDelete");
                                                        widget.onDelete!();
                                                    }
                                                });
                                            });
                                        },
                                        child: Text("Delete".toUpperCase(), style: beTextTheme.captionPrimary.merge(TextStyle(color: beColorScheme.text.accent2)))
                                    )
                                ].nonNulls.toList()
                            ),

                            isEditing ? TextFormField(
                                autofocus:    true,
                                controller:   textEditingController,
                                decoration:   gfieldInputDecoration.copyWith(hintText: "Type your note here.", hintStyle: TextStyle(color: BeColorSwatch.gray)),
                                maxLines:     4,

                            ) : SelectableText(widget.userNote.noteBody, style: beTextTheme.bodyPrimary),
                        ]
                    )
                )
            )
        );
    }
}
