//
//  TeamView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import SwiftUI

struct TeamView: View {
  @EnvironmentObject private var teamsService: TeamsService
  
  @State var team: Team
  @Binding var taskToOpen: ApiTask?
  
  private let tabs = [Tab.tasks, .completed, .members]
  @State private var tab = Tab.tasks
  @State private var error: String?
  
  var body: some View {
    content(membershipStatus: team.membershipStatus)
      .padding()
      .onAppear {
        teamsService.setLatestOpenedTeamId(team.id)
        updateSelectedTabToShowTaskIfNeeded()
      }
  }
  
  @ViewBuilder
  private func content(membershipStatus: Team.MembershipStatus) -> some View {
    switch membershipStatus {
    case .member, .owner:
      TabView(selection: $tab) {
        NavigationView {
          TasksView(team: team,
                    finished: false,
                    allowedToCreate: true,
                    taskToOpen: $taskToOpen)
          .frame(minWidth: 300)
        }
        .tabItem {
          Text("Tasks")
        }
        .tag(Tab.tasks)
        NavigationView {
          TasksView(team: team,
                    finished: true,
                    allowedToCreate: false,
                    taskToOpen: $taskToOpen)
          .frame(minWidth: 300)
        }
        .tabItem {
          Text("Completed")
        }
        .tag(Tab.completed)
        TeamMembersView(team: team)
          .tabItem {
            Text("Members")
          }
          .tag(Tab.members)
        if #available(macOS 13.0, *), team.membershipStatus == .owner {
          TaskVotesStatView(teamId: team.id)
            .tabItem {
              Text("Statistics")
            }
            .tag(Tab.statistics)
        }
      }
      .onChange(of: taskToOpen) { newValue in
        updateSelectedTabToShowTaskIfNeeded()
      }
    case .invited:
      VStack {
        if let error = error {
          ErrorView(error: error)
        }
        Button(action: acceptInvite) {
          Label("Accept", systemImage: "checkmark")
        }
      }
    }
  }
  
  private func acceptInvite() {
    error = nil
    Task {
      do {
        self.team = try await teamsService.acceptInvite(team: team)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func updateSelectedTabToShowTaskIfNeeded() {
    if let task = taskToOpen {
      tab = task.finished ? .completed : .tasks
    }
  }
}

// MARK: - Types
private extension TeamView {
  
  enum Tab {
    case tasks, completed, members, statistics
  }
}

struct TeamView_Previews: PreviewProvider {
  static var previews: some View {
    let team = Team.sample(id: "1", membership: .invited)
    NavigationView {
      TeamView(team: team, taskToOpen: .constant(nil))
      EmptyView()
    }
  }
}
