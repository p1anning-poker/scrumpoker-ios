//
//  TasksView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct TasksView: View {
  
  @EnvironmentObject private var tasksService: TasksService
  @EnvironmentObject private var watchingService: WatchingService
  
  let team: Team
  let filter: TasksFilter
  let allowedToCreate: Bool
  @Binding var taskToOpen: ApiTask?
  @State private var isSubscribed: Bool = true
  
  @State var tasks: [ApiTask] = []
  @State private var error: String?
  @State private var content: ContentType?
  @State private var modal: Modal?
  
  var body: some View {
    VStack(alignment: .leading) {
      if allowedToCreate {
        HStack(alignment: .center) {
          Button(action: createTask) {
            Label("Add task", systemImage: "rectangle.badge.plus")
          }
          Spacer()
          Toggle("Subscription", isOn: isSubscriptionOn())
            .disabled(true)
        }
        .padding([.leading, .trailing])
      }
      if let error = error {
        ErrorView(error: error)
          .padding()
      } else if tasks.isEmpty {
        Text("You have no tasks")
          .padding()
      } else {
        ScrollViewReader { proxy in
          List(tasks) { task in
            taskView(task)
              .listDivider()
          }
          .onChange(of: tasks) { _ in
            showTaskToOpenDetailsIfNeeded(scrollProxy: proxy)
          }
          .onChange(of: taskToOpen) { _ in
            showTaskToOpenDetailsIfNeeded(scrollProxy: proxy)
          }
          .onAppear {
            showTaskToOpenDetailsIfNeeded(scrollProxy: proxy)
          }
        }
      }
      Spacer()
    }
    .onReceive(watchingService.isSubscribed(teamId: team.id)) { subscribed in
      self.isSubscribed = subscribed
    }
    .onReceive(tasksService.subscribe(teamId: team.id,
                                      finished: filter.completed)) { tasks in
      update(tasks: tasks, animated: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear {
      reload()
    }
    .sheet(item: $modal) { modal in
      switch modal {
      case .createNewTask:
        TaskCreateView(teamId: team.id, teamName: team.teamName) { _ in
          self.modal = nil
        }
        .frame(minWidth: 300, maxWidth: 400)
      }
    }
  }
  
  private func isSubscriptionOn() -> Binding<Bool> {
    return Binding {
      isSubscribed
    } set: { newValue in
      do {
        try watchingService.changeSubscription(enabled: newValue, for: team.id)
      } catch {
        print("Failed to change subscription: \(error)")
      }
    }
  }
  
  @ViewBuilder
  private func taskView(_ task: ApiTask) -> some View {
    let binding = Binding<Bool> {
      content == .details(task)
    } set: { active in
      if active {
        content = .details(task)
      } 
    }

    NavigationLink(isActive: binding) {
      TaskView(task: task, teamId: team.id)
    } label: {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(task.name)
          Text(task.url?.absoluteString ?? "No URL")
            .font(.caption2)
            .foregroundColor(.secondary)
          HStack {
            Text("\(task.votedUsers?.count ?? 0) voted")
            Spacer()
            Image(systemName: task.voteValue == nil ? "circle" : "checkmark.circle")
          }
          .font(.caption2)
        }
        Spacer()
        if task.finished {
          Image(systemName: "checkmark.circle.fill")
        }
      }
    }
    .contextMenu {
      Button("Delete") { delete(task: task) }
    }
    .id(task.id)
  }
  
  // MARK: - Actions
  
  private func createTask() {
    modal = .createNewTask
  }
  
  private func reload() {
    error = nil
    Task {
      do {
        let tasks = try await tasksService.reloadTasks(teamId: team.id, filter: filter)
        update(tasks: tasks, animated: false)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func delete(task: ApiTask) {
    error = nil
    Task {
      do {
        try await tasksService.delete(taskId: task.id, teamId: team.id, isFinished: task.finished)
        if content == .details(task) {
          content = nil
        }
      } catch {
        self.error = error.localizedDescription
      }
    }
  }

  private func update(tasks: [ApiTask], animated: Bool) {
    error = nil
    var newTasks: [ApiTask] = tasks
      .sorted { l, r in
        return l.voteValue == nil && r.voteValue != nil
      }
    if let detailedTask = content?.task, !newTasks.contains(where: { $0.id == detailedTask.id }) {
      // Displayed task must be in the list
      newTasks.append(detailedTask)
    }
    
    let action = {
      self.tasks = newTasks
    }
    
    if animated {
      withAnimation {
        action()
      }
    } else {
      action()
    }
  }
  
  private func showTaskToOpenDetailsIfNeeded(scrollProxy: ScrollViewProxy) {
    if let taskToOpen, let task = tasks.first(where: { $0.id == taskToOpen.id }) {
      self.taskToOpen = nil
      withAnimation(.default) {
        scrollProxy.scrollTo(task.id)
        content = .details(task)
      }
    }
  }
}

// MARK: - Types
extension TasksView {
  
  enum Modal: Identifiable {
    case createNewTask
    
    var id: Int {
      switch self {
      case .createNewTask:
        return 0
      }
    }
  }
  
  private enum ContentType: Equatable {
    case details(ApiTask)
    
    var task: ApiTask {
      switch self {
      case .details(let task):
        return task
      }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.details(let l), .details(let r)):
        return l.id == r.id
      }
    }
  }
}

struct MyTasksView_Previews: PreviewProvider {
  static var previews: some View {
    let appState = AppState.shared
    let tasks = (0..<5).map { id in
      ApiTask.sample(
        id: "id",
        vote: Bool.random() ? Vote.one : nil
      )
    }
    
    let deeplinkService = DeeplinkService()
    
//    NavigationView {
      TasksView(
        team: .sample(id: "1"),
        filter: TasksFilter(completed: false),
        allowedToCreate: false,
        taskToOpen: .constant(nil),
        tasks: tasks
      )
        .environmentObject(
          TasksService(
            api: PokerAPI(
              networkService: NetworkService(),
              appState: appState
            ),
            appState: appState,
            notificationsService: NotificationsService(
              deeplinkService: deeplinkService
            ),
            deeplinkService: deeplinkService
          )
        )
        .frame(width: 600)
//    }
  }
}
