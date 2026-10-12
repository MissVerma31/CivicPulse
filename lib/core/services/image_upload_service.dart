import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ImageUploadService {
  static const String _cloudName = 'erxbnjyu';
  static const String _uploadPreset = 'Prachi verma';

  static Future<String> uploadImage(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      throw Exception('Captured image is empty.');
    }

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'complaint.jpg',
          ),
        );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.body.isEmpty) {
        throw Exception(
          'Cloudinary returned an empty response (${response.statusCode}).',
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final errorMessage =
            data['error']?['message']?.toString() ?? 'HTTP ${response.statusCode}';
        throw Exception('Image upload failed: $errorMessage');
      }

      final url = data['secure_url'];
      if (url == null || url.toString().isEmpty) {
        throw Exception('Image uploaded but Cloudinary did not return a URL.');
      }

      return url.toString();
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Image upload error: $e');
    }
  }
}