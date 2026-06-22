import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token过期异常类
class TokenExpiredException implements Exception {
  TokenExpiredException(this.message);
  final String message;

  @override
  String toString() => 'TokenExpiredException: $message';
}

typedef _AuthAttempt = ({
  int version,
  Future<String> Function(String username, String password) signIn,
});

typedef _UserInfoAttempt = ({
  int version,
  Future<User> Function() fetch,
});

/// Memos API service – fully compatible with v0.21.0 → v0.27.x+
///
/// Auth & endpoint behaviour differs significantly across versions:
///
/// | Version       | Login request body              | Token location        | Memo path         |
/// |---------------|---------------------------------|-----------------------|-------------------|
/// | v0.21.0       | {username, password}            | Body: `token`         | /api/v1/memo      |
/// | v0.22–v0.25   | {username, password, neverExpire}| Set-Cookie header    | /api/v1/memos     |
/// | v0.26+        | {passwordCredentials:{…}}       | Body: `accessToken`   | /api/v1/memos     |
class MemosApiServiceFixed {
  MemosApiServiceFixed({required this.baseUrl, this.token});

  final String baseUrl;
  final String? token;

  // In-process cache: baseUrl → minor version integer (21, 22, 25, 26, 27, …)
  // Seeded from SharedPreferences on first access so cold-starts are instant.
  static final Map<String, int> _versionCache = {};
  static const String _prefKeyPrefix = 'memos_server_version_';

