import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Memos资源上传服务
class MemosResourceService {
  MemosResourceService({required this.baseUrl, this.token});
  final String baseUrl;
  final String? token;

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

      // 创建multipart请求
      final uri = Uri.parse('$baseUrl/api/v1/resource/blob');
      final request = http.MultipartRequest('POST', uri);

      // 添加请求头
      request.headers.addAll(_getHeaders());

      // 添加文件
      final fileName = path.basename(imageFile.path);
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: fileName,
      );
      request.files.add(multipartFile);

      debugPrint('MemosResourceService: 发送上传请求到 $uri');

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('MemosResourceService: 收到响应，状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('MemosResourceService: 上传成功 - $data');

        return {
          'success': true,
          'data': data,
          'resourceId': data['id'],
          'resourceUid': data['uid'],
          'filename': data['filename'],
          'type': data['type'],
          'size': data['size'],
        };
      } else {
        debugPrint(
          'MemosResourceService: 上传失败: ${response.statusCode} - ${response.body}',
        );
        throw Exception('上传失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MemosResourceService: 上传图片时发生错误: $e');
      throw Exception('上传图片失败: $e');
    }
  }

  /// 批量上传图片
  Future<List<Map<String, dynamic>>> uploadImages(List<File> imageFiles) async {
    final results = <Map<String, dynamic>>[];

    for (var i = 0; i < imageFiles.length; i++) {
      try {
        debugPrint('MemosResourceService: 上传第${i + 1}/${imageFiles.length}张图片');
        final result = await uploadImage(imageFiles[i]);
        results.add(result);
      } catch (e) {
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
      final resourceUid = uploadResult['resourceUid'];
      return '![$alt](/o/r/$resourceUid)';
    } else {
      throw Exception('无法为上传失败的图片生成Markdown');
    }
  }

  /// 构建完整的图片URL
  String buildImageUrl(String resourcePath) {
    // 如果已经是完整URL，直接返回
    if (resourcePath.startsWith('http://') ||
        resourcePath.startsWith('https://')) {
      return resourcePath;
    }

    // 如果是Memos资源路径，支持多种格式
    if (resourcePath.startsWith('/o/r/') ||
        resourcePath.startsWith('/file/') ||
        resourcePath.startsWith('/resource/') ||
        resourcePath.startsWith('/api/v1/resource/')) {
      return '$baseUrl$resourcePath';
    }

    // 如果是纯ID，尝试构建为/o/r/格式
    if (!resourcePath.contains('/') && resourcePath.isNotEmpty) {
      return '$baseUrl/o/r/$resourcePath';
    }

    // 其他情况，尝试构建完整URL
    return '$baseUrl$resourcePath';
  }
}
