//
//  VotesChart.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 10.11.2022.
//

import SwiftUI
import Charts

@available(macOS 13.0, *)
struct VotesChart: View {
  @State var data: Data
  
  var body: some View {
    Chart {
      ForEach(data.stat, id: \.vote) { stat in
        PointMark(
          x: .value("Vote", stat.vote),
          y: .value("Users", stat.users.count))
      }
    }
  }
}

@available(macOS 13.0, *)
extension VotesChart {
  struct VoteStat {
    let vote: String
    let users: [String]
  }
  struct Data {
    var stat: [VoteStat]
  }
}

@available(macOS 13.0, *)
struct VotesChart_Previews: PreviewProvider {
  static var previews: some View {
    let data = VotesChart.Data(
      stat: [
        .init(
          vote: "1",
          users: [
            "Pavel",
            "Anna"
          ]
        ),
        .init(
          vote: "3",
          users: [
            "Denis",
            "Elizaveta",
            "Dmitry"
          ]
        ),
        .init(
          vote: "8",
          users: [
            "Anton",
          ]
        )
      ]
    )
    
    VotesChart(data: data)
  }
}
