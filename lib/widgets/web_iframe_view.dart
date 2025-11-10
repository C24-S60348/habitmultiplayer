import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../platform_mobile.dart'
  if (dart.library.html) '../platform_web.dart'
  if (dart.library.io) '../platform_windows.dart';

class WebIframeView extends StatelessWidget {
  final String url;

  iframeMatcher() {
    return (context, element) => element.localName == 'iframe';
  }

  const WebIframeView({super.key, required this.url});

  // Helper method to validate and normalize URL
  String? _validateAndNormalizeUrl(String url) {
    if (url.isEmpty) return null;
    
    try {
      // Try parsing as-is first
      final uri = Uri.parse(url);
      // If it has a scheme, return as-is
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return url;
      }
      // If no scheme, try adding https://
      final normalized = Uri.parse('https://$url');
      if (normalized.hasAuthority) {
        return normalized.toString();
      }
      return null;
    } catch (e) {
      // If parsing fails, try adding https://
      try {
        final normalized = Uri.parse('https://$url');
        if (normalized.hasAuthority) {
          return normalized.toString();
        }
      } catch (_) {
        // If that also fails, URL is invalid
        return null;
      }
      return null;
    }
  }

  Widget _buildInvalidUrlView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Invalid URL',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'The URL "$url" is not valid.\nPlease check the habit link.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
   Widget build(BuildContext context) {
    final validUrl = _validateAndNormalizeUrl(url);
    
    if (validUrl == null) {
      return _buildInvalidUrlView();
    }

    if (kIsWeb) {
      // Web platform - use iframe
      final String viewId = 'iframe-${validUrl.hashCode}';
      registerIframe(viewId, validUrl);
      return HtmlElementView(viewType: viewId);
    } else if (Theme.of(context).platform == TargetPlatform.windows) {
      // Windows platform - try webview_windows, fallback if not available
      return _WindowsWebViewWrapper(url: validUrl);
    } else {
      // Mobile platforms (iOS/Android) - use webview_flutter package
      return _buildMobileWebView(validUrl);
    }
  }

  Widget _buildMobileWebView(String validUrl) {
    try {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(validUrl));
    return WebViewWidget(controller: controller);
    } catch (e) {
      // If loading fails, show error view
      return _buildInvalidUrlView();
    }
  }
}

// Windows WebView wrapper with fallback
class _WindowsWebViewWrapper extends StatefulWidget {
  final String url;

  const _WindowsWebViewWrapper({required this.url});

  @override
  _WindowsWebViewWrapperState createState() => _WindowsWebViewWrapperState();
}

class _WindowsWebViewWrapperState extends State<_WindowsWebViewWrapper> {
  bool _webViewAvailable = true;

  @override
  Widget build(BuildContext context) {
    if (_webViewAvailable) {
      return _WindowsWebView(url: widget.url, onError: () {
        setState(() {
          _webViewAvailable = false;
        });
      });
    } else {
      return _buildFallbackView();
    }
  }

  Widget _buildFallbackView() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'WebView not available on Windows',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'URL: ${widget.url}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Try to parse and validate URL
                  Uri uri;
                  try {
                    uri = Uri.parse(widget.url);
                    // If no scheme, try adding https://
                    if (!uri.hasScheme) {
                      uri = Uri.parse('https://${widget.url}');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invalid URL: ${widget.url}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open URL'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening URL: Invalid URL format'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Open in Browser'),
            ),
          ],
        ),
      ),
    );
  }
}

// Windows-specific WebView widget
class _WindowsWebView extends StatefulWidget {
  final String url;
  final VoidCallback onError;

  const _WindowsWebView({required this.url, required this.onError});

  @override
  _WindowsWebViewState createState() => _WindowsWebViewState();
}

class _WindowsWebViewState extends State<_WindowsWebView> {
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Try to use webview_windows package
      await _tryWebViewWindows();
    } catch (e) {
      print('Failed to initialize Windows WebView: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        widget.onError();
      }
    }
  }

  Future<void> _tryWebViewWindows() async {
    // This is a placeholder for the webview_windows implementation
    // You would need to properly import and use the package here
    // For now, we'll simulate an error to trigger the fallback
    throw Exception('webview_windows not properly configured');
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorView();
    }

    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading WebView...'),
          ],
        ),
      );
    }

    // This would be the actual WebView widget when properly configured
    return _buildErrorView();
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'WebView Error',
            style: TextStyle(fontSize: 18, color: Colors.orange),
          ),
          SizedBox(height: 8),
          Text(
            'URL: ${widget.url}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}