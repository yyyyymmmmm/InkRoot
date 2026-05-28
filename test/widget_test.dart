// ============================================================
// InkRoot 测试套件入口
// ============================================================
//
// 第一档（Critical）— 纯逻辑单元测试：
//   test/unit/note_model_test.dart       25 个用例
//   test/unit/weread_parser_test.dart    20 个用例
//   test/unit/todo_parser_test.dart      15 个用例
//   test/unit/time_utils_test.dart       10 个用例
//   test/unit/tag_utils_test.dart        10 个用例
//
// 第二档（Important）— 业务逻辑与集成：
//   test/unit/api_service_factory_test.dart    20 个用例
//   test/unit/memos_api_service_test.dart      20 个用例 (MockClient)
//   test/unit/database_service_test.dart       20 个用例 (sqflite_ffi)
//   test/unit/user_model_test.dart             15 个用例
//
// 第三档（Bonus）— Widget 测试：
//   test/widget_tests/animated_checkbox_test.dart   8 个用例
//   test/widget_tests/note_model_widget_test.dart   11 个用例
//   test/widget_tests/form_validation_test.dart     18 个用例
//   test/widget_tests/ui_components_test.dart       20 个用例
//
// ─── 运行方式 ───────────────────────────────────────────────
//
//   # 运行全部测试
//   flutter test
//
//   # 只运行第一档（最快，约 5 秒）
//   flutter test test/unit/note_model_test.dart \
//              test/unit/weread_parser_test.dart \
//              test/unit/todo_parser_test.dart \
//              test/unit/time_utils_test.dart \
//              test/unit/tag_utils_test.dart
//
//   # 只运行 Widget 测试
//   flutter test test/widget_tests/
//
//   # 覆盖率报告
//   flutter test --coverage
//   genhtml coverage/lcov.info -o coverage/html
//
// ─────────────────────────────────────────────────────────────

// 本文件保留为空（仅注释），各子目录的测试文件由 flutter test 自动发现。
// 原 widget_test.dart.bak 包含旧的 smoke test，已备份保留。

void main() {
  // 空：测试由各 test/*.dart 文件自动运行
}
