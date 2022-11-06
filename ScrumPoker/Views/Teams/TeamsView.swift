//
//  TeamsView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 05.11.2022.
//

import SwiftUI

struct TeamsView: View {
  // MARK: - Properties
  @EnvironmentObject private var teamsService: TeamsService
  @State private var modal: Modal?
  @State private var error: String?
  @Binding var selectedTeam: Team?
  
  var body: some View {
    VStack {
      if let error = error {
        ErrorView(error: error)
      } else if teamsService.teams.isEmpty {
        Text("You have no teams")
          .padding()
      } else {
        List(teamsService.teams) { team in
          VStack {
            teamView(team)
          }
        }
        .listStyle(.sidebar)
      }
      Spacer()
      bottomBar()
    }
    .sheet(item: $modal) { modal in
      switch modal {
      case .createNew:
        TeamCreateView { _ in
          self.modal = nil
        }
          .frame(minWidth: 300, maxWidth: 400)
      }
    }
    .onAppear {
      reload()
    }
  }
  
  @ViewBuilder
  private func bottomBar() -> some View {
    HStack {
      Button(action: addTeam) {
        Image(systemName: "plus.circle.fill")
      }
      .buttonStyle(.plain)
      Spacer()
    }
    .padding()
    .frame(height: 30)
  }
  
  @ViewBuilder
  private func teamView(_ team: Team) -> some View {
    let binding = Binding<Bool> {
      selectedTeam?.id == team.id
    } set: { active in
      if active {
        selectedTeam = team
      }
    }

    VStack {
      NavigationLink(isActive: binding) {
        TeamView(team: .constant(team))
      } label: {
        TeamListView(team: .constant(team))
      }
      .contextMenu {
        Button("Delete") { delete(team: team) }
      }
      Divider()
    }
  }
  
  private func addTeam() {
    modal = .createNew
  }
  
  private func reload() {
    Task {
      do {
        try await teamsService.reloadTeams()
        if selectedTeam == nil {
          selectedTeam = teamsService.teams.first
        }
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func delete(team: Team) {
    
  }
}

// MARK: - Types
extension TeamsView {
  
  private enum Modal: Identifiable {
    case createNew
    
    var id: Int {
      switch self {
      case .createNew:
        return 0
      }
    }
  }
  
  private enum ContentType: Equatable {
    case empty
    case tasks(Team)
    
    static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.empty, .empty):
        return true
      case (.tasks(let l), .tasks(let r)):
        return l.id == r.id
      default:
        return false
      }
    }
  }
}

//struct TeamsView_Previews: PreviewProvider {
//  static var previews: some View {
//    let teams = (0..<1).map { id in
//      return Team.sample(id: String(id))
//    }
//
//    return TeamsView(teams: teams)
//  }
//}
