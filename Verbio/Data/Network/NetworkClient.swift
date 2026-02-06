//
//  NetworkClient.swift
//  Verbio
//
//  URLSession-based network client with JWT authentication
//

import Foundation

// MARK: - Network Client Protocol

protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable?,
        responseType: T.Type
    ) async throws -> T

    func request(
        endpoint: APIEndpoint,
        body: Encodable?
    ) async throws
}

// MARK: - Network Client Implementation

actor NetworkClient: NetworkClientProtocol {

    // MARK: - Properties

    private let session: URLSession
    private let configuration: AppConfiguration
    private let keychainService: KeychainServiceProtocol
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private var isRefreshingToken = false
    private var pendingRequests: [CheckedContinuation<Void, Error>] = []

    // MARK: - Initialization

    init(
        configuration: AppConfiguration = .shared,
        keychainService: KeychainServiceProtocol
    ) {
        self.configuration = configuration
        self.keychainService = keychainService

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.apiTimeout
        sessionConfig.timeoutIntervalForResource = configuration.uploadTimeout
        self.session = URLSession(configuration: sessionConfig)

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            // Try ISO8601 with fractional seconds first (Prisma format)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) { return date }
            // Fall back to standard ISO8601
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }

        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Public Methods

    func request<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        responseType: T.Type
    ) async throws -> T {
        let data = try await performRequest(endpoint: endpoint, body: body)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(reason: error.localizedDescription)
        }
    }

    func request(
        endpoint: APIEndpoint,
        body: Encodable? = nil
    ) async throws {
        _ = try await performRequest(endpoint: endpoint, body: body)
    }

    // MARK: - Private Methods

    private func performRequest(
        endpoint: APIEndpoint,
        body: Encodable?,
        retryCount: Int = 0
    ) async throws -> Data {
        // Build request
        var request = try buildRequest(endpoint: endpoint, body: body)

        // Add auth header if required
        if endpoint.requiresAuth {
            // Wait if token refresh is in progress
            if isRefreshingToken {
                try await waitForTokenRefresh()
            }

            if let accessToken = try? keychainService.loadString(for: .accessToken) {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
        }

        // Perform request
        let (data, response) = try await performURLRequest(request)

        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // Handle success
        if (200...299).contains(httpResponse.statusCode) {
            return data
        }

        // Handle 401 with token refresh
        if httpResponse.statusCode == 401 && endpoint.requiresAuth && retryCount < 1 {
            try await refreshAccessToken()
            return try await performRequest(endpoint: endpoint, body: body, retryCount: retryCount + 1)
        }

        // Parse error message from response
        let errorMessage = parseErrorMessage(from: data)
        throw NetworkError.from(statusCode: httpResponse.statusCode, message: errorMessage)
    }

    private func buildRequest(endpoint: APIEndpoint, body: Encodable?) throws -> URLRequest {
        let url = configuration.apiURL(for: endpoint.path)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(configuration.appVersion, forHTTPHeaderField: "X-App-Version")

        // Add custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body
        if let body = body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw NetworkError.encodingFailed(reason: error.localizedDescription)
            }
        }

        return request
    }

    private func performURLRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            throw NetworkError.from(urlError: error)
        } catch {
            throw NetworkError.unknown(reason: error.localizedDescription)
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let message: String?
            let error: String?
        }

        guard let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) else {
            return nil
        }

        return errorResponse.message ?? errorResponse.error
    }

    // MARK: - Token Refresh

    private func refreshAccessToken() async throws {
        // Prevent multiple concurrent refresh attempts
        if isRefreshingToken {
            try await waitForTokenRefresh()
            return
        }

        isRefreshingToken = true
        defer {
            isRefreshingToken = false
            resumePendingRequests()
        }

        guard let refreshToken = try? keychainService.loadString(for: .refreshToken) else {
            throw NetworkError.unauthorized
        }

        struct RefreshRequest: Encodable {
            let refreshToken: String
        }

        struct RefreshResponse: Decodable {
            let accessToken: String
            let refreshToken: String
            let expiresIn: Int
        }

        let body = RefreshRequest(refreshToken: refreshToken)
        var request = try buildRequest(endpoint: AuthEndpoint.refreshToken, body: body)
        request.setValue(nil, forHTTPHeaderField: "Authorization") // No auth for refresh

        let (data, response) = try await performURLRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Clear tokens on refresh failure
            try? keychainService.clear()
            throw NetworkError.unauthorized
        }

        let refreshResponse = try decoder.decode(RefreshResponse.self, from: data)

        // Store new tokens
        try keychainService.save(refreshResponse.accessToken, for: .accessToken)
        try keychainService.save(refreshResponse.refreshToken, for: .refreshToken)
    }

    private func waitForTokenRefresh() async throws {
        try await withCheckedThrowingContinuation { continuation in
            pendingRequests.append(continuation)
        }
    }

    private func resumePendingRequests() {
        let requests = pendingRequests
        pendingRequests.removeAll()
        for continuation in requests {
            continuation.resume()
        }
    }
}

// MARK: - Any Encodable Wrapper

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: Encodable) {
        self.encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

// MARK: - Convenience Extensions

extension NetworkClientProtocol {
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        try await request(endpoint: endpoint, body: nil, responseType: responseType)
    }

    func request(endpoint: APIEndpoint) async throws {
        try await request(endpoint: endpoint, body: nil)
    }
}
