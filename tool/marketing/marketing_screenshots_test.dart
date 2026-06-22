// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/screens/ai_settings_screen.dart';
import 'package:inkroot/screens/tags_screen.dart';
import 'package:inkroot/screens/webdav_settings_screen.dart';
import 'package:inkroot/themes/app_theme.dart';
import 'package:inkroot/widgets/note_card.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('capture real InkRoot marketing screenshots', (tester) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    tester.view.devicePixelRatio = 3;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      tester.view.resetDevicePixelRatio();
    });

    final outputDir = Directory('marketing/real/raw');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    await _capture(
      tester,
      '01-home',
      _MarketingShell(child: _HomeMarketingScreen(notes: _demoNotes)),
    );
    await _capture(
      tester,
      '02-editor',
      const _MarketingShell(child: _EditorMarketingScreen()),
    );
    await _capture(
      tester,
      '03-tags',
      _MarketingShell(
        provider: _seededProvider(),
        child: const TagsScreen(),
      ),
    );
    await _capture(
      tester,
      '04-ai-settings',
      _MarketingShell(
        provider: _seededProvider(),
        child: const AiSettingsScreen(),
      ),
    );
    await _capture(
      tester,
      '05-webdav',
      _MarketingShell(
        provider: _seededProvider(),
        child: const WebDavSettingsScreen(),
      ),
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name,
  Widget widget,
) async {
  final repaintKey = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: repaintKey,
      child: SizedBox(
        width: 402,
        height: 874,
        child: widget,
      ),
    ),
  );
  await tester.pump();
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }

  final boundary =
      repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  final path = p.join('marketing', 'real', 'raw', '$name.png');
  File(path).writeAsBytesSync(bytes);
}

AppProvider _seededProvider() {
  final provider = AppProvider();
  provider.rawNotes.addAll(_demoNotes);
  return provider;
}

class _MarketingShell extends StatefulWidget {
  const _MarketingShell({
    required this.child,
    this.provider,
  });

  final Widget child;
  final AppProvider? provider;

  @override
  State<_MarketingShell> createState() => _MarketingShellState();
}

class _MarketingShellState extends State<_MarketingShell> {
  late final AppProvider _provider = widget.provider ?? AppProvider();

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppProvider>.value(
      value: _provider,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme('default', false),
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => MediaQuery(
                data: const MediaQueryData(
                  size: Size(402, 874),
                  devicePixelRatio: 3,
                  padding: EdgeInsets.only(top: 48, bottom: 34),
                  textScaler: TextScaler.linear(1),
                ),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMarketingScreen extends StatelessWidget {
  const _HomeMarketingScreen({required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'InkRoot',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          leading: const Icon(Icons.menu_rounded, color: AppTheme.primaryColor),
          actions: const [
            Icon(Icons.psychology_alt_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 18),
            Icon(Icons.search_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 18),
          ],
        ),
        body: Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 116),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) => NoteCard(
                note: notes[index],
                onEdit: () {},
                onDelete: () {},
                onPin: () {},
              ),
            ),
            Positioned(
              right: 22,
              bottom: 26,
              child: FloatingActionButton(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                onPressed: () {},
                child: const Icon(Icons.add_rounded, size: 36),
              ),
            ),
          ],
        ),
      );
}

class _EditorMarketingScreen extends StatefulWidget {
  const _EditorMarketingScreen();

  @override
  State<_EditorMarketingScreen> createState() => _EditorMarketingScreenState();
}

