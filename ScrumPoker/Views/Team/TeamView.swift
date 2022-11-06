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
  @State private var error: String?
  
  var body: some View {
    switch team.membershipStatus {
    case .member, .owner:
      TabView {
        NavigationView {
          TasksView(team: team, filter: TasksFilter(completed: false))
        }
        .tabItem {
          Label("Tasks", systemImage: "checklist.unchecked")
        }
        NavigationView {
          TasksView(team: team, filter: TasksFilter(completed: true))
        }
        .tabItem {
          Label("Completed", systemImage: "checklist.checked")
        }
        TeamMembersView(team: team)
          .tabItem {
            Label("Members", systemImage: "person.3.sequence")
          }
      }
      .padding()
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
}

struct TeamView_Previews: PreviewProvider {
  static var previews: some View {
    let team = Team.sample(id: "1", membership: .invited)
    NavigationView {
      TeamView(team: team)
      EmptyView()
    }
  }
}
