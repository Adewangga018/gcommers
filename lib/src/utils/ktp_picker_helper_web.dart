// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

class KtpPickResult {
  const KtpPickResult({required this.name, required this.bytes, required this.isPdf});
  final String name;
  final Uint8List bytes;
  final bool isPdf;
}

void pickKtpFile(
  void Function(KtpPickResult) onPicked,
  void Function(String) onError,
) {
  final input = html.FileUploadInputElement()
    ..accept = '.jpg,.jpeg,.png,.pdf'
    ..multiple = false;

  input.onChange.listen((_) async {
    try {
      if (input.files == null || input.files!.isEmpty) return;
      final file = input.files![0];

      if (file.size > 5 * 1024 * 1024) {
        onError('Ukuran file maksimal 5 MB');
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final result = reader.result;
      final Uint8List bytes;
      if (result is Uint8List) {
        bytes = result;
      } else if (result is ByteBuffer) {
        bytes = result.asUint8List();
      } else {
        onError('Format hasil baca file tidak didukung');
        return;
      }
      final isPdf = file.name.toLowerCase().endsWith('.pdf');

      onPicked(KtpPickResult(name: file.name, bytes: bytes, isPdf: isPdf));
    } catch (e) {
      onError(e.toString());
    }
  });

  input.click();
}
