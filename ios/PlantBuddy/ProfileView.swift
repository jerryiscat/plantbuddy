import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isEditingUsername = false
    @State private var isEditingEmail = false
    @State private var updatedUsername = ""
    @State private var updatedEmail = ""
    @State private var notificationsEnabled = true
    @State private var wateringReminderTime = Date()
    @State private var showExportAlert = false
    
    // Mock stats
    @State private var plantsAlive = 5
    @State private var daysStreak = 100
    
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Green Thumb Stats
                    VStack(spacing: 15) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Green Thumb Stats")
                            .font(.title2)
                            .bold()
                        
                        Text("You have kept \(plantsAlive) plants alive for \(daysStreak) days!")
                            .font(.headline)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // User Profile Section
                    if let userProfile = authManager.userProfile {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Profile")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            // Username
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)

                                VStack(alignment: .leading) {
                                    Text("Username")
                                        .font(.headline)
                                        .foregroundColor(.gray)

                                    if isEditingUsername {
                                        TextField(userProfile.username, text: $updatedUsername)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    } else {
                                        Text(userProfile.username)
                                            .font(.title2)
                                            .fontWeight(.medium)
                                    }
                                }
                                Spacer()

                                Button(action: {
                                    if isEditingUsername {
                                        updateUsername()
                                    }
                                    isEditingUsername.toggle()
                                }) {
                                    Image(systemName: isEditingUsername ? "checkmark.circle.fill" : "pencil.circle")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)

                            Divider()

                            // Email
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)

                                VStack(alignment: .leading) {
                                    Text("Email")
                                        .font(.headline)
                                        .foregroundColor(.gray)

                                    if isEditingEmail {
                                        TextField(userProfile.email, text: $updatedEmail)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    } else {
                                        Text(userProfile.email)
                                            .font(.title2)
                                            .fontWeight(.medium)
                                    }
                                }
                                Spacer()

                                Button(action: {
                                    if isEditingEmail {
                                        updateEmail()
                                    }
                                    isEditingEmail.toggle()
                                }) {
                                    Image(systemName: isEditingEmail ? "checkmark.circle.fill" : "pencil.circle")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Preferences Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Preferences")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // Watering Reminder Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Watering Reminder Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $wateringReminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Notification Settings
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Notifications")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Toggle("Push Notifications", isOn: $notificationsEnabled)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Export Data
                    Button(action: {
                        exportData()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Sign Out
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                if let userProfile = authManager.userProfile {
                    updatedUsername = userProfile.username
                    updatedEmail = userProfile.email
                } else {
                    authManager.fetchUserProfile()
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Update Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert("Data Exported", isPresented: $showExportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your plant data has been exported successfully!")
            }
        }
    }

    func updateUsername() {
        let originalUsername = authManager.userProfile?.username ?? ""
        guard !updatedUsername.isEmpty, updatedUsername != originalUsername else {
            updatedUsername = originalUsername
            return
        }

        authManager.updateUserProfile(username: updatedUsername, email: nil) { success, errorMessage in
            if !success {
                alertMessage = errorMessage ?? "Failed to update username."
                showAlert = true
                updatedUsername = originalUsername
            }
        }
    }

    func updateEmail() {
        let originalEmail = authManager.userProfile?.email ?? ""
        guard !updatedEmail.isEmpty, updatedEmail != originalEmail else {
            updatedEmail = originalEmail
            return
        }

        authManager.updateUserProfile(username: nil, email: updatedEmail) { success, errorMessage in
            if !success {
                alertMessage = errorMessage ?? "Failed to update email."
                showAlert = true
                updatedEmail = originalEmail
            }
        }
    }
    
    func exportData() {
        // TODO: Implement actual data export
        // For now, just show success message
        showExportAlert = true
    }
}

#Preview {
    ProfileView().environmentObject(AuthManager())
}
