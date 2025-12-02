import SwiftUI

struct PlantGalleryView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = PlantGalleryViewModel()
    
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]

    var body: some View {
        VStack {
            Text("Plant Gallery")
                .font(.largeTitle)
                .bold()
                .padding()

            if viewModel.isLoading {
                ProgressView("Loading Plants...")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.plants.isEmpty {
                Text("No plants found.")
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(viewModel.plants) { plant in
                            PlantCardView(plant: plant)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if let token = authManager.token {
                viewModel.fetchPlants(token: token)
            }
        }
    }
}

#Preview {
    PlantGalleryView()
        .environmentObject(AuthManager())
}
