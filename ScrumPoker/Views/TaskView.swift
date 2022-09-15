//
//  TaskView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct TaskView: View {
  @EnvironmentObject private var api: PokerAPI
  @EnvironmentObject private var appState: AppState
  @Environment(\.openURL) var openURL
  
  @State private var task: ApiTask?
  private let taskId: ApiTask.ID
  @State private var votes: [VoteInfo] = []
  @State private var error: String?
  
  init(task: ApiTask) {
    self.taskId = task.id
    _task = State(initialValue: task)
  }
  
  init(taskId: ApiTask.ID) {
    self.taskId = taskId
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      globalActions
      if let error = error {
        Text(error)
          .foregroundColor(.red)
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
      } else if task == nil {
        reload()
      }
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
        } else {
          votesView
        }
        Spacer()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
  
  @ViewBuilder
  private var globalActions: some View {
    VStack {
      HStack {
        if let task = task {
          Text("Votes: \(task.votesCount)")
          Button("Share link", action: shareLink)
          Spacer()
          if task.userName != nil, task.userName == appState.currentUser?.name {
            Button("Complete") {
              complete()
            }
          }
        } else {
          
        }
      }
      Spacer()
      Divider()
    }
    .frame(height: 30)
  }
  
  @ViewBuilder
  private var voteActions: some View {
    let selectedVote = votes.first {
      $0.userNames.contains(appState.currentUser?.name ?? "")
    }?.value
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
            .border(Color.accentColor, width: selectedVote == vote ? 2 : 0)
          }
        }
      }
    }
  }
  
  @ViewBuilder
  private var votesView: some View {
    ForEach(votes, id: \.value.id) { vote in
      Section(vote.value.name + ": \(vote.userNames.count)") {
        ForEach(vote.userNames, id: \.self) { userName in
          Text("- " + userName)
        }
      }
    }
  }
  
  // MARK: - Functions
  
  private func reload() {
    error = nil
    Task {
      do {
        task = try await api.task(id: taskId)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func vote(_ vote: Vote) {
    error = nil
    Task {
      do {
        try await api.vote(id: taskId, vote: vote)
        reload()
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func reloadVotes() {
    error = nil
    Task {
      do {
        votes = try await api.votes(id: taskId)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func complete() {
    error = nil
    Task {
      do {
        try await api.finish(taskId: taskId)
        reloadVotes()
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func shareLink() {
    let text = "[\(task?.name ?? taskId)](scrumpoker://?taskId=\(taskId))"
    let pasteboard = NSPasteboard.general
    pasteboard.declareTypes([.string], owner: nil)
    pasteboard.setString(text, forType: .string)
  }
}

struct TaskView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      TaskView(
        task: ApiTask(
          taskUuid: "",
          name: "Task name",
          url: URL(string: "https://google.com"),
          finished: false,
          votesCount: 0
        )
      )
    }
  }
}
