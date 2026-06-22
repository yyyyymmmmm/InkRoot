import SwiftUI
import WidgetKit

private let appGroupIdentifier = "group.com.didichou.inkroot"
private let snapshotKey = "inkroot_widget_snapshot"
private let primary = Color(red: 44 / 255, green: 150 / 255, blue: 120 / 255)
private let textColor = Color(red: 31 / 255, green: 42 / 255, blue: 39 / 255)
private let mutedColor = Color(red: 108 / 255, green: 120 / 255, blue: 116 / 255)
private let surfaceColor = Color(red: 245 / 255, green: 247 / 255, blue: 246 / 255)

struct InkRootWidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
}

struct WidgetSnapshot {
  let todayNotes: Int
  let pendingTodos: Int
  let unsyncedCount: Int
  let quickTags: [String]
  let reviewNotes: [ReviewNote]
  let generatedAt: Date?
  let reviewRefreshIntervalMinutes: Int
  let reviewRangeDays: Int

  static let placeholder = WidgetSnapshot(
    todayNotes: 0,
    pendingTodos: 0,
    unsyncedCount: 0,
    quickTags: ["灵感", "工作", "日记"],
    reviewNotes: [],
    generatedAt: nil,
    reviewRefreshIntervalMinutes: 60,
    reviewRangeDays: 0
  )
}

struct ReviewNote {
  let id: String?
  let preview: String
}

struct InkRootTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> InkRootWidgetEntry {
    InkRootWidgetEntry(date: Date(), snapshot: .placeholder)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (InkRootWidgetEntry) -> Void
  ) {
    completion(InkRootWidgetEntry(date: Date(), snapshot: loadSnapshot()))
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<InkRootWidgetEntry>) -> Void
  ) {
    let snapshot = loadSnapshot()
    let interval = TimeInterval(max(15, min(snapshot.reviewRefreshIntervalMinutes, 1440)) * 60)
    let now = Date()
    let entries = (0..<24).map { offset in
      InkRootWidgetEntry(
        date: now.addingTimeInterval(interval * TimeInterval(offset)),
        snapshot: snapshot
      )
    }
    let nextRefresh = now.addingTimeInterval(interval * 24)
    completion(Timeline(entries: entries, policy: .after(nextRefresh)))
  }

  private func loadSnapshot() -> WidgetSnapshot {
    guard
      let defaults = UserDefaults(suiteName: appGroupIdentifier),
      let raw = defaults.string(forKey: snapshotKey),
      let data = raw.data(using: .utf8),
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return .placeholder
    }

    let today = object["today"] as? [String: Any]
    let sync = object["sync"] as? [String: Any]
    let reviewConfig = object["reviewConfig"] as? [String: Any]
    let generatedAt = (object["generatedAt"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) }
    let quickTags = object["quickTags"] as? [String] ?? []
    let reviewObjects = object["reviewNotes"] as? [[String: Any]] ?? []
    let reviews = reviewObjects.compactMap { item -> ReviewNote? in
      guard let preview = item["preview"] as? String, !preview.isEmpty else {
        return nil
      }
      return ReviewNote(id: item["id"] as? String, preview: preview)
    }

    return WidgetSnapshot(
      todayNotes: today?["notes"] as? Int ?? 0,
      pendingTodos: today?["pendingTodos"] as? Int ?? 0,
      unsyncedCount: sync?["unsyncedCount"] as? Int ?? 0,
      quickTags: Array(quickTags.prefix(5)),
      reviewNotes: reviews,
      generatedAt: generatedAt,
      reviewRefreshIntervalMinutes: reviewConfig?["refreshIntervalMinutes"] as? Int ?? 60,
      reviewRangeDays: reviewConfig?["rangeDays"] as? Int ?? 0
    )
  }
}