  static Future<void> _cacheServerVersion(String baseUrl, int minor) async {
    _versionCache[baseUrl] = minor;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_prefKeyPrefix${baseUrl.hashCode}', minor);
    } on Object catch (_) {}
  }

  // ── Headers ───────────────────────────────────────────────────────────────

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      headers['Cookie'] = 'memos.access-token=$token';
    }
    return headers;
  }

  // ── Version detection ──────────────────────────────────────────────────────

  /// Returns the Memos minor version (e.g. 21 for v0.21.x, 26 for v0.26.x).
  ///
  /// Lookup order (fastest → slowest):
  ///   1. In-process static Map  – instant, survives hot reload
  ///   2. SharedPreferences      – instant after cold start, no network call
  ///   3. HTTP /workspace/profile – one lightweight call, result persisted
  static Future<int> getServerVersion(String baseUrl) async {
    // 1. In-process cache
    if (_versionCache.containsKey(baseUrl)) {
      return _versionCache[baseUrl]!;
    }

    // 2. SharedPreferences (persisted across cold starts)
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt('$_prefKeyPrefix${baseUrl.hashCode}');
      if (stored != null) {
        _versionCache[baseUrl] = stored;
        debugPrint('Memos version (cached): 0.$stored.x');
        // Refresh in background so we pick up server upgrades eventually
        _refreshVersionInBackground(baseUrl);
        return stored;
      }
    } on Object catch (_) {}

    // 3. Network detection
    return _fetchAndCacheVersion(baseUrl);
  }

  static Future<int> _fetchAndCacheVersion(String baseUrl) async {
    int? minor;
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/v1/workspace/profile'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final v = (data['version'] as String? ?? '').replaceFirst('v', '');
        final parts = v.split('.');
        minor = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        debugPrint('Memos server version detected: 0.$minor.x');
      } else {
        debugPrint(
          'Memos version endpoint unavailable (workspace/profile → ${resp.statusCode}); probing auth API',
        );
      }
    } on Object catch (e) {
      debugPrint('Memos version detection error: $e – probing auth API');
    }

    minor ??= await _probeVersionByEndpoint(baseUrl);
    await _cacheServerVersion(baseUrl, minor);
    return minor;
  }

  static Future<int> _probeVersionByEndpoint(String baseUrl) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/v1/auth/me'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        debugPrint('Memos version probe: auth/me exists, assuming 0.26+');
        return 26;
      }
    } on Object catch (_) {}

    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/status'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        debugPrint(
          'Memos version probe: auth/status exists, assuming 0.22-0.25',
        );
        return 22;
      }
    } on Object catch (_) {}

    debugPrint('Memos version probe failed; assuming 0.21.x');
    return 21;
  }

  /// Background refresh: silently re-detects version and updates both caches.
  /// Called after a hit on the SharedPreferences cache so we catch server upgrades.
  static void _refreshVersionInBackground(String baseUrl) {
    Future.microtask(() async {
      try {
        final resp = await http.get(
          Uri.parse('$baseUrl/api/v1/workspace/profile'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final v = (data['version'] as String? ?? '').replaceFirst('v', '');
          final parts = v.split('.');
          final minor = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
          if (_versionCache[baseUrl] != minor) {
            debugPrint(
              'Memos version updated: 0.$minor.x (was ${_versionCache[baseUrl]})',
            );
            _versionCache[baseUrl] = minor;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('$_prefKeyPrefix${baseUrl.hashCode}', minor);
          }
        }
      } on Object catch (_) {}
    });
  }

  /// Clears both in-process and persisted version for this server.
  /// Call this if the user manually changes the server URL.
  static Future<void> invalidateVersionCache(String baseUrl) async {
    _versionCache.remove(baseUrl);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefKeyPrefix${baseUrl.hashCode}');
    } on Object catch (_) {}
  }

  Future<int> get _version => getServerVersion(baseUrl);

  /// Base URL for memo endpoints.
  /// v0.21.0: /api/v1/memo (singular)
  /// v0.22.0+: /api/v1/memos (plural)
  Future<String> _memoBase() async {
    final v = await _version;
    return v >= 22 ? '$baseUrl/api/v1/memos' : '$baseUrl/api/v1/memo';
  }

  // ── Authentication ────────────────────────────────────────────────────────

  /// Returns the access token string.
  /// Handles all supported auth flows. Some servers hide their version before
  /// login, so this method treats the detected version as a hint and falls
  /// back through the other known protocols before failing.
  Future<String> createAccessToken(String username, String password) async {
    final v = await _version;
    final attempts = v >= 26
        ? <_AuthAttempt>[
            (version: 26, signIn: _signInV26),
            (version: 22, signIn: _signInV22),
            (version: 21, signIn: _signInV21),
          ]
        : v >= 22
            ? <_AuthAttempt>[
                (version: 22, signIn: _signInV22),
                (version: 26, signIn: _signInV26),
                (version: 21, signIn: _signInV21),
              ]
            : <_AuthAttempt>[
                (version: 21, signIn: _signInV21),
                (version: 26, signIn: _signInV26),
                (version: 22, signIn: _signInV22),
              ];

    final errors = <String>[];
    for (final attempt in attempts) {
      try {
        final accessToken = await attempt.signIn(username, password);
        await _cacheServerVersion(baseUrl, attempt.version);
        return accessToken;
      } on Object catch (e) {
        errors.add(e.toString());
      }
    }

    final cookieError =
        errors.where((error) => error.contains('登录成功但无法获取 Token')).firstOrNull;
    if (cookieError != null) {
      throw Exception(cookieError);
    }

    if (errors.any(_isCredentialFailure)) {
      throw Exception('账号或密码错误，请检查后重试');
    }

    throw Exception(errors.isEmpty ? '登录失败' : errors.last);
  }

  bool _isCredentialFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('incorrect login credentials') ||
        normalized.contains('invalid username or password') ||
        normalized.contains('invalid credentials') ||
        normalized.contains('wrong password') ||
        normalized.contains('用户不存在') ||
        normalized.contains('密码错误') ||
        normalized.contains('账号或密码');
  }

  /// v0.26.0+: credentials wrapped in `passwordCredentials`, token in body.
  Future<String> _signInV26(String username, String password) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'passwordCredentials': {'username': username, 'password': password},
      }),
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final tok = _extractBodyToken(data);
      if (tok != null && tok.isNotEmpty) {
        return tok;
      }
    }
    throw Exception(
      '登录失败 (v0.26+): ${resp.statusCode} – ${_parseError(resp.body)}',
    );
  }

  /// v0.22.0–v0.25.x: flat body, token is returned in `Set-Cookie` header.
  Future<String> _signInV22(String username, String password) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(
        {'username': username, 'password': password, 'neverExpire': false},
      ),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        '登录失败 (v0.22–0.25): ${resp.statusCode} – ${_parseError(resp.body)}',
      );
    }

    // Token lives in Set-Cookie: memos.access-token=eyJ…; Path=/; HttpOnly
    // Some reverse proxies join multiple Set-Cookie headers with ", " so we
    // try splitting on "," first to isolate individual cookie entries.
    final rawCookie = resp.headers['set-cookie'] ?? '';
    final tok = _extractCookieToken(rawCookie);
    if (tok != null && tok.isNotEmpty) {
      return tok;
    }

    // Fallback: body might carry the token if a proxy or future patch returns it
    try {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final bodyTok = _extractBodyToken(data);
      if (bodyTok != null && bodyTok.isNotEmpty) {
        return bodyTok;
      }
    } on Object catch (_) {}

    // Cookie was stripped – almost certainly a reverse-proxy stripping Set-Cookie
    throw Exception(
      '登录成功但无法获取 Token。\n\n'
      '您的 Memos 服务器版本（v0.22–v0.25）通过 Set-Cookie 返回 Token，'
      '但当前反向代理（Nginx/Caddy 等）似乎屏蔽了该响应头。\n\n'
      '推荐解决方法：\n'
      '① 将 Memos 升级到 v0.26.0 或更高版本（Token 改为在响应体返回，不依赖 Cookie）\n'
      '② 或检查并修正反向代理配置，确保 Set-Cookie 响应头透传给客户端',
    );
  }

  /// v0.21.0: flat body, token returned as `token` in response body.
  Future<String> _signInV21(String username, String password) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final tok = _extractBodyToken(data);
      if (tok != null && tok.isNotEmpty) {
        return tok;
      }
    }
    throw Exception(
      '登录失败 (v0.21): ${resp.statusCode} – ${_parseError(resp.body)}',
    );
  }

  /// Extracts the Memos access token value from a `Set-Cookie` header string.
  ///
  /// Handles two common formats:
  ///   • Single cookie:   "memos.access-token=eyJ…; Path=/; HttpOnly"
  ///   • Proxy-joined:    "memos.access-token=eyJ…; Path=/, other=val; Path=/"
  String? _extractCookieToken(String cookieHeader) {
    if (cookieHeader.isEmpty) {
      return null;
    }
    const cookieName = 'memos.access-token=';

    // Split proxy-joined Set-Cookie lines without lookahead regex syntax.
    final entries = cookieHeader.split(', ').where((entry) {
      final semicolonIndex = entry.indexOf(';');
      final firstSegment =
          semicolonIndex == -1 ? entry : entry.substring(0, semicolonIndex);
      return firstSegment.contains('=');
    });

    for (final entry in entries) {
      for (final segment in entry.split(';')) {
        final kv = segment.trim();
        if (kv.startsWith(cookieName)) {
          final value = kv.substring(cookieName.length).trim();
          if (value.isNotEmpty) {
            return value;
          }
        }
      }
    }
    return null;
  }

  String? _extractBodyToken(Map<String, dynamic> data) {
    for (final key in const ['accessToken', 'access_token', 'token']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return _extractBodyToken(nested);
    }
    return null;
  }

  // ── User info ──────────────────────────────────────────────────────────────

  /// Fetches the current authenticated user.
  /// Endpoint varies by version:
  ///   v0.21.0: GET /api/v1/user/me
  ///   v0.22–v0.25: POST /api/v1/auth/status
  ///   v0.26+: GET /api/v1/auth/me → {user: {...}}
  Future<User> getUserInfo() async {
    final v = await _version;
    final attempts = v >= 26
        ? <_UserInfoAttempt>[
            (version: 26, fetch: _getUserV26),
            (version: 22, fetch: _getUserV22),
            (version: 21, fetch: _getUserV21),
          ]
        : v >= 22
            ? <_UserInfoAttempt>[
                (version: 22, fetch: _getUserV22),
                (version: 26, fetch: _getUserV26),
                (version: 21, fetch: _getUserV21),
              ]
            : <_UserInfoAttempt>[
                (version: 21, fetch: _getUserV21),
                (version: 26, fetch: _getUserV26),
                (version: 22, fetch: _getUserV22),
              ];

    final errors = <String>[];
    for (final attempt in attempts) {
      try {
        final user = await attempt.fetch();
        await _cacheServerVersion(baseUrl, attempt.version);
        return user;
      } on Object catch (e) {
        errors.add(e.toString());
      }
    }

    if (errors.any((error) => error.contains('TokenExpiredException'))) {
      throw TokenExpiredException('Token无效或已过期，请重新登录');
    }

    throw Exception(
      errors.isEmpty ? '获取用户信息失败' : errors.last,
    );
  }

  Future<User> _getUserV26() async {
    final resp = await http.get(
      Uri.parse('$baseUrl/api/v1/auth/me'),
      headers: _getHeaders(),
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      // GetCurrentUserResponse wraps the User in a 'user' field
      final userMap = data['user'] as Map<String, dynamic>? ?? data;
      return _convertApiUserToUser(userMap);
    }
    if (resp.statusCode == 401) {
      throw TokenExpiredException('Token无效或已过期，请重新登录');
    }
    throw Exception('获取用户信息失败: ${resp.statusCode} – ${_parseError(resp.body)}');
  }

  Future<User> _getUserV22() async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/status'),
      headers: _getHeaders(),
    );
    if (resp.statusCode == 200) {
      return _convertApiUserToUser(
        json.decode(resp.body) as Map<String, dynamic>,
      );
    }
    if (resp.statusCode == 401) {
      throw TokenExpiredException('Token无效或已过期，请重新登录');
    }
    throw Exception('获取用户信息失败: ${resp.statusCode} – ${_parseError(resp.body)}');
  }

  Future<User> _getUserV21() async {
    final resp = await http.get(
      Uri.parse('$baseUrl/api/v1/user/me'),
      headers: _getHeaders(),
    );
    if (resp.statusCode == 200) {
      return _convertApiUserToUser(
        json.decode(resp.body) as Map<String, dynamic>,
      );
    }
    if (resp.statusCode == 401) {
      throw TokenExpiredException('Token无效或已过期，请重新登录');
    }
    throw Exception('获取用户信息失败: ${resp.statusCode} – ${_parseError(resp.body)}');
  }

  // ── Memo list ──────────────────────────────────────────────────────────────

  /// Returns `{'memos': List<dynamic>}` regardless of server version.
  /// Fetches every page for v0.22+ so local deletion reconciliation is safe.
  Future<Map<String, dynamic>> getMemos({int pageSize = 1000}) async {
    final v = await _version;
    final base = await _memoBase();

    if (v >= 22) {
      final allMemos = <dynamic>[];
      String? pageToken;
      var pageCount = 0;
      var isComplete = true;

      while (true) {
        final query = <String, String>{'pageSize': pageSize.toString()};
        if (pageToken != null && pageToken.isNotEmpty) {
          query['pageToken'] = pageToken;
        }

        final uri = Uri.parse(base).replace(queryParameters: query);
        final resp = await http.get(uri, headers: _getHeaders());
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final pageMemos = data['memos'] as List<dynamic>? ?? <dynamic>[];
          allMemos.addAll(pageMemos);
          pageToken = data['nextPageToken']?.toString();
          if (pageToken != null && pageToken.isEmpty) {
            pageToken = null;
          }
          pageCount++;

          if (pageCount > 1000 && pageToken != null) {
            isComplete = false;
            break;
          }

          if (pageToken == null || pageMemos.isEmpty) {
            break;
          }
          continue;
        }
        if (resp.statusCode == 401) {
          throw TokenExpiredException('Token无效或已过期，请重新登录');
        }
        throw Exception('获取备忘录列表失败: ${resp.statusCode}');
      }

      return {'memos': allMemos, 'isComplete': isComplete};
    } else {
      // Old REST API returns a bare JSON array
      final resp = await http.get(Uri.parse(base), headers: _getHeaders());
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List<dynamic>;
        return {'memos': list, 'isComplete': true};
      }
      if (resp.statusCode == 401) {
        throw TokenExpiredException('Token无效或已过期，请重新登录');
      }
      throw Exception('获取备忘录列表失败: ${resp.statusCode}');
    }
  }

  // ── Create memo ────────────────────────────────────────────────────────────

  Future<Note> createMemo({
    required String content,
    String visibility = 'PRIVATE',
  }) async {
    final base = await _memoBase();
    final resp = await http.post(
      Uri.parse(base),
      headers: _getHeaders(),
      body: json.encode({'content': content, 'visibility': visibility}),
    );
    if (resp.statusCode == 200) {
      return Note.fromJson(json.decode(resp.body) as Map<String, dynamic>);
    }
    if (resp.statusCode == 401) {
      throw TokenExpiredException('Token无效或已过期，请重新登录');
    }
    throw Exception('创建备忘录失败: ${resp.statusCode}');
  }

  // ── Get single memo ────────────────────────────────────────────────────────

  Future<Note> getMemo(String id) async {
    final base = await _memoBase();
    final resp = await http.get(Uri.parse('$base/$id'), headers: _getHeaders());
    if (resp.statusCode == 200) {
      return Note.fromJson(json.decode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('获取备忘录失败: ${resp.statusCode}');
  }

  // ── Update memo ────────────────────────────────────────────────────────────

  Future<Note> updateMemo(
    String id, {
    required String content,
    String? visibility,
  }) async {
    if (id.startsWith('local_') || id.contains('-')) {
      return createMemo(content: content, visibility: visibility ?? 'PRIVATE');
    }

    final v = await _version;
    final base = await _memoBase();

    if (v >= 22) {
      // gRPC-Gateway: PATCH /api/v1/memos/{id}?updateMask=content[,visibility]
      // Body maps to the Memo message (body: "memo" in proto HTTP binding)
      final fields = ['content'];
      final memoBody = <String, dynamic>{
        'name': 'memos/$id',
        'content': content,
      };
      if (visibility != null) {
        memoBody['visibility'] = visibility;
        fields.add('visibility');
      }
      final uri = Uri.parse('$base/$id').replace(
        queryParameters: {'updateMask': fields.join(',')},
      );
      final resp = await http.patch(
        uri,
        headers: _getHeaders(),
        body: json.encode(memoBody),
      );
      if (resp.statusCode == 200) {
        return Note.fromJson(json.decode(resp.body) as Map<String, dynamic>);
      }
      throw Exception(
        '更新备忘录失败: ${resp.statusCode} – ${_parseError(resp.body)}',
      );
    } else {
      final body = <String, dynamic>{'content': content};
      if (visibility != null) {
        body['visibility'] = visibility;
      }
      final resp = await http.patch(
        Uri.parse('$base/$id'),
        headers: _getHeaders(),
        body: json.encode(body),
      );
      if (resp.statusCode == 200) {
        return Note.fromJson(json.decode(resp.body) as Map<String, dynamic>);
      }
      throw Exception('更新备忘录失败: ${resp.statusCode}');
    }
  }

  Future<Note> updateMemoVisibility(
    String id, {
    required String content,
    required String visibility,
  }) =>
      updateMemo(id, content: content, visibility: visibility);

  // ── Delete memo ────────────────────────────────────────────────────────────

  Future<void> deleteMemo(String id) async {
    if (id.startsWith('local_') || id.contains('-')) {
      return;
    }
    final base = await _memoBase();
    final resp =
        await http.delete(Uri.parse('$base/$id'), headers: _getHeaders());
    if (resp.statusCode == 200 ||
        resp.statusCode == 204 ||
        resp.statusCode == 404) {
      return;
    }
    throw Exception(
      '删除备忘录失败: ${resp.statusCode} – ${_parseError(resp.body)}',
    );
  }

  // ── Memo relations ────────────────────────────────────────────────────────

  Future<bool> addMemoReference(
    String memoId,
    String relatedMemoId,
  ) async {
    if (_isLocalMemoId(memoId) || _isLocalMemoId(relatedMemoId)) {
      return false;
    }

    final v = await _version;
    if (v >= 22) {
      final relations = await listMemoRelations(memoId);
      final exists = relations.any(
        (relation) =>
            _relationType(relation) == 'REFERENCE' &&
            _relationMemoId(relation) == memoId &&
            _relationRelatedMemoId(relation) == relatedMemoId,
      );
      if (!exists) {
        relations.add(_buildReferenceRelation(memoId, relatedMemoId));
        await setMemoRelations(memoId, relations);
      }
      return true;
    }

    final resp = await http.post(
      Uri.parse('$baseUrl/api/v1/memo/$memoId/relation'),
      headers: _getHeaders(),
      body: json.encode({
        'relatedMemoId': int.parse(relatedMemoId),
        'type': 'REFERENCE',
      }),
    );
    return resp.statusCode == 200;
  }

  Future<bool> deleteAllMemoRelations(String memoId) async {
    if (_isLocalMemoId(memoId)) {
      return false;
    }

    final v = await _version;
    if (v >= 22) {
      await setMemoRelations(memoId, const []);
      return true;
    }

    final resp = await http.delete(
      Uri.parse('$baseUrl/api/v1/memo/$memoId/relation'),
      headers: _getHeaders(),
    );
    return resp.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> listMemoRelations(String memoId) async {
    final v = await _version;
    if (v < 22) {
      return const [];
    }

    final resp = await http.get(
      Uri.parse('$baseUrl/api/v1/memos/$memoId/relations'),
      headers: _getHeaders(),
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(
        data['relations'] as List<dynamic>? ?? const [],
      );
    }
    if (resp.statusCode == 401) {
      throw TokenExpiredException('Token无效或已过期，请重新登录');
    }
    throw Exception('获取引用关系失败: ${resp.statusCode}');
  }

  Future<void> setMemoRelations(
    String memoId,
    List<Map<String, dynamic>> relations,
  ) async {
    final v = await _version;
    if (v < 22) {
      return;
    }

    final resp = await http.patch(
      Uri.parse('$baseUrl/api/v1/memos/$memoId/relations'),
      headers: _getHeaders(),
      body: json.encode({
        'name': 'memos/$memoId',
        'relations': relations,
      }),
    );
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      return;
    }
    if (resp.statusCode == 401) {
      throw TokenExpiredException('Token无效或已过期，请重新登录');
    }
    throw Exception('更新引用关系失败: ${resp.statusCode}');
  }

  Map<String, dynamic> _buildReferenceRelation(
    String memoId,
    String relatedMemoId,
  ) =>
      {
        'memo': {'name': 'memos/$memoId'},
        'relatedMemo': {'name': 'memos/$relatedMemoId'},
        'type': 'REFERENCE',
      };

  String? _relationMemoId(Map<String, dynamic> relation) =>
      relation['memoId']?.toString() ??
      _idFromResourceName(
        (relation['memo'] as Map?)?['name']?.toString(),
      );

  String? _relationRelatedMemoId(Map<String, dynamic> relation) =>
      relation['relatedMemoId']?.toString() ??
      _idFromResourceName(
        (relation['relatedMemo'] as Map?)?['name']?.toString() ??
            (relation['related_memo'] as Map?)?['name']?.toString(),
      );

  String _relationType(Map<String, dynamic> relation) {
    final type = relation['type'];
    if (type == 1) {
      return 'REFERENCE';
    }
    return type?.toString() ?? '';
  }

  String? _idFromResourceName(String? name) {
    if (name == null || name.isEmpty) {
      return null;
    }
    return name.contains('/') ? name.split('/').last : name;
  }

  bool _isLocalMemoId(String id) => id.startsWith('local_') || id.contains('-');

  // ── Update memo organizer (pin/unpin) ──────────────────────────────────────

  Future<Note> updateMemoOrganizer(String id, {required bool pinned}) async {
    if (id.startsWith('local_') || id.contains('-')) {
      throw Exception('本地笔记无需同步');
    }

    final v = await _version;
    final base = await _memoBase();

    if (v >= 22) {
      // v0.22.0+: use UpdateMemo with pinned in the update mask
      final uri = Uri.parse('$base/$id').replace(
        queryParameters: {'updateMask': 'pinned'},
      );
      final resp = await http.patch(
        uri,
        headers: _getHeaders(),
        body: json.encode({'name': 'memos/$id', 'pinned': pinned}),
      );
      if (resp.statusCode == 200) {
        return Note.fromJson(json.decode(resp.body) as Map<String, dynamic>);
      }
      throw Exception('更新备忘录置顶状态失败: ${resp.statusCode}');
    } else {
      // v0.21.0: POST /api/v1/memo/{id}/organizer
      final resp = await http.post(
        Uri.parse('$base/$id/organizer'),
        headers: _getHeaders(),
        body: json.encode({'pinned': pinned}),
      );
      if (resp.statusCode == 200) {
        return Note.fromJson(json.decode(resp.body) as Map<String, dynamic>);
      }
      throw Exception('更新备忘录置顶状态失败: ${resp.statusCode}');
    }
  }

  // ── Update user info ───────────────────────────────────────────────────────

  Future<User> updateUserInfo({
    String? nickname,
    String? email,
    String? avatarUrl,
    String? description,
  }) async {
    if (token == null || token!.isEmpty) {
      throw Exception('未登录，无法更新用户信息');
    }

    final currentUser = await getUserInfo();

    final body = <String, dynamic>{};
    final fields = <String>[];
    if (nickname != null) {
      body['nickname'] = nickname;
      fields.add('nickname');
    }
    if (email != null) {
      body['email'] = email;
      fields.add('email');
    }
    if (avatarUrl != null) {
      body['avatarUrl'] = avatarUrl;
      fields.add('avatar_url');
    }
    if (description != null) {
      body['description'] = description;
      fields.add('description');
    }

    return _updateUserFields(currentUser, body, fields);
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (token == null || token!.isEmpty) {
      throw Exception('未登录，无法更新密码');
    }

    final currentUser = await getUserInfo();
    await createAccessToken(currentUser.username, currentPassword);

    final body = <String, dynamic>{'password': newPassword};
    await _updateUserFields(currentUser, body, ['password']);
    return true;
  }

  Future<User> _updateUserFields(
    User currentUser,
    Map<String, dynamic> body,
    List<String> fields,
  ) async {
    if (fields.isEmpty) {
      return currentUser;
    }

    final v = await _version;
    if (v >= 22) {
      // gRPC-Gateway: PATCH /api/v1/users/{name}?updateMask=…
      // v0.22–v0.26: name is numeric ID → users/{id}
      // v0.27+: name is username → users/{username}
      final resourceSegment = v >= 27 ? currentUser.username : currentUser.id;
      final apiUrl = '$baseUrl/api/v1/users/$resourceSegment';
      body['name'] = 'users/$resourceSegment';

      final uri = Uri.parse(apiUrl).replace(
        queryParameters:
            fields.isNotEmpty ? {'updateMask': fields.join(',')} : null,
      );
      debugPrint('更新用户信息: $uri');
      final resp = await http.patch(
        uri,
        headers: _getHeaders(),
        body: json.encode(body),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return _convertApiUserToUser({...data, 'token': token});
      }
      if (resp.statusCode == 401) {
        throw TokenExpiredException('Token无效或已过期，请重新登录');
      }
      throw Exception(
        '更新用户信息失败: ${resp.statusCode} – ${_parseError(resp.body)}',
      );
    } else {
      final apiUrl = '$baseUrl/api/v1/user/${currentUser.id}';
      final resp = await http.patch(
        Uri.parse(apiUrl),
        headers: _getHeaders(),
        body: json.encode(body),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return _convertApiUserToUser({...data, 'token': token});
      }
      if (resp.statusCode == 401) {
        throw TokenExpiredException('Token无效或已过期，请重新登录');
      }
      throw Exception('更新用户信息失败: ${resp.statusCode}');
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<bool> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/v1/auth/signout'),
        headers: _getHeaders(),
      );
    } on Object catch (e) {
      debugPrint('登出API失败 (忽略): $e');
    }
    return true;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Extracts a human-readable error message from a JSON error body.
  /// Supports old `{"error":"…"}` and new gRPC `{"code":…,"message":"…"}` formats.
  String _extractErrorMessage(Map<String, dynamic> errorData) =>
      (errorData['message'] ?? errorData['error'] ?? 'Unknown error')
          .toString();

  String _parseError(String body) {
    try {
      final data = json.decode(body) as Map<String, dynamic>;
      final message = _extractErrorMessage(data);
      final grpcMatch = RegExp('message=([^,}]+)').firstMatch(message);
      return grpcMatch?.group(1)?.trim() ?? message;
    } on Object catch (_) {
      return body.length > 200 ? body.substring(0, 200) : body;
    }
  }

  /// Converts a raw API user map to our [User] model.
  /// Handles both v0.21.0 (numeric id) and v0.22.0+ (resource-name 'name') formats.
  User _convertApiUserToUser(Map<String, dynamic> apiUser) {
    // ID: v0.21.0 has int `id`; v0.22.0+ has `id` (int32) AND `name` = "users/{id}"
    final rawId = apiUser['id'];
    String id;
    if (rawId is int) {
      id = rawId.toString();
    } else {
      final idStr = rawId?.toString() ?? '';
      id = idStr.contains('/') ? idStr.split('/').last : idStr;
    }

    // Username: prefer explicit field, fall back to parsing `name`
    var username = apiUser['username'] as String? ?? '';
    if (username.isEmpty) {
      final name = apiUser['name'] as String? ?? '';
      if (name.contains('/')) {
        username = name.split('/').last;
      }
    }

    // avatarUrl: v0.22.0+ uses camelCase 'avatarUrl'
    final avatarUrl =
        apiUser['avatarUrl'] as String? ?? apiUser['avatar_url'] as String?;

    return User(
      id: id,
      username: username,
      email: apiUser['email'] as String?,
      nickname: apiUser['nickname'] as String? ?? username,
      avatarUrl: avatarUrl,
      token: apiUser['token'] as String? ?? token,
      role: _normalizeRole(apiUser['role'] as String?),
      description: apiUser['description'] as String?,
      serverUrl: baseUrl,
    );
  }

  /// Maps proto enum role names to our internal strings.
  /// v0.26.0+: HOST role was renamed to ADMIN.
  String _normalizeRole(String? role) {
    switch (role) {
      case 'HOST':
      case 'ROLE_HOST':
      case 'ADMIN':
      case 'ROLE_ADMIN':
        return 'ADMIN';
      default:
        return 'USER';
    }
  }
}
