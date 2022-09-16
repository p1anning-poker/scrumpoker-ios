//
//  Vote.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation

struct Vote: RawRepresentable, CaseIterable, Decodable, Equatable {
  var rawValue: String
  
  // MARK: - Constants
  
  static let allCases: [Vote] = [
    .zero, .one, .two, .three, .five, .eight, .thirteen, .twentyOne
  ]
  
  static let zero = Vote("VALUE_0")
  static let one = Vote("VALUE_1")
  static let two = Vote("VALUE_2")
  static let three = Vote("VALUE_3")
  static let five = Vote("VALUE_5")
  static let eight = Vote("VALUE_8")
  static let thirteen = Vote("VALUE_13")
  static let twentyOne = Vote("VALUE_21")
  
  // MARK: - Lifecycle
  
  init?(rawValue: String) {
    self.rawValue = rawValue
  }
  
  init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  
  // MARK: - Getters
  
  var name: String {
    switch self {
    case .zero:
      return "0"
    case .one:
      return "1"
    case .two:
      return "2"
    case .three:
      return "3"
    case .five:
      return "5"
    case .eight:
      return "8"
    case .thirteen:
      return "13"
    case .twentyOne:
      return "21"
    default:
      return rawValue
    }
  }
}

extension Vote: Identifiable {
  
  var id: String {
    return rawValue
  }
}
