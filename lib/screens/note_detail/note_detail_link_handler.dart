// 链接处理模块（从 note_detail_screen.dart 拆分）
// 职责：处理笔记内的链接跳转（内部引用和外部链接）

import 'package:flutter/material.dart';
import 'package:inkroot/screens/note_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// 链接处理助手类
///
/// 负责：
/// 1. 处理笔记内部引用 [[noteId]]
/// 2. 处理外部 URL 链接
/// 3. 链接验证和错误处理
class NoteDetailLinkHandler {
  /// 处理链接点击
  ///
  /// 支持两种链接类型：
  /// - 内部引用：[[noteId]]  → 跳转到对应笔记
  /// - 外部链接：http(s)://... → 在外部浏览器打开
  static Future<void> handleLinkTap(BuildContext context, String? href) async {
    if (href == null || href.isEmpty) return;

    try {
      // 处理笔记内部引用 [[noteId]]
      if (href.startsWith('[[') && href.endsWith(']]')) {
        final noteId = href.substring(2, href.length - 2);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(noteId: noteId),
            ),
          );
        }
        return;
      }

      // 处理外部链接
      final uri = Uri.parse(href);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('无法打开链接: $href'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('链接打开失败: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  /// 检查是否为内部引用链接
  static bool isInternalReference(String? href) {
    if (href == null || href.isEmpty) return false;
    return href.startsWith('[[') && href.endsWith(']]');
  }

  /// 从内部引用中提取笔记 ID
  static String? extractNoteId(String internalRef) {
    if (!isInternalReference(internalRef)) return null;
    return internalRef.substring(2, internalRef.length - 2);
  }

  /// 检查是否为有效的 URL
  static bool isValidUrl(String? href) {
    if (href == null || href.isEmpty) return false;
    try {
      final uri = Uri.parse(href);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
