//
//  NotificationsService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 10.11.2022.
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

struct NotificationItem {
  var id: ID
  var title: String
  var body: String
  var appRoute: AppRoute?
}

extension NotificationItem {
  enum ID: String {
    case newTasks = "new_tasks"
  }
}

final class NotificationsService: NSObject {
  
  private let center = UNUserNotificationCenter.current()
  private let deeplinkService: DeeplinkService
  
  let notifications = PassthroughSubject<UNNotificationResponse, Never>()
  
  // MARK: - Lifecycle
  
  init(deeplinkService: DeeplinkService) {
    self.deeplinkService = deeplinkService
    super.init()
    
    configure()
  }
  
  // MARK: - Functions
  
  func schedule(notification: NotificationItem) async throws {
    let content = UNMutableNotificationContent()
    content.title = notification.title
    content.body = notification.body
    content.userInfo["url"] = notification.appRoute.map { deeplinkService.deeplink(from: $0).absoluteString }
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

    let request = UNNotificationRequest(identifier: notification.id.rawValue,
                                        content: content,
                                        trigger: trigger)
    try await center.add(request)
  }
  
  // MARK: Private
  
  private func configure() {
    center.delegate = self
    
    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
    Task {
      try await center.requestAuthorization(options: options)
      await MainActor.run {
        NSUIApplication.shared.registerForRemoteNotifications()
      }
    }
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationsService: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    print("new push notification: \(response.notification.request.content.userInfo)")
    await MainActor.run {
      notifications.send(response)
    }
  }
}

