//
//  TasksService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation
import Cocoa

private enum Keys {
  static let recentlyViewed = "RECENTLY_VIEWED"
}

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
  private(set) var recentlyViewedTasks: [ApiTask] = [] {
    didSet {
      guard recentlyViewedTasks != oldValue else { return }
      objectWillChange.send()
    }
  }
  
  init(api: PokerAPI, appState: AppState) {
    self.api = api
    self.appState = appState
    
    reload()
    let data = UserDefaults.standard.data(forKey: Keys.recentlyViewed)
    recentlyViewedTasks = data.flatMap { try? JSONDecoder().decode([ApiTask].self, from: $0) } ?? []
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
  
  @MainActor
  func add(recentlyViewed task: ApiTask) {
    guard recentlyViewedTasks.first != task else { return }
    var tasks = self.recentlyViewedTasks.filter { $0.id != task.id }
    tasks.insert(task, at: 0)
    if tasks.count > 5 {
      tasks = Array(tasks.prefix(5))
    }
    update(recentlyViewed: tasks, store: true)
  }
  
  private func update(recentlyViewed: [ApiTask], store: Bool) {
    self.recentlyViewedTasks = recentlyViewed
    if store {
      let data = try? JSONEncoder().encode(recentlyViewed)
      UserDefaults.standard.set(data, forKey: Keys.recentlyViewed)
    }
  }
}

extension TasksService {
  
  func task(id: ApiTask.ID) async throws -> ApiTask {
    let task = try await api.task(id: id)
    var tasks = await self.tasks
    if task.userUuid == appState.currentUser?.userUuid,
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
