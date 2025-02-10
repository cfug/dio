import 'dart:js_interop';
import 'package:web/web.dart';

void downloadBlob(String blobUrl, String name) {
  final Document htmlDocument = document;
  final HTMLAnchorElement anchor =
      htmlDocument.createElement('a') as HTMLAnchorElement;
  anchor.href = blobUrl;
  anchor.style.display = name;
  anchor.download = name;
  document.body!.add(anchor);
  anchor.click();
  anchor.remove();
}
