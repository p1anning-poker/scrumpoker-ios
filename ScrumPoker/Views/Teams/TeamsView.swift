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
            TeamView(team: .constant(team))
            Divider()
          }
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
  
  private func addTeam() {
    modal = .createNew
  }
  
  private func reload() {
    Task {
      do {
        try await teamsService.reloadTeams()
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
}

// MARK: - Types
extension TeamsView {
  
  enum Modal: Identifiable {
      case createNew
      
      var id: Int {
        switch self {
        case .createNew:
          return 0
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
