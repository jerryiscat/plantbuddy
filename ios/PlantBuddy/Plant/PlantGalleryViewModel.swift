import SwiftUI

class PlantGalleryViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = "http://192.168.4.23:8000/api"
    
    func fetchPlants(token: String) {
        guard let url = URL(string: "\(baseURL)/plants/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        isLoading = true
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load plants."
                }
                return
            }

            do {
                let decodedPlants = try JSONDecoder().decode([Plant].self, from: data)
                DispatchQueue.main.async {
                    self.plants = decodedPlants
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error decoding data."
                }
            }
        }.resume()
    }
}
