import 'dart:js_interop';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:web/web.dart' as web;

typedef TriggerBrowserDownload = void Function({
  required Uint8List bytes,
  required String filename,
  String? contentType,
});

typedef CreateObjectUrl = String Function(JSObject object);

typedef RevokeObjectUrl = void Function(String objectUrl);

typedef CreateDownloadAnchor = web.HTMLAnchorElement Function(
  String href,
  String filename,
);

typedef ClickDownloadAnchor = void Function(web.HTMLAnchorElement anchor);

TriggerBrowserDownload triggerBrowserDownload = _triggerBrowserDownload;

@visibleForTesting
CreateObjectUrl createObjectUrl = _createObjectUrl;

@visibleForTesting
RevokeObjectUrl revokeObjectUrl = _revokeObjectUrl;

@visibleForTesting
CreateDownloadAnchor createDownloadAnchor = _createDownloadAnchor;

@visibleForTesting
ClickDownloadAnchor clickDownloadAnchor = (anchor) => anchor.click();

@visibleForTesting
void resetBrowserDownloadHooks() {
  triggerBrowserDownload = _triggerBrowserDownload;
  createObjectUrl = _createObjectUrl;
  revokeObjectUrl = _revokeObjectUrl;
  createDownloadAnchor = _createDownloadAnchor;
  clickDownloadAnchor = (anchor) => anchor.click();
}

void _triggerBrowserDownload({
  required Uint8List bytes,
  required String filename,
  String? contentType,
}) {
  // Use JS typed arrays and package:web APIs instead of dart:html so this path
  // remains compatible with Dart's WebAssembly compilation target.
  final blobParts = <JSUint8Array>[bytes.toJS].toJS;
  final blob = contentType == null
      ? web.Blob(blobParts)
      : web.Blob(blobParts, web.BlobPropertyBag(type: contentType));
  final objectUrl = createObjectUrl(blob);
  web.HTMLAnchorElement? anchor;
  try {
    anchor = createDownloadAnchor(objectUrl, filename);
    // Keep the anchor connected while clicking; some browsers are stricter
    // about dispatching downloads from detached elements.
    web.document.body?.appendChild(anchor);
    clickDownloadAnchor(anchor);
  } finally {
    // Once the click is dispatched, cleanup should happen even if browser
    // policies later block, rename, or prompt for the actual download.
    anchor?.remove();
    revokeObjectUrl(objectUrl);
  }
}

web.HTMLAnchorElement _createDownloadAnchor(String href, String filename) {
  return web.HTMLAnchorElement()
    ..href = href
    ..download = filename;
}

String _createObjectUrl(JSObject object) => web.URL.createObjectURL(object);

void _revokeObjectUrl(String objectUrl) {
  web.URL.revokeObjectURL(objectUrl);
}
