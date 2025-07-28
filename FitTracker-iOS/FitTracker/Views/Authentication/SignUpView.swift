import SwiftUI

struct SignUpView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.15, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill.badge.plus")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Join the FitTracker community")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 40)
                        
                        // Sign up form
                        VStack(spacing: 20) {
                            // Display name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Display Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                TextField("Enter your name", text: $displayName)
                                    .textFieldStyle(ModernTextFieldStyle())
                                    .textContentType(.name)
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(ModernTextFieldStyle())
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(ModernTextFieldStyle())
                                    .textContentType(.newPassword)
                            }
                            
                            // Confirm password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(ModernTextFieldStyle())
                                    .textContentType(.newPassword)
                            }
                            
                            // Password requirements
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password must contain:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                HStack {
                                    Image(systemName: password.count >= 6 ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(password.count >= 6 ? .green : .white.opacity(0.5))
                                    Text("At least 6 characters")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                }
                                
                                HStack {
                                    Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(passwordsMatch ? .green : .white.opacity(0.5))
                                    Text("Passwords match")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 8)
                            
                            // Error message
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Sign up button
                            Button(action: signUp) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Create Account")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var passwordsMatch: Bool {
        !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
    
    private var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        passwordsMatch
    }
    
    private func signUp() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await firebaseManager.signUp(email: email, password: password, displayName: displayName)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SignUpView()
}