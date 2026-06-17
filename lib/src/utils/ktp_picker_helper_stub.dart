import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class KtpPickResult {
  const KtpPickResult({required this.name, required this.bytes, required this.isPdf});
  final String name;
  final Uint8List bytes;
  final bool isPdf;
}

void pickKtpFile(
  void Function(KtpPickResult) onPicked,
  void Function(String) onError,
) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final isPdf = file.extension?.toLowerCase() == 'pdf';
    onPicked(KtpPickResult(name: file.name, bytes: file.bytes!, isPdf: isPdf));
  } catch (e) {
    onError(e.toString());
  }
}
