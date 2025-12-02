import Foundation

class PlantService {
    static let shared = PlantService()
    private let baseURL = "http://192.168.4.23:8000/api"
    
    func fetchPlants(token: String, completion: @escaping (Result<[Plant], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/plants/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "Invalid response", code: -1)))
                return
            }
            
            do {
                let plants = try JSONDecoder().decode([Plant].self, from: data)
                completion(.success(plants))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchGraveyard(token: String, completion: @escaping (Result<[Plant], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/plants/graveyard/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "Invalid response", code: -1)))
                return
            }
            
            do {
                let plants = try JSONDecoder().decode([Plant].self, from: data)
                completion(.success(plants))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func performAction(plantId: Int, actionType: String, notes: String? = nil, imageUrl: String? = nil, token: String, completion: @escaping (Result<ActionResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/plants/\(plantId)/action/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["action_type": actionType]
        if let notes = notes {
            body["notes"] = notes
        }
        if let imageUrl = imageUrl {
            body["image_url"] = imageUrl
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 201 else {
                completion(.failure(NSError(domain: "Invalid response", code: -1)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ActionResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func undoAction(plantId: Int, token: String, completion: @escaping (Result<ActionResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/plants/\(plantId)/undo/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "Invalid response", code: -1)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ActionResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

