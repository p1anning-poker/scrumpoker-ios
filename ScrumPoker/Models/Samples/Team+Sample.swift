//
//  Team+Sample.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 05.11.2022.
//

import Foundation

extension Team {
  
  static func sample(id: String, membership: Team.MembershipStatus = .owner) -> Team {
    Team(
      teamUuid: String(id),
      teamName: "Team #\(id)",
      userUuid: PublicUser(userUuid: "id", name: "Test user"),
      membershipStatus: membership
    )
  }
}
