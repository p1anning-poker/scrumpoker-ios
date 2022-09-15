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
  @EnvironmentObject private var api: PokerAPI
  @State private var tasks = [ApiTask]()
  @State private var error: String?
  @State private var displayCreate: Bool = false
  @State private var selection: Int?
  
  @Binding var openAtStart: ApiTask.ID?
  
  var body: some View {
    VStack(alignment: .center) {
      header()
      if let error = error {
        Text(error)
          .foregroundColor(.red)
      } else if tasks.isEmpty {
        Text("You have no tasks")
      } else {
        List(selection: $selection) {
          ForEach(tasks) { task in
            taskView(task)
          }
        }
        .listRowBackground(Color.orange)
      }
      Spacer()
      if let id = openAtStart {
        NavigationLink("", isActive: .constant(true)) {
          TaskView(taskId: id)
        }
      }
    }
    .padding()
    .onAppear {
      reload()
      openAtStart = nil
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
            reload()
          }
        }
        Button("Refresh", action: reload)
      }
      Divider()
    }
    .frame(minWidth: 200, maxWidth: .infinity, minHeight: 30)
  }
  
  @ViewBuilder
  private func taskView(_ task: ApiTask) -> some View {
    NavigationLink {
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
        tasks = try await api.myTasks()
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func delete(task: ApiTask) {
    error = nil
    Task {
      do {
        try await api.delete(taskId: task.id)
        if selection == tasks.firstIndex(where: { $0.id == task.id }) {
          selection = nil
        }
        reload()
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func terminate() {
   exit(0)
  }
}

struct MyTasksView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      MyTasksView(openAtStart: .constant(nil))
    }
  }
}
