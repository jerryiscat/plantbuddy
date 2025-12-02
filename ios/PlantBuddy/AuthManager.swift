import Foundation

struct UserProfile: Codable {
    let id: Int
    let username: String
    let email: String
}

class AuthManager: ObservableObject {
    @Published var userProfile: UserProfile? {
        didSet {
            if let userProfile = userProfile {
                if let encoded = try? JSONEncoder().encode(userProfile) {
                    UserDefaults.standard.set(encoded, forKey: "userProfile")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "userProfile")
            }
        }
    }

    var token: String? {
        get {
            guard let data = KeychainHelper.shared.retrieve(service: "auth", account: "token"),
                  let token = String(data: data, encoding: .utf8) else { return nil }
            return token
        }
        set {
            if let token = newValue {
                KeychainHelper.shared.save(token.data(using: .utf8)!, service: "auth", account: "token")
            } else {
                KeychainHelper.shared.delete(service: "auth", account: "token")
            }
        }
    }

    var isAuthenticated: Bool {
        return token != nil && userProfile != nil
    }

    @Published var errorMessage: String?
    
    init() {
        // Load user profile from UserDefaults on initialization
        loadUserProfile()
        
        // If we have a token but no profile, try to fetch it
        // If we have both, verify by attempting to fetch (will fail if token expired)
        if token != nil {
            if userProfile == nil {
                // We have a token but no profile - fetch it
                fetchUserProfile()
            } else {
                // We have both - verify token is still valid by fetching profile
                // This will automatically sign out if token is expired (401 response)
                fetchUserProfile()
            }
        }
    }
    
    private func loadUserProfile() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = profile
        }
    }
    
    // Base URL for API - change this to your Mac's IP if using physical device
    private let baseURL = "http://192.168.4.23:8000/api"
    
    func signUp(username: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "\(baseURL)/users/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "username": username,
            "email": email,
            "password": password
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Network error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "Invalid response from server")
                }
                return
            }
            
            if httpResponse.statusCode == 201 {
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } else {
                // Parse error message
                var errorMsg = "Sign up failed. Please try again."
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // Check for email duplicate
                        if let emailErrors = json["email"] as? [String], !emailErrors.isEmpty {
                            if emailErrors[0].contains("already exists") {
                                errorMsg = "An account with this email already exists."
                            } else {
                                errorMsg = emailErrors[0]
                            }
                        }
                        // Check for password errors
                        else if let passwordErrors = json["password"] as? [String], !passwordErrors.isEmpty {
                            errorMsg = passwordErrors.joined(separator: " ")
                        }
                        // Check for username errors
                        else if let usernameErrors = json["username"] as? [String], !usernameErrors.isEmpty {
                            errorMsg = usernameErrors[0]
                        }
                        // Check for non-field errors
                        else if let nonFieldErrors = json["non_field_errors"] as? [String], !nonFieldErrors.isEmpty {
                            errorMsg = nonFieldErrors[0]
                        }
                        // Generic error message
                        else if let error = json["error"] as? String {
                            errorMsg = error
                        }
                    }
                }
                DispatchQueue.main.async {
                    completion(false, errorMsg)
                }
            }
        }.resume()
    }

    func signIn(username: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "\(baseURL)/token/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "username": username,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error encoding JSON: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(false, "Error encoding request: \(error.localizedDescription)")
            }
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Network error: \(error.localizedDescription)")
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "Invalid response from server")
                }
                return
            }

            if httpResponse.statusCode == 200 {
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(false, "No data received")
                    }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let authToken = json["access"] as? String {
                        DispatchQueue.main.async {
                            self.token = authToken
                            self.fetchUserProfile()
                            completion(true, nil)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(false, "Invalid response format")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(false, "Error parsing response")
                    }
                }
            } else {
                // Handle authentication errors
                var errorMsg = "Invalid username or password. Please try again."
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let detail = json["detail"] as? String {
                            errorMsg = detail
                        } else if let error = json["error"] as? String {
                            errorMsg = error
                        }
                    }
                }
                DispatchQueue.main.async {
                    completion(false, errorMsg)
                }
            }
        }.resume()
    }
    
    func requestPasswordReset(email: String, completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "\(baseURL)/password-reset/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Network error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "Invalid response from server")
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                var message = "Password reset link sent to your email."
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["message"] as? String {
                    message = msg
                }
                DispatchQueue.main.async {
                    completion(true, message)
                }
            } else {
                var errorMsg = "Failed to send password reset email."
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String {
                    errorMsg = error
                }
                DispatchQueue.main.async {
                    completion(false, errorMsg)
                }
            }
        }.resume()
    }


    func fetchUserProfile() {
        guard let token = token else { return }

        let url = URL(string: "\(baseURL)/users/me/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else { return }
            
            if httpResponse.statusCode == 401 {
                // Token expired or invalid - clear everything
                DispatchQueue.main.async {
                    self.signOut()
                }
                return
            }

            guard let data = data, httpResponse.statusCode == 200 else { return }

            if let userProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                DispatchQueue.main.async {
                    self.userProfile = userProfile
                }
            }
        }.resume()
    }
    
    func signOut() {
        token = nil
        userProfile = nil
    }
    
    func updateUserProfile(username: String?, email: String?, completion: @escaping (Bool, String?) -> Void) {
        guard let token = token else {
            completion(false, "You are not logged in.")
            return
        }

        let url = URL(string: "\(baseURL)/users/me/")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [:]
        if let username = username { body["username"] = username }
        if let email = email { body["email"] = email }

        guard !body.isEmpty else {
            completion(false, "Nothing to update.")
            return
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "No response from server.")
                }
                return
            }

            if httpResponse.statusCode == 200 {
                if let updatedUser = try? JSONDecoder().decode(UserProfile.self, from: data) {
                    DispatchQueue.main.async {
                        self.userProfile = updatedUser
                        completion(true, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false, "Failed to decode response.")
                    }
                }
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error."
                DispatchQueue.main.async {
                    completion(false, "Error: \(errorMessage)")
                }
            }
        }.resume()
    }





}