struct InkRootQuickNoteView: View {
  @Environment(\.widgetFamily) private var family
  let entry: InkRootWidgetEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("快速记录")
          .font(.subheadline.weight(.semibold))
          .foregroundColor(textColor)
        Spacer()
        Text("今日 \(entry.snapshot.todayNotes)")
          .font(.caption2)
          .foregroundColor(mutedColor)
      }

      Link(destination: URL(string: "inkroot://quick-note")!) {
        Text("+ 写一条")
          .font(.footnote.weight(.semibold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity, minHeight: 38)
          .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(primary))
      }

      if family != .systemSmall {
        HStack(spacing: 6) {
          ForEach(Array(entry.snapshot.quickTags.prefix(3)), id: \.self) { tag in
            Link(destination: URL(string: "inkroot://quick-note?tag=\(encoded(tag))")!) {
              Text("#\(tag)")
                .font(.caption2.weight(.medium))
                .foregroundColor(primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 30)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(surfaceColor))
            }
          }
        }
      }

      Spacer(minLength: 0)
      Text(statusText)
        .font(.caption2)
        .foregroundColor(mutedColor)
        .lineLimit(1)
    }
    .padding(14)
    .widgetBackground(Color.white)
  }

  private var statusText: String {
    if entry.snapshot.unsyncedCount > 0 {
      return "\(entry.snapshot.unsyncedCount) 条待同步"
    }
    if entry.snapshot.pendingTodos > 0 {
      return "\(entry.snapshot.pendingTodos) 个待办"
    }
    return "静待沉淀，蓄势而鸣"
  }

  private func encoded(_ text: String) -> String {
    text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
  }
}

struct InkRootRandomReviewView: View {
  @Environment(\.widgetFamily) private var family
  let entry: InkRootWidgetEntry

  private var review: ReviewNote? {
    guard !entry.snapshot.reviewNotes.isEmpty else {
      return nil
    }

    let intervalSeconds = max(15, min(entry.snapshot.reviewRefreshIntervalMinutes, 1440)) * 60
    let bucket = max(0, Int(entry.date.timeIntervalSince1970) / intervalSeconds)
    let index = bucket % entry.snapshot.reviewNotes.count
    return entry.snapshot.reviewNotes[index]
  }

  var body: some View {
    let currentReview = review
    let destination = currentReview?.id.flatMap { URL(string: "inkroot://note/\($0)") }
      ?? URL(string: "inkroot://random-review")!

    Link(destination: destination) {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("随机回顾")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(textColor)
          Spacer()
          Text(rangeText)
            .font(.caption2)
            .foregroundColor(mutedColor)
        }

        Text(currentReview?.preview ?? emptyReviewText)
          .font(family == .systemSmall ? .footnote : .body)
          .foregroundColor(textColor)
          .lineLimit(family == .systemLarge ? 8 : 5)
          .frame(maxWidth: .infinity, alignment: .leading)

        Spacer(minLength: 0)

        HStack {
          Text(refreshText)
            .font(.caption2)
            .foregroundColor(mutedColor)
            .lineLimit(1)
          Spacer()
          Text("打开")
            .font(.caption2.weight(.semibold))
            .foregroundColor(primary)
        }
      }
      .padding(14)
      .widgetBackground(Color.white)
    }
  }

  private var refreshText: String {
    let minutes = entry.snapshot.reviewRefreshIntervalMinutes
    return minutes < 60 ? "\(minutes)分钟刷新" : "\(minutes / 60)小时刷新"
  }

  private var emptyReviewText: String {
    if entry.snapshot.generatedAt != nil {
      return "暂无可回顾笔记"
    }
    return "打开 InkRoot 同步小组件"
  }

  private var rangeText: String {
    switch entry.snapshot.reviewRangeDays {
    case 0:
      return "全部"
    case 30:
      return "近30天"
    case 90:
      return "近90天"
    case 180:
      return "近半年"
    case 365:
      return "近一年"
    default:
      return "\(entry.snapshot.reviewRangeDays)天"
    }
  }
}

struct InkRootQuickNoteWidget: Widget {
  let kind = "InkRootQuickNoteWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: InkRootTimelineProvider()) { entry in
      InkRootQuickNoteView(entry: entry)
    }
    .configurationDisplayName("InkRoot 快速记录")
    .description("打开快捷编辑器，或从常用标签开始记录。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct InkRootRandomReviewWidget: Widget {
  let kind = "InkRootRandomReviewWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: InkRootTimelineProvider()) { entry in
      InkRootRandomReviewView(entry: entry)
    }
    .configurationDisplayName("InkRoot 随机回顾")
    .description("按设置的时间和范围回顾历史笔记。")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

@main
struct InkRootWidgets: WidgetBundle {
  var body: some Widget {
    InkRootQuickNoteWidget()
    InkRootRandomReviewWidget()
  }
}

extension View {
  @ViewBuilder
  func widgetBackground(_ color: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(color, for: .widget)
    } else {
      background(color)
    }
  }
}
