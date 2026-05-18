import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FileUploadService {
  FileUploadService({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:5001',
            );

  final String baseUrl;
  final _picker = ImagePicker();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );
  }

  Future<String> uploadKtpImage({
    required String email,
    required XFile imageFile,
  }) async {
    // Use readAsBytes() which works on all platforms (web, mobile, desktop)
    final bytes = await imageFile.readAsBytes();
    final fileName = imageFile.name;

    final request = http.MultipartRequest(
      'POST',
      _uri('/auth/upload-ktp'),
    );

    request.fields['email'] = email;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Upload failed: $responseBody');
    }

    return responseBody;
  }
}
