//
//  ScrumPokerApp.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

@main
struct ScrumPokerApp: App {
  
  private let dependencies = Dependencies()
  
  var body: some Scene {
    WindowGroup {
      MainView()
        .onOpenURL { url in
          print("url: \(url)")
          dependencies.coordinator.handle(deeplink: url,
                                          button: dependencies.menuService.statusItem.button ?? NSStatusBarButton())
        }
        .onAppear {
          _ = dependencies.menuService
        }
        .environmentObject(dependencies.appState)
        .environmentObject(dependencies.coordinator)
    }
  }
}

private struct MainView: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var coordinator: Coordinator
  
  var body: some View {
    EmptyView()
        .frame(width: .zero)
        .onReceive(appState.isAuthorized) { isAuthorized in
          updateContent(isAuthorized: isAuthorized)
        }
        .onAppear {
          updateContent(isAuthorized: appState.isAuthorizedValue)
        }
  }
  
  private func updateContent(isAuthorized: Bool) {
    if isAuthorized {
      coordinator.set(content: .myTasks())
    } else {
      coordinator.set(content: appState.lastLogin == nil ? .registration : .authorization)
    }
  }
}
