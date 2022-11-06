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
  // MARK: Properties
  private let api: PokerAPI
  private let appState: AppState
  
  @MainActor
  private(set) var tasks: [Team.ID: [ApiTask]] = [:] {
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
  
  // MARK: - Lifecycle
  
  init(api: PokerAPI, appState: AppState) {
    self.api = api
    self.appState = appState
    
    let data = UserDefaults.standard.data(forKey: Keys.recentlyViewed)
    recentlyViewedTasks = data.flatMap { try? JSONDecoder().decode([ApiTask].self, from: $0) } ?? []
  }
  
  // MARK: - Functions
  
  @MainActor
  func tasks(teamId: Team.ID, filter: TasksFilter) -> [ApiTask] {
    var tasks = self.tasks[teamId] ?? []
    if let completed = filter.completed {
      tasks = tasks.filter {
        $0.finished == completed
      }
    }
    return tasks
  }
  
  func reloadTasks(teamId: Team.ID) async throws {
    let tasks = try await api.tasks(teamId: teamId)
    await update(tasks: tasks, teamId: teamId)
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
  
  // MARK: - Private
  
  private func reload(teamId: Team.ID) {
    Task {
      try await reloadTasks(teamId: teamId)
    }
  }
  
  @MainActor
  private func update(tasks: [ApiTask], teamId: Team.ID) {
    self.tasks[teamId] = tasks
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
  
  func task(id: ApiTask.ID, teamId: Team.ID) async throws -> ApiTask {
    let task = try await api.task(id: id, teamId: teamId)
    return task
  }
  
  func createTask(name: String, url: URL, teamId: Team.ID) async throws -> ApiTask {
    let task = try await api.createTask(name: name, url: url, teamId: teamId)
    reload(teamId: teamId)
    return task
  }
  
  func finish(taskId: ApiTask.ID, teamId: Team.ID) async throws {
    try await api.finish(taskId: taskId, teamId: teamId)
    reload(teamId: teamId)
  }
  
  func delete(taskId: ApiTask.ID, teamId: Team.ID) async throws {
    try await api.delete(taskId: taskId, teamId: teamId)
    reload(teamId: teamId)
  }
  
  func share(task: ApiTask, teamId: Team.ID) {
    let text = "[\(task.name)](scrumpoker://?teamId=\(teamId)&taskId=\(task.id))"
    let pasteboard = NSPasteboard.general
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString(text, forType: .string)
  }
}

// MARK: - Votes
extension TasksService {
  
  func votes(taskId: ApiTask.ID, teamId: Team.ID) async throws -> [VoteInfo] {
    return try await api.votes(taskId: taskId, teamId: teamId)
  }
  
  func vote(taskId: ApiTask.ID, teamId: Team.ID, vote: Vote) async throws {
    try await api.vote(taskId: taskId, teamId: teamId, vote: vote)
    reload(teamId: teamId)
  }
}
