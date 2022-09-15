//
//  AppState.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation
import Combine

private struct Keys {
  static let profile = "PROFILE"
  static let lastLogin = "LAST_LOGIN"
}

typealias Token = String

private struct Profile: Codable, Equatable {
  var token: Token
  var user: User
}

final class AppState: ObservableObject {
  /// Current API token
  private let profileSubject = CurrentValueSubject<Profile?, Never>(nil)
  
  private let defaults = UserDefaults.standard
  static let shared = AppState()
  private(set) var lastLogin: String?
  
  // MARK: - Lifecycle
  
  private init() {
    let cachedProfileData = defaults.data(forKey: Keys.profile)
    profileSubject.send(cachedProfileData.flatMap { try? JSONDecoder().decode(Profile.self, from: $0) })
    lastLogin = defaults.string(forKey: Keys.lastLogin)
    
    setup()
  }
  
  // MARK: - Getters
  
  /// Идентификация, авторизованы ли мы
  var isAuthorized: AnyPublisher<Bool, Never> {
    return profileSubject.map { $0 != nil }
      .eraseToAnyPublisher()
  }
  
  var isAuthorizedValue: Bool {
    return profileSubject.value != nil
  }
  
  var numberOfTasks: AnyPublisher<Int, Never> {
    return Just(3).eraseToAnyPublisher()
  }
  
  var token: Token? {
    return profileSubject.value?.token
  }
  
  var currentUser: User? {
    return profileSubject.value?.user
  }
  
  // MARK: - Private
  
  private func setup() {
    
  }
  
  // MARK: - Setters
  
  func set(token: Token?, user: User?) {
    let profile = user.map { Profile(token: token ?? "", user: $0) }
    guard self.profileSubject.value != profile else { return }
    set(lastLogin: user?.email ?? lastLogin)
    
    let data = try? JSONEncoder().encode(profile)
    defaults.set(data, forKey: Keys.profile)
    self.profileSubject.send(profile)
    objectWillChange.send()
  }
  
  private func set(lastLogin: String?) {
    self.lastLogin = lastLogin
    defaults.set(lastLogin, forKey: Keys.lastLogin)
  }
}
