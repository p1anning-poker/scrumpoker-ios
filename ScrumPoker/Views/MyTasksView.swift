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
  @State private var content: ContentType = .empty
  @State private var tasksListType: TasksLiskType = .my
  
  var body: some View {
    VStack(alignment: .center) {
      picker()
        .padding()
      if let error = error {
        Text(error)
          .foregroundColor(.red)
          .padding()
      } else if tasks.isEmpty {
        Text("You have no tasks")
      } else {
        List(tasks) { task in
          taskView(task)
        }
      }
      Spacer()
//      NavigationLink(isActive: .constant(content == .empty)) {
//        switch content {
//        case .empty:
//          Text("Nothing to display")
//        case .details(let apiTask):
//          TaskView(task: apiTask)
//        case .none:
//          EmptyView()
//        }
//      } label: {
//        EmptyView()
//      }
//      .frame(width: 0)
//      .opacity(0)
    }
    .onAppear {
      reload()
    }
    .onReceive(tasksService.objectWillChange) { _ in
      updateTasks(type: tasksListType, animated: true)
    }
  }
  
  @ViewBuilder
  private func picker() -> some View {
    Picker(selection: $tasksListType) {
      Text("My tasks").tag(TasksLiskType.my)
      Text("Recently viewed").tag(TasksLiskType.recent)
    } label: {
      EmptyView()
    }
    .pickerStyle(SegmentedPickerStyle())
    .onChange(of: tasksListType) { newValue in
      updateTasks(type: newValue, animated: false)
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
      TaskView(task: task, addToRecentlyViewed: tasksListType != .recent)
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
      switch tasksListType {
      case .my:
        Button("Delete") { delete(task: task) }
      case .recent:
        EmptyView()
      }
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
        updateTasks(type: tasksListType, animated: true)
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
  
  private func updateTasks(type: TasksLiskType, animated: Bool) {
    let newTasks: [ApiTask] = {
      switch type {
      case .my:
        return tasksService.tasks
      case .recent:
        return tasksService.recentlyViewedTasks
      }
    }()
    if animated {
      withAnimation {
        tasks = newTasks
      }
    } else {
      tasks = newTasks
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
  
  private enum TasksLiskType {
    case my, recent
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
