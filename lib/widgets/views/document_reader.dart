/*
 * Document Reader
 *
 * Created by:  Blake Davis
 * Description: A widget for displaying multi-page documents such as PDFs
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

import "dart:async";
import "dart:io";
import "package:bmd_flutter_tools/controllers/environment.dart";
import "package:bmd_flutter_tools/controllers/global_state.dart";
import "package:bmd_flutter_tools/main.dart";
import "package:bmd_flutter_tools/theme/snackbar_styles.dart";
import "package:bmd_flutter_tools/utilities/print_utilities.dart";
import "package:bmd_flutter_tools/widgets/components/foating_scanner_button.dart";
import "package:bmd_flutter_tools/widgets/navigation/primary_navigation_bar.dart";
import "package:bmd_flutter_tools/widgets/navigation/bottom_navigation_bar.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_pdfview/flutter_pdfview.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:path_provider/path_provider.dart";
import "package:http/http.dart" as http;




/* ======================================================================================================================
 * MARK: Document Reader
 * ------------------------------------------------------------------------------------------------------------------ */
class DocumentReader extends ConsumerStatefulWidget {

    static const Key rootKey = Key("document_reader__root");

    final String? assetPath,
                  title;


    // { pageNumber: { label: Text("Click Here"), action: () {} } }
    final Map<int, Map<String, dynamic>> actions;

    DocumentReader({ super.key,
                      this.title,
                      this.assetPath,
                      this.actions = const {} });


    @override
    ConsumerState<DocumentReader> createState() => _DocumentReaderState();
}




