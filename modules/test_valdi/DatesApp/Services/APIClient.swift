import Foundation

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case networkError(Error)
    case unauthorized
}

struct APIConfig {
    static let baseURL = "http://localhost:8080"
    static var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "access_token") }
    }
    static var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "refresh_token") }
    }
}

struct AuthSession: Codable {
    let user: APIUser
    let tokenType: String
    let accessToken: String
    let refreshToken: String
    let expiresInSec: Int64
    
    enum CodingKeys: String, CodingKey {
        case user
        case tokenType = "token_type"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresInSec = "expires_in"
    }
}

struct APIUser: Codable {
    let id: String
    let email: String
}

struct ErrorResponse: Codable {
    let error: String
}

struct CoupleStatus: Codable {
    let coupleID: String?
    let user1ID: String?
    let user2ID: String?
    let isPaired: Bool
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case coupleID = "couple_id"
        case user1ID = "user1_id"
        case user2ID = "user2_id"
        case isPaired = "is_paired"
        case createdAt = "created_at"
    }
}

struct InvitationResponse: Codable {
    let code: String
    let expiresAt: String
    
    enum CodingKeys: String, CodingKey {
        case code
        case expiresAt = "expires_at"
    }
}

@MainActor
class APIClient {
    static let shared = APIClient()
    
    private init() {}
    
    // MARK: - Auth
    
    func register(email: String, password: String) async throws -> AuthSession {
        let endpoint = "\(APIConfig.baseURL)/api/auth/register"
        let body = ["email": email, "password": password]
        
        let session: AuthSession = try await post(endpoint: endpoint, body: body, authenticated: false)
        APIConfig.accessToken = session.accessToken
        APIConfig.refreshToken = session.refreshToken
        return session
    }
    
    func login(email: String, password: String) async throws -> AuthSession {
        let endpoint = "\(APIConfig.baseURL)/api/auth/login"
        let body = ["email": email, "password": password]
        
        let session: AuthSession = try await post(endpoint: endpoint, body: body, authenticated: false)
        APIConfig.accessToken = session.accessToken
        APIConfig.refreshToken = session.refreshToken
        return session
    }
    
    func logout() async throws {
        guard let refreshToken = APIConfig.refreshToken else {
            throw APIError.unauthorized
        }
        
        let endpoint = "\(APIConfig.baseURL)/api/auth/logout"
        let body = ["refresh_token": refreshToken]
        
        let _: EmptyResponse = try await post(endpoint: endpoint, body: body, authenticated: false)
        APIConfig.accessToken = nil
        APIConfig.refreshToken = nil
    }
    
    // MARK: - Dates
    
    func listDates() async throws -> [DatePlan] {
        let endpoint = "\(APIConfig.baseURL)/api/dates"
        return try await get(endpoint: endpoint)
    }
    
    func createDate(_ plan: DatePlan) async throws -> DatePlan {
        let endpoint = "\(APIConfig.baseURL)/api/dates"
        return try await post(endpoint: endpoint, body: plan, authenticated: true)
    }
    
    func getDate(id: String) async throws -> DatePlan {
        let endpoint = "\(APIConfig.baseURL)/api/dates/\(id)"
        return try await get(endpoint: endpoint)
    }
    
    func updateDate(id: String, _ plan: DatePlan) async throws -> DatePlan {
        let endpoint = "\(APIConfig.baseURL)/api/dates/\(id)"
        return try await put(endpoint: endpoint, body: plan)
    }
    
    func deleteDate(id: String) async throws {
        let endpoint = "\(APIConfig.baseURL)/api/dates/\(id)"
        let _: EmptyResponse = try await delete(endpoint: endpoint)
    }
        // MARK: - Couples
    
    func createInvitation() async throws -> InvitationResponse {
        let endpoint = "\(APIConfig.baseURL)/api/couples/invite"
        return try await post(endpoint: endpoint, body: EmptyBody(), authenticated: true)
    }
    
    func acceptInvitation(code: String) async throws -> CoupleStatus {
        let endpoint = "\(APIConfig.baseURL)/api/couples/accept"
        let body = ["code": code]
        return try await post(endpoint: endpoint, body: body, authenticated: true)
    }
    
    func getCoupleStatus() async throws -> CoupleStatus {
        let endpoint = "\(APIConfig.baseURL)/api/couples/me"
        return try await get(endpoint: endpoint)
    }
        // MARK: - Private Helpers
    
    private func get<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = APIConfig.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return try await performRequest(request)
    }
    
    private func post<T: Encodable, U: Decodable>(
        endpoint: String,
        body: T,
        authenticated: Bool = true
    ) async throws -> U {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if authenticated, let token = APIConfig.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request)
    }
    
    private func put<T: Encodable, U: Decodable>(endpoint: String, body: T) async throws -> U {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = APIConfig.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request)
    }
    
    private func delete<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = APIConfig.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return try await performRequest(request)
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            if httpResponse.statusCode >= 400 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error)
                }
                throw APIError.serverError("Server error: \(httpResponse.statusCode)")
            }
            
            // Handle empty responses (204 No Content)
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// Empty response type for DELETE and other no-content responses
struct EmptyResponse: Codable {
    init() {}
}

// Empty body type for POST requests with no body
struct EmptyBody: Codable {
    init() {}
}
