//
//  MyTasksView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI
import Cocoa

struct MyTasksView: View {
  
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var tasksService: TasksService
  
  @State private var tasks: [ApiTask] = []
  @State private var error: String?
  @State private var displayCreate: Bool = false
  @State private var selection: Int?
  @State private var content: ContentType = .empty
  
  var body: some View {
    VStack(alignment: .center) {
      if let error = error {
        Text(error)
          .foregroundColor(.red)
      } else if tasks.isEmpty {
        Text("You have no tasks")
      } else {
        List(tasks) { task in
          taskView(task)
        }
      }
      Spacer()
      NavigationLink(isActive: .constant(content == .empty)) {
        switch content {
        case .empty:
          Text("Nothing to display")
        case .details(let apiTask):
          TaskView(task: apiTask)
        case .none:
          EmptyView()
        }
      } label: {
        EmptyView()
      }
      .frame(width: 0)
      .opacity(0)
    }
    .onAppear {
      reload()
    }
    .onReceive(tasksService.objectWillChange) { _ in
      updateTasks(animated: true)
    }
    .toolbar {
      ToolbarItem(placement: .keyboard) {
        Button("RELOAD") {
          reload()
        }
      }
    }
  }
  
  @ViewBuilder
  private func header() -> some View {
    VStack(alignment: .leading) {
      HStack {
        Text(appState.currentUser?.name ?? "")
          .contextMenu {
            Button("Logout", action: logout)
            Button("Exit", action: terminate)
          }
        Spacer()
        NavigationLink("Add", isActive: $displayCreate) {
          TaskCreate { _ in
            displayCreate = false
          }
        }
        Button("Refresh", action: reload)
      }
      Divider()
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
      TaskView(task: task)
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
  
  private func logout() {
    appState.set(token: nil, user: nil)
  }
  
  private func reload() {
    error = nil
    Task {
      do {
        try await tasksService.reloadTasks()
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
        try await tasksService.delete(taskId: task.id)
        if content == .details(task) {
          content = .empty
        }
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func terminate() {
   exit(0)
  }
  
  private func updateTasks(animated: Bool) {
    if animated {
      withAnimation {
        tasks = tasksService.tasks
      }
    } else {
      tasks = tasksService.tasks
    }
  }
}

// MARK: - Types
extension MyTasksView {
  
  private enum ContentType: Equatable {
    case empty
    case details(ApiTask)
    case none
    
    static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.empty, .empty), (.none, .none):
        return true
      case (.details(let l), .details(let r)):
        return l.id == r.id
      default:
        return false
      }
    }
  }
}

struct MyTasksView_Previews: PreviewProvider {
  static var previews: some View {
    let appState = AppState.shared
    NavigationView {
      MyTasksView()
        .environmentObject(appState)
        .environmentObject(TasksService(api: PokerAPI(networkService: NetworkService(), appState: appState), appState: appState))
    }
  }
}
