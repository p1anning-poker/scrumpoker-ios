//
//  TeamMembersView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import SwiftUI

struct TeamMembersView: View {
  @EnvironmentObject private var teamsService: TeamsService
  
  let team: Team
  @State var members: [TeamMember] = []
  @State private var error: String?
  
  @State private var modal: Modal?
  
  var body: some View {
    VStack {
      if let error = error {
        ErrorView(error: error)
      } else if members.isEmpty {
        Text("No members")
      } else {
        List(members) { member in
          memberView(member)
        }
      }
      Spacer()
      if team.membershipStatus == .owner {
        Button {
          modal = .addMember
        } label: {
          Text("Invite")
        }
      }
    }
    .onAppear {
      reload()
    }
    .sheet(item: $modal) { modal in
      switch modal {
      case .addMember:
        InviteMemberView(team: team) { sent in
          self.modal = nil
          if sent {
            reload()
          }
        }
        .frame(minWidth: 300, maxWidth: 400)
      }
    }
  }
  
  private func reload() {
    error = nil
    Task {
      do {
        members = try await teamsService.members(teamId: team.id)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  @ViewBuilder
  private func memberView(_ member: TeamMember) -> some View {
    HStack {
      Text(member.user.name)
      Spacer()
      statusView(member.membershipStatus)
    }
  }
  
  @ViewBuilder
  private func statusView(_ status: Team.MembershipStatus) -> some View {
    let name: String = {
      switch status {
      case .owner:
        return "crown.fill"
      case .member:
        return "person.fill"
      case .invited:
        return "person.fill.questionmark"
      }
    }()
    Image(systemName: name)
      .frame(width: 20, alignment: .center)
  }
}

// MARK: - Types
extension TeamMembersView {
  private enum Modal: Identifiable {
    case addMember
    
    var id: Int {
      switch self {
      case .addMember:
        return 0
      }
    }
  }
}

struct TeamMembersView_Previews: PreviewProvider {
  static var previews: some View {
    let members = (0..<4).map { id -> TeamMember in
      let status: Team.MembershipStatus
      switch id {
      case 0:
        status = .owner
      case 3:
        status = .invited
      default:
        status = .member
      }
      return TeamMember.sample(id: String(id), membershipStatus: status)
    }
    TeamMembersView(team: .sample(id: "1"), members: members)
      .environmentObject(TeamsService(api: .init(networkService: .init(),
                                                 appState: .shared)))
  }
}
