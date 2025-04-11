import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:io' show Platform;
import 'package:web/web.dart' as web;
import 'package:flutter_html_iframe/flutter_html_iframe.dart';

void registerIframe(String viewId, String url) {
  // Register the iframe for web
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    return iframe;
  });
}
