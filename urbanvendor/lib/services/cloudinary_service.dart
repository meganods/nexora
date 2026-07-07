import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static String get _cloudName => dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: 'dbjxlsoua');
  static String get _uploadPreset => dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: 'urbancompany');

  static CloudinaryPublic get _cloudinary {
    return CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  /// Uploads an image to Cloudinary and returns the secure URL.
  /// [filePath] is the path to the image file.
  /// [folder] is the target folder in Cloudinary.
  static Future<String?> uploadImage({
    required String filePath,
    String folder = 'urban_company',
  }) async {
    try {
      debugPrint('Cloudinary Upload → cloudName: $_cloudName, preset: $_uploadPreset, folder: $folder');
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      debugPrint('Cloudinary Upload Success: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      return null;
    }
  }

  /// Uploads an image as bytes (useful for Web).
  static Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    String folder = 'urban_company',
  }) async {
    try {
      debugPrint('Cloudinary Bytes Upload → cloudName: $_cloudName, preset: $_uploadPreset, folder: $folder');
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: fileName,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      debugPrint('Cloudinary Bytes Upload Success: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary Bytes Upload Error: $e');
      return null;
    }
  }
  
  /// Generates a transformed URL (e.g., resizing, quality optimization).
  static String getOptimizedUrl(String? url, {int? width, int? height, String? crop}) {
    if (url == null || url.isEmpty) return '';
    
    // Safety check: Only attempt to inject transformations if it's a Cloudinary upload URL
    if (!url.contains('cloudinary.com') || !url.contains('/upload/')) {
      return url;
    }
    
    try {
      final parts = url.split('/upload/');
      if (parts.length < 2) return url;

      final baseUrl = parts[0];
      final remainingUrl = parts[1];
      
      List<String> transforms = ['f_auto', 'q_auto'];
      if (width != null) transforms.add('w_$width');
      if (height != null) transforms.add('h_$height');
      if (crop != null) transforms.add('c_$crop');
      
      return '$baseUrl/upload/${transforms.join(',')}/$remainingUrl';
    } catch (e) {
      debugPrint('Optimization error: $e');
      return url; 
    }
  }

  /// Automatically provides a professional icon URL based on the name.
  /// Uses Cloudinary's Fetch API to proxy and optimize high-quality public icons.
  static String getAutoIconUrl(String name) {
    final Map<String, String> keywordMap = {
      'salon': 'hair-dryer',
      'barber': 'barber-pole',
      'haircut': 'scissors',
      'beauty': 'makeup-brush',
      'men': 'beard',
      'women': 'spa',
      'ac': 'air-conditioner',
      'repair': 'wrench',
      'cleaning': 'broom',
      'sanitation': 'disinfectant',
      'plumb': 'plumbing',
      'electric': 'voltage',
      'handyman': 'toolbox',
      'cctv': 'security-camera',
      'pest': 'insecticide',
      'carpenter': 'hammer',
      'massage': 'massage',
      'wash': 'washing-machine',
      'paint': 'paint-roller',
      'home': 'home-automation',
      'pet': 'dog',
      'yoga': 'yoga',
      'fitness': 'weight-training',
      'legal': 'law',
      'finance': 'money-bag',
      'education': 'graduation-cap',
    };

    String keyword = 'service'; // Default
    final lowerName = name.toLowerCase();
    
    for (var entry in keywordMap.entries) {
      if (lowerName.contains(entry.key)) {
        keyword = entry.value;
        break;
      }
    }

    // Using Icons8 as a source, proxied through Cloudinary for optimization and caching
    final sourceUrl = 'https://img.icons8.com/fluency/200/$keyword.png';
    return 'https://res.cloudinary.com/$_cloudName/image/fetch/f_auto,q_auto/$sourceUrl';
  }
}
