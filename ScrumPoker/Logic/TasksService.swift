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
  private let notificationsService: NotificationsService
  private let deeplinkService: DeeplinkService
  
  private var reloadTasks: [Team.ID: Task<[ApiTask], Error>] = [:]
  
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
  
  init(api: PokerAPI, appState: AppState, notificationsService: NotificationsService, deeplinkService: DeeplinkService) {
    self.api = api
    self.appState = appState
    self.notificationsService = notificationsService
    self.deeplinkService = deeplinkService
    
    let data = UserDefaults.standard.data(forKey: Keys.recentlyViewed)
    recentlyViewedTasks = data.flatMap { try? JSONDecoder().decode([ApiTask].self, from: $0) } ?? []
    configure()
  }
  
  // MARK: - Getters
  
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
    if let task = reloadTasks[teamId] {
      _ = try await task.value
    } else {
      let task = Task {
        try await api.tasks(teamId: teamId)
      }
      self.reloadTasks[teamId] = task
      let result = try await task.value
      await update(newTasks: [teamId: result])
      reloadTasks[teamId] = nil
    }
  }
  
  func reloadTasks(teamIds: [Team.ID]) async throws {
    var tasks = [Team.ID: [ApiTask]]()
    for teamId in teamIds {
      tasks[teamId] = try? await api.tasks(teamId: teamId)
    }
    await update(newTasks: tasks)
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
  
  @MainActor
  private func update(newTasks: [Team.ID: [ApiTask]]) {
    tasks.merge(newTasks, uniquingKeysWith: { l, r in
      return r
    })
  }
  
  private func reload(teamId: Team.ID) {
    Task {
      try await reloadTasks(teamId: teamId)
    }
  }
  
  private func configure() {}

  private func update(recentlyViewed: [ApiTask], store: Bool) {
    self.recentlyViewedTasks = recentlyViewed
    if store {
      let data = try? JSONEncoder().encode(recentlyViewed)
      UserDefaults.standard.set(data, forKey: Keys.recentlyViewed)
    }
  }
  
  private func notVotedTasks(from tasksMap: [Team.ID: [ApiTask]], userId: User.ID, teamIds: Set<Team.ID>) -> [ApiTask] {
    return tasksMap
      .filter { teamIds.contains($0.key) }
      .flatMap { pair in
        pair.value.filter { task in
          // not finished and not voted
          task.finished == false && task.votedUsers?.contains(where: { $0.userUuid == userId }) == false
        }
      }
  }
  
  private func notifyIfNeeded(newNotVotedTasks: [ApiTask], previousNotVotedTasks: [ApiTask], tasksMap: [Team.ID: [ApiTask]]) {
    let oldIds = Set(previousNotVotedTasks.map { $0.id })
    let newTasks = newNotVotedTasks
      .filter { !oldIds.contains($0.id) }
    guard !newTasks.isEmpty else { return }
    
    let taskForRoute = newTasks[0]
    var body = taskForRoute.name
    if newTasks.count > 1 {
      body += " and \(newTasks.count - 1) more..."
    }
    let teamId = tasksMap.filter { $0.value.contains(where: { $0.id == taskForRoute.id }) }.first?.key
    
    let notification = NotificationItem(
      id: .newTasks,
      title: "New \(newTasks.count == 1 ? "task" : "tasks") to vote",
      body: body,
      appRoute: teamId.map { .taskDetails(taskId: taskForRoute.id, teamId: $0) }
    )
    Task {
      try await notificationsService.schedule(notification: notification)
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
    let deeplink = deeplinkService.deeplink(from: .taskDetails(taskId: task.id, teamId: teamId))
    let text = "[\(task.name)](\(deeplink.absoluteString)"
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
