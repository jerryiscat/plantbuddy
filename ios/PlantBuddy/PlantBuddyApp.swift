import SwiftUI

@main
struct PlantBuddyApp: App {
    @StateObject var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            MainView().environmentObject(authManager)
        }
    }
}
