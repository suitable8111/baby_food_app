//
//  BabyTrackerWidget.swift
//  BabyTrackerWidget
//

import WidgetKit
import SwiftUI

// ─────────────────────────────────────────
// MARK: - App Group ID
// ─────────────────────────────────────────
private let appGroupId = "group.com.babyfood.babyFoodApp"

// ─────────────────────────────────────────
// MARK: - 데이터 모델
// ─────────────────────────────────────────
struct BabyStats {
    var feedingCount: Int = 0
    var feedingMl: Int = 0
    var diaperCount: Int = 0
    var playMinutes: Int = 0
    var babyName: String = "우리아이"
    var lastUpdate: String = "--:--"

    static func load() -> BabyStats {
        let defaults = UserDefaults(suiteName: appGroupId)
        var s = BabyStats()
        s.feedingCount  = defaults?.integer(forKey: "feedingCount")  ?? 0
        s.feedingMl     = defaults?.integer(forKey: "feedingMl")     ?? 0
        s.diaperCount   = defaults?.integer(forKey: "diaperCount")   ?? 0
        s.playMinutes   = defaults?.integer(forKey: "playMinutes")   ?? 0
        s.babyName      = defaults?.string(forKey: "babyName")       ?? "우리아이"
        s.lastUpdate    = defaults?.string(forKey: "lastUpdate")     ?? "--:--"
        return s
    }
}

struct BabyTrackerEntry: TimelineEntry {
    let date: Date
    let stats: BabyStats
}

// ─────────────────────────────────────────
// MARK: - Timeline Provider
// ─────────────────────────────────────────
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BabyTrackerEntry {
        BabyTrackerEntry(date: Date(), stats: BabyStats())
    }

    func getSnapshot(in context: Context, completion: @escaping (BabyTrackerEntry) -> Void) {
        completion(BabyTrackerEntry(date: Date(), stats: BabyStats.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BabyTrackerEntry>) -> Void) {
        let entry = BabyTrackerEntry(date: Date(), stats: BabyStats.load())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// ─────────────────────────────────────────
// MARK: - 색상
// ─────────────────────────────────────────
extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

private let bgTop      = Color(hex: "1E3A2F")  // 진한 다크그린
private let bgBottom   = Color(hex: "0F2318")  // 더 진한 그린
private let accentGreen = Color(hex: "6BBF59") // 브랜드 그린
private let cardBg     = Color.white.opacity(0.1)
private let textPrimary = Color.white
private let textSecondary = Color.white.opacity(0.65)

// ─────────────────────────────────────────
// MARK: - Small 위젯 (2×2)
// ─────────────────────────────────────────
struct SmallWidgetView: View {
    let stats: BabyStats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(accentGreen)
                Text(stats.babyName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentGreen)
                    .lineLimit(1)
                Spacer()
                Text("오늘")
                    .font(.system(size: 9))
                    .foregroundColor(textSecondary)
            }

            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical, 6)

            SmallRow(emoji: "🍼", label: "수유",
                     value: "\(stats.feedingCount)회",
                     badge: stats.feedingMl > 0 ? "\(stats.feedingMl)ml" : nil)
            Spacer().frame(height: 5)
            SmallRow(emoji: "🚼", label: "기저귀",
                     value: "\(stats.diaperCount)회",
                     badge: nil)
            Spacer().frame(height: 5)
            SmallRow(emoji: "🎮", label: "놀이",
                     value: "\(stats.playMinutes)분",
                     badge: nil)

            Spacer()

            Text("⏱ \(stats.lastUpdate) 업데이트")
                .font(.system(size: 8.5))
                .foregroundColor(textSecondary)
        }
        .padding(12)
        .containerBackground(
            LinearGradient(
                colors: [bgTop, bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .widget
        )
    }
}

struct SmallRow: View {
    let emoji: String
    let label: String
    let value: String
    let badge: String?

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji).font(.system(size: 12))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(textPrimary)
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 9))
                    .foregroundColor(accentGreen)
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Medium 위젯 (4×2)
// ─────────────────────────────────────────
struct MediumWidgetView: View {
    let stats: BabyStats

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentGreen)
                    Text("\(stats.babyName) 오늘의 기록")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textPrimary)
                }
                Spacer()
                Text("⏱ \(stats.lastUpdate)")
                    .font(.system(size: 10))
                    .foregroundColor(textSecondary)
            }

            HStack(spacing: 8) {
                StatCard(emoji: "🍼", label: "수유",
                         mainValue: "\(stats.feedingCount)회",
                         subValue: stats.feedingMl > 0 ? "\(stats.feedingMl)ml" : "",
                         color: Color(hex: "FF9800"))
                StatCard(emoji: "🚼", label: "기저귀",
                         mainValue: "\(stats.diaperCount)회",
                         subValue: "",
                         color: Color(hex: "FFB74D"))
                StatCard(emoji: "🎮", label: "놀이",
                         mainValue: "\(stats.playMinutes)분",
                         subValue: "",
                         color: accentGreen)
            }
        }
        .padding(14)
        .containerBackground(
            LinearGradient(
                colors: [bgTop, bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .widget
        )
    }
}

struct StatCard: View {
    let emoji: String
    let label: String
    let mainValue: String
    let subValue: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji).font(.system(size: 22))
            Text(mainValue)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(textPrimary)
            if !subValue.isEmpty {
                Text(subValue)
                    .font(.system(size: 10))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// ─────────────────────────────────────────
// MARK: - 위젯 진입점
// ─────────────────────────────────────────
struct BabyTrackerWidgetEntryView: View {
    let entry: BabyTrackerEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:  SmallWidgetView(stats: entry.stats)
            case .systemMedium: MediumWidgetView(stats: entry.stats)
            default:            SmallWidgetView(stats: entry.stats)
            }
        }
        .widgetURL(URL(string: "babyfood://diary")!)
    }
}

struct BabyTrackerWidget: Widget {
    let kind = "BabyTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BabyTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("우리 아이 기록")
        .description("오늘의 수유·기저귀·놀이 현황을 한눈에 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
