//
//  InviteMemberView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import SwiftUI

struct InviteMemberView: View {
  @EnvironmentObject private var teamsService: TeamsService
  
  let team: Team
  @State private var email = ""
  @State private var error: String?
  let onFinish: (Bool) -> Void
  
  var body: some View {
    VStack {
      Text("Invite member")
      if let error = error {
        ErrorView(error: error)
      }
      TextField("email", text: $email)
        .textContentType(.username)
      HStack {
        Button("Cancel") {
          onFinish(false)
        }
        Button("Invite", action: invite)
          .disabled(email.isEmpty)
      }
    }
    .padding()
  }
  
  private func invite() {
    error = nil
    Task {
      do {
        try await teamsService.invite(member: email, teamId: team.id)
        onFinish(true)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
}

struct InviteMemberView_Previews: PreviewProvider {
  static var previews: some View {
    InviteMemberView(team: .sample(id: "1")) { _ in
      
    }
  }
}
