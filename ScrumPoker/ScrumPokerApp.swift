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
    WindowGroup("viewer") {
      MainView()
        .handlesExternalEvents(preferring: Set(arrayLiteral: "viewer"), allowing: Set(arrayLiteral: "*")) // activate existing window if exists
        .environmentObject(dependencies.appState)
        .environmentObject(dependencies.pokerApi)
        .environmentObject(dependencies.tasksService)
        .environmentObject(dependencies.profileService)
        .environmentObject(dependencies.teamsService)
    }
    .windowStyle(HiddenTitleBarWindowStyle())
    .windowToolbarStyle(UnifiedWindowToolbarStyle())
    .commands {
      CommandGroup(replacing: CommandGroupPlacement.newItem, addition: {})
    }
    .handlesExternalEvents(matching: Set(arrayLiteral: "viewer")) // create new window if one doesn't exist
  }
}

private struct MainView: View {
  
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var profileService: ProfileService
  @State private var modal: Modal?
  @State private var deferredModal: Modal?
  
  enum Modal: Identifiable {
    case createNew
    case details(ApiTask.ID)
    
    var id: Int {
      switch self {
      case .createNew:
        return 0
      case .details(let id):
        return id.hashValue
      }
    }
  }
  
  var body: some View {
    if let user = appState.currentUser {
      contentView(user: user)
    } else {
      AuthorizationView(content: appState.lastLogin == nil ? .registration : .authorization) {
        if let modal = deferredModal {
          deferredModal = nil
          self.modal = modal
        }
      }
      .frame(width: 350, alignment: .center)
      .onOpenURL { url in
        if let modal = self.modal(for: url) {
          // waiting for the authorization
          deferredModal = modal
        }
      }
    }
  }
  
  @ViewBuilder
  private func contentView(user: User) -> some View {
    NavigationView {
      TeamsView()
        .frame(minWidth: 250, maxWidth: 300)
    }
    .toolbar {
      Toolbar(userName: user.name) {
        logout()
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
      case .details(let id):
        TaskView(taskId: id, addToRecentlyViewed: true)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button {
                self.modal = nil
              } label: {
                Text("Close")
              }
            }
          }
          .frame(minWidth: 500, maxWidth: 700, minHeight: 300, alignment: .top)
      }
    }
    .onOpenURL { url in
      modal = self.modal(for: url)
    }
  }
  
  private func modal(for deeplink: URL) -> Modal? {
    guard let components = URLComponents(url: deeplink, resolvingAgainstBaseURL: false),
          let taskId = components.queryItems?.first(where: { $0.name == "taskId" })?.value else {
      return nil
    }
    return .details(taskId)
  }
  
  private func logout() {
    Task {
      await profileService.logout()
    }
  }
}
