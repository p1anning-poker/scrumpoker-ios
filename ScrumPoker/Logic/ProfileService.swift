//
//  ProfileService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 18.09.2022.
//

import Foundation

final class ProfileService: ObservableObject {
  
  private let api: PokerAPI
  private let appState: AppState
  
  init(api: PokerAPI, appState: AppState) {
    self.api = api
    self.appState = appState
  }
}

extension ProfileService {
  
  func authorize(email: String, password: String) async throws {
    let token = try await api.authorize(email: email, password: password)
    let user = try await api.myUser()
    appState.set(profile: Profile(token: token, user: user))
  }
  
  func register(email: String, userName: String, password: String) async throws {
    let token = try await api.register(
      email: email,
      name: userName,
      password: password
    )
    let user = try await api.myUser()
    appState.set(profile: Profile(token: token, user: user))
  }
  
  func logout() async {
    appState.set(profile: nil)
    appState.set(numberOfTasks: 0)
  }
}

struct ProfileServiceKey: InjectionKey {
    static var currentValue: ProfileService = ProfileService(
      api: InjectedValues[\.pokerApi],
      appState: InjectedValues[\.appState]
    )
}

extension InjectedValues {
  var profileService: ProfileService {
    get { Self[ProfileServiceKey.self] }
    set { Self[ProfileServiceKey.self] = newValue }
  }
}
