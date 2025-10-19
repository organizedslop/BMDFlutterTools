import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "package:webview_flutter/webview_flutter.dart";

/* ======================================================================================================================
 * MARK: Web View
 * ------------------------------------------------------------------------------------------------------------------ */
class RemoteHtmlWebView extends StatefulWidget {
  final bool fullscreen;

  final double? height, width;

  final String url;

  const RemoteHtmlWebView({
    super.key,
    fullscreen,
    this.height,
    required this.url,
    this.width,
  }) : this.fullscreen = fullscreen ?? false;

  @override
  State<RemoteHtmlWebView> createState() => _RemoteHtmlWebViewState();
}

/* ======================================================================================================================
 * MARK: Widget State
 * ------------------------------------------------------------------------------------------------------------------ */
class _RemoteHtmlWebViewState extends State<RemoteHtmlWebView> {
  late final WebViewController _ctrl;
  late final Uri _initialUri;
  bool _hasLoadedInitialUrl = false;

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Initialize
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  void initState() {
    super.initState();

    _initialUri = Uri.parse(widget.url);

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 1) Inject zoom via JS after content loads and normalize anchor navigation
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            if (!request.isMainFrame) {
              return NavigationDecision.navigate;
            }

            if (!_hasLoadedInitialUrl) {
              return NavigationDecision.navigate;
            }

            final Uri? uri = Uri.tryParse(request.url);
            if (uri == null || uri.scheme == 'about' || uri.scheme == 'javascript') {
              return NavigationDecision.navigate;
            }

            final LaunchMode mode =
                (uri.scheme == 'http' || uri.scheme == 'https')
                    ? LaunchMode.externalApplication
                    : LaunchMode.platformDefault;

            final bool launched = await launchUrl(
              uri,
              mode: mode,
            );

            return launched ? NavigationDecision.prevent : NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            if (!_hasLoadedInitialUrl) {
              _hasLoadedInitialUrl = true;
            }
            _ctrl.runJavaScript("""
                        (function() {
                            const html = document.documentElement;
                            // Look for an existing viewport meta
                            let vp = document.querySelector('meta[name="viewport"]');
                            // Define the scaling you want
                            const content = 'width=device-width, initial-scale=1, maximum-scale=3.0, user-scalable=yes';
                            if (vp) {
                                vp.setAttribute('content', content);
                            } else {
                                vp = document.createElement('meta');
                                vp.name = 'viewport';
                                vp.content = content;
                                document.head.appendChild(vp);
                            }
                            html.style.setProperty('max-width', 'min(100vw, 35rem)');
                            html.style.setProperty('-webkit-transform-origin', 'top center');

                            document.querySelectorAll('a[href]').forEach(function(anchor) {
                                anchor.addEventListener('click', function(event) {
                                    const href = anchor.getAttribute('href');
                                    if (!href) {
                                        return;
                                    }
                                    // Allow same-page anchors to behave normally
                                    if (href.startsWith('#')) {
                                        return;
                                    }
                                    event.preventDefault();
                                    event.stopPropagation();
                                    window.location.href = anchor.href;
                                }, { capture: true });
                            });
                        })();
                    """);
          },
        ),
      )
      // 2) Load the requested URL with mobile UA
      ..loadRequest(_initialUri, headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) '
            'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 '
            'Mobile/15A372 Safari/604.1',
      });
  }

  /* -----------------------------------------------------------------------------------------------------------------
     * MARK: Build Widget
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: widget.fullscreen ? null : widget.height,
        width: widget.fullscreen ? null : widget.width,
        child: WebViewWidget(
          controller: _ctrl,
        ));
  }
}
