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
  
  @State private var tasks: [ApiTask] = []
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
        List(tasks) { task in
          taskView(task)
            .listDivider()
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
    .frame(width: 300)
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
        VStack(alignment: .leading) {
          Text(task.name)
          Text(task.url?.absoluteString ?? "No URL")
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
    let newTasks: [ApiTask] = tasksService.tasks(teamId: team.id,
                                                 filter: filter)
    let action = {
      self.tasks = newTasks
      if let task = taskToOpen, let newTask = newTasks.first(where: { $0.id == task.id }) {
        content = .details(newTask)
        self.taskToOpen = nil
      }
    }
    
    if animated {
      withAnimation {
        action()
      }
    } else {
      action()
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
    NavigationView {
      TasksView(
        team: .sample(id: "1"),
        filter: TasksFilter(),
        allowedToCreate: false,
        taskToOpen: .constant(nil)
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
    }
  }
}
