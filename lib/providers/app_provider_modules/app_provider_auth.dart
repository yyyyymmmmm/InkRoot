import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/models/user_model.dart';
import 'package:inkroot/services/api_service.dart';
import 'package:inkroot/services/api_service_factory.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:inkroot/services/incremental_sync_service.dart';
import 'package:inkroot/services/memos_api_service_fixed.dart';
import 'package:inkroot/services/memos_resource_service.dart';
import 'package:inkroot/services/preferences_service.dart';
import 'package:inkroot/models/app_config_model.dart';
import 'package:inkroot/widgets/cached_avatar.dart';
import 'package:uuid/uuid.dart';

/// 认证相关功能的 Mixin
/// 包含注册、登录、登出等认证操作
mixin AppProviderAuth on ChangeNotifier {
  // 需要在 AppProvider 中定义的属性（由子类提供）
  User? get _user;
  set _user(User? value);

  ApiService? get _apiService;
  set _apiService(ApiService? value);

  MemosApiServiceFixed? get _memosApiService;
  set _memosApiService(MemosApiServiceFixed? value);

  MemosResourceService? get _resourceService;
  set _resourceService(MemosResourceService? value);

  DatabaseService get _databaseService;
  PreferencesService get _preferencesService;
  AppConfig get _appConfig;
  set _appConfig(AppConfig value);

  IncrementalSyncService? get _incrementalSyncService;
  set _incrementalSyncService(IncrementalSyncService? value);

  bool get _isSyncing;
  set _isSyncing(bool value);

  String? get _syncMessage;
  set _syncMessage(String? value);

  Timer? get _syncTimer;
  set _syncTimer(Timer? value);

  bool get mounted;
  bool get isLoggedIn;

  // 需要由子类实现的方法
  Future<void> updateConfig(AppConfig config);
  Future<bool> hasLocalData();
  Future<bool> hasServerData();
  Future<void> fetchNotesFromServer();
  Future<void> loadNotesFromLocal();
  void startAutoSync();
  void stopAutoSync();
  void _setLoading(bool loading);
  Future<void> syncNotesWithServer();

  // ==================== 注册功能 ====================

  /// 使用账号密码注册
  Future<(bool, String?)> registerWithPassword(
    String serverUrl,
    String username,
    String password, {
    bool remember = false,
  }) async {
    try {
      debugPrint('AppProvider: 尝试注册账号 - URL: $serverUrl, 用户名: $username');

      // 规范化URL（确保末尾没有斜杠）
      final normalizedUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;

      debugPrint('AppProvider: 规范化后的URL: $normalizedUrl');

      // 调用注册API
      final response = await http.post(
        Uri.parse('$normalizedUrl/api/v1/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      debugPrint('AppProvider: 注册API响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('AppProvider: 注册成功，尝试自动登录');

        // 注册成功后自动登录
        final loginResult = await loginWithPassword(
          serverUrl,
          username,
          password,
          remember: remember,
        );

        if (loginResult.$1) {
          debugPrint('AppProvider: 注册并登录成功');
          return (true, null);
        } else {
          debugPrint('AppProvider: 注册成功但自动登录失败: ${loginResult.$2}');
          return (false, '注册成功，请手动登录');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final serverMessage = errorData['message']?.toString() ?? '';
        String userFriendlyMessage;

        // 根据HTTP状态码和服务器消息提供用户友好的错误提示
        switch (response.statusCode) {
          case 400:
            if (serverMessage.toLowerCase().contains('invalid username')) {
              userFriendlyMessage = '用户名格式不正确\n只能包含字母、数字、下划线和连字符';
            } else if (serverMessage.toLowerCase().contains('username') &&
                serverMessage.toLowerCase().contains('exists')) {
              userFriendlyMessage = '用户名已存在，请选择其他用户名';
            } else if (serverMessage.toLowerCase().contains('password')) {
              userFriendlyMessage = '密码不符合要求，请重新设置';
            } else if (serverMessage
                .toLowerCase()
                .contains('failed to create user')) {
              userFriendlyMessage = '创建用户失败，用户名可能已存在';
            } else {
              userFriendlyMessage = '注册信息有误，请检查后重试';
            }
            break;
          case 401:
            if (serverMessage.toLowerCase().contains('signup is disabled') ||
                serverMessage.toLowerCase().contains('disallow')) {
              userFriendlyMessage = '该服务器已禁用用户注册功能\n请联系管理员或使用现有账号登录';
            } else if (serverMessage
                .toLowerCase()
                .contains('password login is deactivated')) {
              userFriendlyMessage = '该服务器已禁用密码登录功能\n请联系管理员';
            } else {
              userFriendlyMessage = '注册功能已被管理员禁用，请联系管理员';
            }
            break;
          case 403:
            userFriendlyMessage = '注册功能已被管理员禁用，请联系管理员';
            break;
          case 409:
            userFriendlyMessage = '用户名已被占用，请选择其他用户名';
            break;
          case 429:
            userFriendlyMessage = '注册请求过于频繁，请稍后再试';
            break;
          case 500:
            if (serverMessage.toLowerCase().contains('failed to create user')) {
              userFriendlyMessage = '创建用户失败，可能是用户名已存在或服务器配置问题';
            } else if (serverMessage
                .toLowerCase()
                .contains('failed to generate password hash')) {
              userFriendlyMessage = '密码处理失败，请重新尝试';
            } else {
              userFriendlyMessage = '服务器内部错误，请稍后重试或联系管理员';
            }
            break;
          case 503:
            userFriendlyMessage = '服务器暂时不可用，请稍后重试';
            break;
          default:
            userFriendlyMessage = '注册失败，请检查网络连接和服务器地址';
        }

        debugPrint('AppProvider: 注册失败: $serverMessage');
        return (false, userFriendlyMessage);
      }
    } catch (e) {
      debugPrint('AppProvider: 注册异常: $e');
      String userFriendlyMessage;

      // 根据异常类型提供用户友好的错误提示
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        userFriendlyMessage = '网络连接失败，请检查网络设置';
      } else if (e.toString().contains('TimeoutException')) {
        userFriendlyMessage = '连接超时，请检查网络或稍后重试';
      } else if (e.toString().contains('FormatException') ||
          e.toString().contains('Invalid')) {
        userFriendlyMessage = '服务器响应格式错误，请检查服务器地址';
      } else if (e.toString().contains('HandshakeException') ||
          e.toString().contains('TlsException')) {
        userFriendlyMessage = 'SSL连接失败，请检查服务器证书';
      } else {
        userFriendlyMessage = '注册失败，请检查服务器地址和网络连接';
      }

      return (false, userFriendlyMessage);
    }
  }

  // ==================== 密码登录功能 ====================

  /// 使用账号密码登录
  Future<(bool, String?)> loginWithPassword(
    String serverUrl,
    String username,
    String password, {
    bool remember = false,
  }) async {
    try {
      debugPrint('AppProvider: 尝试使用账号密码登录 - URL: $serverUrl, 用户名: $username');

      // 规范化URL（确保末尾没有斜杠）
      final normalizedUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;

      debugPrint('AppProvider: 规范化后的URL: $normalizedUrl');

      // 构建请求体
      final requestBody = {
        'username': username,
        'password': password,
        'remember': remember,
      };
      debugPrint('AppProvider: 登录请求体: ${jsonEncode(requestBody)}');

      // 调用登录API
      final response = await http.post(
        Uri.parse('$normalizedUrl/api/v1/auth/signin'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('AppProvider: 登录API响应状态: ${response.statusCode}');
      debugPrint('AppProvider: 登录API响应头: ${response.headers}');
      debugPrint('AppProvider: 登录API响应体: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('AppProvider: 登录成功，解析用户信息');

        // 从响应头获取Token（可能在Set-Cookie中）
        String? token;
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          // 解析Cookie中的memos.access-token（注意Cookie名称包含memos.前缀）
          final cookieRegex = RegExp(r'memos\.access-token=([^;]+)');
          final match = cookieRegex.firstMatch(cookies);
          if (match != null) {
            token = match.group(1);
            debugPrint(
              'AppProvider: 从Cookie中提取Token: ${token?.substring(0, 10)}...',
            );
          }
        }

        // 如果没有从Cookie中获取到Token，尝试从响应体中获取
        if (token == null && responseData['accessToken'] != null) {
          token = responseData['accessToken'];
          debugPrint(
            'AppProvider: 从响应体中获取Token: ${token?.substring(0, 10)}...',
          );
        }

        if (token == null) {
          throw Exception('登录成功但无法获取访问令牌，请重试或联系管理员');
        }

        // 创建用户对象
        final user = User(
          id: responseData['id']?.toString() ?? '',
          username: responseData['username'] ?? username,
          email: responseData['email'] ?? '',
          nickname:
              responseData['nickname'] ?? responseData['username'] ?? username,
          avatarUrl: responseData['avatarUrl'],
          role: responseData['role'] ?? 'USER',
          token: token,
        );

        // 保存用户信息到持久化存储和内存
        await _preferencesService.saveUser(user);
        _user = user;

        // 注意：新token登录成功后，服务器端的旧token应该会自动失效
        // 这是大多数现代认证系统的标准行为
        // 如果服务器不支持自动撤销旧token，可以考虑：
        // 1. 在登录前调用logout API撤销旧token（需要旧token仍有效）
        // 2. 设置更短的token过期时间
        // 3. 要求服务器端实现单点登录机制

        // 更新应用配置
        _appConfig = _appConfig.copyWith(
          memosApiUrl: normalizedUrl,
          lastToken: remember ? token : null,
          lastUsername: remember ? username : null,
          lastServerUrl: normalizedUrl,
          rememberLogin: remember,
          autoLogin: true, // 登录成功后自动开启自动登录
          isLocalMode: false, // 登录成功后切换到在线模式
        );

        // 保存配置更新
        await _preferencesService.saveAppConfig(_appConfig);

        // 如果选择记住登录，保存到安全存储
        if (remember) {
          await saveLoginInfo(
            normalizedUrl,
            username,
            token: token,
            password: password,
          );
        }

        // 初始化API服务
        _memosApiService = await ApiServiceFactory.createApiService(
          baseUrl: normalizedUrl,
          token: token,
        ) as MemosApiServiceFixed;

        // 初始化资源服务
        _resourceService = MemosResourceService(
          baseUrl: normalizedUrl,
          token: token,
        );

        debugPrint('AppProvider: 账号密码登录成功');
        notifyListeners();

        // 🖼️ 预加载用户头像（提升用户体验）
        _preloadUserAvatarAsync();

        return (true, null);
      } else {
        final errorData = jsonDecode(response.body);
        final serverMessage = errorData['message']?.toString() ?? '';
        String userFriendlyMessage;

        // 根据HTTP状态码和服务器消息提供用户友好的错误提示
        switch (response.statusCode) {
          case 401:
            if (serverMessage.toLowerCase().contains('password') ||
                serverMessage.toLowerCase().contains('credentials')) {
              userFriendlyMessage = '用户名或密码错误，请检查后重试';
            } else if (serverMessage.toLowerCase().contains('deactivated')) {
              userFriendlyMessage = '密码登录已被管理员禁用，请联系管理员';
            } else {
              userFriendlyMessage = '账号或密码不正确';
            }
            break;
          case 403:
            if (serverMessage.toLowerCase().contains('archived')) {
              userFriendlyMessage = '该账号已被停用，请联系管理员';
            } else {
              userFriendlyMessage = '账号被禁止登录，请联系管理员';
            }
            break;
          case 404:
            userFriendlyMessage = '服务器地址不正确或服务不可用';
            break;
          case 429:
            userFriendlyMessage = '登录尝试过于频繁，请稍后再试';
            break;
          case 500:
            userFriendlyMessage = '服务器内部错误，请稍后重试或联系管理员';
            break;
          case 503:
            userFriendlyMessage = '服务器暂时不可用，请稍后重试';
            break;
          default:
            userFriendlyMessage = '登录失败，请检查网络连接和服务器地址';
        }

        debugPrint('AppProvider: 登录失败 - 状态码: ${response.statusCode}');
        debugPrint('AppProvider: 服务器原始消息: $serverMessage');
        debugPrint('AppProvider: 完整响应体: ${response.body}');
        return (false, userFriendlyMessage);
      }
    } catch (e) {
      debugPrint('AppProvider: 账号密码登录失败: $e');
      String userFriendlyMessage;

      // 根据异常类型提供用户友好的错误提示
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        userFriendlyMessage = '网络连接失败，请检查网络设置';
      } else if (e.toString().contains('TimeoutException')) {
        userFriendlyMessage = '连接超时，请检查网络或稍后重试';
      } else if (e.toString().contains('FormatException') ||
          e.toString().contains('Invalid')) {
        userFriendlyMessage = '服务器响应格式错误，请检查服务器地址';
      } else if (e.toString().contains('HandshakeException') ||
          e.toString().contains('TlsException')) {
        userFriendlyMessage = 'SSL连接失败，请检查服务器证书';
      } else {
        userFriendlyMessage = '登录失败，请检查服务器地址和网络连接';
      }

      return (false, userFriendlyMessage);
    }
  }

  // ==================== Token登录功能 ====================

  /// 使用Token登录
  Future<(bool, String?)> loginWithToken(
    String serverUrl,
    String token, {
    bool remember = false,
  }) async {
    try {
      debugPrint('AppProvider: 尝试使用Token登录 - URL: $serverUrl');

      // 规范化URL（确保末尾没有斜杠）
      final normalizedUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;

      debugPrint('AppProvider: 规范化后的URL: $normalizedUrl');

      // 初始化API服务
      _memosApiService = await ApiServiceFactory.createApiService(
        baseUrl: normalizedUrl,
        token: token,
      ) as MemosApiServiceFixed;

      // 初始化资源服务
      _resourceService = MemosResourceService(
        baseUrl: normalizedUrl,
        token: token,
      );

      // 验证Token
      try {
        // 先尝试 v1 API
        debugPrint('AppProvider: 尝试访问 v1 API: $normalizedUrl/api/v1/user/me');
        final response = await http.get(
          Uri.parse('$normalizedUrl/api/v1/user/me'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        debugPrint('AppProvider: v1 API响应状态码: ${response.statusCode}');
        debugPrint('AppProvider: v1 API响应内容: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final userInfo = jsonDecode(response.body);
            debugPrint('AppProvider: 解析到的用户信息: $userInfo');

            // 检查响应格式
            if (userInfo == null) {
              throw Exception('服务器返回空数据');
            }

            User? user;
            if (userInfo['data'] != null) {
              // 新版API格式
              debugPrint('AppProvider: 使用新版API格式解析');
              final userData = userInfo['data'];
              user = User(
                id: userData['id'].toString(),
                username: userData['username'] as String? ?? '',
                nickname: userData['nickname'] as String?,
                email: userData['email'] as String?,
                avatarUrl: userData['avatarUrl'] as String?,
                description: userData['description'] as String?,
                role: (userData['role'] as String?) ?? 'USER',
                token: token,
                lastSyncTime: DateTime.now(),
              );
            } else {
              // 旧版API格式
              debugPrint('AppProvider: 使用旧版API格式解析');
              user = User(
                id: userInfo['id'].toString(),
                username: userInfo['username'] as String? ?? '',
                nickname: userInfo['nickname'] as String?,
                email: userInfo['email'] as String?,
                avatarUrl: userInfo['avatarUrl'] as String?,
                description: userInfo['description'] as String?,
                role: (userInfo['role'] as String?) ?? 'USER',
                token: token,
                lastSyncTime: DateTime.now(),
              );
            }

            // 保存用户信息
            await _preferencesService.saveUser(user);
            _user = user;

            // 更新配置
            final updatedConfig = _appConfig.copyWith(
              memosApiUrl: normalizedUrl,
              lastToken: remember ? token : null,
              rememberLogin: remember,
              isLocalMode: false,
            );
            await updateConfig(updatedConfig);

            debugPrint('AppProvider: Token登录成功');

            // 🖼️ 预加载用户头像（提升用户体验）
            _preloadUserAvatarAsync();

            // 检查本地是否有未同步笔记
            final hasLocalNotes = await hasLocalData();
            if (hasLocalNotes) {
              debugPrint('AppProvider: 检测到本地有笔记数据，需要同步');
            }

            return (true, null);
          } catch (e, stackTrace) {
            debugPrint('AppProvider: 解析用户信息失败: $e');
            debugPrint('AppProvider: 错误堆栈: $stackTrace');
            throw Exception('解析用户信息失败: $e');
          }
        } else if (response.statusCode == 404 || response.statusCode == 401) {
          // 如果v1 API不存在或未授权，尝试旧版API
          debugPrint('AppProvider: v1 API返回 ${response.statusCode}，尝试旧版API');
          debugPrint('AppProvider: 尝试访问旧版API: $normalizedUrl/api/user/me');

          final oldResponse = await http.get(
            Uri.parse('$normalizedUrl/api/user/me'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          debugPrint('AppProvider: 旧版API响应状态码: ${oldResponse.statusCode}');
          debugPrint('AppProvider: 旧版API响应内容: ${oldResponse.body}');

          if (oldResponse.statusCode == 200) {
            try {
              final userInfo = jsonDecode(oldResponse.body);
              debugPrint('AppProvider: 解析到的用户信息（旧版API）: $userInfo');

              final user = User(
                id: userInfo['id'].toString(),
                username: userInfo['username'] as String? ?? '',
                nickname: userInfo['nickname'] as String?,
                email: userInfo['email'] as String?,
                avatarUrl: userInfo['avatarUrl'] as String?,
                description: userInfo['description'] as String?,
                role: (userInfo['role'] as String?) ?? 'USER',
                token: token,
                lastSyncTime: DateTime.now(),
              );

              // 保存用户信息
              await _preferencesService.saveUser(user);
              _user = user;

              // 更新配置
              final updatedConfig = _appConfig.copyWith(
                memosApiUrl: normalizedUrl,
                lastToken: remember ? token : null,
                rememberLogin: remember,
                isLocalMode: false,
              );
              await updateConfig(updatedConfig);

              debugPrint('AppProvider: Token登录成功（旧版API）');

              // 检查本地是否有未同步笔记
              final hasLocalNotes = await hasLocalData();
              if (hasLocalNotes) {
                debugPrint('AppProvider: 检测到本地有笔记数据，需要同步');
              }

              return (true, null);
            } catch (e, stackTrace) {
              debugPrint('AppProvider: 解析用户信息失败（旧版API）: $e');
              debugPrint('AppProvider: 错误堆栈: $stackTrace');
              throw Exception('解析用户信息失败（旧版API）: $e');
            }
          } else {
            throw Exception('获取用户信息失败: ${oldResponse.statusCode}');
          }
        } else {
          throw Exception('获取用户信息失败: ${response.statusCode}');
        }
      } catch (e, stackTrace) {
        debugPrint('AppProvider: 验证Token失败: $e');
        debugPrint('AppProvider: 错误堆栈: $stackTrace');
        throw Exception('验证Token失败: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('AppProvider: Token登录失败: $e');
      debugPrint('AppProvider: 错误堆栈: $stackTrace');
      return (false, e.toString());
    }
  }

  // ==================== 登出功能 ====================

  /// 退出登录
  Future<(bool, String?)> logout({
    bool force = false,
    bool keepLocalData = true,
  }) async {
    if (!force) {
      _setLoading(true);
    } else {
      // 设置同步状态
      _isSyncing = true;
      _syncMessage = '正在处理退出登录...';
      notifyListeners();
    }

    try {
      // 检查是否有未同步的笔记
      if (!force && !_appConfig.isLocalMode && isLoggedIn) {
        final unsyncedNotes = await _databaseService.getUnsyncedNotes();
        if (unsyncedNotes.isNotEmpty) {
          _setLoading(false);
          return (
            false,
            '有${unsyncedNotes.length}条笔记未同步到云端，退出登录后这些笔记将无法同步。确定要退出吗？'
          );
        }
      }

      // 如果不保留本地数据，则清空数据库
      if (!keepLocalData) {
        _syncMessage = '清空本地数据库...';
        notifyListeners();

        debugPrint('AppProvider: 清空本地数据库');
        await _databaseService.clearAllNotes();
      } else {
        _syncMessage = '保存本地数据...';
        notifyListeners();

        debugPrint('AppProvider: 保留本地数据');
      }

      // 取消同步定时器
      _syncTimer?.cancel();
      _syncTimer = null;

      // 🔐 在清除本地信息前，先撤销服务器端的token
      if (_memosApiService != null && !_appConfig.isLocalMode) {
        _syncMessage = '撤销服务器token...';
        notifyListeners();

        try {
          await _memosApiService!.logout();
          if (kDebugMode) debugPrint('AppProvider: 服务器token撤销成功');
        } catch (e) {
          if (kDebugMode) debugPrint('AppProvider: 服务器token撤销失败: $e');
          // 继续执行，不阻塞登出流程
        }
      }

      // 清除用户信息
      _user = null;
      await _preferencesService.clearUser();

      _syncMessage = '清除登录信息...';
      notifyListeners();

      // 🔐 总是清除 token（退出登录后不应该自动登录）
      // 但如果之前选择了"记住密码"，保留 username 和 password
      final rememberLogin = _appConfig.rememberLogin;

      if (rememberLogin) {
        // 只清除 token，保留 username 和 password
        await _preferencesService.clearLoginInfo();
        debugPrint('AppProvider: 已清除 token，保留用户名和密码');
      } else {
        // 清除所有登录信息（包括 username、password、token）
        await _preferencesService.clearAllSecureData();
        debugPrint('AppProvider: 已清除所有登录信息');
      }

      _syncMessage = '更新配置...';
      notifyListeners();

      // 更新配置为本地模式，不保留 token
      _appConfig = _appConfig.copyWith(
        isLocalMode: true,
        rememberLogin: rememberLogin,
        lastToken: null, // 退出登录后总是清除 token
        lastServerUrl: rememberLogin ? _appConfig.lastServerUrl : null,
      );
      await _preferencesService.saveAppConfig(_appConfig);

      // 清除API服务
      _apiService = null;
      _memosApiService = null;

      // 重新加载本地笔记
      if (keepLocalData) {
        _syncMessage = '加载本地笔记...';
        notifyListeners();

        await loadNotesFromLocal();
      } else {
        // 清空笔记列表（需要在子类中实现）
        // _notes = [];
      }

      _syncMessage = '退出登录完成';
      notifyListeners();

      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isSyncing = false;
          _syncMessage = null;
          notifyListeners();
        }
      });

      return (true, null);
    } catch (e) {
      debugPrint('退出登录失败: $e');

      _syncMessage = '退出登录失败: ${e.toString().split('\n')[0]}';
      notifyListeners();

      // 延迟一点时间再清除同步状态
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _isSyncing = false;
          _syncMessage = null;
          _setLoading(false);
          notifyListeners();
        }
      });

      return (false, '退出登录失败: $e');
    } finally {
      if (!force) {
        _setLoading(false);
      }
    }
  }

  // ==================== 辅助方法 ====================

  /// 保存登录信息
  Future<void> saveLoginInfo(
    String server,
    String usernameOrToken, {
    String? token,
    String? password,
  }) async {
    debugPrint('AppProvider: 保存登录信息 - 服务器: $server');
    // 规范化URL（确保末尾没有斜杠）
    final normalizedUrl =
        server.endsWith('/') ? server.substring(0, server.length - 1) : server;

    // 生成一个刷新令牌（这里只是为了满足接口要求）
    final refreshToken = const Uuid().v4();

    // 如果提供了token参数，则usernameOrToken是用户名，否则是token（兼容旧版本）
    if (token != null) {
      // 新版本：保存用户名和token
      await _preferencesService.saveLoginInfo(
        token: token,
        refreshToken: refreshToken,
        serverUrl: normalizedUrl,
        username: usernameOrToken, // 这里是用户名
        password: password, // 保存密码（如果提供）
      );

      // 同时更新AppConfig
      final updatedConfig = _appConfig.copyWith(
        memosApiUrl: normalizedUrl,
        lastToken: token,
        lastUsername: usernameOrToken,
        lastServerUrl: normalizedUrl,
        rememberLogin: true,
      );
      await updateConfig(updatedConfig);
    } else {
      // 旧版本：usernameOrToken是token
      await _preferencesService.saveLoginInfo(
        token: usernameOrToken,
        refreshToken: refreshToken,
        serverUrl: normalizedUrl,
      );

      // 同时更新AppConfig
      final updatedConfig = _appConfig.copyWith(
        memosApiUrl: normalizedUrl,
        lastToken: usernameOrToken,
        lastServerUrl: normalizedUrl,
        rememberLogin: true,
      );
      await updateConfig(updatedConfig);
    }
  }

  /// 清除登录信息
  Future<void> clearLoginInfo() async {
    await _preferencesService.clearLoginInfo();
  }

  /// 获取保存的服务器地址
  Future<String?> getSavedServer() async =>
      _preferencesService.getSavedServer();

  /// 获取保存的Token
  Future<String?> getSavedToken() async => _preferencesService.getSavedToken();

  /// 获取保存的用户名
  Future<String?> getSavedUsername() async =>
      _preferencesService.getSavedUsername();

  /// 获取保存的密码
  Future<String?> getSavedPassword() async =>
      _preferencesService.getSavedPassword();

  /// 初始化API服务
  Future<void> _initializeApiService(String baseUrl, String token) async {
    try {
      debugPrint('AppProvider: 开始初始化API服务，URL：$baseUrl');
      final normalizedUrl = ApiServiceFactory.normalizeApiUrl(baseUrl);
      debugPrint('AppProvider: 规范化后的URL: $normalizedUrl');

      _memosApiService = await ApiServiceFactory.createApiService(
        baseUrl: normalizedUrl,
        token: token,
      ) as MemosApiServiceFixed;

      // 验证API服务是否正常工作
      final testResponse = await _memosApiService!.getMemos();
      // 初始化增量同步服务
      _incrementalSyncService =
          IncrementalSyncService(_databaseService, _memosApiService);
      debugPrint('AppProvider: 增量同步服务已初始化');

      // 更新配置
      final updatedConfig = _appConfig.copyWith(
        memosApiUrl: normalizedUrl,
        lastToken: token,
        isLocalMode: false,
      );
      await updateConfig(updatedConfig);

      // 启动自动同步
      startAutoSync();
    } catch (e) {
      debugPrint('AppProvider: API服务初始化失败: $e');
      _memosApiService = null;
      // 清除保存的凭证
      await _preferencesService.clearLoginInfo();
      rethrow;
    }
  }

  /// 在后台初始化API服务（用于自动登录）
  Future<void> _initializeApiServiceInBackground() async {
    if (_memosApiService != null) return;

    // 检查是否启用自动登录
    if (!_appConfig.autoLogin) {
      if (kDebugMode) debugPrint('AppProvider: 未启用自动登录，跳过自动登录');
      return;
    }

    // 检查是否有保存的token和服务器信息
    final savedServerUrl = _appConfig.lastServerUrl ?? _user?.serverUrl;
    final savedToken = _appConfig.lastToken ?? _user?.token;

    if (savedServerUrl == null || savedToken == null) {
      if (kDebugMode) debugPrint('AppProvider: 缺少保存的服务器信息或token，跳过自动登录');
      return;
    }

    try {
      if (kDebugMode) debugPrint('AppProvider: 开始验证保存的token并尝试自动登录');

      // 尝试使用保存的token自动登录
      final loginResult = await loginWithToken(savedServerUrl, savedToken);

      if (loginResult.$1) {
        if (kDebugMode) debugPrint('AppProvider: 自动登录成功');

        // 初始化API服务
        _memosApiService = await ApiServiceFactory.createApiService(
          baseUrl: savedServerUrl,
          token: savedToken,
        ) as MemosApiServiceFixed;

        // 🚀 初始化增量同步服务（关键！）
        _incrementalSyncService =
            IncrementalSyncService(_databaseService, _memosApiService);

        _resourceService = MemosResourceService(
          baseUrl: savedServerUrl,
          token: savedToken,
        );

        // 更新应用配置为在线模式
        if (_appConfig.isLocalMode) {
          if (kDebugMode) debugPrint('AppProvider: 切换到在线模式');
          _appConfig = _appConfig.copyWith(isLocalMode: false);
          await _preferencesService.saveAppConfig(_appConfig);
        }

        if (kDebugMode) debugPrint('AppProvider: API服务和资源服务初始化成功');

        // 启动自动同步
        startAutoSync();

        notifyListeners();
      } else {
        if (kDebugMode) {
          debugPrint('AppProvider: 自动登录失败: ${loginResult.$2}，清除保存的登录信息');
        }

        // Token无效，清除保存的登录信息
        await _preferencesService.clearLoginInfo();
        _user = null;
        _appConfig = _appConfig.copyWith();
        await _preferencesService.saveAppConfig(_appConfig);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AppProvider: 自动登录过程中发生异常: $e');

      // 发生异常时清除保存的登录信息
      try {
        await _preferencesService.clearLoginInfo();
        _user = null;
        _appConfig = _appConfig.copyWith();
        await _preferencesService.saveAppConfig(_appConfig);
        notifyListeners();
      } catch (clearError) {
        if (kDebugMode) debugPrint('AppProvider: 清除登录信息时发生异常: $clearError');
      }
    }
  }

  /// 处理Token过期
  Future<void> _handleTokenExpired() async {
    try {
      if (kDebugMode) debugPrint('AppProvider: 处理Token过期，清除登录状态');

      // 1. 停止自动同步
      stopAutoSync();

      // 2. 尝试撤销过期的token（尽力而为）
      if (_memosApiService != null) {
        try {
          await _memosApiService!.logout();
          if (kDebugMode) debugPrint('AppProvider: 过期token撤销成功');
        } catch (e) {
          if (kDebugMode) debugPrint('AppProvider: 过期token撤销失败: $e');
          // 继续执行，因为token已经过期
        }
      }

      // 3. 清除API服务
      _memosApiService = null;
      _resourceService = null;

      // 4. 清除用户信息和登录状态
      await _preferencesService.clearLoginInfo();
      _user = null;

      // 5. 更新应用配置，切换到本地模式
      _appConfig = _appConfig.copyWith(
        isLocalMode: true,
        autoLogin: false, // 禁用自动登录
      );
      await _preferencesService.saveAppConfig(_appConfig);

      // 6. 设置同步消息提示用户
      _syncMessage = 'Token已过期，请重新登录';
      _isSyncing = false;

      // 7. 通知UI更新
      notifyListeners();

      if (kDebugMode) debugPrint('AppProvider: Token过期处理完成，已切换到本地模式');
    } catch (e) {
      if (kDebugMode) debugPrint('AppProvider: 处理Token过期时发生错误: $e');
    }
  }

  /// 🖼️ 异步预加载用户头像
  void _preloadUserAvatarAsync() {
    if (_user?.avatarUrl == null || _user!.avatarUrl!.trim().isEmpty) {
      return; // 没有头像URL，无需预加载
    }

    // 在微任务中执行预加载，避免阻塞主线程
    Future.microtask(() async {
      try {
        // 使用NavigatorState获取context，但只在widget树构建完成后
        final context = NavigatorKey.currentContext;
        if (context != null && _user != null) {
          debugPrint('AppProvider: 开始预加载用户头像');
          await AvatarPreloader.preloadUserAvatar(context, _user!);
        }
      } catch (e) {
        // 预加载失败不影响正常功能
        debugPrint('AppProvider: 头像预加载失败（不影响正常使用）: $e');
      }
    });
  }
}

/// NavigatorKey 辅助类（用于获取 BuildContext）
class NavigatorKey {
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static BuildContext? get currentContext => _navigatorKey?.currentContext;
}

/// Token过期异常类
class TokenExpiredException implements Exception {
  final String message;

  TokenExpiredException([this.message = 'Token已过期']);

  @override
  String toString() => 'TokenExpiredException: $message';
}
