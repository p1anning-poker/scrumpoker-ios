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
  private(set) lazy var coordinator = Coordinator(initialContent: .authorization,
                                                  dependencies: self)
  private(set) lazy var menuService = MenuService(
    statusBar: NSStatusBar.system,
    coordinator: coordinator,
    appState: appState
  )
  private(set) lazy var networkService = NetworkService()
  private(set) lazy var pokerApi = PokerAPI(networkService: networkService, appState: appState)
}
