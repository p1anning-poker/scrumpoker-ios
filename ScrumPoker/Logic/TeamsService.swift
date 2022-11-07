//
//  TeamsService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 05.11.2022.
//

import Foundation

private enum Keys {
  static let latestOpenedTeamId = "LATEST_OPENED_TEAM_ID"
}

final class TeamsService: ObservableObject {
  // MARK: - Properties
  private let api: PokerAPI
  private let defaults = UserDefaults.standard
  
  private(set) var teams: [Team] = [] {
    didSet {
      guard teams != oldValue else { return }
      objectWillChange.send()
    }
  }
  private(set) var latestOpenedTeamId: Team.ID?
  
  // MARK: - Lifecycle
  
  init(api: PokerAPI) {
    self.api = api
    
    latestOpenedTeamId = defaults.string(forKey: Keys.latestOpenedTeamId)
    reload()
  }
  
  // MARK: - Functions
  
  func reloadTeams() async throws {
    let teams = try await api.teams()
    await update(teams: teams)
  }
  
  func setLatestOpenedTeamId(_ id: Team.ID) {
    guard latestOpenedTeamId != id else { return }
    latestOpenedTeamId = id
    defaults.set(id, forKey: Keys.latestOpenedTeamId)
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

// MARK: - Actions
extension TeamsService {
  
  func createTeam(name: String) async throws -> Team {
    let team = try await api.createTeam(name: name)
    reload()
    return team
  }
  
  func members(teamId: Team.ID) async throws -> [TeamMember] {
    try await api.members(teamId: teamId)
  }
  
  func invite(member email: String, teamId: Team.ID) async throws {
    try await api.invite(member: email, teamId: teamId)
  }
  
  func acceptInvite(team: Team) async throws -> Team {
    try await api.acceptInvite(teamId: team.id)
    var team = team
    team.membershipStatus = .member
    if let index = teams.firstIndex(where: { $0.id == team.id }) {
      teams[index] = team
    }
    return team
  }
}
