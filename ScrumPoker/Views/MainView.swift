//
//  MainView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 24.11.2022.
//

import SwiftUI

struct MainView: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var profileService: ProfileService
  @EnvironmentObject private var teamsService: TeamsService
  @EnvironmentObject private var tasksService: TasksService
  @EnvironmentObject private var deeplinkService: DeeplinkService
  
  @State private var modal: Modal?
  @State private var selectedTeam: Team?
  @State private var taskToOpen: ApiTask?
  
  var body: some View {
    if let user = appState.currentUser {
      contentView(user: user)
        .frame(minWidth: 1000, minHeight: 500)
        .onOpenURL { url in
          guard let route = Dependencies.shared.deeplinkService.appRoute(from: url) else { return }
          handleAppRoute(route)
        }
        .onReceive(Dependencies.shared.notificationsService.notifications) { response in
          guard let route = response.notification.request.content.userInfo["route"] as? String,
             let appRoute = deeplinkService.appRoute(from: route) else {
            return
          }
          handleAppRoute(appRoute)
        }
    } else {
      AuthorizationView(content: appState.lastLogin == nil ? .registration : .authorization) {
        
      }
      .frame(width: 350, alignment: .center)
      .onOpenURL { url in
        guard let route = deeplinkService.appRoute(from: url) else { return }
        handleAppRoute(route)
      }
      .onReceive(Dependencies.shared.notificationsService.notifications) { response in
        guard let route = response.notification.request.content.userInfo["route"] as? String,
           let appRoute = deeplinkService.appRoute(from: route) else {
          return
        }
        handleAppRoute(appRoute)
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
  }
  
  @ViewBuilder
  private func taskDetails(id: ApiTask.ID, teamId: Team.ID) -> some View {
    TaskView(taskId: id, teamId: teamId)
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
  
  private func handleAppRoute(_ appRoute: AppRoute) {
    modal = nil
    switch appRoute {
    case .taskDetails(let taskId, let teamId):
      if let team = teamsService.teams.first(where: { $0.id == teamId }) {
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
}
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
