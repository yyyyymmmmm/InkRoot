/// 提醒通知模型 - 记录已触发的笔记提醒
class ReminderNotification {
  // 是否已点击

  ReminderNotification({
    required this.id,
    required this.noteId,
    required this.noteTitle,
    required this.noteContent,
    required this.reminderTime,
    required this.triggeredAt,
    this.isRead = false,
    this.isClicked = false,
  });

  /// 从数据库Map创建对象
  factory ReminderNotification.fromMap(Map<String, dynamic> map) =>
      ReminderNotification(
        id: map['id'],
        noteId: map['note_id'],
        noteTitle: map['note_title'],
        noteContent: map['note_content'],
        reminderTime: DateTime.parse(map['reminder_time']),
        triggeredAt: DateTime.parse(map['triggered_at']),
        isRead: map['is_read'] == 1,
        isClicked: map['is_clicked'] == 1,
      );
  final String id; // 通知ID（使用UUID）
  final String noteId; // 关联的笔记ID
  final String noteTitle; // 笔记标题（提醒时的内容摘要）
  final String noteContent; // 笔记内容预览
  final DateTime reminderTime; // 提醒时间
  final DateTime triggeredAt; // 实际触发时间
  final bool isRead; // 是否已读
  final bool isClicked;

  /// 转换为数据库Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'note_id': noteId,
        'note_title': noteTitle,
        'note_content': noteContent,
        'reminder_time': reminderTime.toIso8601String(),
        'triggered_at': triggeredAt.toIso8601String(),
        'is_read': isRead ? 1 : 0,
        'is_clicked': isClicked ? 1 : 0,
      };

  /// 复制并修改
  ReminderNotification copyWith({
    String? id,
    String? noteId,
    String? noteTitle,
    String? noteContent,
    DateTime? reminderTime,
    DateTime? triggeredAt,
    bool? isRead,
    bool? isClicked,
  }) =>
      ReminderNotification(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        noteTitle: noteTitle ?? this.noteTitle,
        noteContent: noteContent ?? this.noteContent,
        reminderTime: reminderTime ?? this.reminderTime,
        triggeredAt: triggeredAt ?? this.triggeredAt,
        isRead: isRead ?? this.isRead,
        isClicked: isClicked ?? this.isClicked,
      );

  @override
  String toString() =>
      'ReminderNotification(id: $id, noteId: $noteId, title: $noteTitle, reminderTime: $reminderTime, isRead: $isRead)';
}

/// 统一通知模型 - 整合系统公告和提醒通知
class UnifiedNotification {
  UnifiedNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.publishDate,
    required this.type,
    required this.isRead,
    this.noteId,
    this.reminderTime,
    this.announcementType,
    this.actionUrls,
    this.imageUrl,
  });

  /// 从提醒通知创建
  factory UnifiedNotification.fromReminder(ReminderNotification reminder) =>
      UnifiedNotification(
        id: reminder.id,
        title: reminder.noteTitle,
        content: reminder.noteContent,
        publishDate: reminder.triggeredAt,
        type: 'reminder',
        isRead: reminder.isRead,
        noteId: reminder.noteId,
        reminderTime: reminder.reminderTime,
      );

  /// 从系统公告创建
  factory UnifiedNotification.fromAnnouncement(
    String id,
    String title,
    String content,
    DateTime publishDate,
    String announcementType,
    bool isRead, {
    Map<String, String>? actionUrls,
    String? imageUrl,
  }) =>
      UnifiedNotification(
        id: id,
        title: title,
        content: content,
        publishDate: publishDate,
        type: 'system',
        isRead: isRead,
        announcementType: announcementType,
        actionUrls: actionUrls,
        imageUrl: imageUrl,
      );
  final String id;
  final String title;
  final String content;
  final DateTime publishDate; // 发布/触发时间
  final String type; // 'system', 'reminder'
  final bool isRead;

  // 提醒通知特有字段
  final String? noteId;
  final DateTime? reminderTime;

  // 系统公告特有字段
  final String? announcementType; // 'update', 'info', 'event', 'warning'
  final Map<String, String>? actionUrls;
  final String? imageUrl;

  /// 是否是提醒通知
  bool get isReminder => type == 'reminder';

  /// 是否是系统公告
  bool get isSystemAnnouncement => type == 'system';

  @override
  String toString() =>
      'UnifiedNotification(id: $id, type: $type, title: $title, isRead: $isRead)';
}
