// ============================================================
// 第三档测试 · AnimatedCheckbox Widget
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/widgets/animated_checkbox.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('AnimatedCheckbox — 渲染', () {
    testWidgets('CB-01 未勾选时不显示 check 图标', (tester) async {
      await tester.pumpWidget(
        _wrap(AnimatedCheckbox(value: false, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('CB-02 已勾选时显示 check 图标', (tester) async {
      await tester.pumpWidget(
        _wrap(AnimatedCheckbox(value: true, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('CB-03 点击触发 onChanged 回调', (tester) async {
      bool? received;
      await tester.pumpWidget(
        _wrap(
          AnimatedCheckbox(
            value: false,
            onChanged: (v) => received = v,
          ),
        ),
      );
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
      expect(received, isTrue);
    });

    testWidgets('CB-04 从 false 切换到 true 时显示图标', (tester) async {
      var checked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (ctx, setState) => AnimatedCheckbox(
                value: checked,
                onChanged: (v) => setState(() => checked = v ?? false),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNothing);
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('CB-05 onChanged=null 时点击不崩溃', (tester) async {
      await tester.pumpWidget(
        _wrap(const AnimatedCheckbox(value: false, onChanged: null)),
      );
      // 不应抛出任何异常
      await tester.tap(find.byType(GestureDetector), warnIfMissed: false);
      await tester.pumpAndSettle();
    });

    testWidgets('CB-06 自定义 size 参数被应用', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AnimatedCheckbox(
            value: false,
            onChanged: (_) {},
            size: 36,
          ),
        ),
      );
      // 能渲染不崩溃即可（size 影响内部 Container）
      expect(find.byType(AnimatedCheckbox), findsOneWidget);
    });

    testWidgets('CB-07 已勾选初始状态正确（控制器 value=1）', (tester) async {
      await tester.pumpWidget(
        _wrap(AnimatedCheckbox(value: true, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      // 已勾选时 check 图标存在
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('CB-08 从 true 切换到 false 后图标消失', (tester) async {
      var checked = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (ctx, setState) => AnimatedCheckbox(
                value: checked,
                onChanged: (v) => setState(() => checked = v ?? true),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsNothing);
    });
  });
}
