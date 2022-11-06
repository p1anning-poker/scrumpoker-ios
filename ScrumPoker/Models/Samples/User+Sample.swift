//
//  User+Sample.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import Foundation

extension User {
  static func sample() -> User {
    return User(
      userUuid: "1",
      email: "test@user.com",
      name: "TestUser"
    )
  }
}
