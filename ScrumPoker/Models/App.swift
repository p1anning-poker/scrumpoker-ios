//
//  App.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 22.11.2022.
//

import Cocoa

protocol Application {
  func registerForRemoteNotifications()
}

let application: Application = {
  return NSApplication.shared
}()

extension NSApplication: Application {}
