//
//  Toolbar.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI

struct Toolbar: View {
  var teamName: String
  
  var body: some View {
    Button {
      NSApp.keyWindow?.firstResponder?.tryToPerform(
        #selector(NSSplitViewController.toggleSidebar(_:)), with: nil
      )
    } label: {
      Label("Toggle sidebar", systemImage: "sidebar.left")
    }
    .help("Logout")
    Text(teamName)
      .font(.title)
  }
}
