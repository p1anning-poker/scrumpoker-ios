//
//  Profile.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 18.09.2022.
//

import Foundation

struct Profile: Codable, Equatable {
  var token: Token
  var user: User
}
