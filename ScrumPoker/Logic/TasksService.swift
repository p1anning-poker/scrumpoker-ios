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
  private let appState: AppState
  @MainActor
  private(set) var tasks: [ApiTask] = [] {
    didSet {
      guard tasks != oldValue else { return }
      objectWillChange.send()
    }
  }
  
  init(api: PokerAPI, appState: AppState) {
    self.api = api
    self.appState = appState
    
    reload()
  }
  
  func reloadTasks() async throws {
    let tasks = try await api.myTasks()
    await updates(tasks: tasks)
  }
  
  private func reload() {
    Task {
      try await reloadTasks()
    }
  }
  
  @MainActor
  private func updates(tasks: [ApiTask]) {
    self.tasks = tasks
  }
}

extension TasksService {
  
  func task(id: ApiTask.ID) async throws -> ApiTask {
    let task = try await api.task(id: id)
    var tasks = await self.tasks
    if task.userName == appState.currentUser?.name,
        let index = tasks.firstIndex(where: { $0.id == id }) {
      tasks[index] = task
      await updates(tasks: tasks)
    }
    return task
  }
  
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

// MARK: - Votes
extension TasksService {
  
  func votes(id: ApiTask.ID) async throws -> [VoteInfo] {
    return try await api.votes(id: id)
  }
  
  func vote(id: ApiTask.ID, vote: Vote) async throws {
    try await api.vote(id: id, vote: vote)
    reload()
  }
}
