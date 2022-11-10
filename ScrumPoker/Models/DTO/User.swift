//
//  User.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation

struct User: Equatable, Codable, Identifiable {
  var userUuid: String
  var email: String
  var name: String
  
  var id: String {
    return userUuid
  }
}
