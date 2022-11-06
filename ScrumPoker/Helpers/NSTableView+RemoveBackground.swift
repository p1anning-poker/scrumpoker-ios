//
//  NSTableView+RemoveBackground.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import AppKit

extension NSTableView {
  open override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()

    backgroundColor = NSColor.clear
    enclosingScrollView!.drawsBackground = false
  }
}
