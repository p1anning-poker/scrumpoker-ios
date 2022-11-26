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
      url: URL(string: "https://sample.url.com/task/123")!,
      finished: finished,
      voteValue: vote
    )
  }
}

extension String {
  static let finishedTaskId: ApiTask.ID = "finished"
}
