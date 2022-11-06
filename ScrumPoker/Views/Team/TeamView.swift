//
//  TeamView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import SwiftUI

struct TeamView: View {
  @Binding
  var team: Team
  
  var body: some View {
    //    NavigationView {
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
      Text("")
    }
    //    }
  }
}

struct TeamView_Previews: PreviewProvider {
  static var previews: some View {
    let team = Team.sample(id: "1")
    NavigationView {
      TeamView(team: .constant(team))
      EmptyView()
    }
  }
}
