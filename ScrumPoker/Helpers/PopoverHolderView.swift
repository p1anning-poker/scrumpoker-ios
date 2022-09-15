//
//  PopoverHolderView.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import SwiftUI
import Cocoa

//struct NSPopoverHolderView<T: View>: NSViewRepresentable {
//  @Binding var isVisible: Bool
//  var content: () -> T
//  let relativeTo: NSView
//  
//  func makeNSView(context: Context) -> NSView {
//    NSView()
//  }
//  
//  func updateNSView(_ nsView: NSView, context: Context) {
//    context.coordinator.setVisible(isVisible, in: nsView)
//  }
//  
//  func makeCoordinator() -> Coordinator {
//    Coordinator(state: _isVisible, content: content)
//  }
//  
//  class Coordinator: NSObject, NSPopoverDelegate {
//    private let popover: NSPopover
//    private let state: Binding<Bool>
//    
//    init<V: View>(state: Binding<Bool>, content: @escaping () -> V) {
//      self.popover = NSPopover()
//      self.state = state
//      
//      super.init()
//      
//      popover.delegate = self
//      popover.contentViewController = NSHostingController(rootView: content())
//      popover.behavior = .transient
//    }
//    
//    func setVisible(_ isVisible: Bool, in view: NSView) {
//      if isVisible {
//        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
//      } else {
//        popover.close()
//      }
//    }
//    
//    func popoverDidClose(_ notification: Notification) {
//      self.state.wrappedValue = false
//    }
//    
//    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
//      true
//    }
//  }
//}
