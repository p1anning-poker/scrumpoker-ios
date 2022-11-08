//
//  Task+Sample.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import Foundation

extension ApiTask {
  static func sample(id: String, finished: Bool = false, vote: Vote? = nil) -> ApiTask {
    ApiTask(
      taskUuid: id,
      taskOwner: .sample(),
      name: "Task \(id)",
      finished: finished,
      voteValue: vote
    )
  }
}
