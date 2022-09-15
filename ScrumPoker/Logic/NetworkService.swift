//
//  NetworkService.swift
//  ScrumPoker
//
//  Created by Aleksey Konshin on 15.09.2022.
//

import Foundation

struct NetworkResponse {
  var data: Data
  var code: Int
  var headers: [AnyHashable: Any]
}

final class NetworkService {
  
  private let session = URLSession.shared
  
  func perform(reqeust: URLRequest) async throws -> NetworkResponse {
    let (data, response) = try await session.data(for: reqeust)
    
    let urlResponse = response as! HTTPURLResponse
    print(request: reqeust, response: urlResponse, data: data)
    return NetworkResponse(
      data: data,
      code: urlResponse.statusCode,
      headers: urlResponse.allHeaderFields
    )
  }
  
  private func print(request: URLRequest, response: HTTPURLResponse, data: Data) {
    let requestBody = String(data: request.httpBody ?? Data(), encoding: .utf8)
    let responseBody = String(data: data, encoding: .utf8)
    let text = """
  [\(request.httpMethod ?? "")] \(request.url?.absoluteString ?? "")
  Request body:
  \(requestBody ?? "")
  Response: Status code: \(response.statusCode)
  \(responseBody ?? "")
  """
    Swift.print(text)
  }
}
