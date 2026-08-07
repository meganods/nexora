import 'dart:async';
import 'dart:html' as html;

Future<Map<String, dynamic>?> pickDocument() async {
  final completer = Completer<Map<String, dynamic>?>();
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.pdf,.png,.jpg,.jpeg';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final blobUrl = html.Url.createObjectUrl(file);
      completer.complete({
        'name': file.name,
        'size': file.size,
        'url': blobUrl,
      });
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
