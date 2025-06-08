import 'dart:ui_web' as ui;
import 'dart:html' as html;

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
