//
//  PublicUser+Sample.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 05.11.2022.
//

import Foundation

extension PublicUser {
  static func sample(id: String = "1") -> PublicUser {
    PublicUser(
      userUuid: id,
      name: "Test user"
    )
  }
}
