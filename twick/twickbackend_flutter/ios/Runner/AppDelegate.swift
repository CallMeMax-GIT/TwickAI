import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register method channel for widget data sync
    let controller = window?.rootViewController as! FlutterViewController
    let widgetChannel = FlutterMethodChannel(
      name: "com.twick.app/widget",
      binaryMessenger: controller.binaryMessenger
    )
    
    widgetChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "syncTasksToWidget" {
        if let args = call.arguments as? [String: Any],
           let appGroupId = args["appGroupId"] as? String,
           let tasks = args["tasks"] as? [[String: Any]],
           let todayTasks = args["todayTasks"] as? [[String: Any]] {
          
          print("📱 AppDelegate: Received \(todayTasks.count) today tasks to sync")
          
          // Save to App Group UserDefaults
          if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
            do {
              let tasksData = try JSONSerialization.data(withJSONObject: tasks)
              let todayTasksData = try JSONSerialization.data(withJSONObject: todayTasks)
              
              sharedDefaults.set(tasksData, forKey: "widget_tasks")
              sharedDefaults.set(todayTasksData, forKey: "widget_today_tasks")
              sharedDefaults.synchronize()
              
              print("✅ AppDelegate: Successfully saved \(todayTasks.count) today tasks to App Group")
              
              // Verify the save
              if let savedData = sharedDefaults.data(forKey: "widget_today_tasks") {
                print("✅ AppDelegate: Verified - \(savedData.count) bytes saved")
                if let json = try? JSONSerialization.jsonObject(with: savedData) as? [[String: Any]] {
                  print("✅ AppDelegate: Verified - \(json.count) tasks in saved data")
                }
              }
              
              // Reload widget timeline to force update (iOS 14.0+)
              if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadTimelines(ofKind: "TwickWidget")
                print("✅ AppDelegate: Requested widget timeline reload")
              }
              
              result(true)
            } catch {
              print("❌ AppDelegate: Error serializing data: \(error)")
              result(FlutterError(code: "SYNC_ERROR", message: error.localizedDescription, details: nil))
            }
          } else {
            print("❌ AppDelegate: Could not access App Group: \(appGroupId)")
            result(FlutterError(code: "APP_GROUP_ERROR", message: "Could not access App Group. Make sure App Groups capability is enabled for both Runner and TwickWidget targets.", details: nil))
          }
        } else {
          print("❌ AppDelegate: Invalid arguments received")
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
