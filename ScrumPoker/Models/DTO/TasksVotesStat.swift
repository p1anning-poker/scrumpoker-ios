//
//  TasksVotesStat.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 27.11.2022.
//

import Foundation

//{
//  "totalTasksCount": 0,
//  "userVotesStat": [
//    {
//      "user": {
//        "userUuid": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
//        "name": "string"
//      },
//      "votedTasksCount": 0
//    }
//  ]
//}
struct TasksVotesStat: Equatable, Codable {
  var totalTasksCount: Int
  var userVotesStat: [UserVotesStat]
}

extension TasksVotesStat {
  struct UserVotesStat: Equatable, Codable {
    var user: PublicUser
    var votedTasksCount: Int
  }
}
