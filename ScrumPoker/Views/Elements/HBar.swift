//
//  HBar.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 26.11.2022.
//

import SwiftUI

struct HBar<Content: View>: View {
  @ViewBuilder
  let content: () -> Content
  
  var body: some View {
    HStack {
      content()
    }
    .frame(height: 40)
  }
}

struct HBar_Previews: PreviewProvider {
  static var previews: some View {
    HBar {
      Text("Text")
      Spacer()
      Text("end")
    }
  }
}
