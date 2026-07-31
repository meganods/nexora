import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class CloudinaryService {
  static String get _cloudName => dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: 'dkiwspjmd');
  static String get _uploadPreset => dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: 'urbancompany');
  static String get _apiKey => dotenv.get('CLOUDINARY_API_KEY', fallback: '157752988333175');
  static String get _apiSecret => dotenv.get('CLOUDINARY_API_SECRET', fallback: 'ErgEzGtT6uDfmS9PQHRUHMeAHp4');
  static String get _folderName => dotenv.get('CLOUDINARY_FOLDER', fallback: 'Urban Company Admin/urban_company');

  static CloudinaryPublic get _cloudinary {
    return CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  /// Uploads an image to Cloudinary and returns the secure URL.
  /// [filePath] is the path to the image file.
  /// [folder] is the target folder in Cloudinary.
  static Future<String?> uploadImage({
    required String filePath,
    String? folder,
  }) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          folder: folder ?? _folderName,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      return null;
    }
  }

  /// Uploads an image as bytes (useful for Web) using Signed API.
  static Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? folder,
  }) async {
    try {
      String cleanFileName = fileName;
      if (!cleanFileName.contains('.')) {
        cleanFileName = '$cleanFileName.jpg';
      }
      
      final targetFolder = folder ?? _folderName;
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = {
        'folder': targetFolder,
        'timestamp': timestamp.toString(),
      };
      
      final sortedKeys = params.keys.toList()..sort();
      final parameterString = sortedKeys.map((key) => '$key=${params[key]}').join('&');
      final stringToSign = '$parameterString$_apiSecret';
      
      final signature = sha1.convert(utf8.encode(stringToSign)).toString();
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      debugPrint('Cloudinary Signed Bytes Upload → cloudName: $_cloudName, folder: $targetFolder, fileName: $cleanFileName');
      final request = http.MultipartRequest('POST', url)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['folder'] = targetFolder
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: cleanFileName,
        ));
        
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final secureUrl = data['secure_url'] as String?;
        debugPrint('Cloudinary Signed Bytes Upload Success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('Cloudinary Signed Bytes Upload Failed with code ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary Signed Bytes Upload Error: $e');
      return null;
    }
  }

  /// Uploads a remote image URL directly to Cloudinary (bypassing browser CORS)
  static Future<String?> uploadImageUrl({
    required String imageUrl,
    String? folder,
  }) async {
    try {
      final targetFolder = folder ?? _folderName;
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final params = {
        'folder': targetFolder,
        'timestamp': timestamp.toString(),
      };
      
      final sortedKeys = params.keys.toList()..sort();
      final parameterString = sortedKeys.map((key) => '$key=${params[key]}').join('&');
      final stringToSign = '$parameterString$_apiSecret';
      
      final signature = sha1.convert(utf8.encode(stringToSign)).toString();
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['folder'] = targetFolder
        ..fields['file'] = imageUrl;
        
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final secureUrl = data['secure_url'] as String?;
        debugPrint('Cloudinary URL Upload Success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('Cloudinary URL Upload Failed with code ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary URL Upload Error: $e');
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

    // Using Icons8 as a source directly to avoid Cloudinary Fetched URL 401 restriction
    final sourceUrl = 'https://img.icons8.com/fluency/200/$keyword.png';
    return sourceUrl;
  }
}
