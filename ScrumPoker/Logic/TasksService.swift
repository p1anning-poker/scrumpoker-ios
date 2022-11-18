//
//  TasksService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation
import Combine
import AppKit

final class TasksService: ObservableObject {
  // MARK: Properties
  private let api: PokerAPI
  private let appState: AppState
  private let notificationsService: NotificationsService
  private let deeplinkService: DeeplinkService
  
  private var reloadTasks: [FetchParams: Task<[ApiTask], Error>] = [:]
  
  private var cachedTasks: CurrentValueSubject<[FetchParams: [ApiTask]], Never> = CurrentValueSubject([:])

  // MARK: - Lifecycle
  
  init(api: PokerAPI, appState: AppState, notificationsService: NotificationsService, deeplinkService: DeeplinkService) {
    self.api = api
    self.appState = appState
    self.notificationsService = notificationsService
    self.deeplinkService = deeplinkService
    
    configure()
  }
  
  // MARK: - Getters
  
  // MARK: - Functions
  
  func subscribe(teamId: Team.ID, finished: Bool) -> AnyPublisher<[ApiTask], Never> {
    let fetchParams = FetchParams(teamId: teamId, filter: TasksFilter(completed: finished))
    return cachedTasks
      .compactMap { $0[fetchParams] }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }
  
  func subscribe(teamIds: Set<Team.ID>, finished: Bool) -> AnyPublisher<[Team.ID: [ApiTask]], Never> {
    return cachedTasks
      .map { tasks -> [Team.ID: [ApiTask]] in
        var result = [Team.ID: [ApiTask]]()
        tasks.forEach { element in
          if teamIds.contains(element.key.teamId) {
            result[element.key.teamId] = element.value
          }
        }
        return result
      }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }
  
  func cachedTasks(teamId: Team.ID, filter: TasksFilter) -> [ApiTask] {
    let fetchParams = FetchParams(teamId: teamId, filter: filter)
    return self.cachedTasks.value[fetchParams] ?? []
  }
  
  func reloadTasks(teamId: Team.ID, filter: TasksFilter) async throws -> [ApiTask] {
    let fetchParams = FetchParams(teamId: teamId, filter: filter)
    if let task = reloadTasks[fetchParams] {
      return try await task.value
    } else {
      let task = Task {
        try await api.tasks(teamId: teamId, finished: filter.completed)
      }
      self.reloadTasks[fetchParams] = task
      let result = try await task.value
      await update(newTasks: [fetchParams: result])
      reloadTasks[fetchParams] = nil
      return result
    }
  }
  
  func reloadNotFinishedTasks(teamIds: [Team.ID]) async throws {
    var tasks = [FetchParams: [ApiTask]]()
    for teamId in teamIds {
      _ = try? await reloadTasks(teamId: teamId, filter: TasksFilter(completed: false))
      tasks[FetchParams(teamId: teamId, filter: TasksFilter(completed: false))] = try? await api.tasks(teamId: teamId, finished: false)
    }
    await update(newTasks: tasks)
  }
  
  // MARK: - Private
  
  @MainActor
  private func update(newTasks: [FetchParams: [ApiTask]]) {
    cachedTasks.value.merge(newTasks, uniquingKeysWith: { l, r in
      return r
    })
  }
  
  private func reload(teamId: Team.ID, finished: Bool) {
    Task {
      try await reloadTasks(teamId: teamId, filter: TasksFilter(completed: finished))
    }
  }
  
  private func configure() {}
}

extension TasksService {
  
  func task(id: ApiTask.ID, teamId: Team.ID) async throws -> ApiTask {
    let task = try await api.task(id: id, teamId: teamId)
    return task
  }
  
  func createTask(name: String, url: URL, teamId: Team.ID) async throws -> ApiTask {
    let task = try await api.createTask(name: name, url: url, teamId: teamId)
    reload(teamId: teamId, finished: false)
    return task
  }
  
  func finish(taskId: ApiTask.ID, teamId: Team.ID) async throws {
    try await api.finish(taskId: taskId, teamId: teamId)
    reload(teamId: teamId, finished: false)
    reload(teamId: teamId, finished: true)
  }
  
  func delete(taskId: ApiTask.ID, teamId: Team.ID, isFinished: Bool) async throws {
    try await api.delete(taskId: taskId, teamId: teamId)
    reload(teamId: teamId, finished: isFinished)
  }
  
  func share(task: ApiTask, teamId: Team.ID) {
    let deeplink = deeplinkService.deeplink(from: .taskDetails(taskId: task.id, teamId: teamId))
    let text = "[\(task.name)](\(deeplink.absoluteString))"
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
    reload(teamId: teamId, finished: false)
  }
}

// MARK: - Types
private extension TasksService {
  struct FetchParams: Hashable {
    var teamId: Team.ID
    var filter: TasksFilter
  }
}
