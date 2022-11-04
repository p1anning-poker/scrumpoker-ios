//
//  TeamView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 05.11.2022.
//

import SwiftUI

struct TeamView: View {
  @Binding
  var team: Team
  
  var body: some View {
    HStack {
      Text(team.teamName)
      Spacer()
      switch team.membershipStatus {
      case .owner:
        Image(systemName: "crown.fill")
      case .member:
        EmptyView()
      case .invited:
        Text("INVITED")
      }
    }
  }
}

struct TeamView_Previews: PreviewProvider {
  static var previews: some View {
    TeamView(team: .constant(.sample(id: "1", membership: .member)))
  }
}
