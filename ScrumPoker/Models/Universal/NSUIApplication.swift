//
//  App.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 22.11.2022.
//

import SwiftUI

#if os(iOS)
import UIKit
typealias NSUIApplication = UIApplication
typealias NSUIApplicationDelegate = UIApplicationDelegate
typealias NSUIApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
#else
import Cocoa
typealias NSUIApplication = NSApplication
typealias NSUIApplicationDelegate = NSApplicationDelegate
typealias NSUIApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
#endif
