//
//  VotesInfo.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation

struct VoteInfo: Decodable {
  var value: Vote
  var userNames: [String]
}
