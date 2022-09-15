//
//  Task.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation

struct ApiTask: Decodable, Identifiable, Hashable {
  var taskUuid: String
  var name: String
  var url: URL?
  var finished: Bool
  var votesCount: Int
  var userName: String?
  
  var id: String {
    return taskUuid
  }
}
