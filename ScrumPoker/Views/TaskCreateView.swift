//
//  TaskCreate.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct TaskCreateView: View {
  @EnvironmentObject private var taskService: TasksService
  
  let teamId: Team.ID
  let teamName: String?
  @State private var name = ""
  @State private var url = ""
  @State private var error: String?
  let onFinish: (ApiTask?) -> Void
  
  var body: some View {
    VStack {
      if let name = teamName {
        Text("Create task for \(name)")
      } else {
        Text("Create task")
      }
      if let error = error {
        Text(error)
          .foregroundColor(.red)
      }
      TextField("Name", text: $name)
      TextField("URL", text: $url)
      HStack {
        Button("Cancel") {
          onFinish(nil)
        }
        Button("Create", action: create)
          .disabled(name.isEmpty || url.isEmpty)
      }
    }
    .padding()
  }
  
  private func create() {
    guard let url = URL(string: url) else {
      error = "Invalid URL"
      return
    }
    error = nil
    Task {
      do {
        let task = try await taskService.createTask(name: name, url: url, teamId: teamId)
        taskService.share(task: task, teamId: teamId)
        onFinish(task)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
}

struct TaskCreate_Previews: PreviewProvider {
  static var previews: some View {
    TaskCreateView(teamId: "1", teamName: "test") { _ in
      
    }
  }
}
