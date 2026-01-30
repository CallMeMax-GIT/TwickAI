# iOS Widget Setup Instructions

## 1. Configure App Group

1. Open your project in Xcode
2. Select your **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **App Groups**
6. Add a new group: `group.com.twick.app` (or update the ID in code if you use a different one)

## 2. Configure Widget Target App Group

1. Select your **TwickWidget** target
2. Go to **Signing & Capabilities**
3. Add **App Groups** capability
4. Add the same group: `group.com.twick.app`
5. Make sure both targets use the same App Group ID

## 3. Update App Group ID in Code

If you use a different App Group ID, update it in:
- `lib/services/WidgetDataService.dart` - Update `_appGroupId` constant
- `ios/TwickWidget/TwickWidget.swift` - Update `appGroupId` in `loadTasks()` method

## 4. Widget Features

The widget displays:
- Today's task count
- Completion progress indicator
- Up to 3 task items (if space allows)
- "LIVE" tag when there are tasks
- Green color scheme matching the app's "Today" stat card

## 5. Testing

1. Build and run the app
2. Create some tasks for today
3. Add the widget to your home screen
4. The widget should update automatically when tasks change

## Notes

- Widget refreshes every 15 minutes automatically
- Widget updates when app syncs tasks
- Make sure both Runner and TwickWidget targets are signed with the same team
