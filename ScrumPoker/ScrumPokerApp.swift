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
        .onAppear {
          // init menu
          _ = self.dependencies.menuService
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

private struct MainView: View {
  
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var profileService: ProfileService
  @EnvironmentObject private var teamsService: TeamsService
  @EnvironmentObject private var tasksService: TasksService
  
  @State private var modal: Modal?
  @State private var selectedTeam: Team?
  @State private var taskToOpen: ApiTask?
  
  var body: some View {
    if let user = appState.currentUser {
      contentView(user: user)
        .frame(minWidth: 1000, minHeight: 500)
    } else {
      AuthorizationView(content: appState.lastLogin == nil ? .registration : .authorization) {
        
      }
      .frame(width: 350, alignment: .center)
      .onOpenURL { url in
        if let route = self.route(from: url) {
          // waiting for the authorization
          switch route {
          case .taskDetails(let taskId, let teamId):
            self.modal = .details(taskId, teamId: teamId)
          }
        }
      }
    }
  }
  
  @ViewBuilder
  private func contentView(user: User) -> some View {
    NavigationView {
      SideBar(profile: user) {
        logout()
      } content: {
        TeamsView(selectedTeam: $selectedTeam, taskToOpen: $taskToOpen)
      }
      .frame(minWidth: 250, maxWidth: 300)
      EmptyView()
    }
    .toolbar {
      Toolbar(teamName: selectedTeam?.teamName ?? "No Team Selected")
    }
    .sheet(item: $modal) { modal in
      switch modal {
      case .details(let id, let teamId):
        // userUuid used for user's default team
        taskDetails(id: id, teamId: teamId ?? user.userUuid)
      }
    }
    .onOpenURL { url in
      modal = nil
      guard let route = self.route(from: url) else { return }
      switch route {
      case .taskDetails(let taskId, let teamId):
        if let teamId = teamId, let team = teamsService.teams.first(where: { $0.id == teamId }) {
          Task {
            do {
              let task = try await tasksService.task(id: taskId, teamId: teamId)
              await MainActor.run {
                // set values
                selectedTeam = team
                taskToOpen = task
              }
            } catch {
              await MainActor.run {
                modal = .details(taskId, teamId: teamId)
              }
            }
          }
        } else {
          modal = .details(taskId, teamId: teamId)
        }
      }
    }
  }
  
  private func route(from deeplink: URL) -> Route? {
    guard let components = URLComponents(url: deeplink, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems,
          let taskId = queryItems.first(where: { $0.name == "taskId" })?.value else {
      return nil
    }
    let teamId = queryItems.first(where: { $0.name == "teamId" })?.value
    return .taskDetails(taskId: taskId, teamId: teamId)
  }
  
  @ViewBuilder
  private func taskDetails(id: ApiTask.ID, teamId: Team.ID) -> some View {
    TaskView(taskId: id, teamId: teamId, addToRecentlyViewed: true)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            self.modal = nil
          } label: {
            Text("Close")
          }
        }
      }
      .frame(minWidth: 500, maxWidth: 800, minHeight: 300, alignment: .top)
  }
  
  private func logout() {
    Task {
      await profileService.logout()
    }
  }
}

// MARK: - Types
private extension MainView {
  
  enum Modal: Identifiable {
    case details(ApiTask.ID, teamId: Team.ID?)
    
    var id: Int {
      switch self {
      case .details(let id, _):
        return id.hashValue
      }
    }
  }
  
  enum Route {
    case taskDetails(taskId: ApiTask.ID, teamId: Team.ID?)
  }
}
