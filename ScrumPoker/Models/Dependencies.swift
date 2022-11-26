//
//  Dependencies.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation
import SwiftUI

final class Dependencies {
  
  static let shared = Dependencies()
  private init() {}
  
  private(set) lazy var appState = AppState.shared
  private(set) lazy var networkService = NetworkService()
  private(set) lazy var pokerApi = PokerAPI(networkService: networkService, appState: appState)
  private(set) lazy var tasksService = TasksService(api: pokerApi, appState: appState, notificationsService: notificationsService, deeplinkService: deeplinkService)
  private(set) lazy var profileService = ProfileService(api: pokerApi, appState: appState)
  private(set) lazy var teamsService = TeamsService(api: pokerApi)
  private(set) lazy var deeplinkService = DeeplinkService()
  private(set) lazy var notificationsService = NotificationsService(deeplinkService: deeplinkService)
  private(set) lazy var watchingService = WatchingService(
    tasksService: tasksService,
    teamsService: teamsService,
    notificationsService: notificationsService,
    appState: appState
  )
}

extension View {
  func testDependences() -> some View {
    let appState = AppState.shared
    let networkService = NetworkService()
    let pokerApi = PokerAPI(networkService: networkService, appState: appState)
    let deeplinkService = DeeplinkService()
    let notificationsService = NotificationsService(deeplinkService: deeplinkService)
    let tasksService = TestTasksService(api: pokerApi, appState: appState, notificationsService: notificationsService, deeplinkService: deeplinkService)
    let profileService = ProfileService(api: pokerApi, appState: appState)
    let teamsService = TeamsService(api: pokerApi)
    let watchingService = WatchingService(tasksService: tasksService, teamsService: teamsService, notificationsService: notificationsService, appState: appState)
    
    InjectedValues[\.appState] = appState
    InjectedValues[\.networkService] = networkService
    InjectedValues[\.pokerApi] = pokerApi
    InjectedValues[\.deeplinkService] = deeplinkService
    InjectedValues[\.notificationsService] = notificationsService
    InjectedValues[\.tasksService] = tasksService
    InjectedValues[\.profileService] = profileService
    InjectedValues[\.teamsService] = teamsService
    InjectedValues[\.watchingService] = watchingService
    
    return self
  }
}
