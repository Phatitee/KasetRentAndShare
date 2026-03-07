import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

class CloudinaryService {
  /// Upload a single image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'] as String;
      } else {
        final responseData = await response.stream.bytesToString();
        throw Exception(
            'Upload failed with status ${response.statusCode}: $responseData');
      }
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }

  /// Upload multiple images to Cloudinary
  /// Returns a list of secure URLs
  Future<List<String>> uploadMultipleImages(
      List<File> imageFiles, String folder) async {
    final List<String> urls = [];

    for (final imageFile in imageFiles) {
      final url = await uploadImage(imageFile, folder);
      urls.add(url);
    }

    return urls;
  }

  /// Delete an image from Cloudinary by its URL
  /// Note: For unsigned deletion, you need to configure it in Cloudinary settings
  /// For now, this logs the deletion request (images can be managed via Cloudinary dashboard)
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract public_id from Cloudinary URL
      // URL format: https://res.cloudinary.com/{cloud}/image/upload/v{version}/{folder}/{filename}
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the index after 'upload' and optional version
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return;

      int startIndex = uploadIndex + 1;
      // Skip version segment (starts with 'v' followed by numbers)
      if (startIndex < pathSegments.length &&
          pathSegments[startIndex].startsWith('v') &&
          int.tryParse(pathSegments[startIndex].substring(1)) != null) {
        startIndex++;
      }

      // Join remaining segments and remove file extension
      final publicIdWithExt = pathSegments.sublist(startIndex).join('/');
      final lastDot = publicIdWithExt.lastIndexOf('.');
      final publicId =
          lastDot != -1 ? publicIdWithExt.substring(0, lastDot) : publicIdWithExt;

      print('Cloudinary: Would delete image with public_id: $publicId');
      // Note: Unsigned deletion is not supported by Cloudinary API
      // Images should be managed through Cloudinary dashboard or a backend server
    } catch (e) {
      print('Failed to process Cloudinary image deletion: $e');
    }
  }
}
