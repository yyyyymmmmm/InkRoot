import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/providers/app_provider.dart';
import 'package:inkroot/screens/knowledge_graph_screen_custom.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        home: child,
      ),
    );

void main() {
  testWidgets('knowledge graph screen builds without crashing', (tester) async {
    await tester.pumpWidget(_wrap(const KnowledgeGraphScreenCustom()));
    await tester.pump();

    expect(find.byType(KnowledgeGraphScreenCustom), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
