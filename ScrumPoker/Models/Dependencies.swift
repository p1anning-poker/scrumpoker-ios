//
//  Dependencies.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation
import Cocoa

final class Dependencies {
  
  private(set) lazy var appState = AppState.shared
  private(set) lazy var menuService = MenuService(
    statusBar: NSStatusBar.system,
    appState: appState
  )
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
