//
//  SearchBar.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 27.11.2022.
//

import SwiftUI
import Combine

private final class DebounceObject: ObservableObject {
  @Published var text: String = ""
  @Binding var debouncedText: String
  private var bag = Set<AnyCancellable>()
  
  public init(dueTime: TimeInterval = 0.5, text: Binding<String>) {
    self._debouncedText = text
    $text
      .removeDuplicates()
      .debounce(for: .seconds(dueTime), scheduler: DispatchQueue.main)
      .sink(receiveValue: { [weak self] value in
        self?.debouncedText = value
      })
      .store(in: &bag)
  }
}

struct SearchBar: View {
  @StateObject private var debounceObject: DebounceObject
  let placeholder: String
  
  init(text: Binding<String>, placeholder: String, debounceInterval: TimeInterval) {
    _debounceObject = StateObject(
      wrappedValue: DebounceObject(
        dueTime: debounceInterval,
        text: text
      )
    )
    self.placeholder = placeholder
  }
  
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
      TextField(placeholder, text: $debounceObject.text)
        .textFieldStyle(PlainTextFieldStyle())
    }
    .padding([.leading, .trailing], 8)
    .frame(height: 24)
    .background(Color(.controlBackgroundColor))
    .cornerRadius(8)
    .overlay {
      RoundedRectangle(cornerSize: CGSize(width: 8, height: 8))
        .stroke(Color(.separatorColor), lineWidth: 1)
    }
  }
}

struct SearchBar_Previews: PreviewProvider {
  static var previews: some View {
    SearchBar(text: .constant(""), placeholder: "Search it!", debounceInterval: 0.5)
      .background(Color.orange)
  }
}
