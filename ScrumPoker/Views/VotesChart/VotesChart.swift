//
//  VotesChart.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 10.11.2022.
//

import SwiftUI
import Charts

@available(macOS 13.0, iOS 16.0, *)
struct VotesChart: View {
  var data: Data
  @State private var displayUsers: [String]?
  
  var body: some View {
    Chart {
      ForEach(data.stat, id: \.vote) { stat in
        BarMark(
          x: .value("Users", stat.users.count),
          y: .value("Vote", "\(stat.vote) SP")
        )
        .annotation(position: .automatic, alignment: .trailing) {
          annotation(users: stat.users)
        }
      }
    }
    .foregroundColor(.accentColor)
    .chartXAxisLabel("Voted users", position: .trailing)
    .frame(minHeight: CGFloat(data.stat.count) * 40)
  }
  
  @ViewBuilder
  private func annotation(users: [String]) -> some View {
    let text = users.joined(separator: ",")
    Text(text)
      .font(.caption2)
  }
}

@available(macOS 13.0, iOS 16.0, *)
extension VotesChart {
  struct VoteStat {
    let vote: String
    let users: [String]
  }
  struct Data {
    var stat: [VoteStat]
  }
}

@available(macOS 13.0, iOS 16.0, *)
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
          vote: "2",
          users: [
            "Denis Dazhin",
            "Elizaveta Petrovna",
            "Dmitry Swarowski",
            "Stas Mikhailov"
          ]
        ),
        .init(
          vote: "3",
          users: [
            "Anton",
          ]
        )
      ]
    )
    
    VotesChart(data: data)
      .padding()
      .frame(width: 300)
  }
}
