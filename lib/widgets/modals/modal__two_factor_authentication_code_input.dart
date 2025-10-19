/*
 * Two Factor Authentication Code Input Modal
 *
 * Created by:  Blake Davis
 * Description: A widget which displays a modal prompt to enter a a 2FA code
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/api_client.dart";
import "package:bmd_flutter_tools/controllers/app_router.dart";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/data/model/data__icecrm_response.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/app_styles.dart";
import "package:bmd_flutter_tools/utilities/utilities__theme.dart";
import "package:bmd_flutter_tools/utilities/utilities__type_extensions.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";




/* ======================================================================================================================
 * MARK: Two Factor Auth Code Input Modal
 * ------------------------------------------------------------------------------------------------------------------ */
class TwoFactorAuthenticationCodeInputModal extends ConsumerStatefulWidget {

    final String email,
                 text,
                 token;

    final Function onComplete;

    TwoFactorAuthenticationCodeInputModal({
                super.key,
        required this.email,
                 this.text   = "",
        required this.token,
        required this.onComplete,
    });

    @override
    ConsumerState<TwoFactorAuthenticationCodeInputModal> createState() => _TwoFactorAuthenticationCodeInputModalState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _TwoFactorAuthenticationCodeInputModalState extends ConsumerState<TwoFactorAuthenticationCodeInputModal> {

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
                        Text("Enter your 2FA code", style: beTextTheme.headingTertiary),
                        const SizedBox(height: 8),

                        formFieldLabel(labelText: ""),

                        TextFormField(
                            controller: _textEditingController,
                            decoration: gfieldInputDecoration.merge(InputDecoration(filled: true, fillColor: beColorScheme.background.secondary))
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
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
                                const SizedBox(width: 12),
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

                                            IceCrmResponseData? responseData = await ApiClient.instance.submitTwoFactorAuthenticationCode(
                                                _textEditingController.text,
                                                widget.email,
                                                widget.token,
                                            );

                                            if (context.mounted) {
                                                setState(() {
                                                    isSubmitting = false;
                                                });
                                                appRouter.pop();
                                            }

                                            if (responseData?.data["access_token"] != null) {
                                                await widget.onComplete(responseData);
                                            }

                                            _textEditingController.clear();
                                        },
                                        child: Text(
                                            "Confirm",
                                            style: beTextTheme.bodyPrimary.merge(TextStyle(color: beColorScheme.text.accent, fontWeight: FontWeight.bold)),
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
