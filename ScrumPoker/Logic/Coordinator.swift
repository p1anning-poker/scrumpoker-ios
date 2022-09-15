//
//  Coordinator.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Cocoa
import SwiftUI

final class Coordinator: NSObject, ObservableObject {
  
  enum Content: Equatable {
    case authorization
    case registration
    case myTasks(autoopenTask: ApiTask.ID? = nil)
  }
  
  private let dependencies: Dependencies
  private var content: Content
  
  private let popover = NSPopover()
  
  init(initialContent: Content, dependencies: Dependencies) {
    self.content = initialContent
    self.dependencies = dependencies
    super.init()
    
    popover.contentViewController = controller(for: content)
    NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
      self?.dissmissPopover()
    }
  }
  
  // MARK: - Getters
  
  var isPopoverVisible: Bool {
    return popover.isShown
  }
  
  // MARK: - Actions
  
  func showCurrentContentPopover(aroundButton button: NSStatusBarButton) {
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
  }
  
  func dissmissPopover() {
    popover.performClose(nil)
  }
  
  func set(content: Content) {
    guard self.content != content else { return }
    
    self.content = content
    popover.contentViewController = controller(for: content)
  }
  
  func handle(deeplink: URL, button: NSStatusBarButton) {
    guard let components = URLComponents(url: deeplink, resolvingAgainstBaseURL: false),
          let taskId = components.queryItems?.first(where: { $0.name == "taskId" })?.value else {
      return
    }
    set(content: .myTasks(autoopenTask: taskId))
    if !isPopoverVisible {
      showCurrentContentPopover(aroundButton: button)
    }
  }
}

extension Coordinator {
  
  private func controller(for content: Content) -> NSViewController {
    switch content {
    case .authorization:
      return NSHostingController(
        rootView: AuthorizationView(onRegister: { self.set(content: .registration) })
          .frame(width: 350)
          .environmentObject(dependencies.appState)
          .environmentObject(dependencies.pokerApi)
      )
    case .myTasks(let autoopenTask):
      return NSHostingController(
        rootView: NavigationView {
          MyTasksView(openAtStart: .constant(autoopenTask))
        }
          .navigationViewStyle(DefaultNavigationViewStyle())
          .frame(minWidth: 650)
          .environmentObject(dependencies.pokerApi)
          .environmentObject(dependencies.appState)
      )
    case .registration:
      return NSHostingController(
        rootView: RegistrationView(onSignIn: { self.set(content: .authorization) })
          .frame(width: 350)
          .environmentObject(dependencies.appState)
          .environmentObject(dependencies.pokerApi)
      )
    }
  }
}

extension Coordinator: NSPopoverDelegate {
  
  func popoverWillShow(_ notification: Notification) {
//    popover.contentSize = popover.contentViewController?.preferredContentSize
  }
}
