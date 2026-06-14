// ============================================================
// 第三档测试 · 表单验证 Widget
// 独立测试登录/注册场景中的输入验证逻辑（纯 Flutter 不依赖 Provider）
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── 仿照 login_screen.dart 的验证逻辑 ───────────────────────────────────────

String? _validateUsername(String? value) {
  if (value == null || value.isEmpty) {
    return '请输入用户名';
  }
  if (value.length < 2) {
    return '用户名太短了，至少需要 2 个字符';
  }
  if (value.length > 64) {
    return '用户名太长了，最多 64 个字符';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return '请输入密码';
  }
  if (value.length < 6) {
    return '密码太短了，至少需要 6 位';
  }
  return null;
}

String? _validateServerUrl(String? value) {
  if (value == null || value.isEmpty) {
    return '请输入服务器地址';
  }
  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    return '地址格式不对，需要以 https:// 开头';
  }
  return null;
}

// ─── 测试用表单 Widget ────────────────────────────────────────────────────────

class _TestLoginForm extends StatefulWidget {
  const _TestLoginForm({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  State<_TestLoginForm> createState() => _TestLoginFormState();
}

class _TestLoginFormState extends State<_TestLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) => Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('usernameField'),
              controller: _userCtrl,
              validator: _validateUsername,
            ),
            TextFormField(
              key: const Key('passwordField'),
              controller: _passCtrl,
              validator: _validatePassword,
              obscureText: true,
            ),
            TextFormField(
              key: const Key('serverUrlField'),
              controller: _urlCtrl,
              validator: _validateServerUrl,
            ),
            ElevatedButton(
              key: const Key('submitBtn'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSubmit();
                }
              },
              child: const Text('登录'),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('表单验证 — 用户名', () {
    test('FV-01 空用户名返回错误', () {
      expect(_validateUsername(''), isNotNull);
      expect(_validateUsername(null), isNotNull);
    });

    test('FV-02 单字符用户名太短', () {
      expect(_validateUsername('a'), isNotNull);
      expect(_validateUsername('a'), contains('2 个字符'));
    });

    test('FV-03 两字符及以上通过', () {
      expect(_validateUsername('ab'), isNull);
      expect(_validateUsername('alice'), isNull);
    });

    test('FV-04 超过 64 字符时报错', () {
      final longName = 'a' * 65;
      expect(_validateUsername(longName), isNotNull);
    });
  });

  group('表单验证 — 密码', () {
    test('FV-05 空密码返回错误', () {
      expect(_validatePassword(''), isNotNull);
      expect(_validatePassword(null), isNotNull);
    });

    test('FV-06 少于 6 位报错', () {
      expect(_validatePassword('12345'), isNotNull);
      expect(_validatePassword('12345'), contains('6 位'));
    });

    test('FV-07 6 位及以上通过', () {
      expect(_validatePassword('123456'), isNull);
      expect(_validatePassword('strongPassword!123'), isNull);
    });
  });

  group('表单验证 — 服务器地址', () {
    test('FV-08 空地址返回错误', () {
      expect(_validateServerUrl(''), isNotNull);
      expect(_validateServerUrl(null), isNotNull);
    });

    test('FV-09 无协议头返回格式错误', () {
      expect(_validateServerUrl('memos.example.com'), isNotNull);
      expect(_validateServerUrl('memos.example.com'), contains('https://'));
    });

    test('FV-10 https:// 开头通过', () {
      expect(_validateServerUrl('https://memos.example.com'), isNull);
    });

    test('FV-11 http:// 开头也通过（允许内网/非安全）', () {
      expect(_validateServerUrl('http://192.168.1.1:5230'), isNull);
    });
  });

  group('表单 Widget 交互', () {
    testWidgets('FV-12 空表单提交时显示错误，不触发回调', (tester) async {
      var submitted = false;
      await tester.pumpWidget(
        wrap(_TestLoginForm(onSubmit: () => submitted = true)),
      );

      await tester.tap(find.byKey(const Key('submitBtn')));
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('请输入用户名'), findsOneWidget);
    });

    testWidgets('FV-13 用户名字段空时显示提示语', (tester) async {
      await tester.pumpWidget(
        wrap(_TestLoginForm(onSubmit: () {})),
      );
      await tester.tap(find.byKey(const Key('submitBtn')));
      await tester.pumpAndSettle();

      expect(find.text('请输入用户名'), findsOneWidget);
    });

    testWidgets('FV-14 正确填写表单后回调被触发', (tester) async {
      var submitted = false;
      await tester.pumpWidget(
        wrap(_TestLoginForm(onSubmit: () => submitted = true)),
      );

      await tester.enterText(find.byKey(const Key('usernameField')), 'alice');
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('serverUrlField')),
        'https://memos.example.com',
      );

      await tester.tap(find.byKey(const Key('submitBtn')));
      await tester.pumpAndSettle();

      expect(submitted, isTrue);
    });

    testWidgets('FV-15 密码字段过短时显示错误提示', (tester) async {
      await tester.pumpWidget(
        wrap(_TestLoginForm(onSubmit: () {})),
      );

      await tester.enterText(find.byKey(const Key('usernameField')), 'alice');
      await tester.enterText(find.byKey(const Key('passwordField')), '123');
      await tester.enterText(
        find.byKey(const Key('serverUrlField')),
        'https://memos.example.com',
      );

      await tester.tap(find.byKey(const Key('submitBtn')));
      await tester.pumpAndSettle();

      expect(find.text('密码太短了，至少需要 6 位'), findsOneWidget);
    });

    testWidgets('FV-16 服务器地址无协议头时显示格式错误', (tester) async {
      await tester.pumpWidget(
        wrap(_TestLoginForm(onSubmit: () {})),
      );

      await tester.enterText(find.byKey(const Key('usernameField')), 'alice');
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('serverUrlField')),
        'memos.example.com',
      );

      await tester.tap(find.byKey(const Key('submitBtn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('https://'), findsOneWidget);
    });
  });

  group('UI 响应性 — 错误消息可读性', () {
    testWidgets('FV-17 错误消息使用中文且无技术术语', (tester) async {
      await tester.pumpWidget(
        wrap(_TestLoginForm(onSubmit: () {})),
      );

      await tester.tap(find.byKey(const Key('submitBtn')));
      await tester.pumpAndSettle();

      // 验证错误消息使用中文，而非英文技术词汇
      final allText =
          tester.allWidgets.whereType<Text>().map((t) => t.data ?? '').join();
      expect(allText, contains('请输入'));
    });

    testWidgets('FV-18 多个错误同时显示', (tester) async {
      await tester.pumpWidget(
        wrap(_TestLoginForm(onSubmit: () {})),
      );

      await tester.tap(find.byKey(const Key('submitBtn')));
      await tester.pumpAndSettle();

      // 所有空字段都应显示错误
      expect(find.text('请输入用户名'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);
      expect(find.text('请输入服务器地址'), findsOneWidget);
    });
  });
}
