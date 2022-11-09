//
//  View+Helpers.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 08.11.2022.
//

import SwiftUI

extension View {
  @ViewBuilder func onWidthChange(_ action: @escaping (CGFloat) -> Void) -> some View {
    self
      .background(
        GeometryReader { reader in
          Color.clear
            .onChange(of: reader.frame(in: .global).width) { newValue in
              action(newValue)
            }
        }
      )
  }
}
