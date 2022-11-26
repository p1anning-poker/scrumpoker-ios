//
//  VoteInfo+Sample.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 26.11.2022.
//

import Foundation

extension VoteInfo {
  
  static func sample(vote: Vote, count: Int = 3) -> VoteInfo {
    return VoteInfo(
      value: vote,
      votedUsers: (0..<count).map { id in
        return .sample(id: "User_\(id)")
      }
    )
  }
}
