//
//  Toolbar.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct Toolbar: View {
  
  let userName: String
  let onExit: () -> Void
  let onCreate: () -> Void
  
  var body: some View {
    Text(userName)
      .font(.title)
    Button {
      onExit()
    } label: {
      Image(systemName: "person.crop.circle.fill.badge.minus")
    }
    .help("Logout")
    Spacer()
    Button {
      onCreate()
    } label: {
      Image(systemName: "plus.circle.fill")
    }
    .help("Create new Task")
  }
}
