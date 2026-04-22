import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notion_sync_service.dart';
import '../services/notion_api_service.dart';
import '../models/notion_field_mapping.dart';
import '../themes/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../providers/app_provider.dart';
import '../l10n/app_localizations_simple.dart';
import 'package:provider/provider.dart';

/// Notion 设置页面
/// 参考滴答清单的 Notion 集成 UI
class NotionSettingsScreen extends StatefulWidget {
  const NotionSettingsScreen({super.key});

  @override
  State<NotionSettingsScreen> createState() => _NotionSettingsScreenState();
}

class _NotionSettingsScreenState extends State<NotionSettingsScreen> {
  final NotionSyncService _syncService = NotionSyncService();
  final TextEditingController _tokenController = TextEditingController();
  
  bool _isEnabled = false;
  bool _isAutoSync = false;
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isSyncing = false;
  
  String? _selectedDatabaseId;
  String? _selectedDatabaseName;
  List<NotionDatabase> _databases = [];
  NotionDatabase? _selectedDatabase;
  
  String _syncDirection = 'to_notion';
  DateTime? _lastSyncTime;
  
  NotionFieldMapping? _fieldMapping;
  int _syncProgress = 0;
  int _syncTotal = 0;
  bool _showFieldMapping = false;
  
  // 进度对话框的状态更新函数
  void Function(void Function())? _dialogSetState;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      _isEnabled = await _syncService.isEnabled();
      _isAutoSync = await _syncService.isAutoSyncEnabled();
      _syncDirection = await _syncService.getSyncDirection();
      _selectedDatabaseId = await _syncService.getDatabaseId();
      _lastSyncTime = await _syncService.getLastSyncTime();
      _fieldMapping = await _syncService.getFieldMapping();
      
      final token = await _syncService.getAccessToken();
      if (token != null) {
        _tokenController.text = token;
      }
      
      // 如果已配置，加载数据库列表
      if (token != null && token.isNotEmpty) {
        await _loadDatabases();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '加载设置失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDatabases() async {
    try {
      print('🔍 开始加载 Notion 数据库列表...');
      _databases = await _syncService.getDatabases();
      print('✅ 成功加载 ${_databases.length} 个数据库');
      
      // 打印数据库信息
      for (var db in _databases) {
        print('  📚 数据库: ${db.title} (ID: ${db.id})');
      }
      
      // 查找选中的数据库
      if (_selectedDatabaseId != null) {
        try {
          _selectedDatabase = _databases.firstWhere((db) => db.id == _selectedDatabaseId);
          _selectedDatabaseName = _selectedDatabase!.title;
          
          // 如果还没有字段映射，创建默认映射
          if (_fieldMapping == null && _selectedDatabase != null) {
            _fieldMapping = NotionFieldMapping.createDefault(_selectedDatabase!.propertyList);
            print('📋 创建默认字段映射:');
            print('  标题 → ${_fieldMapping!.titleProperty}');
            print('  标签 → ${_fieldMapping!.tagsProperty}');
            print('  创建时间 → ${_fieldMapping!.createdProperty}');
            print('  更新时间 → ${_fieldMapping!.updatedProperty}');
          }
        } catch (e) {
          _selectedDatabaseName = '未知数据库';
        }
      }
      
      if (mounted) {
        setState(() {});
        if (_databases.isEmpty) {
          SnackBarUtils.showError(context, '未找到任何数据库，请确保已在 Notion 中分享数据库给集成');
        }
      }
    } catch (e, stackTrace) {
      print('❌ 加载数据库列表失败: $e');
      print('堆栈跟踪: $stackTrace');
      if (mounted) {
        SnackBarUtils.showError(context, '加载数据库列表失败: $e');
      }
    }
  }

  Future<void> _testConnection() async {
    if (_tokenController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, '请输入访问令牌');
      return;
    }
    
    setState(() => _isTesting = true);
    
