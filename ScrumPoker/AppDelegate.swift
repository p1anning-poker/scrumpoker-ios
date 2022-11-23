//
//  AppDelegate.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 22.11.2022.
//

import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

final class AppDelegate: NSObject, NSUIApplicationDelegate {
  private var sendPushTokenTask: Task<Void, Error>?
  
#if os(macOS)
  func applicationDidFinishLaunching(_ notification: Notification) {
    print("notification: \(String(describing: notification.userInfo))")
  }
#else
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    print("notification: \(String(describing: launchOptions))")
    return true
  }
#endif
  
  func application(_ application: NSUIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    sendPushToken(token)
  }
  
  func application(_ application: NSUIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error)")
  }
  
  private func sendPushToken(_ token: String) {
    sendPushTokenTask?.cancel()
    sendPushTokenTask = Task {
      do {
        try await Dependencies.shared.pokerApi.register(pushToken: token)
      } catch {
        try? await Task.sleep(nanoseconds: 30_000_000_000)
        try Task.checkCancellation()
        sendPushToken(token)
      }
    }
  }
}
