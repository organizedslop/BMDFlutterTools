/*
 * Invite Guests Modal
 *
 * Created by:  Blake Davis
 * Description: A widget which displays a modal prompt to invite guests to a show
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";




/* ======================================================================================================================
 * MARK: Invite Modal
 * ------------------------------------------------------------------------------------------------------------------ */
class InviteModal extends ConsumerStatefulWidget {

    final String text;

    InviteModal({ super.key,
                   this.text = "" });

    @override
    ConsumerState<InviteModal> createState() => _InviteModalState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _InviteModalState extends ConsumerState<InviteModal> {

    late final String text;

    bool isSubmitting = false;

    final TextEditingController _textEditingController = TextEditingController();




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        text = widget.text;

        showSystemUiOverlays();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    dispose() {
        _textEditingController.dispose();
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        return Dialog(
            child: Padding(
                padding: EdgeInsets.all(24),
                child:   Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment:  MainAxisAlignment.center,
                    mainAxisSize:       MainAxisSize.min,
                    children:           [
                        Text("Invite a guest to attend", style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 16),

                        formFieldLabel(labelText: "Email Address"),

                        TextFormField(
                            controller: _textEditingController,
                            decoration: gfieldInputDecoration.merge(InputDecoration(filled: true, fillColor: beColorScheme.background.secondary, hintText: "Email Address"))
                        ),

                        const SizedBox(height: 16),

                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                if (isSubmitting)
                                    SizedBox(
                                        height: beTextTheme.headingSecondary.fontSize,
                                        width:  beTextTheme.headingSecondary.fontSize,
                                        child: const Center(child: CircularProgressIndicator()),
                                    )
                                else
                                    TextButton(
                                        onPressed: () async {
                                            if (_textEditingController.text.isEmpty) {
                                                return;
                                            }

                                            setState(() {
                                                isSubmitting = true;
                                            });

                                            // ApiClient - send invite

                                            if (context.mounted) {
                                                setState(() {
                                                    isSubmitting = false;
                                                });
                                                appRouter.pop();
                                            }

                                            _textEditingController.clear();
                                        },
                                        child: Text(
                                            "Confirm",
                                            style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent, fontWeight: FontWeight.bold)),
                                        ),
                                    ),
                                const SizedBox(width: 12),
                                TextButton(
                                    onPressed: () {
                                        context.pop();
                                        _textEditingController.clear();
                                    },
                                    child: Text(
                                        "Cancel",
                                        style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent)),
                                    ),
                                ),
                            ],
                        )
                    ]
                )
            )
        );
    }
}
