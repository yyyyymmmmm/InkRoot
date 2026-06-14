import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:inkroot/services/memos_api_service_fixed.dart';
import 'package:path/path.dart' as path;

/// Memos资源上传服务
class MemosResourceService {
  MemosResourceService({required this.baseUrl, this.token, this.serverVersion});
  final String baseUrl;
  final String? token;
  final int? serverVersion;

  /// 创建请求头，包含授权信息
  Map<String, String> _getHeaders() {
    final headers = <String, String>{};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// 上传图片到Memos服务器
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      debugPrint('MemosResourceService: 开始上传图片 - ${imageFile.path}');

      if (token == null || token!.isEmpty) {
        throw Exception('未登录，无法上传图片');
      }

      // 检查文件是否存在
      if (!await imageFile.exists()) {
        throw Exception('图片文件不存在');
      }

      // 检查文件大小（限制32MB）
      final fileSize = await imageFile.length();
      const maxSize = 32 * 1024 * 1024; // 32MB
      if (fileSize > maxSize) {
        throw Exception('图片文件太大，最大支持32MB');
      }

      final fileName = path.basename(imageFile.path);
      final version =
          serverVersion ?? await MemosApiServiceFixed.getServerVersion(baseUrl);
      final attempts = version >= 27
          ? <Future<Map<String, dynamic>> Function()>[
              () => _uploadAttachmentJson(imageFile, fileName),
              () => _uploadResourceBlob(imageFile, fileName),
            ]
          : <Future<Map<String, dynamic>> Function()>[
              () => _uploadResourceBlob(imageFile, fileName),
              () => _uploadAttachmentJson(imageFile, fileName),
            ];

      Object? lastError;
      for (final attempt in attempts) {
        try {
          final data = await attempt();
          debugPrint('MemosResourceService: 上传成功 - $data');
          final serverPath = buildResourcePath(data);

          return {
            'success': true,
            'data': data,
            'resourceId': data['id'] ?? data['name'],
            'resourceUid':
                data['uid'] ?? data['name']?.toString().split('/').last,
            'filename': data['filename'] ?? data['name']?.toString(),
            'type': data['type'] ?? data['mimeType'],
            'size': data['size'],
            'serverPath': serverPath,
          };
        } on Object catch (e) {
          lastError = e;
          debugPrint('MemosResourceService: 当前资源接口失败，尝试兜底: $e');
        }
      }

      throw Exception('上传失败: $lastError');
    } on Object catch (e) {
      debugPrint('MemosResourceService: 上传图片时发生错误: $e');
      throw Exception('上传图片失败: $e');
    }
  }

  Future<Map<String, dynamic>> _uploadResourceBlob(
    File imageFile,
    String fileName,
  ) async {
    final uri = Uri.parse('$baseUrl/api/v1/resource/blob');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_getHeaders());
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: fileName,
      ),
    );

    debugPrint('MemosResourceService: 发送 legacy resource 上传请求到 $uri');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('resource/blob 上传失败: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _uploadAttachmentJson(
    File imageFile,
    String fileName,
  ) async {
    final uri = Uri.parse('$baseUrl/api/v1/attachments');
    final mimeType = _mimeTypeFor(fileName);
    final body = {
      'filename': fileName,
      'type': mimeType.toString(),
      'content': base64Encode(await imageFile.readAsBytes()),
    };

    debugPrint('MemosResourceService: 发送 attachment 上传请求到 $uri');
    final response = await http.post(
      uri,
      headers: {
        ..._getHeaders(),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('attachments 上传失败: ${response.statusCode}');
  }

  /// 批量上传图片
  Future<List<Map<String, dynamic>>> uploadImages(List<File> imageFiles) async {
    final results = <Map<String, dynamic>>[];

    for (var i = 0; i < imageFiles.length; i++) {
      try {
        debugPrint('MemosResourceService: 上传第${i + 1}/${imageFiles.length}张图片');
        final result = await uploadImage(imageFiles[i]);
        results.add(result);
      } on Object catch (e) {
        debugPrint('MemosResourceService: 第${i + 1}张图片上传失败: $e');
        results.add({
          'success': false,
          'error': e.toString(),
          'filename': path.basename(imageFiles[i].path),
        });
      }
    }

    return results;
  }

  /// 生成图片的Markdown代码
  static String generateImageMarkdown(
    Map<String, dynamic> uploadResult, {
    String alt = '图片',
  }) {
    if (uploadResult['success'] == true) {
      final serverPath = uploadResult['serverPath']?.toString() ??
          buildResourcePath(uploadResult['data'] as Map<String, dynamic>);
      return '![$alt]($serverPath)';
    } else {
      throw Exception('无法为上传失败的图片生成Markdown');
    }
  }

  static String buildResourcePath(Map<String, dynamic> data) {
    final externalLink = data['externalLink']?.toString();
    if (externalLink != null && externalLink.isNotEmpty) {
      return externalLink;
    }

    final name = data['name']?.toString();
    final filename = data['filename']?.toString();
    if (name != null &&
        name.startsWith('attachments/') &&
        filename != null &&
        filename.isNotEmpty) {
      return '/file/$name/$filename';
    }

    final uid = data['uid']?.toString() ?? name?.split('/').last;
    if (uid != null && uid.isNotEmpty) {
      return '/o/r/$uid';
    }

    final id = data['id']?.toString();
    if (id != null && id.isNotEmpty) {
      return '/o/r/$id';
    }

    throw Exception('服务器未返回可用的资源路径');
  }

  /// 构建完整的图片URL
  String buildImageUrl(String resourcePath) {
    // 如果已经是完整URL，直接返回
    if (resourcePath.startsWith('http://') ||
        resourcePath.startsWith('https://')) {
      return resourcePath;
    }

    if (resourcePath.startsWith('attachments/')) {
      return '$baseUrl/file/$resourcePath';
    }

    // 如果是Memos资源路径，支持多种格式
    if (isServerResourcePath(resourcePath)) {
      return '$baseUrl$resourcePath';
    }

    // 如果是纯ID，尝试构建为/o/r/格式
    if (!resourcePath.contains('/') && resourcePath.isNotEmpty) {
      return '$baseUrl/o/r/$resourcePath';
    }

    // 其他情况，尝试构建完整URL
    return '$baseUrl$resourcePath';
  }

  static bool isServerResourcePath(String resourcePath) =>
      resourcePath.startsWith('/o/r/') ||
      resourcePath.startsWith('/file/') ||
      resourcePath.startsWith('attachments/') ||
      resourcePath.startsWith('/resource/') ||
      resourcePath.startsWith('/api/v1/attachments/') ||
      resourcePath.startsWith('/api/v1/resource/');

  static MediaType _mimeTypeFor(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    switch (ext) {
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      case '.gif':
        return MediaType('image', 'gif');
      case '.heic':
        return MediaType('image', 'heic');
      case '.heif':
        return MediaType('image', 'heif');
      case '.jpg':
      case '.jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
