//
//  TasksService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation
import Combine

final class TestTasksService: TasksService {
  
  private var testTasks: CurrentValueSubject<[ApiTask], Never> = CurrentValueSubject((0..<5).map { id in
    ApiTask.sample(
      id: "id",
      vote: Bool.random() ? Vote.one : nil
    )
  })
  
  override func subscribe(teamId: Team.ID, finished: Bool) -> AnyPublisher<[ApiTask], Never> {
    return testTasks.eraseToAnyPublisher()
  }
  
  override func reloadTasks(teamId: Team.ID, filter: TasksFilter) async throws -> [ApiTask] {
    return testTasks.value
  }
  
  override func delete(taskId: ApiTask.ID, teamId: Team.ID, isFinished: Bool) async throws {
    testTasks.value.removeAll(where: { $0.id == taskId })
  }
  
  override func task(id: ApiTask.ID, teamId: Team.ID) async throws -> ApiTask {
    return ApiTask.sample(id: id, finished: id == .finishedTaskId)
  }
  
  override func votes(taskId: ApiTask.ID, teamId: Team.ID) async throws -> [VoteInfo] {
    return (0..<4).map { id in
      return VoteInfo.sample(vote: Vote("\(id)"), count: id + 1)
    }
  }
  
  override func tasksVotesStat(teamId: Team.ID) async throws -> TasksVotesStat {
    return TasksVotesStat(
      totalTasksCount: 10,
      userVotesStat: (0..<5).map { id in
        return .init(
          user: PublicUser(userUuid: "\(id)", name: "User #\(id)"),
          votedTasksCount: .random(in: 0..<10)
        )
      }
    )
  }
}

private actor ReloadTasksStorage {
  typealias ReloadTask = Task<[ApiTask], Error>
  
  var tasks: [TasksService.FetchParams: ReloadTask] = [:]
  
  func add(task: ReloadTask, params: TasksService.FetchParams) {
    tasks[params] = task
  }
  
  func removeTask(params: TasksService.FetchParams) {
    tasks[params] = nil
  }
}

class TasksService: ObservableObject {
  // MARK: Properties
  private let api: PokerAPI
  private let appState: AppState
  private let notificationsService: NotificationsService
  private let deeplinkService: DeeplinkService
  
  private let reloadTasks = ReloadTasksStorage()
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
  
  func subscribe(taskId: ApiTask.ID, teamId: Team.ID) -> AnyPublisher<ApiTask, Never> {
    let finished = FetchParams(teamId: teamId, filter: TasksFilter(completed: true))
    let notFinished = FetchParams(teamId: teamId, filter: TasksFilter(completed: false))
    return cachedTasks
      .compactMap { tasks in
        tasks[notFinished]?.first(where: { $0.id == taskId }) ?? tasks[finished]?.first(where: { $0.id == taskId })
      }
      .removeDuplicates()
      .dropFirst()
      .eraseToAnyPublisher()
  }
  
  func subscribe(teamIds: Set<Team.ID>, finished: Bool) -> AnyPublisher<[Team.ID: [ApiTask]], Never> {
    return cachedTasks
      .map { tasks -> [Team.ID: [ApiTask]] in
        var result = [Team.ID: [ApiTask]]()
        tasks.forEach { element in
          if element.key.filter.completed == finished, teamIds.contains(element.key.teamId) {
            result[element.key.teamId] = element.value
          }
        }
        return result
      }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }
  
  func cachedTasks(teamId: Team.ID, finished: Bool) -> [ApiTask] {
    let fetchParams = FetchParams(teamId: teamId, filter: .init(completed: finished))
    return self.cachedTasks.value[fetchParams] ?? []
  }
  
  func reloadTasks(teamId: Team.ID, filter: TasksFilter) async throws -> [ApiTask] {
    let fetchParams = FetchParams(teamId: teamId, filter: filter)
    if let task = await reloadTasks.tasks[fetchParams] {
      return try await task.value
    } else {
      let task = Task {
        try await api.tasks(teamId: teamId, finished: filter.completed, search: filter.searchText.isEmpty ? nil : filter.searchText)
      }
      await self.reloadTasks.add(task: task, params: fetchParams)
      let result = try await task.value
      if filter.searchText.isEmpty {
        // Reload cache only for non search requests
        await update(newTasks: [fetchParams: result])
      }
      await reloadTasks.removeTask(params: fetchParams)
      return result
    }
  }
  
  func reloadNotFinishedTasks(teamIds: [Team.ID]) async throws {
    var tasks = [FetchParams: [ApiTask]]()
    for teamId in teamIds {
      _ = try? await reloadTasks(teamId: teamId, filter: TasksFilter(completed: false))
      tasks[FetchParams(teamId: teamId, filter: TasksFilter(completed: false))] = try? await api.tasks(teamId: teamId, finished: false, search: nil)
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
  
  // MARK: - Tasks
  
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
  
  func restart(taskId: ApiTask.ID, teamId: Team.ID) async throws {
    try await api.activate(taskId: taskId, teamId: teamId)
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
    let pasteboard = NSUIPasteboard.general
    pasteboard.setString(text)
  }
  
  // MARK: - Votes
  
  func votes(taskId: ApiTask.ID, teamId: Team.ID) async throws -> [VoteInfo] {
    return try await api.votes(taskId: taskId, teamId: teamId)
  }
  
  func vote(taskId: ApiTask.ID, teamId: Team.ID, vote: Vote) async throws {
    try await api.vote(taskId: taskId, teamId: teamId, vote: vote)
    reload(teamId: teamId, finished: false)
  }
  
  func tasksVotesStat(teamId: Team.ID) async throws -> TasksVotesStat {
    return try await api.votesStat(teamId: teamId)
  }
}

// MARK: - Types
private extension TasksService {
  struct FetchParams: Hashable {
    var teamId: Team.ID
    var filter: TasksFilter
  }
}

struct TasksServiceKey: InjectionKey {
    static var currentValue: TasksService = TasksService(
      api: InjectedValues[\.pokerApi],
      appState: InjectedValues[\.appState],
      notificationsService: InjectedValues[\.notificationsService],
      deeplinkService: InjectedValues[\.deeplinkService]
    )
}

extension InjectedValues {
  var tasksService: TasksService {
    get { Self[TasksServiceKey.self] }
    set { Self[TasksServiceKey.self] = newValue }
  }
}
