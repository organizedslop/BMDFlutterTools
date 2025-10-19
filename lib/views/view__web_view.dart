/*
 * Web View
 *
 * Created by:  Blake Davis
 * Description:
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/widgets/component__foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/component__remote_html.dart";
import "package:bmd_flutter_tools/widgets/navigation_bar__bottom.dart";
import "package:bmd_flutter_tools/widgets/navigation_bar__primary.dart";
import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";




/* ======================================================================================================================
 * MARK: User Home View
 * ------------------------------------------------------------------------------------------------------------------ */
class WebView extends ConsumerStatefulWidget {

    static const Key rootKey = Key("web_view__root");

    final String title,
                 url;


    WebView({   super.key,
        required this.title,
        required this.url,
    });


    @override
    ConsumerState<WebView> createState() => _WebViewState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _WebViewState extends ConsumerState<WebView> {

    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        showSystemUiOverlays();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    dispose() {
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    Widget build(BuildContext context) {

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         * MARK: Scaffold
         * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
        return Scaffold(
            appBar:               PrimaryNavigationBar(title: widget.title),
            bottomNavigationBar:  QuickNavigationBar(),
            floatingActionButton: (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false) ? FloatingScannerButton() : null,
            key:                  WebView.rootKey,

            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Widget Body
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            body: RemoteHtmlWebView(
                fullscreen: true,
                url:        widget.url
            )
        );
    }
}