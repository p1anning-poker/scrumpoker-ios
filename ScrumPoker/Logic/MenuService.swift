//
//  MenuService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Cocoa
import Combine

final class MenuService: NSObject {
  private let coordinator: Coordinator
  private let appState: AppState
  /// Инстанс статус бара osx
  private let statusBar: NSStatusBar
  /// Инстанс итема приложения в баре osx
  let statusItem: NSStatusItem
  private var cancellables = Set<AnyCancellable>()
  
  init(statusBar: NSStatusBar, coordinator: Coordinator, appState: AppState) {
    self.statusBar = statusBar
    statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
    self.coordinator = coordinator
    self.appState = appState
    
    super.init()
    
    setup()
  }
  
  //MARK: - Actions
  
  private func setup() {
    if let button = statusItem.button {
      button.target = self
      button.action = #selector(tapToItem(button:))
    }
    
    appState.numberOfTasks
      .sink { number in
        self.setNumberOfTasks(number)
      }
      .store(in: &cancellables)
  }
  
  @objc func tapToItem(button: NSStatusBarButton) {
    togglePopover(button: button)
  }
  
  func togglePopover(button: NSStatusBarButton) {
    if coordinator.isPopoverVisible {
      coordinator.dissmissPopover()
    } else {
      coordinator.showCurrentContentPopover(aroundButton: button)
    }
  }
  /// Отображает количество реквестов на статус баре
  private func setNumberOfTasks(_ number: Int) {
    statusItem.button?.image = NSImage(named: "unnamed")
  }
}
