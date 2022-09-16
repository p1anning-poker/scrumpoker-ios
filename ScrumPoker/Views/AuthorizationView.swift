//
//  AuthorizationView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct AuthorizationView: View {
  enum Content {
    case authorization
    case registration
  }
  
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var api: PokerAPI
  
  @State private(set) var content: Content
  @State private var email = ""
  @State private var password = ""
  @State private var name = ""
  @State private var error: String?
  
  let onAuthorize: () -> Void
  
  var body: some View {
    VStack(alignment: .center, spacing: 16) {
      if let error = error {
        Text(error)
          .fixedSize(horizontal: false, vertical: true)
          .foregroundColor(.red)
          .multilineTextAlignment(.center)
      }
      switch content {
      case .authorization:
        authorizationView()
      case .registration:
        registrationView()
      }
    }
    .padding()
    .onAppear {
      if content == .authorization {
        email = appState.lastLogin ?? ""
      }
    }
  }
  
  @ViewBuilder
  private func authorizationView() -> some View {
    TextField("Email", text: $email)
      .textContentType(.username)
    SecureField("Password", text: $password)
      .textContentType(.password)
    HStack {
      Button("Exit", action: terminate)
      Button("Register Instead") {
        update(content: .registration)
      }
    }
    Button("Sign In", action: login)
      .disabled(email.isEmpty || password.isEmpty)
  }
  
  @ViewBuilder
  private func registrationView() -> some View {
    TextField("Email", text: $email)
      .textContentType(.username)
    TextField("Name", text: $name)
    SecureField("Password", text: $password)
      .textContentType(.password)
    HStack {
      Button("Exit", action: terminate)
      Button("Sign In Instead") {
        update(content: .authorization)
      }
    }
    Button("Register", action: register)
      .disabled(email.isEmpty || password.isEmpty || name.isEmpty)
  }
  
  private func login() {
    error = nil
    Task {
      do {
        let token = try await api.authorize(email: email, password: password)
        let user = try await api.myUser()
        appState.set(token: token, user: user)
        onAuthorize()
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func register() {
    error = nil
    Task {
      do {
        let token = try await api.register(email: email, name: name, password: password)
        let user = User(email: email, name: name)
        appState.set(token: token, user: user)
        onAuthorize()
      } catch {
        self.error = error.localizedDescription
      }
    }
  }
  
  private func update(content: Content) {
    withAnimation {
      self.content = content
    }
  }
  
  private func terminate() {
    exit(0)
  }
}

struct AuthorizationView_Previews: PreviewProvider {
  static var previews: some View {
    AuthorizationView(content: .authorization) {
      
    }
  }
}
