# Widget Troubleshooting Guide

## Issue: Widget Shows 0 Tasks

### Step 1: Check App Group Configuration

1. **Open Xcode**
2. **Select Runner target** → Signing & Capabilities
3. **Add App Groups capability** if not present
4. **Add group**: `group.com.twick.app`
5. **Select TwickWidget target** → Signing & Capabilities
6. **Add App Groups capability** if not present
7. **Add the same group**: `group.com.twick.app`
8. **Both targets must use the same App Group ID**

### Step 2: Check Debug Logs

Look for these log messages in Xcode console:

**Flutter side:**
- `WidgetDataService: Found X today tasks out of Y total tasks`
- `WidgetDataService: Synced X today tasks to widget`

**iOS side (AppDelegate):**
- `📱 AppDelegate: Received X today tasks to sync`
- `✅ AppDelegate: Successfully saved X today tasks to App Group`

**Widget side:**
- `✅ Widget: Loaded X tasks from App Group`
- `✅ Widget: Parsed X tasks successfully`
- `✅ Widget: Using X tasks for today`

### Step 3: Verify Data is Saved

Add this temporary code to test in Xcode:

```swift
// In AppDelegate, after saving:
if let savedData = sharedDefaults.data(forKey: "widget_today_tasks") {
    print("✅ Saved data size: \(savedData.count) bytes")
    if let json = try? JSONSerialization.jsonObject(with: savedData) as? [[String: Any]] {
        print("✅ Saved \(json.count) tasks")
    }
}
```

### Step 4: Check Date Format

The widget expects ISO8601 date format. Check if your task dates are in the correct format:
- Format: `2026-01-28T14:30:00.000Z` or `2026-01-28T14:30:00`
- The widget tries both with and without fractional seconds

### Step 5: Manual Test

1. **Create a task for today** in the app
2. **Check Flutter logs** - should see "Synced X today tasks to widget"
3. **Check Xcode console** - should see AppDelegate logs
4. **Force refresh widget** - Long press widget → Reload
5. **Check widget logs** - should see task count

### Step 6: Common Issues

**Issue: "Could not access App Group"**
- Solution: Make sure App Groups capability is added to BOTH Runner and TwickWidget targets
- Make sure both use the same group ID: `group.com.twick.app`

**Issue: "No data found for key"**
- Solution: The method channel might not be working. Check if AppDelegate method channel handler is registered
- Try restarting the app after adding App Groups

**Issue: "Failed to parse date"**
- Solution: Check the date format in your tasks. Should be ISO8601 format
- The widget now handles both with and without fractional seconds

**Issue: Tasks show in app but not widget**
- Solution: Make sure `syncTasksToWidget()` is called after tasks are loaded
- Check if tasks are actually "today's tasks" (not recurring, scheduled for today)

### Step 7: Force Widget Refresh

After fixing issues:
1. Delete the widget from home screen
2. Rebuild and run the app
3. Add widget again
4. Widget should now show tasks

### Debug Commands

To manually trigger sync from Flutter:
```dart
await WidgetDataService.syncTasksToWidget();
```

To check what's in App Group (add to widget code temporarily):
```swift
if let sharedDefaults = UserDefaults(suiteName: "group.com.twick.app") {
    if let data = sharedDefaults.data(forKey: "widget_today_tasks") {
        print("Data exists: \(data.count) bytes")
    } else {
        print("No data found")
    }
} else {
    print("App Group not accessible")
}
```
