import 'package:flutter/material.dart';
import 'package:inkroot/models/note_model.dart' show Note;
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:inkroot/services/weread_parser.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:inkroot/l10n/app_localizations_simple.dart';

/// 微信读书笔记导入页面
class WeReadImportScreen extends StatefulWidget {
  const WeReadImportScreen({super.key});

  @override
  State<WeReadImportScreen> createState() => _WeReadImportScreenState();
}

class _WeReadImportScreenState extends State<WeReadImportScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _isImporting = false;
  WeReadNotesData? _previewData;
  bool _showAdvancedOptions = false;  // 是否显示高级选项
  
  // 导入选项
  bool _showBookTitle = true;  // 显示书名
  bool _showChapter = true;    // 显示章节
  bool _showReview = true;     // 显示点评
  
  // 自定义标签
  List<String> _customTags = [];

  @override
  void dispose() {
    _controller.dispose();
    _tagController.dispose();
    super.dispose();
  }
  
  // 添加标签
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) {
      SnackBarUtils.showError(context, '标签不能为空');
      return;
    }
    if (_customTags.contains(tag)) {
      SnackBarUtils.showError(context, '标签已存在');
      return;
    }
    setState(() {
      _customTags.add(tag);
      _tagController.clear();
    });
  }
  
  // 删除标签
  void _removeTag(String tag) {
    setState(() {
      _customTags.remove(tag);
    });
  }

  // 检查笔记
  void _checkNotes() {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      final l10n = AppLocalizationsSimple.of(context);
      SnackBarUtils.showError(context, l10n?.wereadPleasePasteContent ?? '请粘贴微信读书笔记内容');
      return;
    }

    try {
      final data = WeReadParser.parse(content);
      setState(() {
        _previewData = data;
        // 自动添加默认标签（如果用户还没有添加）
        if (_customTags.isEmpty) {
          _customTags = ['微信读书', data.bookTitle];
        }
      });
      final l10n = AppLocalizationsSimple.of(context);
      SnackBarUtils.showSuccess(context, l10n?.wereadCheckSuccess(data.notes.length) ?? '✅ 检查通过！共 ${data.notes.length} 条笔记');
    } catch (e) {
      final l10n = AppLocalizationsSimple.of(context);
      SnackBarUtils.showError(context, '${l10n?.wereadParseFailed ?? '解析失败'}: $e');
      setState(() {
        _previewData = null;
      });
    }
  }

  // 导入笔记
  Future<void> _importNotes() async {
    if (_previewData == null) {
      final l10n = AppLocalizationsSimple.of(context);
      SnackBarUtils.showError(context, l10n?.wereadPleaseCheckFirst ?? '请先预览笔记');
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      // 为每条笔记创建单独的 Note
      int importedCount = 0;
      final bookTitle = _previewData!.bookTitle;
      
      for (final wereadNote in _previewData!.notes) {
        // 构建笔记内容
        final buffer = StringBuffer();
        
        // 根据用户选择添加点评
        if (_showReview && wereadNote.review != null) {
          buffer.writeln('📝 **点评** (${wereadNote.reviewDate ?? ''})\n');
          buffer.writeln('${wereadNote.review}\n');
          buffer.writeln('---\n');
        }
        
        // 根据用户选择添加章节信息
        if (_showChapter) {
          buffer.writeln('**${wereadNote.chapter}**\n');
        }
        
        // 添加笔记内容（使用引用格式）
        buffer.writeln('> ${wereadNote.content}\n');
        
        // 根据用户选择添加来源标记
        if (_showBookTitle) {
          buffer.writeln('---');
          buffer.writeln('*来自《$bookTitle》*');
        }
        
        // 🔥 在内容末尾添加标签标记，确保标签能被正确提取
        final tagsToUse = _customTags.isNotEmpty ? _customTags : ['微信读书', bookTitle];
        buffer.write('\n');
        for (final tag in tagsToUse) {
          buffer.write('#$tag ');
        }
        
        // 创建单独的笔记，使用用户自定义的标签
        final note = Note(
          id: const Uuid().v4(),
          content: buffer.toString(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: tagsToUse,
        );
        
        await _databaseService.saveNote(note);
        importedCount++;
      }

      // 🔥 刷新笔记列表（关键！否则主页看不到新笔记）
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.loadNotesFromLocal();
      }

      if (mounted) {
        final l10n = AppLocalizationsSimple.of(context);
        SnackBarUtils.showSuccess(context, l10n?.wereadImportSuccess(importedCount) ?? '成功导入 $importedCount 条笔记！');
        Navigator.of(context).pop(true); // 返回 true 表示需要刷新
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '导入失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsSimple.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkTextSecondaryColor
        : AppTheme.textSecondaryColor;
    final iconColor =
        isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n?.wereadImportTitle ?? '微信读书笔记导入',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
        actions: [
          if (_previewData != null)
            TextButton(
              onPressed: _isImporting ? null : _importNotes,
              child: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n?.wereadImport ?? '导入',
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 使用说明
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.wereadUsageInstructions ?? '使用说明',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.wereadInstructions ?? '1. 在微信读书 App 中打开一本书\n2. 点击右上角"..."\u2192"笔记"\n3. 点击"分享"\u2192"复制为文本"\n4. 粘贴到下方输入框\n5. 点击"检查"验证格式\n6. 可选：展开"高级选项"自定义设置\n7. 点击右上角"导入"完成导入',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          // 输入框
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: l10n?.wereadPasteHint ?? '粘贴微信读书笔记...\n\n例如：\n《书名》\n\n35个笔记\n点评\n\n第一章 标题\n\n笔记内容...',
                  hintStyle: TextStyle(
                    color: secondaryTextColor.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  // 清除预览
                  if (_previewData != null) {
                    setState(() {
                      _previewData = null;
                    });
                  }
                },
              ),
            ),
          ),

          // 检查结果
          if (_previewData != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // 解析成功提示
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '解析成功',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.wereadBookInfo(
                              _previewData!.bookTitle,
                              _previewData!.notes.length,
                              _previewData!.notes.map((n) => n.chapter).toSet().length,
                            ) ?? '书名: ${_previewData!.bookTitle}\n笔记数: ${_previewData!.notes.length} 条\n章节数: ${_previewData!.notes.map((n) => n.chapter).toSet().length} 个',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 高级选项按钮
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showAdvancedOptions = !_showAdvancedOptions;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: iconColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n?.wereadAdvancedOptions ?? '高级选项',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _showAdvancedOptions ? '收起' : '展开',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showAdvancedOptions 
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 高级选项面板
                    if (_showAdvancedOptions) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 显示选项标题
                            Text(
                              '显示选项',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                          CheckboxListTile(
                            title: Text(l10n?.wereadShowBookTitle ?? '显示书名来源', style: TextStyle(color: textColor)),
                            subtitle: Text(l10n?.wereadShowBookTitleDesc ?? '在笔记末尾显示"来自《书名》"', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                            value: _showBookTitle,
                            activeColor: iconColor,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _showBookTitle = value ?? true;
                              });
                            },
                          ),
                          Divider(height: 1, color: secondaryTextColor.withOpacity(0.1)),
                          CheckboxListTile(
                            title: Text(l10n?.wereadShowChapter ?? '显示章节信息', style: TextStyle(color: textColor)),
                            subtitle: Text(l10n?.wereadShowChapterDesc ?? '显示笔记所在章节', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                            value: _showChapter,
                            activeColor: iconColor,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _showChapter = value ?? true;
                              });
                            },
                          ),
                          Divider(height: 1, color: secondaryTextColor.withOpacity(0.1)),
                          CheckboxListTile(
                            title: Text('显示阅读点评', style: TextStyle(color: textColor)),
                            subtitle: Text('如果有点评内容则显示', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                            value: _showReview,
                            activeColor: iconColor,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _showReview = value ?? true;
                              });
                            },
                          ),
                            
                            const SizedBox(height: 20),
                            
                            // 自定义标签标题
                            Text(
                              l10n?.wereadCustomTags ?? '自定义标签',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // 标签输入框
                            Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: '输入标签名称...',
                              hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode 
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode 
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: iconColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addTag,
                          icon: Icon(Icons.add_circle, color: iconColor, size: 32),
                          tooltip: '添加标签',
                        ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // 标签列表
                            if (_customTags.isNotEmpty)
                              Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _customTags.map((tag) {
                          return Chip(
                            label: Text(tag, style: TextStyle(color: textColor)),
                            backgroundColor: iconColor.withOpacity(0.1),
                            deleteIcon: Icon(Icons.close, size: 18, color: iconColor),
                            onDeleted: () => _removeTag(tag),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: iconColor.withOpacity(0.3)),
                            ),
                          );
                                }).toList(),
                              ),
                            
                            if (_customTags.isEmpty)
                              Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: secondaryTextColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: secondaryTextColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '点击上方添加按钮添加标签，默认使用"微信读书"和书名作为标签',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _previewData = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: iconColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.wereadClear ?? '清空',
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkNotes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.wereadCheck ?? '检查',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
