//
//  TaskView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct TaskView: View {
  @EnvironmentObject private var taskService: TasksService
  @EnvironmentObject private var appState: AppState
  @Environment(\.openURL) var openURL
  
  let addToRecentlyViewed: Bool
  let teamId: Team.ID
  @State private var task: ApiTask?
  private let taskId: ApiTask.ID
  @State private var votes: [VoteInfo] = []
  @State private var error: String?
  
  init(task: ApiTask, teamId: Team.ID, addToRecentlyViewed: Bool) {
    self.taskId = task.id
    self.teamId = teamId
    self.addToRecentlyViewed = addToRecentlyViewed
    _task = State(initialValue: task)
  }
  
  init(taskId: ApiTask.ID, teamId: Team.ID, addToRecentlyViewed: Bool) {
    self.taskId = taskId
    self.teamId = teamId
    self.addToRecentlyViewed = addToRecentlyViewed
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      globalActions
      if let error = error {
        ErrorView(error: error)
      } else if task != nil {
        taskBody
      } else {
        Text("Loading...")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding()
    .onAppear {
      if task?.finished == true {
        reloadVotes()
      }
      reload(animated: true)
    }
  }
  
  @ViewBuilder
  private var taskBody: some View {
    let task = self.task!
    ScrollView(.vertical, showsIndicators: false) {
      VStack(alignment: .leading) {
        Text(task.name)
        if let url = task.url {
          Link(url.absoluteString, destination: url)
        }
        if !task.finished {
          Spacer(minLength: 16)
          voteActions
          Spacer(minLength: 16)
          votedView
        } else {
          votesView
        }
        Spacer()
      }
      .textSelection(.enabled)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
  
  @ViewBuilder
  private var globalActions: some View {
    VStack {
      HStack {
        if let task = task {
          Button("Share link", action: shareLink)
          Spacer()
          if task.finished == false {
            Button("Finish") {
              finish()
            }
          }
        } else {
          
        }
      }
      Spacer()
    }
    .frame(height: 30)
  }
  
  @ViewBuilder
  private var voteActions: some View {
    let slices = Vote.allCases.reduce(into: [[Vote]]()) { partialResult, vote in
      if (partialResult.last?.count ?? 3) > 2 {
        partialResult.append([vote])
      } else {
        partialResult[partialResult.count - 1].append(vote)
      }
    }

    VStack {
      ForEach(0..<slices.count, id: \.self) { idx in
        HStack {
          ForEach(slices[idx]) { vote in
            Button(action: { self.vote(vote) }) {
              Text(vote.name)
                .frame(maxWidth: .infinity)
            }
            .disabled(task?.voteValue == vote)
            .overlay(
              RoundedRectangle(cornerRadius: 4, style: RoundedCornerStyle.continuous)
                .stroke(
                  Color.accentColor,
                  style: StrokeStyle(
                    lineWidth: task?.voteValue == vote ? 2 : 0
                  )
                )
                .padding(1)
                .animation(Animation.default, value: task?.voteValue)
            )
          }
        }
      }
    }
  }
  
  @ViewBuilder
  private var votesView: some View {
    ForEach(votes, id: \.value.id) { vote in
      Section(vote.value.name + ": \(vote.votedUsers.count)") {
        ForEach(vote.votedUsers, id: \.userUuid) { user in
          Text("- " + user.name)
        }
      }
    }
    .textSelection(.enabled)
  }
  
  @ViewBuilder
  private var votedView: some View {
    VStack(alignment: .leading, spacing: 4) {
      if let count = task?.votedUsers?.count, count > 0 {
        Text("Voted \(count):")
      }
      ForEach(task?.votedUsers ?? [], id: \.userUuid) { user in
        Text("✅ \(user.name)")
          .textSelection(.enabled)
      }
    }
  }
  
  // MARK: - Functions
  
  private func reload(animated: Bool) {
    error = nil
    Task {
      do {
        let task = try await taskService.task(id: taskId, teamId: teamId)
        if addToRecentlyViewed {
          taskService.add(recentlyViewed: task)
        }
        await MainActor.run {
          setTask(task, animated: animated)
        }
        if task.finished {
          reloadVotes()
        }
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func setTask(_ task: ApiTask, animated: Bool) {
    if animated {
      self.task = task
    } else {
      withAnimation {
        self.task = task
      }
    }
  }
  
  private func vote(_ vote: Vote) {
    error = nil
    Task {
      do {
        try await taskService.vote(taskId: taskId, teamId: teamId, vote: vote)
        reload(animated: true)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func reloadVotes() {
    error = nil
    Task {
      do {
        votes = try await taskService.votes(taskId: taskId, teamId: teamId)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func finish() {
    error = nil
    Task {
      do {
        try await taskService.finish(taskId: taskId, teamId: teamId)
        reload(animated: true)
        reloadVotes()
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func shareLink() {
    guard let task = task else { return }
    taskService.share(task: task, teamId: teamId)
  }
}

struct TaskView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      TaskView(
        task: ApiTask(
          taskUuid: "task_id",
          taskOwner: PublicUser(userUuid: "id", name: "name"),
          name: "Task name",
          url: URL(string: "https://google.com"),
          finished: false,
          voteValue: nil,
          votedUsers: [
            PublicUser(
              userUuid: "1",
              name: "Short name"
            ),
            PublicUser(
              userUuid: "2",
              name: "Long Long name"
            )
          ]
        ),
        teamId: "1",
        addToRecentlyViewed: false
      )
      .environmentObject(AppState.shared)
    }
  }
}
