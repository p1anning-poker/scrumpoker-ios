//
//  ErrorView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 05.11.2022.
//

import SwiftUI

struct ErrorView: View {
  var error: String
 
  var body: some View {
    return Text(error)
      .foregroundColor(.red)
  }
}
