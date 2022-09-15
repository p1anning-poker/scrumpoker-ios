//
//  RegistrationView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct RegistrationView: View {
  @EnvironmentObject private var api: PokerAPI
  @EnvironmentObject private var appState: AppState
  
  @State private var error: String?
  @State private var email = ""
  @State private var name = ""
  @State private var password = ""
  let onSignIn: () -> Void
  
  var body: some View {
    VStack {
      if let error = error {
        Text(error)
          .foregroundColor(.red)
          .fixedSize(horizontal: false, vertical: true)
      }
      
    }
    .padding()
  }
  
  private func register() {
    error = nil
    Task {
      do {
        let token = try await api.register(email: email, name: name, password: password)
        let user = User(email: email, name: name)
        appState.set(token: token, user: user)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func login() {
    onSignIn()
  }
  
  private func terminate() {
    exit(0)
  }
}

struct RegistrationView_Previews: PreviewProvider {
  static var previews: some View {
    RegistrationView {}
  }
}