class _EditorMarketingScreenState extends State<_EditorMarketingScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: const Icon(Icons.arrow_back_ios_new_rounded),
          title: const Text(
            '编辑笔记',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '发布',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 17,
                          height: 1.55,
                        ),
                        children: [
                          TextSpan(
                            text: '今天的复盘\n\n',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: '用户只需要像写文档一样记录。\n\n'),
                          TextSpan(text: '选中文字，点'),
                          TextSpan(
                            text: '加粗',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: '、'),
                          TextSpan(
                            text: '下划线',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationThickness: 1.4,
                            ),
                          ),
                          TextSpan(text: '、待办，内容直接按最终效果展示。\n\n'),
                          TextSpan(text: '☐ 明天继续补充\n'),
                          TextSpan(
                            text: '#复盘 #产品',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.14),
                      ),
                    ),
                    child: const Wrap(
                      runSpacing: 10,
                      spacing: 10,
                      children: [
                        _FormatChip(label: '加粗', selected: true),
                        _FormatChip(label: '下划线', selected: true),
                        _FormatChip(label: '链接'),
                        _FormatChip(label: '待办'),
                        _FormatChip(label: '#层级/标签'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEDEDED), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _ToolbarIcon(label: '#'),
                          _ToolbarIcon(icon: Icons.photo_outlined),
                          _ToolbarIcon(icon: Icons.check_box_outlined),
                          _ToolbarIcon(icon: Icons.auto_awesome),
                          _ToolbarIcon(label: 'B', selected: true),
                          _ToolbarIcon(
                            icon: Icons.format_underlined,
                            selected: true,
                          ),
                          _ToolbarIcon(icon: Icons.link),
                          _ToolbarIcon(icon: Icons.more_horiz),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.label,
    this.selected = false,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                : const Color(0xFFE8EAED),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      );
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    this.icon,
    this.label,
    this.selected = false,
  });

  final IconData? icon;
  final String? label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(
                icon,
                size: 21,
                color: selected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
              )
            : Text(
                label ?? '',
                style: TextStyle(
                  color: selected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
      );
}

final List<Note> _demoNotes = [
  Note(
    id: 'demo-001',
    content: '# 今天的产品观察\n\n'
        '用户并不需要复杂流程，真正重要的是：打开、记录、回看。\n\n'
        '- [x] 记录一个想法\n'
        '- [x] 补充上下文\n'
        '- [ ] 明天复盘\n\n'
        '#产品/洞察 #工作/复盘',
    createdAt: DateTime(2026, 6, 17, 8, 30),
    updatedAt: DateTime(2026, 6, 17, 8, 30),
    tags: const ['产品/洞察', '工作/复盘'],
    isPinned: true,
  ),
  Note(
    id: 'demo-002',
    content: '把临时灵感先放进 InkRoot，等晚上统一整理。\n\n'
        '**重点：** 不打断当下工作流。\n\n'
        '#灵感 #效率',
    createdAt: DateTime(2026, 6, 16, 21, 15),
    updatedAt: DateTime(2026, 6, 16, 21, 15),
    tags: const ['灵感', '效率'],
  ),
  Note(
    id: 'demo-003',
    content: '阅读《长期主义》时的摘录：\n\n'
        '> 好的系统会让正确行为更容易发生。\n\n'
        '联想到笔记产品：输入要轻，回看要自然，整理要克制。\n\n'
        '#阅读/摘录 #方法论',
    createdAt: DateTime(2026, 6, 15, 19, 40),
    updatedAt: DateTime(2026, 6, 15, 19, 40),
    tags: const ['阅读/摘录', '方法论'],
  ),
  Note(
    id: 'demo-004',
    content: '本周计划\n\n'
        '- [ ] 完成官网素材\n'
        '- [ ] 整理 App Store 截图\n'
        '- [x] 修复待办和 Markdown 渲染\n\n'
        '#计划 #发布',
    createdAt: DateTime(2026, 6, 14, 9, 5),
    updatedAt: DateTime(2026, 6, 14, 9, 5),
    tags: const ['计划', '发布'],
  ),
  Note(
    id: 'demo-005',
    content: 'AI 点评要给出具体反馈，而不是模板话。\n\n'
        '好的点评应该指出：这条笔记真正有价值的部分、可以继续追问的问题，以及和历史笔记的连接。\n\n'
        '#AI #产品/体验',
    createdAt: DateTime(2026, 6, 8, 16, 45),
    updatedAt: DateTime(2026, 6, 8, 16, 45),
    tags: const ['AI', '产品/体验'],
  ),
];
