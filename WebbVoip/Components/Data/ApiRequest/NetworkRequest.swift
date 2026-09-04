import Foundation

/// A simple class to do network request
protocol NetworkRequest {
    /// Redefine this variable with the headers you want to send
    var sendingHeaders: [String: String] { get }

    /// the URL to send the request to
    var url: URL { get set }
}

extension NetworkRequest {
    /// Send a GET request, override if you need to do other requests
    /// - Parameter _: the expected contenttype of the document *unused for now
    /// - Parameter body: the HTTP request''s body
    /// - Parameter httpRequestMethod: the method of sending i.e. GET, POST
    /// - Returns: Data object of the returned response body
    func sendRequest(expectedContentType _: String? = nil, body: String? = nil, httpRequestMethod: String = "GET") async throws -> Data {
        var request = URLRequest(url: url)
        for (key, value) in sendingHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpMethod = httpRequestMethod

        if let body {
            request.httpBody = body.data(using: .utf8)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard
            let response = response as? HTTPURLResponse,
            (200 ... 299).contains(response.statusCode)
        else {
            throw GeneralError.runtimeError("Server returned non 200 exits")
        }

        return data
    }
}
