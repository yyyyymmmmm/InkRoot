import 'dart:io';
import 'dart:convert';
import 'package:dotenv/dotenv.dart';
import '../lib/services/memos_api_factory.dart';
import '../lib/services/memos_api_interface.dart';

/// 测试配置
class TestConfig {
  final String version;
  final String baseUrl;
  final String username;
  final String password;

  TestConfig({
    required this.version,
    required this.baseUrl,
    this.username = 'testuser',
    this.password = 'testpass123',
  });

  /// 从环境变量加载配置
  factory TestConfig.fromEnv(DotEnv env, String versionKey) {
    final version = versionKey;
    final baseUrl = env['MEMOS_${versionKey}_BASE_URL'] ?? 'http://localhost:5230';
    final username = env['MEMOS_${versionKey}_USERNAME'] ?? 'testuser';
    final password = env['MEMOS_${versionKey}_PASSWORD'] ?? 'testpass123';

    return TestConfig(
      version: version,
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
  }
}

/// 测试结果
class TestResult {
  final String testName;
  final String version;
  final bool passed;
  final String? error;
  final Duration duration;

  TestResult({
    required this.testName,
    required this.version,
    required this.passed,
    this.error,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'testName': testName,
        'version': version,
        'passed': passed,
        'error': error,
        'duration': duration.inMilliseconds,
      };
}

/// 主函数 - 7个版本完整测试
void main() async {
  // 加载 .env 文件（如果存在）
  final env = DotEnv();
  final envFile = File('.env');

  if (await envFile.exists()) {
    print('📄 加载配置文件: .env\n');
    env.load(['.env']);
  } else {
    print('⚠️  未找到 .env 文件，使用默认配置');
    print('   提示：复制 .env.example 为 .env 并修改配置\n');
  }

  print('🚀 Memos API 7版本完整兼容性测试');
  print('=' * 80);
  print('测试覆盖：v0.21.0 → v0.22.5 → v0.23.1 → v0.24.4 → v0.25.3 → v0.26.2 → v0.27.1');
  print('=' * 80);
  print('');

  // 从环境变量或使用默认值加载7个版本配置
  final configs = [
    TestConfig.fromEnv(env, 'V21'),  // v0.21.0
    TestConfig.fromEnv(env, 'V22'),  // v0.22.5
    TestConfig.fromEnv(env, 'V23'),  // v0.23.1
    TestConfig.fromEnv(env, 'V24'),  // v0.24.4
    TestConfig.fromEnv(env, 'V25'),  // v0.25.3
    TestConfig.fromEnv(env, 'V26'),  // v0.26.2
    TestConfig.fromEnv(env, 'V27'),  // v0.27.1
  ];

  final results = <TestResult>[];
  int passedCount = 0;
  int failedCount = 0;

  // 测试每个版本
  for (final config in configs) {
    print('\n📦 测试版本: ${config.version}');
    print('   服务器: ${config.baseUrl}');
    print('   用户: ${config.username}');
    print('-' * 80);

    final versionResults = await _testVersion(config);
    results.addAll(versionResults);

    final versionPassed = versionResults.where((r) => r.passed).length;
    final versionFailed = versionResults.where((r) => !r.passed).length;

    passedCount += versionPassed;
    failedCount += versionFailed;

    print('\n   版本结果: ✅ $versionPassed 通过, ❌ $versionFailed 失败');
    print('-' * 80);
  }

  // 打印总结
  print('\n');
  print('=' * 80);
  print('📊 测试总结');
  print('=' * 80);
  print('总测试用例: ${results.length}');
  print('✅ 通过: $passedCount');
  print('❌ 失败: $failedCount');
  print('成功率: ${(passedCount / results.length * 100).toStringAsFixed(1)}%');
  print('=' * 80);

  // 导出结果
  final report = {
    'timestamp': DateTime.now().toIso8601String(),
    'summary': {
      'total': results.length,
      'passed': passedCount,
      'failed': failedCount,
      'successRate': passedCount / results.length,
    },
    'results': results.map((r) => r.toJson()).toList(),
  };

  final reportFile = File('test_results_7versions.json');
  await reportFile.writeAsString(JsonEncoder.withIndent('  ').convert(report));
  print('\n📄 测试报告已保存: ${reportFile.path}');

  // 根据失败数量返回退出码
  exit(failedCount > 0 ? 1 : 0);
}

/// 测试单个版本
Future<List<TestResult>> _testVersion(TestConfig config) async {
  final results = <TestResult>[];
  IMemosApi? api;

  // 测试1: 版本检测
  results.add(await _runTest(config, '版本检测', () async {
    final version = await MemosApiFactory._detectVersion(config.baseUrl);
    print('      → 检测到版本: $version');
  }));

  // 测试2: 创建适配器
  results.add(await _runTest(config, '创建适配器', () async {
    api = await MemosApiFactory.create(config.baseUrl);
    print('      → 适配器类型: ${api!.adapterVersion}');
  }));

  if (api == null) {
    print('   ⚠️  适配器创建失败，跳过后续测试');
    return results;
  }

  // 测试3: 用户登录
  Map<String, dynamic>? loginResult;
  results.add(await _runTest(config, '用户登录', () async {
    loginResult = await api!.login(config.username, config.password);
    print('      → 用户: ${loginResult!['username']}');
  }));

  if (loginResult == null) {
    print('   ⚠️  登录失败，跳过后续测试');
    return results;
  }

  // 测试4: 获取用户信息
  results.add(await _runTest(config, '获取用户信息', () async {
    final userInfo = await api!.getUserInfo();
    print('      → 用户ID: ${userInfo['id']}');
  }));

  // 测试5: 创建Memo
  Map<String, dynamic>? memo;
  results.add(await _runTest(config, '创建Memo', () async {
    memo = await api!.createMemo(
      content: 'Test memo from ${config.version} - ${DateTime.now()}',
      visibility: 'PRIVATE',
    );
    print('      → Memo ID: ${memo!['id']}');
  }));

  if (memo != null) {
    final memoId = memo!['id'] is int
        ? memo!['id'] as int
        : int.parse(memo!['id'].toString());

    // 测试6: 获取Memo
    results.add(await _runTest(config, '获取Memo', () async {
      final fetched = await api!.getMemo(memoId);
      print('      → 内容: ${fetched['content']?.toString().substring(0, 20)}...');
    }));

    // 测试7: 更新Memo
    results.add(await _runTest(config, '更新Memo', () async {
      await api!.updateMemo(
        memoId: memoId,
        content: 'Updated content from ${config.version}',
      );
      print('      → 更新成功');
    }));

    // 测试8: 列出Memos
    results.add(await _runTest(config, '列出Memos', () async {
      final memos = await api!.listMemos();
      print('      → 总数: ${memos.length}');
    }));

    // 测试9: 删除Memo
    results.add(await _runTest(config, '删除Memo', () async {
      await api!.deleteMemo(memoId);
      print('      → 删除成功');
    }));
  }

  // 测试10: 用户登出
  results.add(await _runTest(config, '用户登出', () async {
    await api!.logout();
    print('      → 登出成功');
  }));

  return results;
}

/// 运行单个测试
Future<TestResult> _runTest(
  TestConfig config,
  String testName,
  Future<void> Function() test,
) async {
  final stopwatch = Stopwatch()..start();
  try {
    print('   🔹 $testName...');
    await test();
    stopwatch.stop();
    print('      ✅ 通过 (${stopwatch.elapsedMilliseconds}ms)');
    return TestResult(
      testName: testName,
      version: config.version,
      passed: true,
      duration: stopwatch.elapsed,
    );
  } catch (e) {
    stopwatch.stop();
    print('      ❌ 失败: $e');
    return TestResult(
      testName: testName,
      version: config.version,
      passed: false,
      error: e.toString(),
      duration: stopwatch.elapsed,
    );
  }
}
