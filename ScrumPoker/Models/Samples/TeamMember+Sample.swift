//
//  TeamMember+Sample.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import Foundation

extension TeamMember {
  static func sample(id: String = "1", membershipStatus: Team.MembershipStatus = .owner) -> TeamMember {
    TeamMember(
      teamUuid: "Test id",
      teamName: "Test team",
      user: .sample(id: id),
      membershipStatus: membershipStatus
    )
  }
}
