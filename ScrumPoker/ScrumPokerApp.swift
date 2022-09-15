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
        .environmentObject(dependencies.appState)
        .environmentObject(dependencies.pokerApi)
        .environmentObject(dependencies.tasksService)
//        .onOpenURL { url in
//          print("url: \(url)")
//          dependencies.coordinator.handle(deeplink: url,
//                                          button: dependencies.menuService.statusItem.button ?? NSStatusBarButton())
//        }
//        .onAppear {
//          _ = dependencies.menuService
//        }
    }
    .windowStyle(HiddenTitleBarWindowStyle())
    .windowToolbarStyle(UnifiedWindowToolbarStyle())
  }
}

private struct MainView: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var coordinator: Coordinator
  @State private var modal: Modal?
  
  enum Modal: Identifiable {
    case createNew
    
    var id: Int {
      return 0
    }
  }
  
  var body: some View {
    if let user = appState.currentUser {
      NavigationView {
        MyTasksView(openAtStart: .constant(nil))
          .frame(minWidth: 250, maxWidth: 300)
      }
      .toolbar {
        Toolbar(userName: user.name) {
          appState.set(token: nil, user: nil)
        } onCreate: {
          modal = .createNew
        }
      }
      .frame(minWidth: 600, idealWidth: 800, minHeight: 400, idealHeight: 400)
      .sheet(item: $modal) { modal in
        switch modal {
        case .createNew:
          TaskCreate { _ in
            self.modal = nil
          }
          .frame(minWidth: 300, maxWidth: 400)
        }
      }
    } else {
      AuthorizationView(onRegister: {})
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
