//
//  TasksFilter.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 06.11.2022.
//

import Foundation

struct TasksFilter: Hashable {
  var completed: Bool
  var searchText: String = ""
}
