import Foundation

class TaskService {
    static let shared = TaskService()
    private let baseURL = "http://192.168.4.23:8000/api"
    
    func fetchTodayTasks(token: String, completion: @escaping (Result<[Task], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/tasks/today/") else {
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
                let tasks = try JSONDecoder().decode([Task].self, from: data)
                completion(.success(tasks))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

