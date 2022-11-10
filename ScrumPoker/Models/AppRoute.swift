//
//  AppRoute.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 10.11.2022.
//

import Foundation

enum AppRoute {
  case taskDetails(taskId: ApiTask.ID, teamId: Team.ID)
}
