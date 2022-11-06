//
//  SideBar.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import SwiftUI

struct SideBar<T: View>: View {
  var profile: User
  let onLogout: () -> Void
  let content: () -> T
  
  var body: some View {
    VStack {
      profileView()
        .frame(maxWidth: .infinity)
      content()
        .frame(maxWidth: .infinity)
    }
    .frame(maxWidth: .infinity)
  }
  
  @ViewBuilder
  private func profileView() -> some View {
    HStack {
      Image(systemName: "person.crop.circle")
        .font(.largeTitle)
      VStack(alignment: .leading, spacing: 2) {
        Text(profile.name)
          .font(.title)
        Button(action: onLogout) {
          Text("Sign Out")
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(Color.white)
    .cornerRadius(16)
    .padding()
  }
}

struct SideBar_Previews: PreviewProvider {
  static var previews: some View {
    SideBar(profile: .sample()) {
      
    } content: {
      Text("Content")
    }
    .previewLayout(PreviewLayout.fixed(width: 300, height: 300))
  }
}