//
//  WatchingService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 10.11.2022.
//

import Foundation
import Combine

final class WatchingService: ObservableObject {
  
  private enum Keys {
    static let ignoredTeamIds = "ignored_team_ids"
  }
  
  private enum WatchingError: Error {
    case notSupported
  }
  
  // MARK: - Properties
  
  private let tasksService: TasksService
  private let teamsService: TeamsService
  private let notificationsService: NotificationsService
  private let appState: AppState
  
  // MARK: - Lifecycle
  
  init(tasksService: TasksService, teamsService: TeamsService, notificationsService: NotificationsService, appState: AppState) {
    self.tasksService = tasksService
    self.teamsService = teamsService
    self.notificationsService = notificationsService
    self.appState = appState

    configure()
  }
  
  // MARK: - Functions
  
  private func configure() {}
}

// MARK: - Subscriptions
extension WatchingService {
  func isSubscribed(teamId: Team.ID) -> AnyPublisher<Bool, Never> {
    return Just(isSubscribed(teamId: teamId))
      .eraseToAnyPublisher()
  }
  
  func isSubscribed(teamId: Team.ID) -> Bool {
    return true
  }
  
  func changeSubscription(enabled: Bool, for teamId: Team.ID) throws {
    throw WatchingError.notSupported
  }
}

struct WatchingServiceKey: InjectionKey {
    static var currentValue: WatchingService = WatchingService(
      tasksService: InjectedValues[\.tasksService],
      teamsService: InjectedValues[\.teamsService],
      notificationsService: InjectedValues[\.notificationsService],
      appState: InjectedValues[\.appState]
    )
}

extension InjectedValues {
  var watchingService: WatchingService {
    get { Self[WatchingServiceKey.self] }
    set { Self[WatchingServiceKey.self] = newValue }
  }
}
