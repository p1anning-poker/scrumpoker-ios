//
//  ScrumPokerApp.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

@main
struct ScrumPokerApp: App {
  
  @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
  private let dependencies = Dependencies.shared
  
  var body: some Scene {
    WindowGroup("viewer") {
      MainView()
        .handlesExternalEvents(preferring: Set(arrayLiteral: "viewer"), allowing: Set(arrayLiteral: "*")) // activate existing window if exists
        .environmentObject(dependencies.appState)
        .environmentObject(dependencies.pokerApi)
        .environmentObject(dependencies.tasksService)
        .environmentObject(dependencies.profileService)
        .environmentObject(dependencies.teamsService)
        .environmentObject(dependencies.deeplinkService)
        .environmentObject(dependencies.watchingService)
        .onAppear {
          // init watching
          _ = self.dependencies.watchingService
        }
    }
    .windowStyle(HiddenTitleBarWindowStyle())
    .windowToolbarStyle(UnifiedWindowToolbarStyle())
    .commands {
      CommandGroup(replacing: CommandGroupPlacement.newItem, addition: {})
    }
    .handlesExternalEvents(matching: Set(arrayLiteral: "viewer")) // create new window if one doesn't exist
  }
}
