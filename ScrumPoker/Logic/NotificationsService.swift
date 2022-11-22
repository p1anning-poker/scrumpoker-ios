//
//  NotificationsService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 10.11.2022.
//

import Foundation
import UserNotifications

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

final class NotificationsService {
  
  private let center = UNUserNotificationCenter.current()
  private let deeplinkService: DeeplinkService
  
  // MARK: - Lifecycle
  
  init(deeplinkService: DeeplinkService) {
    self.deeplinkService = deeplinkService
    
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
    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
    Task {
      try await center.requestAuthorization(options: options)
      await MainActor.run {
        application.registerForRemoteNotifications()
      }
    }
  }
}

