import 'dart:convert';
import 'dart:typed_data';

import 'api_service.dart';

class AcademicService {
  Future<Map<String, dynamic>> calculateCgpaFromImage(Uint8List bytes) async {
    return await ApiService.instance.post('/cgpa/calculate', {
      'imageBase64': base64Encode(bytes),
    }) as Map<String, dynamic>;
  }

  Future<String> roastResumeText(String resumeText) async {
    final json = await ApiService.instance.post('/ai/roast-resume', {
      'resumeText': resumeText,
    }) as Map<String, dynamic>;
    return json['roast'] as String? ?? 'No roast generated.';
  }

  Future<String> roastResumeFile(String fileBase64, String mimeType) async {
    final json = await ApiService.instance.post('/ai/roast-resume', {
      'fileBase64': fileBase64,
      'mimeType': mimeType,
    }) as Map<String, dynamic>;
    return json['roast'] as String? ?? 'No roast generated.';
  }
}
