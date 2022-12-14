//
//  TaskView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct TaskView: View {
  @Injected(\.tasksService)
  private var taskService: TasksService
  @Injected(\.appState)
  private var appState: AppState
  @Environment(\.openURL) var openURL
  
  let teamId: Team.ID
  @State private var task: ApiTask?
  private let taskId: ApiTask.ID
  @State private var votes: [VoteInfo] = []
  @State private var error: String?
  
  init(task: ApiTask, teamId: Team.ID) {
    self.taskId = task.id
    self.teamId = teamId
    _task = State(initialValue: task)
  }
  
  init(taskId: ApiTask.ID, teamId: Team.ID) {
    self.taskId = taskId
    self.teamId = teamId
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
    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding()
    .onReceive(taskService.subscribe(taskId: taskId, teamId: teamId)) { task in
      setTask(task, animated: true)
    }
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
    HBar {
      if let task = task {
        Button("Share link", action: shareLink)
        Spacer()
        if task.finished {
          Button("Restart") {
            restart()
          }
        } else {
          Button("Finish") {
            finish()
          }
        }
      }
    }
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
                .foregroundColor(color(for: vote))
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
    if #available(macOS 13.0, iOS 16.0, *) {
      votesResultChart()
    } else {
      votesResultText()
    }
  }
  
  @ViewBuilder
  private func votesResultText() -> some View {
    ForEach(votes, id: \.value.id) { vote in
      Section(vote.value.name + ": \(vote.votedUsers.count)") {
        ForEach(vote.votedUsers, id: \.userUuid) { user in
          Text("- " + user.name)
        }
      }
    }
    .textSelection(.enabled)
  }
  
  @available(macOS 13.0, iOS 16.0, *)
  @ViewBuilder
  private func votesResultChart() -> some View {
    let data = VotesChart.Data(
      stat: votes.map { vote in
        VotesChart.VoteStat(
          vote: vote.value.name,
          users: vote.votedUsers.map { $0.name }
        )
      }
    )
    VStack(alignment: .leading) {
      Divider()
      VotesChart(data: data)
        .frame(maxWidth: .infinity)
    }
  }
  
  @ViewBuilder
  private var votedView: some View {
    VStack(alignment: .leading, spacing: 4) {
      if let count = task?.votedUsers?.count, count > 0 {
        Text("Voted \(count):")
      }
      ForEach(task?.votedUsers ?? [], id: \.userUuid) { user in
        Text("??? \(user.name)")
          .textSelection(.enabled)
      }
    }
  }
  
  private func color(for vote: Vote) -> Color {
    // Commented for now
//    switch vote {
//    case .zero:
//      return Color(.systemMint)
//    case .one, .two:
//      return Color(.systemGreen)
//    case .three, .five:
//      return .primary
//    case .eight:
//      return Color(.systemOrange)
//    case .thirteen, .twentyOne:
//      return Color(.systemRed)
//    default:
      return .primary
//    }
  }
  
  // MARK: - Functions
  
  private func reload(animated: Bool) {
    error = nil
    Task {
      do {
        let task = try await taskService.task(id: taskId, teamId: teamId)
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
        reloadVotes()
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func restart() {
    error = nil
    Task {
      do {
        try await taskService.restart(taskId: taskId, teamId: teamId)
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
    TaskView(
      task: ApiTask.sample(id: ApiTask.ID.finishedTaskId), teamId: "teamId"
    )
    .testDependences()
  }
}
