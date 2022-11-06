//
//  Team.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 05.11.2022.
//

import Foundation

struct Team: Codable, Identifiable, Equatable {
  var teamUuid: String
  var teamName: String
  var user: PublicUser
  var membershipStatus: MembershipStatus
  
  var id: String {
    return teamUuid
  }
}

extension Team {
  enum MembershipStatus: String, Codable {
    case owner = "OWNER"
    case member = "MEMBER"
    case invited = "INVITED"
  }
}
