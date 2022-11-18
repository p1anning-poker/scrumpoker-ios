//
//  WatchingService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 10.11.2022.
//

import Foundation
import Combine

final class WatchingService: ObservableObject {
  
  private enum Keys {
    static let ignoredTeamIds = "ignored_team_ids"
  }
  
  // MARK: - Properties
  
  private let tasksService: TasksService
  private let teamsService: TeamsService
  private let notificationsService: NotificationsService
  private let appState: AppState
  
  private var cancellables: Set<AnyCancellable> = []
  private var ignoredTeams: CurrentValueSubject<Set<Team.ID>, Never>
  private var subscriptionCancellable: AnyCancellable?
  
  // MARK: - Lifecycle
  
  init(tasksService: TasksService, teamsService: TeamsService, notificationsService: NotificationsService, appState: AppState) {
    self.tasksService = tasksService
    self.teamsService = teamsService
    self.notificationsService = notificationsService
    self.appState = appState
    
    let ignoredTeams = UserDefaults.standard.array(forKey: Keys.ignoredTeamIds) as? [Team.ID] ?? []
    self.ignoredTeams = CurrentValueSubject(Set(ignoredTeams))
    
    configure()
  }
  
  // MARK: - Functions
  
  private func configure() {
    let teamIds = Publishers.CombineLatest(ignoredTeams, teamsService.objectWillChange.map { [teamsService] in teamsService.teams })
      .map { ignoredTeams, teams in
        return teams
          .map { $0.id }
          .filter { !ignoredTeams.contains($0) }
      }
      .removeDuplicates()
      .share()
    let timer = Timer
      .publish(every: 30, on: .main, in: .common)
      .autoconnect()
    
    Publishers.CombineLatest(timer, teamIds)
      .sink { [tasksService] _, teamIds in
        Task {
          do {
            try await tasksService.reloadNotFinishedTasks(teamIds: teamIds)
          } catch {
            print("Failed to poll tasks: \(error)")
          }
        }
      }
      .store(in: &cancellables)
    
    teamIds
      .flatMapLatest { [tasksService] teamIds in
        tasksService.subscribe(teamIds: Set(teamIds), finished: false)
      }
      .scan(nil as [Team.ID: [ApiTask]]?) { [weak self] (previous, tasks) in
        self?.handleUpdate(tasks: tasks, previous: previous ?? tasks)
        return tasks
      }
      .sink(receiveValue: { _ in })
      .store(in: &cancellables)
  }
  
  private func updateNotVoted(tasks: [Team.ID: [ApiTask]]) {
    guard let userId = appState.currentUser?.userUuid else { return }
    let notVotedTasks = self.notVotedTasks(from: tasks, userId: userId, userIsNotOwner: false)
    appState.set(numberOfTasks: notVotedTasks.count)
  }
  
  private func handleUpdate(tasks: [Team.ID: [ApiTask]],
                            previous: [Team.ID: [ApiTask]]) {
    guard let userId = appState.currentUser?.userUuid else { return }
    
    let notVotedTasks = self.notVotedTasks(from: tasks, userId: userId, userIsNotOwner: true)
    let previousNotVotedTasks = self.notVotedTasks(from: previous, userId: userId, userIsNotOwner: true)
    notifyIfNeeded(newNotVotedTasks: notVotedTasks, previousNotVotedTasks: previousNotVotedTasks, tasksMap: tasks)
    
    updateNotVoted(tasks: tasks)
  }
  
  private func notVotedTasks(from tasksMap: [Team.ID: [ApiTask]],
                             userId: User.ID,
                             userIsNotOwner: Bool) -> [ApiTask] {
    return tasksMap
      .flatMap { pair in
        pair.value.filter { task in
          // not finished and not voted
          guard task.finished == false && task.voteValue == nil else {
            return false
          }
          if userIsNotOwner {
            return task.taskOwner.userUuid != userId
          } else {
            return true
          }
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

// MARK: - Subscriptions
extension WatchingService {
  func isSubscribed(teamId: Team.ID) -> AnyPublisher<Bool, Never> {
    ignoredTeams
      .map { !$0.contains(teamId) }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }
  
  func isSubscribed(teamId: Team.ID) -> Bool {
    !ignoredTeams.value.contains(teamId)
  }
  
  func changeSubscription(enabled: Bool, for teamId: Team.ID) {
    if enabled {
      ignoredTeams.value.remove(teamId)
    } else {
      ignoredTeams.value.insert(teamId)
    }
    save(ignoredTeamIds: ignoredTeams.value)
  }
  
  private func save(ignoredTeamIds: Set<Team.ID>) {
    UserDefaults.standard.set(Array(ignoredTeamIds), forKey: Keys.ignoredTeamIds)
  }
}

public extension Publisher {

  /// Transforms an output value into a new publisher, and flattens the stream of events from
  /// these multiple upstream publishers to appear as if they were coming from a single stream of events
  ///
  /// Mapping to a new publisher will cancel the subscription to the previous one, keeping only a single
  /// subscription active along with its event emissions
  ///
  /// - parameter transform: A transform to apply to each emitted value, from which you can return a new Publisher
  ///
  /// - note: This operator is a combination of `map` and `switchToLatest`
  ///
  /// - returns: A publisher emitting the values of the latest inner publisher
  func flatMapLatest<P: Publisher>(_ transform: @escaping (Output) -> P) -> Publishers.SwitchToLatest<P, Publishers.Map<Self, P>> {
    map(transform).switchToLatest()
  }
}
