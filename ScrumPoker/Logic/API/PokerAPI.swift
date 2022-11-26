//
//  PokerAPI.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation

final class PokerAPI: ObservableObject {
  
  private enum Keys {
    static let deviceUuid = "device_uuid"
  }
  
  private enum APIError: Error, LocalizedError {
    case invalidResponse
    case errorResponse(code: Int, data: Data)
    
    var errorDescription: String? {
      switch self {
      case .invalidResponse:
        return "Invalid Response"
      case .errorResponse(let code, let data):
        let text = String(data: data, encoding: .utf8) ?? ""
        return "[\(code)] \(text)"
      }
    }
  }
  
  enum Method: String {
    case GET, POST, PUT, DELETE
  }
  
  private let baseURL = URL(string: "https://poker.pervush.in/api/v1/")!
  private let networkService: NetworkService
  private let appState: AppState
  private let deviceUuid: String
  
  init(networkService: NetworkService, appState: AppState) {
    self.networkService = networkService
    self.appState = appState
    
    if let uuid = UserDefaults.standard.string(forKey: Keys.deviceUuid) {
      deviceUuid = uuid
    } else {
      deviceUuid = UUID().uuidString
      UserDefaults.standard.set(deviceUuid, forKey: Keys.deviceUuid)
    }
  }
 
  @discardableResult
  private func perform(
    path: String,
    method: Method = .GET,
    queryParams: [String: String]? = nil,
    params: [String: Any]? = nil,
    authorize: Bool = true
  ) async throws -> NetworkResponse {
    var url = baseURL.appendingPathComponent(path)
    if let queryParams, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
      components.queryItems = queryParams.map { pair in
        URLQueryItem(name: pair.key, value: pair.value)
      }
      url = components.url ?? url
    }
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(deviceUuid, forHTTPHeaderField: "x-device-uuid")
    request.httpBody = params.flatMap { params in
      try? JSONSerialization.data(withJSONObject: params)
    }
        
    let response = try await networkService.perform(reqeust: request)
    guard 200...299 ~= response.code else {
      throw APIError.errorResponse(code: response.code, data: response.data)
    }
    return response
  }
  
  private func perform<T: Decodable>(
    type: T.Type = T.self,
    path: String,
    method: Method = .GET,
    queryParams: [String: String]? = nil,
    params: [String: Any]? = nil,
    authorize: Bool = true
  ) async throws -> T {
    let response: NetworkResponse = try await perform(
      path: path,
      method: method,
      queryParams: queryParams,
      params: params,
      authorize: authorize
    )
    return try JSONDecoder().decode(T.self, from: response.data)
  }
}

// MARK: - Profile
extension PokerAPI {
  
  func register(email: String, name: String, password: String) async throws -> Token {
    _ = try await perform(
      path: "registration",
      method: .POST,
      params: ["email": email, "name": name, "password": password],
      authorize: false
    )
    guard let token = HTTPCookieStorage.shared.cookies?.first(where: { $0.name == "SESSIONID" })?.value else {
      throw APIError.invalidResponse
    }
    return token
  }
  
  func authorize(email: String, password: String) async throws -> Token {
    _ = try await perform(
      path: "login",
      method: .POST,
      params: ["email": email, "password": password, "deviceUuid": deviceUuid],
      authorize: false
    )
    guard let token = HTTPCookieStorage.shared.cookies?.first(where: { $0.name == "SESSIONID" })?.value else {
      throw APIError.invalidResponse
    }
    return token
  }
  
  func myUser() async throws -> User {
    return try await perform(path: "user")
  }
}

// MARK: - Tasks
extension PokerAPI {
  
  func createTask(name: String, url: URL, teamId: Team.ID) async throws -> ApiTask {
    return try await perform(
      path: "teams/\(teamId)/tasks",
      method: .POST,
      params: [
        "scale": "FIBONACCI",
        "name": name,
        "url": url.absoluteString
      ]
    )
  }
  
  func task(id: ApiTask.ID, teamId: Team.ID) async throws -> ApiTask {
    return try await perform(path: "teams/\(teamId)/tasks/\(id)")
  }
  
  func tasks(teamId: Team.ID, finished: Bool?) async throws -> [ApiTask] {
    var queryParams = [String: String]()
    queryParams["finished"] = finished.map(String.init)
    return try await perform(
      type: [ApiTask].self,
      path: "teams/\(teamId)/tasks",
      queryParams: queryParams
    )
  }
  
  func finish(taskId: ApiTask.ID, teamId: Team.ID) async throws {
    _ = try await perform(path: "teams/\(teamId)/tasks/\(taskId)/finish", method: .POST)
  }
  
  func activate(taskId: ApiTask.ID, teamId: Team.ID) async throws {
    _ = try await perform(path: "teams/\(teamId)/tasks/\(taskId)/activate", method: .POST)
  }
  
  func delete(taskId: ApiTask.ID, teamId: Team.ID) async throws {
    _ = try await perform(path: "teams/\(teamId)/tasks/\(taskId)", method: .DELETE)
  }
}

// MARK: - Votes
extension PokerAPI {
  
  func votes(taskId: ApiTask.ID, teamId: Team.ID) async throws -> [VoteInfo] {
    return try await perform(path: "teams/\(teamId)/tasks/\(taskId)/votes")
  }
  
  func vote(taskId: ApiTask.ID, teamId: Team.ID, vote: Vote) async throws {
    _ = try await perform(path: "teams/\(teamId)/tasks/\(taskId)/votes", method: .PUT, params: ["value": vote.rawValue])
  }
}

// MARK: - Teams
extension PokerAPI {
  
  func teams() async throws -> [Team] {
    return try await perform(path: "teams")
  }
  
  func createTeam(name: String) async throws -> Team {
    try await perform(
      path: "teams",
      method: .POST,
      params: ["teamName": name]
    )
  }
  
  func deleteTeam(id: Team.ID) async throws {
    try await perform(
      path: "teams/\(id)",
      method: .DELETE
    )
  }
}

// MARK: - Team Members
extension PokerAPI {
  
  func members(teamId: Team.ID) async throws -> [TeamMember] {
    return try await perform(path: "teams/\(teamId)/members")
  }
  
  func invite(member email: String, teamId: Team.ID) async throws {
    try await perform(
      path: "teams/\(teamId)/members/invite",
      method: .POST,
      params: ["email": email]
    )
  }
  
  func acceptInvite(teamId: Team.ID) async throws {
    try await perform(
      path: "teams/\(teamId)/members/accept"
    )
  }
}

// MARK: - Pushes
extension PokerAPI {
  
  func register(pushToken: String) async throws {
    try await perform(
      path: "notifications/push/token",
      method: .PUT,
      params: ["token": pushToken]
    )
  }
}

struct PokerApiKey: InjectionKey {
  static var currentValue: PokerAPI = PokerAPI(
    networkService: InjectedValues[\.networkService],
    appState: InjectedValues[\.appState]
  )
}

extension InjectedValues {
  var pokerApi: PokerAPI {
    get { Self[PokerApiKey.self] }
    set { Self[PokerApiKey.self] = newValue }
  }
}