    try {
      await _syncService.setAccessToken(_tokenController.text.trim());
      final success = await _syncService.testConnection();
      
      if (mounted) {
        if (success) {
          SnackBarUtils.showSuccess(context, '✅ 连接成功！');
          await _loadDatabases();
        } else {
          SnackBarUtils.showError(context, '❌ 连接失败，请检查令牌是否正确');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '连接测试失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _saveSettings({bool showSuccessMessage = true}) async {
    final l10n = AppLocalizationsSimple.of(context);
    
    if (_tokenController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, l10n?.notionPleaseEnterToken ?? '请输入访问令牌');
      return;
    }
    
    if (_selectedDatabaseId == null) {
      SnackBarUtils.showError(context, l10n?.notionPleaseSelectDatabase ?? '请选择数据库');
      return;
    }
    
    try {
      await _syncService.setAccessToken(_tokenController.text.trim());
      await _syncService.setDatabaseId(_selectedDatabaseId!);
      await _syncService.setEnabled(_isEnabled);
      await _syncService.setAutoSync(_isAutoSync);
      await _syncService.setSyncDirection(_syncDirection);
      
      // 保存字段映射
      if (_fieldMapping != null) {
        await _syncService.setFieldMapping(_fieldMapping!);
        print('💾 已保存字段映射配置');
      }
      
      if (mounted && showSuccessMessage) {
        SnackBarUtils.showSuccess(context, l10n?.notionSettingsSaved ?? '✅ 设置已保存');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '${l10n?.notionSaveSettingsFailed ?? '保存设置失败'}: $e');
      }
    }
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizationsSimple.of(context);
    
    if (!_isEnabled) {
      SnackBarUtils.showError(context, l10n?.notionPleaseEnableSync ?? '请先启用 Notion 同步');
      return;
    }
    
    // 先自动保存配置（不显示成功提示）
    await _saveSettings(showSuccessMessage: false);
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final notes = appProvider.notes;
    
    setState(() {
      _isSyncing = true;
      _syncProgress = 0;
      _syncTotal = _syncDirection == 'to_notion' ? notes.length : 0;
    });
    
    // 显示进度对话框
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSyncProgressDialog(),
      );
    }
    
    try {
      Map<String, dynamic> result;
      
      switch (_syncDirection) {
        case 'to_notion':
          result = await _syncService.syncNotesToNotion(
            notes,
            onProgress: (current, total) {
              if (mounted) {
                setState(() {
                  _syncProgress = current;
                  _syncTotal = total;
                });
                // 同时更新对话框
                _dialogSetState?.call(() {});
              }
            },
          );
          break;
        case 'from_notion':
          result = await _syncService.syncNotesFromNotion(
            onProgress: (current, total) {
              if (mounted) {
                setState(() {
                  _syncProgress = current;
                  _syncTotal = total;
                });
                // 同时更新对话框
                _dialogSetState?.call(() {});
              }
            },
          );
          break;
        default:
          result = await _syncService.syncNotesToNotion(
            notes,
            onProgress: (current, total) {
              if (mounted) {
                setState(() {
                  _syncProgress = current;
                  _syncTotal = total;
                });
                // 同时更新对话框
                _dialogSetState?.call(() {});
              }
            },
          );
      }
      
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        final successCount = result['success'] ?? 0;
        final failCount = result['failed'] ?? 0;
        
        if (failCount > 0) {
          SnackBarUtils.showError(
            context,
            l10n?.notionSyncComplete(successCount, failCount) ?? '同步完成: 成功 $successCount 条，失败 $failCount 条',
          );
        } else {
          SnackBarUtils.showSuccess(
            context,
            l10n?.notionSyncSuccess(successCount) ?? '同步成功！已同步 $successCount 条笔记',
          );
        }
        
        // 重新加载设置以更新最后同步时间
        await _loadSettings();
      }
    } catch (e) {
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        SnackBarUtils.showError(context, '${l10n?.notionSyncFailed ?? '同步失败'}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncProgress = 0;
          _syncTotal = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizationsSimple.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDarkMode ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;
    final iconColor = isDarkMode ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(l10n?.notionSync ?? 'Notion 同步', style: TextStyle(color: textColor)),
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: iconColor),
        ),
        body: Center(
          child: CircularProgressIndicator(color: iconColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Notion 同步', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: iconColor),
            onPressed: () => _showHelpDialog(context, textColor, secondaryTextColor, iconColor),
            tooltip: '常见问题',
          ),
          TextButton(
            onPressed: _saveSettings,
            child: Text(l10n?.notionSave ?? '保存', style: TextStyle(color: iconColor, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明卡片
            Container(
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
                      Text(l10n?.notionHowToGetToken ?? '如何获取 Notion 访问令牌？', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.notionTokenInstructions ?? '1. 访问 https://www.notion.so/my-integrations\n2. 点击"New integration"创建集成\n3. 复制"Internal Integration Token"\n4. 在 Notion 中分享数据库给该集成',
                    style: TextStyle(color: secondaryTextColor, fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 启用开关
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.sync, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n?.notionEnableSync ?? '启用 Notion 同步', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(l10n?.notionAutoSyncDesc ?? '自动同步笔记到 Notion', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEnabled,
                    onChanged: (value) => setState(() => _isEnabled = value),
                    activeColor: iconColor,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 访问令牌
            Text(l10n?.notionAccessToken ?? '访问令牌', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: '输入 Notion Integration Token',
                      hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isTesting ? null : _testConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isTesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(l10n?.notionTest ?? '测试', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 选择数据库
            Text(l10n?.notionSelectDatabase ?? '选择数据库', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedDatabaseId,
                isExpanded: true,
                underline: const SizedBox(),
                hint: Text(l10n?.notionSelectDatabaseHint ?? '选择一个 Notion 数据库', style: TextStyle(color: secondaryTextColor)),
                items: _databases.map((db) {
                  return DropdownMenuItem(
                    value: db.id,
                    child: Text(db.title, style: TextStyle(color: textColor)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDatabaseId = value;
                    _selectedDatabaseName = _databases.firstWhere((db) => db.id == value).title;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 同步方向
            Text(l10n?.notionSyncDirection ?? '同步方向', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text(l10n?.notionSyncToNotion ?? '仅同步到 Notion', style: TextStyle(color: textColor)),
                    subtitle: Text(l10n?.notionSyncToNotionDesc ?? '本地笔记 → Notion', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                    value: 'to_notion',
                    groupValue: _syncDirection,
                    activeColor: iconColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _syncDirection = value!),
                  ),
                  Divider(height: 1, color: secondaryTextColor.withOpacity(0.1)),
                  RadioListTile<String>(
                    title: Text(l10n?.notionSyncFromNotion ?? '仅从 Notion 同步', style: TextStyle(color: textColor)),
                    subtitle: Text(l10n?.notionSyncFromNotionDesc ?? 'Notion → 本地笔记', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                    value: 'from_notion',
                    groupValue: _syncDirection,
                    activeColor: iconColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _syncDirection = value!),
                  ),
                  Divider(height: 1, color: secondaryTextColor.withOpacity(0.1)),
                  RadioListTile<String>(
                    title: Text(l10n?.notionSyncBoth ?? '双向同步', style: TextStyle(color: textColor)),
                    subtitle: Text(l10n?.notionSyncBothDesc ?? '本地笔记 ↔ Notion', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                    value: 'both',
                    groupValue: _syncDirection,
                    activeColor: iconColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _syncDirection = value!),
                  ),
                ],
              ),
            ),
            
            // 字段映射配置
            _buildFieldMappingSection(cardColor, textColor, secondaryTextColor, iconColor),
            
            const SizedBox(height: 16),
            
            // 自动同步
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.autorenew, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n?.notionAutoSync ?? '自动同步', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(l10n?.notionAutoSyncWhen ?? '创建或修改笔记时自动同步', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAutoSync,
                    onChanged: (value) => setState(() => _isAutoSync = value),
                    activeColor: iconColor,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 立即同步按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSyncing ? null : _syncNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(l10n?.notionSyncNowButton ?? '立即同步', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            
            // 最后同步时间
            if (_lastSyncTime != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  l10n?.notionLastSyncTime(_formatDateTime(_lastSyncTime!)) ?? '最后同步: ${_formatDateTime(_lastSyncTime!)}',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建字段映射配置 UI
  Widget _buildFieldMappingSection(Color cardColor, Color textColor, Color secondaryTextColor, Color iconColor) {
    final l10n = AppLocalizationsSimple.of(context);
    
    if (_selectedDatabase == null || _fieldMapping == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和展开按钮
          InkWell(
            onTap: () => setState(() => _showFieldMapping = !_showFieldMapping),
            child: Row(
              children: [
                Icon(Icons.settings_suggest, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.notionFieldMapping ?? '字段映射',
                        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        l10n?.notionFieldMappingDescription ?? '配置笔记字段如何映射到 Notion 属性',
                        style: TextStyle(color: secondaryTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showFieldMapping ? Icons.expand_less : Icons.expand_more,
                  color: secondaryTextColor,
                ),
              ],
            ),
          ),
          
          // 展开的映射配置
          if (_showFieldMapping) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // 标题映射（必需）
            _buildMappingRow(
              label: l10n?.notionNoteTitle ?? '笔记标题',
              required: true,
              currentValue: _fieldMapping!.titleProperty,
              availableProperties: _selectedDatabase!.getPropertiesByType('title'),
              onChanged: (value) {
                setState(() {
                  _fieldMapping = _fieldMapping!.copyWith(titleProperty: value);
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              iconColor: iconColor,
            ),
            
            const SizedBox(height: 12),
            
            // 内容映射（可选）
            _buildMappingRow(
              label: l10n?.notionNoteContent ?? '笔记内容',
              required: false,
              currentValue: _fieldMapping!.contentProperty,
              availableProperties: _selectedDatabase!.getPropertiesByType('rich_text'),
              onChanged: (value) {
                setState(() {
                  _fieldMapping = _fieldMapping!.copyWith(contentProperty: value);
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              iconColor: iconColor,
              hint: l10n?.notionContentMappingHint ?? '不映射则写入页面正文',
            ),
            
            const SizedBox(height: 12),
            
            // 标签映射（可选）- 支持 select 和 multi_select
            _buildMappingRow(
              label: l10n?.notionNoteTags ?? '笔记标签',
              required: false,
              currentValue: _fieldMapping!.tagsProperty,
              availableProperties: _getUniqueProperties([
                ..._selectedDatabase!.getPropertiesByType('multi_select'),
                ..._selectedDatabase!.getPropertiesByType('select'),
              ]),
              onChanged: (value) {
                setState(() {
                  _fieldMapping = _fieldMapping!.copyWith(tagsProperty: value);
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              iconColor: iconColor,
            ),
            
            const SizedBox(height: 12),
            
            // 创建时间映射（可选）- 支持 date 和 created_time 类型
            _buildMappingRow(
              label: l10n?.notionNoteCreated ?? '创建时间',
              required: false,
              currentValue: _fieldMapping!.createdProperty,
              availableProperties: _getUniqueProperties([
                ..._selectedDatabase!.getPropertiesByType('date'),
                ..._selectedDatabase!.getPropertiesByType('created_time'),
              ]),
              onChanged: (value) {
                setState(() {
                  _fieldMapping = _fieldMapping!.copyWith(createdProperty: value);
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              iconColor: iconColor,
            ),
            
            const SizedBox(height: 12),
            
            // 更新时间映射（可选）- 支持 date 和 last_edited_time 类型
            _buildMappingRow(
              label: l10n?.notionNoteUpdated ?? '更新时间',
              required: false,
              currentValue: _fieldMapping!.updatedProperty,
              availableProperties: _getUniqueProperties([
                ..._selectedDatabase!.getPropertiesByType('date'),
                ..._selectedDatabase!.getPropertiesByType('last_edited_time'),
              ]),
              onChanged: (value) {
                setState(() {
                  _fieldMapping = _fieldMapping!.copyWith(updatedProperty: value);
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              iconColor: iconColor,
            ),
            
            const SizedBox(height: 16),
            
            // 重置为默认映射按钮
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _fieldMapping = NotionFieldMapping.createDefault(_selectedDatabase!.propertyList);
                  });
                  SnackBarUtils.showSuccess(context, '已重置为智能默认映射');
                },
                icon: Icon(Icons.refresh, size: 18, color: iconColor),
                label: Text(
                  l10n?.notionUseDefaultMapping ?? '使用默认映射',
                  style: TextStyle(color: iconColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// 构建单个映射行
  Widget _buildMappingRow({
    required String label,
    required bool required,
    required String? currentValue,
    required List<NotionProperty> availableProperties,
    required Function(String?) onChanged,
    required Color textColor,
    required Color secondaryTextColor,
    required Color iconColor,
    String? hint,  // 提示文本
  }) {
    final l10n = AppLocalizationsSimple.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            if (required)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n?.notionMappingRequired ?? '必需',
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: secondaryTextColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n?.notionMappingOptional ?? '可选',
                  style: TextStyle(color: secondaryTextColor, fontSize: 10),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: secondaryTextColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentValue,
              hint: Text(
                l10n?.notionNoProperty ?? '不映射',
                style: TextStyle(color: secondaryTextColor),
              ),
              items: [
                // 不映射选项
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    l10n?.notionNoProperty ?? '不映射',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
                // 可用属性
                ...availableProperties.map((prop) => DropdownMenuItem<String>(
                  value: prop.name,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          prop.name,
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          prop.typeDisplayName,
                          style: TextStyle(color: iconColor, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(color: secondaryTextColor, fontSize: 12),
          ),
        ],
      ],
    );
  }

  /// 去重属性列表（按属性名）
  List<NotionProperty> _getUniqueProperties(List<NotionProperty> properties) {
    final seen = <String>{};
    return properties.where((prop) => seen.add(prop.name)).toList();
  }
  
  /// 构建同步进度对话框
  Widget _buildSyncProgressDialog() {
    final l10n = AppLocalizationsSimple.of(context);
    
    return StatefulBuilder(
      builder: (context, setDialogState) {
        // 保存对话框的 setState 引用
        _dialogSetState = setDialogState;
        
        final progress = _syncTotal > 0 ? _syncProgress / _syncTotal : 0.0;
        
        return AlertDialog(
          title: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(_syncDirection == 'to_notion' ? (l10n?.notionSyncingToNotion ?? '同步到 Notion') : (l10n?.notionSyncingFromNotion ?? '从 Notion 同步')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${l10n?.notionSyncingProgress ?? '正在同步'}: $_syncProgress / $_syncTotal',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示帮助对话框
  void _showHelpDialog(BuildContext context, Color textColor, Color secondaryTextColor, Color iconColor) {
    final l10n = AppLocalizationsSimple.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: iconColor),
            const SizedBox(width: 8),
            Text(l10n?.notionHelpTitle ?? '常见问题'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFAQItem(
                l10n?.notionFaqSyncFailTitle ?? '❓ 同步失败怎么办？',
                l10n?.notionFaqSyncFailContent ?? '1. 检查字段映射是否完整（标题必须映射）\n2. 确认已在 Notion 中分享数据库给集成\n3. 查看控制台日志了解具体错误\n4. 尝试完全重启应用',
                textColor,
                secondaryTextColor,
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                l10n?.notionFaqSelectTagTitle ?? '❓ 标签属性是单选怎么办？',
                l10n?.notionFaqSelectTagContent ?? '如果你的 Notion 数据库中标签属性是"单选"类型：\n• 只会同步第一个标签\n• 建议在 Notion 中改为"多选"类型',
                textColor,
                secondaryTextColor,
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                l10n?.notionFaqSystemTimeTitle ?? '❓ 创建时间/更新时间无法写入？',
                l10n?.notionFaqSystemTimeContent ?? '如果映射到系统属性（created_time、last_edited_time）：\n• 这些是只读属性，由 Notion 自动管理\n• 建议映射到普通的"日期"类型属性',
                textColor,
                secondaryTextColor,
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                l10n?.notionFaqGlobalKeyTitle ?? '❓ GlobalKey 错误怎么办？',
                l10n?.notionFaqGlobalKeyContent ?? '这是 Flutter 热重载的已知问题：\n• 完全停止应用（按 q）\n• 重新运行 flutter run -d macos',
                textColor,
                secondaryTextColor,
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                l10n?.notionFaqViewLogsTitle ?? '❓ 如何查看详细日志？',
                l10n?.notionFaqViewLogsContent ?? '在终端中查看以下标记的日志：\n• 📊 数据库信息\n• 🔍 字段映射\n• 📤 同步过程\n• ✅/❌ 成功/失败',
                textColor,
                secondaryTextColor,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.notionHelpKnowIt ?? '知道了', style: TextStyle(color: iconColor)),
          ),
        ],
      ),
    );
  }
  
  /// 构建FAQ项
  Widget _buildFAQItem(String question, String answer, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          answer,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} 小时前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
