//
//  NSUIPasteboard.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 24.11.2022.
//

#if os(iOS)
import UIKit
typealias NSUIPasteboard = UIPasteboard
#else
import Cocoa
typealias NSUIPasteboard = NSPasteboard
#endif

extension NSUIPasteboard {
  func setString(_ string: String) {
#if os(iOS)
    self.string = string
#else
    declareTypes([.string], owner: nil)
    setString(string, forType: .string)
#endif
  }
}
