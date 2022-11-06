//
//  List+Divider.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import SwiftUI

extension View {
  func listDivider(yOffset: CGFloat = 4) -> some View {
    background(Divider().offset(y: yOffset), alignment: .bottom)
  }
}
