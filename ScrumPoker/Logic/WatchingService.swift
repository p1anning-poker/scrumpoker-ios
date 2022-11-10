//
//  WatchingService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 10.11.2022.
//

import Foundation
import Combine

final class WatchingService {
  
  // MARK: - Properties
  
  private let tasksService: TasksService
  private let teamsService: TeamsService
  private let notificationsService: NotificationsService
  private let appState: AppState
  
  private var cancellables: Set<AnyCancellable> = []
  private var ignoredTeams: Set<Team.ID> = []
  
  // MARK: - Lifecycle
  
  init(tasksService: TasksService, teamsService: TeamsService, notificationsService: NotificationsService, appState: AppState) {
    self.tasksService = tasksService
    self.teamsService = teamsService
    self.notificationsService = notificationsService
    self.appState = appState
    
    configure()
  }
  
  // MARK: - Functions
  
  private func configure() {
//    let teams = teamsService.teams
//      .filter { !ignoredTeams.contains($0.id) }
//    Task {
//      try? await tasksService.reloadTasks(teamIds: teams.map { $0.id })
//      let tasks = tasksService.tasks
//      await startWatching(teams: teams, tasks: tasks)
//    }
  }
  
  @MainActor
  private func startWatching(teams: [Team], tasks: [Team.ID: [ApiTask]]) {
    var teams = teams
    var previousUpdateTeams = teams
    teamsService.objectWillChange
      .sink { [teamsService] _ in
        previousUpdateTeams = teams
        teams = teamsService.teams
          .filter { !self.ignoredTeams.contains($0.id) }
      }
      .store(in: &cancellables)
    
//    Timer
//      .publish(every: 5, on: .main, in: .common)
//      .sink { [tasksService] _ in
//        let teams = teams
//        Task {
//          print("RELOAD FROM WATHCER")
//          try? await tasksService.reloadTasks(teamIds: teams.map { $0.id })
//        }
//      }
//      .store(in: &cancellables)
    
    var tasks = tasks
    tasksService.objectWillChange
      .sink { [tasksService] _ in
        let newTasks = tasksService.tasks
        self.handleUpdate(
          tasks: newTasks,
          previous: tasks,
          teams: previousUpdateTeams
        )
        tasks = newTasks
      }
      .store(in: &cancellables)
  }
  
  private func handleUpdate(tasks: [Team.ID: [ApiTask]],
                            previous: [Team.ID: [ApiTask]],
                            teams: [Team]) {
    guard let userId = appState.currentUser?.userUuid else { return }
    
    let tasks = tasksService.tasks
    let observedTeamIds = Set(teams.map({ $0.id }))
      .filter { !ignoredTeams.contains($0) }
    let notVotedTasks = self.notVotedTasks(from: tasks, userId: userId, teamIds: observedTeamIds)
    appState.set(numberOfTasks: notVotedTasks.count)
    
    let previousNotVotedTasks = self.notVotedTasks(from: previous, userId: userId, teamIds: observedTeamIds)
    notifyIfNeeded(newNotVotedTasks: notVotedTasks, previousNotVotedTasks: previousNotVotedTasks, tasksMap: tasks)
  }
  
  private func notVotedTasks(from tasksMap: [Team.ID: [ApiTask]], userId: User.ID, teamIds: Set<Team.ID>) -> [ApiTask] {
    return tasksMap
      .filter { teamIds.contains($0.key) }
      .flatMap { pair in
        pair.value.filter { task in
          // not finished and not voted
          task.finished == false && task.taskOwner.userUuid != userId && task.votedUsers?.contains(where: { $0.userUuid == userId }) == false
        }
      }
  }
  
  private func notifyIfNeeded(
    newNotVotedTasks: [ApiTask],
    previousNotVotedTasks: [ApiTask],
    tasksMap: [Team.ID: [ApiTask]]
  ) {
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