/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _DocumentReaderState extends ConsumerState<DocumentReader> with WidgetsBindingObserver {

    final Completer<PDFViewController> _controller = Completer<PDFViewController>();

    bool isReady = false;

    int? pages       = 0;
    int? currentPage = 0;

    String errorMessage = "";

    String? appStoragePath;




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void initState() {
        super.initState();

        showSystemUiOverlays();

        _prepareDocument();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Dispose
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    @override
    void dispose() {
        super.dispose();
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Prepare the Document
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    void _prepareDocument() {
        final String assetName = widget.assetPath?.split("/").last ?? "";
        final cachedPath       = ref.read(appStoragePathsProvider)[assetName];

        // Use the cached asset if it has already been copied to app storage...
        if (cachedPath != null) {
            File(cachedPath).exists().then((exists) {
                if (exists) {
                    logPrint("⚠️  Document exists in app storage, displaying cached copy...");

                    setState(() {
                        appStoragePath = cachedPath;
                    });

                } else {
                    _downloadOrCopy(assetName);
                }
            });

        // Otherwise, download or copy it to app storage
        } else if (widget.assetPath != null) {
            _downloadOrCopy(assetName);
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Download or Copy the Document to App Storage
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    void _downloadOrCopy(String assetName) {
        final String pathOrUrl = widget.assetPath!;

        if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
            try {
            _downloadRemoteFile(pathOrUrl).then((file) {
                    if (file != null) {
                        ref.read(appStoragePathsProvider).addAll({assetName: file.path});
                        setState(() {
                            appStoragePath = file.path;
                        });
                    } else {
                        if (!mounted) return;
                        setState(() {
                            isReady = true;
                        });
                    }
                });

            } catch (error) {
                final msg = "Error downloading document: ${error.toString()}";
                logPrint("❌ ${msg}");

                if (!mounted) return;

                setState(() {
                    errorMessage = msg;
                });
            }

        } else {
            copyAssetToAppStorage(pathOrUrl).then((assetCopy) {
                ref.read(appStoragePathsProvider).addAll({assetName: assetCopy.path});
                setState(() {
                    appStoragePath = assetCopy.path;
                });
            });
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Download Remote Document
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<File?> _downloadRemoteFile(String url) async {
        logPrint("🔄 Downloading document (from ${url})...");

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
            final bytes     = response.bodyBytes;
            final directory = await getApplicationDocumentsDirectory();
            final fileName  = Uri.parse(url).pathSegments.last;
            final file      = File("${directory.path}/${fileName}");

            await file.writeAsBytes(bytes, flush: true);

            return file;

        } else {
            final String message = "Error (${response.statusCode}): Unable to download document";

            logPrint("❌ ${message}");

            setState(() {
                errorMessage = message;
                isReady = true;
            });

            scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                    content: Text(
                        message,
                        textAlign: TextAlign.center,
                    ),
                    padding: EdgeInsets.all(16),
                )
            );

            return null;
        }
    }




    /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Copy File to App Storage
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
    Future<File> copyAssetToAppStorage(String assetPath) async {
        logPrint("🔄 Copying asset (from ${assetPath}) to app storage...");

        Completer<File> completer = Completer();

        try {
            final directory = await getApplicationDocumentsDirectory();

            final String filename = assetPath.split("/").last;

            File file = File("${directory.path}/${filename}");

            final data  = await rootBundle.load(assetPath);
            final bytes = data.buffer.asUint8List();

            await file.writeAsBytes(bytes, flush: true);

            logPrint("ℹ️  Adding app storage path to global state...");
            ref.read(appStoragePathsProvider).addAll({ filename: file.path });

            completer.complete(file);

        } catch (error) {
            context.pop();

            scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                    content: Text("Error displaying document",
                        textAlign: TextAlign.center),
                    padding: EdgeInsets.all(16),
                )
            );

            throw Exception("Error parsing asset file.");

        }

        return completer.future;
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
            appBar:               PrimaryNavigationBar(title: widget.title ?? "", subtitle: ref.read(showProvider)?.title),
            bottomNavigationBar:  QuickNavigationBar(),
            floatingActionButton: (ref.read(badgeProvider)?.hasLeadScannerLicense ?? false) ? FloatingScannerButton() : null,
            key:                  DocumentReader.rootKey,

            /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
             * MARK: Widget Body
             * -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -  */
            body: appStoragePath == null
                ? (errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child:   Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                            )
                        )
                    )
                    : const Center(child: CircularProgressIndicator())
                )
                : Stack(
                        alignment: AlignmentDirectional.bottomCenter,
                        children:  <Widget>[
                            PDFView(
                                    filePath:              appStoragePath,
                                    enableSwipe:           true,
                                    swipeHorizontal:       true,
                                    autoSpacing:           false,
                                    pageFling:             true,
                                    pageSnap:              true,
                                    defaultPage:           currentPage!,
                                    fitPolicy:             FitPolicy.HEIGHT,
                                    preventLinkNavigation: false,
                                    onRender: (_pages) {
                                        setState(() {
                                            pages   = _pages;
                                            isReady = true;
                                        });
                                    },

                                    onError: (error) {
                                        setState(() {
                                            errorMessage = error.toString();
                                        });
                                        logPrint("❌ ${error.toString()}");
                                    },

                                    onPageError: (page, error) {
                                        setState(() {
                                            errorMessage = "${page}: ${error.toString()}";
                                        });
                                        logPrint('❌ $page: ${error.toString()}');
                                    },

                                    onViewCreated: (PDFViewController pdfViewController) {
                                        _controller.complete(pdfViewController);
                                    },

                                    onLinkHandler: (String? uri) {
                                        logPrint("✅ Go to: $uri");
                                    },

                                    onPageChanged: (int? page, int? total) {
                                        logPrint("✅ Page changed to: ${page}/${total}");

                                        setState(() {
                                            currentPage = page;
                                        });
                                    },
                            ),

                            // Bottom action button
                            InkWell(
                                child: widget.actions[currentPage]?["label"]  ??  SizedBox.shrink(),
                                onTap: () async { (widget.actions[currentPage]?["action"]  ??  () { })(); }
                            ),

                            // Error message
                            errorMessage.isEmpty ?  (!isReady   ?  Center(child: CircularProgressIndicator())  :
                                                                    Container())  :
                                                    Center(child: Text(errorMessage))
                        ]
                    )
        );
    }
}