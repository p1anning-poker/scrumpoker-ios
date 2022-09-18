//
//  User.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation

struct User: Equatable, Codable {
  var userUuid: String
  var email: String
  var name: String
}
