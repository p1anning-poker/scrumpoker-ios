//
//  Task.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation

struct ApiTask: Codable, Identifiable, Hashable {
  var taskUuid: String
  var taskOwner: PublicUser
  var name: String
  var url: URL?
  var finished: Bool
  var voteValue: Vote?
  var votedUsers: [PublicUser]?
  
  var id: String {
    return taskUuid
  }
}
