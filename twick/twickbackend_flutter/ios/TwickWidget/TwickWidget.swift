//
//  TwickWidget.swift
//  TwickWidget
//
//  Created by Kevin Philip on 28/01/26.
//

import WidgetKit
import SwiftUI

// Task model for widget
struct WidgetTask: Codable {
    let id: String
    let title: String
    let scheduledTime: Date
    let isCompleted: Bool
    let priority: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), todayTasksCount: 0, completedCount: 0, progress: 0.0, tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadTasks()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = loadTasks()
        
        print("🕐 Widget: getTimeline called - entry has \(entry.todayTasksCount) tasks")
        
        // Refresh every 15 minutes, but also allow immediate refresh
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadTasks() -> SimpleEntry {
        // Load tasks from App Group UserDefaults
        let appGroupId = "group.com.twick.app" // Update with your App Group ID
        guard let sharedDefaults = UserDefaults(suiteName: appGroupId) else {
            print("⚠️ Widget: Could not access App Group: \(appGroupId)")
            return SimpleEntry(date: Date(), todayTasksCount: 0, completedCount: 0, progress: 0.0, tasks: [])
        }
        
        // Try to load today's tasks (pre-filtered by Flutter)
        guard let tasksData = sharedDefaults.data(forKey: "widget_today_tasks") else {
            print("⚠️ Widget: No data found for key 'widget_today_tasks'")
            return SimpleEntry(date: Date(), todayTasksCount: 0, completedCount: 0, progress: 0.0, tasks: [])
        }
        
        guard let tasksJson = try? JSONSerialization.jsonObject(with: tasksData) as? [[String: Any]] else {
            print("⚠️ Widget: Failed to parse JSON data")
            return SimpleEntry(date: Date(), todayTasksCount: 0, completedCount: 0, progress: 0.0, tasks: [])
        }
        
        print("✅ Widget: Loaded \(tasksJson.count) tasks from App Group")
        
        var tasks: [WidgetTask] = []
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        for (index, taskDict) in tasksJson.enumerated() {
            print("📋 Widget: Processing task \(index + 1)/\(tasksJson.count)")
            
            guard let id = taskDict["id"] as? String else {
                print("⚠️ Widget: Missing id in task \(index + 1)")
                continue
            }
            
            guard let title = taskDict["title"] as? String else {
                print("⚠️ Widget: Missing title in task \(index + 1)")
                continue
            }
            
            // Prefer epoch milliseconds (timezone-agnostic) over ISO8601 string
            var scheduledTime: Date?
            
            if let epochMs = taskDict["scheduledTimeEpoch"] as? Int {
                // Use epoch milliseconds - this is timezone-agnostic and more reliable
                scheduledTime = Date(timeIntervalSince1970: TimeInterval(epochMs) / 1000.0)
                print("📅 Widget: Using epoch milliseconds: \(epochMs) -> \(scheduledTime!)")
            } else if let scheduledTimeStr = taskDict["scheduledTime"] as? String {
                // Fallback to ISO8601 string parsing
                print("📅 Widget: Parsing ISO8601 date: \(scheduledTimeStr)")
                
                // Configure formatter to handle UTC timezone
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
                
                // Try with fractional seconds first
                scheduledTime = formatter.date(from: scheduledTimeStr)
                
                // If that fails, try without fractional seconds
                if scheduledTime == nil {
                    let simpleFormatter = ISO8601DateFormatter()
                    simpleFormatter.formatOptions = [.withInternetDateTime]
                    simpleFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
                    scheduledTime = simpleFormatter.date(from: scheduledTimeStr)
                }
                
                // If that fails, try DateFormatter as fallback
                if scheduledTime == nil {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
                    scheduledTime = dateFormatter.date(from: scheduledTimeStr)
                }
                
                if scheduledTime == nil {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
                    scheduledTime = dateFormatter.date(from: scheduledTimeStr)
                }
            } else {
                print("⚠️ Widget: Missing both scheduledTime and scheduledTimeEpoch in task \(index + 1)")
                continue
            }
            
            guard let date = scheduledTime else {
                print("❌ Widget: Failed to parse date")
                continue
            }
            
            // Date is now correctly parsed, and will display in local timezone automatically
            print("✅ Widget: Parsed date successfully: \(date)")
            print("✅ Widget: Local timezone: \(TimeZone.current.identifier)")
            let localFormatter = DateFormatter()
            localFormatter.timeStyle = .short
            localFormatter.dateStyle = .none
            localFormatter.timeZone = TimeZone.current
            print("✅ Widget: Date in local time: \(localFormatter.string(from: date))")
            
            let isCompleted = taskDict["isCompleted"] as? Bool ?? false
            let priority = taskDict["priority"] as? String ?? "medium"
            
            tasks.append(WidgetTask(
                id: id,
                title: title,
                scheduledTime: date,
                isCompleted: isCompleted,
                priority: priority
            ))
            
            print("✅ Widget: Added task: \(title) at \(date)")
        }
        
        print("✅ Widget: Parsed \(tasks.count) tasks successfully out of \(tasksJson.count) JSON entries")
        
        // Flutter already filtered to today's tasks, so use them directly
        // Don't filter again - trust Flutter's filtering
        // Only verify dates are parseable (which we already did above)
        let finalTasks = tasks
        
        print("✅ Widget: Using \(finalTasks.count) tasks (Flutter pre-filtered to today)")
        
        // Log task details for debugging
        for (index, task) in finalTasks.enumerated() {
            print("📋 Widget: Task \(index + 1): '\(task.title)' at \(task.scheduledTime), completed: \(task.isCompleted)")
        }
        
        let completedCount = finalTasks.filter { $0.isCompleted }.count
        let progress = finalTasks.isEmpty ? 0.0 : Double(completedCount) / Double(finalTasks.count)
        
        print("✅ Widget: Final entry - count: \(finalTasks.count), completed: \(completedCount), progress: \(progress)")
        
        return SimpleEntry(
            date: Date(),
            todayTasksCount: finalTasks.count,
            completedCount: completedCount,
            progress: progress,
            tasks: Array(finalTasks.prefix(3)) // Show max 3 tasks
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let todayTasksCount: Int
    let completedCount: Int
    let progress: Double
    let tasks: [WidgetTask]
}

struct TwickWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    // Helper to format time in local timezone
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = TimeZone.current // Explicitly use local timezone
        let formatted = formatter.string(from: date)
        
        // Debug logging
        print("🕐 Widget: Formatting time - UTC: \(date), Local: \(formatted), Timezone: \(TimeZone.current.identifier)")
        
        return formatted
    }
    
    var body: some View {
        let _ = print("🎨 Widget: Rendering entry with \(entry.todayTasksCount) tasks, family: \(family)")
        
        switch family {
        case .systemSmall:
            return AnyView(smallWidgetView)
        case .systemMedium, .systemLarge:
            return AnyView(mediumWidgetView)
        default:
            return AnyView(smallWidgetView)
        }
    }
    
    // Small widget: Match _StatGlassCard layout exactly
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: Icon + Tag
            HStack {
                // Icon (48x48, 24pt)
                ZStack {
                    Circle()
                        .fill(Color(red: 0.29, green: 0.79, blue: 0.31).opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "bolt.fill")
                        .foregroundColor(Color(red: 0.29, green: 0.79, blue: 0.31))
                        .font(.system(size: 24))
                }
                
                Spacer()
                
                // LIVE tag
                if entry.todayTasksCount > 0 {
                    Text("LIVE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.29, green: 0.79, blue: 0.31))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.29, green: 0.79, blue: 0.31).opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
            
            // Value row: Count + Progress
            HStack(alignment: .center) {
                Text("\(entry.todayTasksCount)")
                    .font(.system(size: 35, weight: .bold))
                    .foregroundColor(.primary)
                    .kerning(-1)
                
                if entry.todayTasksCount > 0 {
                    Spacer()
                    
                    // Progress indicator (28x28)
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 28, height: 28)
                        
                        Circle()
                            .trim(from: 0, to: entry.progress)
                            .stroke(Color(red: 0.29, green: 0.79, blue: 0.31), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
                        
                        if entry.progress >= 1.0 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(red: 0.29, green: 0.79, blue: 0.31))
                        }
                    }
                }
            }
            
            // Spacing (8pt)
            Spacer()
                .frame(height: 8)
            
            // Title
            Text("TODAY")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(17)
    }
    
    // Medium/Large widget: Count + tasks
    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with icon and live tag
            HStack {
                // Icon (48x48, 24pt)
                ZStack {
                    Circle()
                        .fill(Color(red: 0.29, green: 0.79, blue: 0.31).opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "bolt.fill")
                        .foregroundColor(Color(red: 0.29, green: 0.79, blue: 0.31))
                        .font(.system(size: 24))
                }
                
                Spacer()
                
                // Live tag
                if entry.todayTasksCount > 0 {
                    Text("LIVE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.29, green: 0.79, blue: 0.31))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.29, green: 0.79, blue: 0.31).opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 17)
            .padding(.top, 17)
            
            // Reduced spacing - removed Spacer() to minimize gap
            Spacer()
                .frame(height: 8)
            
            // Count and progress
            HStack(alignment: .center) {
                Text("\(entry.todayTasksCount)")
                    .font(.system(size: 35, weight: .bold))
                    .foregroundColor(.primary)
                    .kerning(-1)
                
                Spacer()
                
                // Progress indicator
                if entry.todayTasksCount > 0 {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 28, height: 28)
                        
                        Circle()
                            .trim(from: 0, to: entry.progress)
                            .stroke(Color(red: 0.29, green: 0.79, blue: 0.31), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
                        
                        if entry.progress >= 1.0 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(red: 0.29, green: 0.79, blue: 0.31))
                        }
                    }
                }
            }
            .padding(.horizontal, 17)
            
            // Title
            HStack {
                Text("TODAY")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .kerning(0.5)
                Spacer()
            }
            .padding(.horizontal, 17)
            .padding(.top, 8)
            
            // Task list (show up to 3 tasks) - reduced spacing
            if !entry.tasks.isEmpty {
                Divider()
                    .padding(.horizontal, 17)
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.tasks.prefix(3), id: \.id) { task in
                        HStack(spacing: 8) {
                            // Checkbox
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? Color(red: 0.29, green: 0.79, blue: 0.31) : .gray)
                                .font(.system(size: 14))
                            
                            // Task title
                            Text(task.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .strikethrough(task.isCompleted)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Time - format explicitly in local timezone
                            Text(formatTime(task.scheduledTime))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 17)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct TwickWidget: Widget {
    let kind: String = "TwickWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                TwickWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TwickWidgetEntryView(entry: entry)
                    .padding()
            }
        }
        .configurationDisplayName("Today's Tasks")
        .description("View your tasks for today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    TwickWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        todayTasksCount: 5,
        completedCount: 2,
        progress: 0.4,
        tasks: [
            WidgetTask(id: "1", title: "Team Meeting", scheduledTime: .now, isCompleted: false, priority: "medium"),
            WidgetTask(id: "2", title: "Review Documents", scheduledTime: .now, isCompleted: true, priority: "high"),
            WidgetTask(id: "3", title: "Call Client", scheduledTime: .now, isCompleted: false, priority: "low")
        ]
    )
}
