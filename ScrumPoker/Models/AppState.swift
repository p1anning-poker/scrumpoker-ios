//
//  AppState.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Combine
import Foundation

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
    DispatchQueue.main.async {
      self.objectWillChange.send()
    }
  }
  
  func set(numberOfTasks: Int) {
    numberOfTasksSubject.send(numberOfTasks)
    // TODO: Disabled for push notifications
//    DispatchQueue.main.async {
//      NSApp.dockTile.badgeLabel = numberOfTasks > 0 ? String(numberOfTasks) : nil
//    }
  }
  
  private func set(lastLogin: String?) {
    self.lastLogin = lastLogin
    defaults.set(lastLogin, forKey: Keys.lastLogin)
  }
}

struct AppStateKey: InjectionKey {
  static var currentValue: AppState = AppState.shared
}

extension InjectedValues {
  var appState: AppState {
    get { Self[AppStateKey.self] }
    set { Self[AppStateKey.self] = newValue }
  }
}
