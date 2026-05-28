import 'package:inkroot/models/reminder_notification_model.dart';
import 'package:inkroot/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// 提醒通知服务 - 管理提醒通知的数据库存储
class ReminderNotificationService {
  factory ReminderNotificationService() => _instance;
  ReminderNotificationService._internal();
  static final ReminderNotificationService _instance =
      ReminderNotificationService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// 获取数据库实例
  Future<Database> get _database async => _databaseService.database;

  /// 保存提醒通知
  Future<void> saveReminderNotification(
    ReminderNotification notification,
  ) async {
    final db = await _database;
    await db.insert(
      'reminder_notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有提醒通知（按触发时间倒序）
  Future<List<ReminderNotification>> getAllReminderNotifications() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminder_notifications',
      orderBy: 'triggered_at DESC',
    );

    return List.generate(
      maps.length,
      (i) => ReminderNotification.fromMap(maps[i]),
    );
  }

  /// 获取未读提醒通知数量
  Future<int> getUnreadCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reminder_notifications WHERE is_read = 0',
    );
    return result.isNotEmpty ? (result.first['count'] as int? ?? 0) : 0;
  }

  /// 标记提醒通知为已读
  Future<void> markAsRead(String notificationId) async {
    final db = await _database;
    await db.update(
      'reminder_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// 标记提醒通知为已点击
  Future<void> markAsClicked(String notificationId) async {
    final db = await _database;
    await db.update(
      'reminder_notifications',
      {'is_clicked': 1, 'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// 标记所有提醒通知为已读
  Future<void> markAllAsRead() async {
    final db = await _database;
    await db.update(
      'reminder_notifications',
      {'is_read': 1},
      where: 'is_read = ?',
      whereArgs: [0],
    );
  }

  /// 根据笔记ID获取提醒通知
  Future<List<ReminderNotification>> getReminderNotificationsByNoteId(
    String noteId,
  ) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminder_notifications',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'triggered_at DESC',
    );

    return List.generate(
      maps.length,
      (i) => ReminderNotification.fromMap(maps[i]),
    );
  }

  /// 删除提醒通知
  Future<void> deleteReminderNotification(String notificationId) async {
    final db = await _database;
    await db.delete(
      'reminder_notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// 删除指定笔记的所有提醒通知
  Future<void> deleteReminderNotificationsByNoteId(String noteId) async {
    final db = await _database;
    await db.delete(
      'reminder_notifications',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }

  /// 清空所有提醒通知
  Future<void> clearAllReminderNotifications() async {
    final db = await _database;
    await db.delete('reminder_notifications');
  }

  /// 获取最近N天的提醒通知
  Future<List<ReminderNotification>> getRecentReminderNotifications({
    int days = 30,
  }) async {
    final db = await _database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'reminder_notifications',
      where: 'triggered_at >= ?',
      whereArgs: [cutoffDate.toIso8601String()],
      orderBy: 'triggered_at DESC',
    );

    return List.generate(
      maps.length,
      (i) => ReminderNotification.fromMap(maps[i]),
    );
  }

  /// 获取分页提醒通知
  Future<List<ReminderNotification>> getReminderNotificationsPaged({
    int page = 0,
    int pageSize = 20,
  }) async {
    final db = await _database;
    final offset = page * pageSize;

    final List<Map<String, dynamic>> maps = await db.query(
      'reminder_notifications',
      orderBy: 'triggered_at DESC',
      limit: pageSize,
      offset: offset,
    );

    return List.generate(
      maps.length,
      (i) => ReminderNotification.fromMap(maps[i]),
    );
  }

  /// 获取提醒通知总数
  Future<int> getTotalCount() async {
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reminder_notifications',
    );
    return result.isNotEmpty ? (result.first['count'] as int? ?? 0) : 0;
  }
}
