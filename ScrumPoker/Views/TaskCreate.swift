//
//  TaskCreate.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct TaskCreate: View {
  @EnvironmentObject private var taskService: TasksService
  
  let team: Team
  @State private var name = ""
  @State private var url = ""
  @State private var error: String?
  let onFinish: (ApiTask?) -> Void
  
  var body: some View {
    VStack {
      Text("Create task for \(team.teamName)")
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
        let task = try await taskService.createTask(name: name, url: url, teamId: team.id)
        taskService.share(task: task, teamId: team.id)
        onFinish(task)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
}

struct TaskCreate_Previews: PreviewProvider {
  static var previews: some View {
    TaskCreate(team: .sample(id: "1")) { _ in
      
    }
  }
}
