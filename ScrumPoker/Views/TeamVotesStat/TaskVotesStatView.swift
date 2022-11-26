//
//  TaskVotesStatView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 27.11.2022.
//

import SwiftUI
import Charts

@available(macOS 13.0, *)
struct TaskVotesStatView: View {
  let teamId: Team.ID
  @Injected(\.tasksService)
  private var tasksService: TasksService
  @State
  private var stat: TasksVotesStat = TasksVotesStat(totalTasksCount: 0, userVotesStat: [])
  @State
  private var error: String?
  
  var body: some View {
    VStack(alignment: .leading) {
      if let error {
        ErrorView(error: error)
      }
      Text("Total tasks count: \(stat.totalTasksCount)")
      Chart {
        ForEach(stat.userVotesStat, id: \.user.userUuid) { stat in
          BarMark(
            x: .value("User", stat.user.name),
            yStart: .value("Count", 0),
            yEnd: .value("Count", stat.votedTasksCount)
          )
          .annotation {
            Text("\(stat.votedTasksCount) \(stat.votedTasksCount == 1 ? "task" : "tasks")")
          }
        }
      }
      .foregroundColor(.accentColor)
    }
    .padding()
    .onAppear {
      reload()
    }
  }
  
  private func reload() {
    error = nil
    Task {
      do {
        stat = try await tasksService.tasksVotesStat(teamId: teamId)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
}

@available(macOS 13.0, *)
struct TaskVotesStatView_Previews: PreviewProvider {
  static var previews: some View {
    TaskVotesStatView(teamId: "test")
      .testDependences()
  }
}
