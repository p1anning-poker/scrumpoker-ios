//
//  TeamMember.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import Foundation

struct TeamMember: Codable, Identifiable, Equatable {
  var teamUuid: String
  var teamName: String
  var user: PublicUser
  var membershipStatus: Team.MembershipStatus
  
  var id: String {
    return user.userUuid
  }
}
