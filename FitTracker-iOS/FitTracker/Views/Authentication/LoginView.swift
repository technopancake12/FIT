import SwiftUI

struct LoginView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showSignUp = false
    
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
                        Spacer(minLength: 60)
                        
                        // Logo and title
                        VStack(spacing: 16) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("FitTracker")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Track your fitness journey")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Login form
                        VStack(spacing: 20) {
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
                                    .textContentType(.password)
                            }
                            
                            // Error message
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Login button
                            Button(action: signIn) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                            
                            // Forgot password
                            Button("Forgot Password?") {
                                resetPassword()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                        
                        // Sign up link
                        VStack(spacing: 16) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 1)
                                .padding(.horizontal, 32)
                            
                            HStack {
                                Text("Don't have an account?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Button("Sign Up") {
                                    showSignUp = true
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
    }
    
    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await firebaseManager.signIn(email: email, password: password)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        Task {
            do {
                try await firebaseManager.resetPassword(email: email)
                await MainActor.run {
                    errorMessage = "Password reset email sent"
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium))
    }
}

#Preview {
    LoginView()
}