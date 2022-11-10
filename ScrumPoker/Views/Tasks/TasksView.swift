//
//  TasksView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI
import Cocoa

struct TasksView: View {
  
  @EnvironmentObject private var tasksService: TasksService
  
  let team: Team
  let filter: TasksFilter
  let allowedToCreate: Bool
  @Binding var taskToOpen: ApiTask?
  
  @State var tasks: [ApiTask] = []
  @State private var error: String?
  @State private var content: ContentType?
  @State private var modal: Modal?
  
  var body: some View {
    VStack(alignment: .leading) {
      if allowedToCreate {
        Button(action: createTask) {
          Label("Add task", systemImage: "rectangle.badge.plus")
        }
        .padding(.leading)
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
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear {
      reload()
    }
    .onReceive(tasksService.objectWillChange) { _ in
      updateTasks(animated: true)
    }
    .sheet(item: $modal) { modal in
      switch modal {
      case .createNewTask:
        TaskCreate(teamId: team.id, teamName: team.teamName) { _ in
          self.modal = nil
        }
        .frame(minWidth: 300, maxWidth: 400)
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
      TaskView(task: task, teamId: team.id, addToRecentlyViewed: false)
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
        try await tasksService.reloadTasks(teamId: team.id)
        updateTasks(animated: true)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func delete(task: ApiTask) {
    error = nil
    Task {
      do {
        try await tasksService.delete(taskId: task.id, teamId: team.id)
        if content == .details(task) {
          content = nil
        }
      } catch {
        self.error = error.localizedDescription
      }
    }
  }

  private func updateTasks(animated: Bool) {
    var newTasks: [ApiTask] = tasksService.tasks(
      teamId: team.id,
      filter: filter
    )
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
    
//    NavigationView {
      TasksView(
        team: .sample(id: "1"),
        filter: TasksFilter(),
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
            appState: appState
          )
        )
        .frame(width: 600)
//    }
  }
}
