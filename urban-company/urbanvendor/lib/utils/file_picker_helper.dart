import 'file_picker_helper_stub.dart'
    if (dart.library.html) 'file_picker_helper_web.dart' as platform_picker;

Future<Map<String, dynamic>?> pickDocumentFile() async {
  return platform_picker.pickDocument();
}
