//
//  TasksService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation
import Cocoa

final class TasksService: ObservableObject {
  
  private let api: PokerAPI
  private(set) var tasks: [ApiTask] = []
  
  init(api: PokerAPI) {
    self.api = api
    
    reload()
  }
  
  func reloadTasks() async throws {
    self.tasks = try await api.myTasks()
    await MainActor.run {
      self.objectWillChange.send()
    }
  }
  
  private func reload() {
    Task {
      try await reloadTasks()
    }
  }
}

extension TasksService {
  
  func createTask(name: String, url: URL) async throws -> ApiTask {
    let task = try await api.createTask(name: name, url: url)
    reload()
    return task
  }
  
  func finish(taskId: ApiTask.ID) async throws {
    try await api.finish(taskId: taskId)
    reload()
  }
  
  func delete(taskId: ApiTask.ID) async throws {
    try await api.delete(taskId: taskId)
    reload()
  }
  
  func share(task: ApiTask) {
    let text = "[\(task.name)](scrumpoker://?taskId=\(task.id))"
    let pasteboard = NSPasteboard.general
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString(text, forType: .string)
  }
}
