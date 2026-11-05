import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiClient {
  static Uri _parseUri(String url) {
    final cleaned = url
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .trim();
    return Uri.parse(cleaned);
  }

  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      if (response.statusCode == 404) {
        throw Exception(
          'Endpoint tidak ditemukan (404 Not Found). Periksa URL API Anda.',
        );
      }
      throw Exception(
        'Server mengembalikan format tidak valid (Status: ${response.statusCode}).',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'data': data};
    }

    if (data is Map && data['message'] != null) {
      throw Exception(data['message'].toString());
    }

    throw Exception(
      'Terjadi kesalahan pada server (Status: ${response.statusCode}).',
    );
  }

  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await http.get(
      _parseUri(url),
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await http.post(
      _parseUri(url),
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> upload(
    String url, {
    required String filePath,
    required String fieldName,
    Uint8List? fileBytes,
    String? fileName,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _parseUri(url),
    );

    if (fileBytes != null) {
      final safeName = (fileName != null && fileName.isNotEmpty)
          ? fileName
          : (filePath.split(RegExp(r'[/\\]')).last.isNotEmpty
              ? filePath.split(RegExp(r'[/\\]')).last
              : 'upload.jpg');
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: safeName.contains('.') ? safeName : '$safeName.jpg',
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          filePath,
        ),
      );
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    return _handleResponse(response);
  }
}
