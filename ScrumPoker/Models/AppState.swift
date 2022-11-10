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

final class AppState: ObservableObject {
  /// Current User
  private let profileSubject = CurrentValueSubject<Profile?, Never>(nil)
  private let numberOfTasksSubject = CurrentValueSubject<Int, Never>(0)
  
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
    return numberOfTasksSubject
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
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
  
  func set(profile: Profile?) {
    guard self.profileSubject.value != profile else { return }
    set(lastLogin: profile?.user.email ?? lastLogin)
    
    let data = try? JSONEncoder().encode(profile)
    defaults.set(data, forKey: Keys.profile)
    self.profileSubject.send(profile)
    objectWillChange.send()
  }
  
  func set(numberOfTasks: Int) {
    numberOfTasksSubject.send(numberOfTasks)
  }
  
  private func set(lastLogin: String?) {
    self.lastLogin = lastLogin
    defaults.set(lastLogin, forKey: Keys.lastLogin)
  }
}
