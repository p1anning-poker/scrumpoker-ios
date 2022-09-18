//
//  Task.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation

struct ApiTask: Codable, Identifiable, Hashable {
  var taskUuid: String
  var userUuid: String
  var name: String
  var url: URL?
  var finished: Bool
  var votesCount: Int
  var voteValue: Vote?
  
  var id: String {
    return taskUuid
  }
}
