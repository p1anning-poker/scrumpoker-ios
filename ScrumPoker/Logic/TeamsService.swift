//
//  TeamsService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 05.11.2022.
//

import Foundation

final class TeamsService: ObservableObject {
  // MARK: - Properties
  private let api: PokerAPI
  private(set) var teams: [Team] = [] {
    didSet {
      guard teams != oldValue else { return }
      objectWillChange.send()
    }
  }
  
  // MARK: - Lifecycle
  
  init(api: PokerAPI) {
    self.api = api
    
    reload()
  }
  
  // MARK: - Functions
  
  func reloadTeams() async throws {
    let teams = try await api.teams()
    await update(teams: teams)
  }
  
  func createTeam(name: String) async throws -> Team {
    let team = try await api.createTeam(name: name)
    reload()
    return team
  }
  
  // MARK: - Private
  
  private func reload() {
    Task {
      try await reloadTeams()
    }
  }
  
  @MainActor
  private func update(teams: [Team]) {
    self.teams = teams
  }
}
