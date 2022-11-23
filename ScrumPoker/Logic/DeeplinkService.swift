//
//  DeeplinkService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 10.11.2022.
//

import Foundation

final class DeeplinkService: ObservableObject {
  static let scheme = "scrumpoker"
  
  func appRoute(from deeplink: URL) -> AppRoute? {
    guard let components = URLComponents(url: deeplink, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems,
          let taskId = queryItems.first(where: { $0.name == "taskId" })?.value,
          let teamId = queryItems.first(where: { $0.name == "teamId" })?.value else {
      return nil
    }
    return .taskDetails(taskId: taskId, teamId: teamId)
  }
  
  func appRoute(from notificationRoute: String) -> AppRoute? {
    let deeplinkString = "\(DeeplinkService.scheme)://\(notificationRoute)"
    return URL(string: deeplinkString)
      .flatMap(appRoute)
  }
  
  func deeplink(from appRoute: AppRoute) -> URL {
    switch appRoute {
    case .taskDetails(let taskId, let teamId):
      return URL(string: "\(Self.scheme)://?teamId=\(teamId)&taskId=\(taskId)")!
    }
  }
}
