//
//  TeamCreateView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 05.11.2022.
//

import SwiftUI

struct TeamCreateView: View {
  @EnvironmentObject private var teamsService: TeamsService
  
  @State private var name = ""
  @State private var error: String?
  let onFinish: (Team?) -> Void
  
  var body: some View {
    VStack {
      if let error = error {
        ErrorView(error: error)
      }
      TextField("Name", text: $name)
      HStack {
        Button("Cancel") {
          onFinish(nil)
        }
        Button("Create", action: create)
          .disabled(name.isEmpty)
      }
    }
    .padding()
  }
  
  private func create() {
    error = nil
    Task {
      do {
        let team = try await teamsService.createTeam(name: name)
        onFinish(team)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
}

struct TeamCreateView_Previews: PreviewProvider {
  static var previews: some View {
    TeamCreateView(onFinish: { _ in })
  }
}
