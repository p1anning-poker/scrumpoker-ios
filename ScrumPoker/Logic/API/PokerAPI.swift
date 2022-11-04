//
//  PokerAPI.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation

final class PokerAPI: ObservableObject {
  
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
  
  init(networkService: NetworkService, appState: AppState) {
    self.networkService = networkService
    self.appState = appState
  }
 
  private func perform(
    path: String,
    method: Method = .GET,
    params: [String: Any]? = nil,
    authorize: Bool = true
  ) async throws -> NetworkResponse {
    let url = baseURL.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
    params: [String: Any]? = nil,
    authorize: Bool = true
  ) async throws -> T {
    let response: NetworkResponse = try await perform(
      path: path,
      method: method,
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
      params: ["email": email, "password": password],
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
  
  func createTask(name: String, url: URL) async throws -> ApiTask {
    return try await perform(
      path: "tasks",
      method: .POST,
      params: [
        "scale": "FIBONACCI",
        "name": name,
        "url": url.absoluteString
      ]
    )
  }
  
  func task(id: ApiTask.ID) async throws -> ApiTask {
    return try await perform(path: "tasks/\(id)")
  }
  
  func myTasks() async throws -> [ApiTask] {
    return try await perform(type: [ApiTask].self, path: "tasks")
  }
  
  func finish(taskId: ApiTask.ID) async throws {
    _ = try await perform(path: "tasks/\(taskId)/finish", method: .POST)
  }
  
  func delete(taskId: ApiTask.ID) async throws {
    _ = try await perform(path: "tasks/\(taskId)", method: .DELETE)
  }
}

// MARK: - Votes
extension PokerAPI {
  
  func votes(id: ApiTask.ID) async throws -> [VoteInfo] {
    return try await perform(path: "tasks/\(id)/votes")
  }
  
  func vote(id: ApiTask.ID, vote: Vote) async throws {
    _ = try await perform(path: "tasks/\(id)/votes", method: .PUT, params: ["value": vote.rawValue])
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
}