import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isCheckingAuth = true

    var body: some View {
        Group {
            if isCheckingAuth {
                ProgressView("Loading...")
                    .onAppear {
                        // Small delay to ensure AuthManager is initialized
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isCheckingAuth = false
                        }
                    }
            } else if authManager.isAuthenticated {
                ContentView()
            } else {
                AuthView()
            }
        }
    }
}

#Preview {
    MainView().environmentObject(AuthManager())
}
