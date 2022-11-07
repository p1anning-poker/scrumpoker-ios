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
  
  @Binding var selectedTeam: Team?
  @Binding var taskToOpen: ApiTask?
  
  @State private var modal: Modal?
  @State private var alert: Alert?
  @State private var error: String?
  
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
        .refreshable {
          reload()
        }
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
    .alert(item: $alert) { alert in
      switch alert {
      case .error(let text):
        return SwiftUI.Alert(title: Text("Failed to delete team"),
                             message: Text(text),
                             dismissButton: SwiftUI.Alert.Button.cancel())
      case .askToDelete(let team, let accept):
        return SwiftUI.Alert(
          title: Text("Delete \(team.teamName)?"),
          primaryButton: .destructive(Text("Delete"),
                                      action: accept),
          secondaryButton: .cancel()
        )
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
        TeamView(team: team, taskToOpen: $taskToOpen)
      } label: {
        TeamListView(team: .constant(team))
      }
      .contextMenu {
        Button("Delete") {
          alert = .askToDelete(team: team) {
            delete(team: team)
          }
        }
      }
    }
    .listDivider(yOffset: 6)
  }
  
  private func addTeam() {
    modal = .createNew
  }
  
  private func reload() {
    Task {
      do {
        try await teamsService.reloadTeams()
        if selectedTeam == nil {
          selectedTeam = teamsService.latestOpenedTeamId.flatMap { id in
            teamsService.teams.first(where: { $0.id == id })
          } ?? teamsService.teams.first
        }
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func delete(team: Team) {
    Task {
      do {
        try await teamsService.deleteTeam(id: team.id)
      } catch {
        alert = .error(error.localizedDescription)
      }
    }
  }
}

// MARK: - Types
extension TeamsView {
  
  private enum Alert: Identifiable {
    case error(String)
    case askToDelete(team: Team, accept: () -> Void)
    
    var id: Int {
      switch self {
      case .error:
        return 0
      case .askToDelete:
        return 1
      }
    }
  }
  
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
