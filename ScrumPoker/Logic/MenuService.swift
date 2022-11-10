//
//  MenuService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Cocoa
import Combine

final class MenuService: NSObject {
  private let appState: AppState
  /// Инстанс статус бара osx
  private let statusBar: NSStatusBar
  /// Инстанс итема приложения в баре osx
  let statusItem: NSStatusItem
  private var cancellables = Set<AnyCancellable>()
  
  init(statusBar: NSStatusBar, appState: AppState) {
    self.statusBar = statusBar
    statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
    self.appState = appState
    
    super.init()
    
    setup()
  }
  
  //MARK: - Actions
  
  private func setup() {
    if let button = statusItem.button {
      button.target = self
      button.action = #selector(tapToItem(button:))
      button.image = NSImage(named: "menu_bg")
      button.integerValue = -1
    }
    
    appState.numberOfTasks
      .sink { number in
        self.setNumberOfTasks(number)
      }
      .store(in: &cancellables)
  }
  
  @objc func tapToItem(button: NSStatusBarButton) {
    NSApp.orderedWindows.first?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
  
  /// Отображает количество реквестов на статус баре
  private func setNumberOfTasks(_ number: Int) {
    guard statusItem.button?.integerValue != number else { return }
    statusItem.button?.integerValue = number
    let text: String
    if number > 0 {
      text = String(number)
    } else {
      text = "✔"
    }
    let title = NSAttributedString(
      string: text,
      attributes: [
        .font: NSFont.menuBarFont(ofSize: 16),
        .baselineOffset: -1
      ]
    )
    statusItem.button?.attributedTitle = title
  }
}
