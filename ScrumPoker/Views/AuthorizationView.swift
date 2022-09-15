//
//  AuthorizationView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct AuthorizationView: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var api: PokerAPI
  
  @State private var email = ""
  @State private var password = ""
  @State private var error: String?
  
  let onRegister: () -> Void
  
  var body: some View {
    VStack(alignment: .center, spacing: 16) {
      if let error = error {
        Spacer(minLength: 40)
        Text(error)
          .fixedSize(horizontal: false, vertical: true)
          .foregroundColor(.red)
          .multilineTextAlignment(.center)
      }
      TextField("Email", text: $email)
        .textContentType(.username)
      SecureField("Password", text: $password)
        .textContentType(.password)
      HStack {
        Button("Exit", action: terminate)
        Button("Register Instead", action: register)
      }
      Button("Sign In", action: login)
    }
    .padding()
    .onAppear {
      email = appState.lastLogin ?? ""
    }
  }
  
  private func login() {
    error = nil
    Task {
      do {
        let token = try await api.authorize(email: email, password: password)
        let user = try await api.myUser()
        appState.set(token: token, user: user)
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func register() {
    onRegister()
  }
  
  private func terminate() {
    exit(0)
  }
}

struct AuthorizationView_Previews: PreviewProvider {
  static var previews: some View {
    AuthorizationView {}
  }
}
