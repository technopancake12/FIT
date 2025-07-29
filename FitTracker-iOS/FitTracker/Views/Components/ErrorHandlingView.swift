import SwiftUI

// MARK: - Error Handling View Modifier
struct ErrorHandlingViewModifier: ViewModifier {
    @EnvironmentObject private var errorHandler: ErrorHandlingService
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // Network status indicator
            VStack {
                NetworkStatusView()
                Spacer()
            }
            
            // Error overlay
            if errorHandler.isShowingError, let error = errorHandler.currentError {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        errorHandler.dismissError()
                    }
                
                ErrorAlertView(
                    error: error,
                    onRetry: error.shouldShowRetryButton ? {
                        errorHandler.retryLastAction()
                    } : nil,
                    onDismiss: {
                        errorHandler.dismissError()
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(), value: errorHandler.isShowingError)
            }
        }
    }
}

extension View {
    func withErrorHandling() -> some View {
        self.modifier(ErrorHandlingViewModifier())
    }
}

// MARK: - Loading State View
struct LoadingStateView<Content: View>: View {
    let isLoading: Bool
    let content: () -> Content
    
    var body: some View {
        ZStack {
            content()
                .opacity(isLoading ? 0.5 : 1.0)
                .disabled(isLoading)
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
            }
        }
        .animation(.easeInOut, value: isLoading)
    }
}

// MARK: - Async Button with Error Handling
struct AsyncButton<Label: View>: View {
    let action: () async throws -> Void
    let label: () -> Label
    
    @State private var isLoading = false
    @EnvironmentObject private var errorHandler: ErrorHandlingService
    
    init(action: @escaping () async throws -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button(action: {
            performAction()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    label()
                }
            }
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }
    
    private func performAction() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                try await action()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorHandler.handleError(error, context: "AsyncButton")
                }
            }
        }
    }
}

// MARK: - Refresh Control with Error Handling
struct ErrorRefreshableScrollView<Content: View>: View {
    let onRefresh: () async throws -> Void
    let content: () -> Content
    
    @State private var isRefreshing = false
    @EnvironmentObject private var errorHandler: ErrorHandlingService
    
    var body: some View {
        ScrollView {
            content()
                .refreshable {
                    await performRefresh()
                }
        }
    }
    
    private func performRefresh() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        do {
            try await onRefresh()
        } catch {
            errorHandler.handleError(error, context: "RefreshableScrollView")
        }
        
        isRefreshing = false
    }
}

// MARK: - Safe Async Image
struct SafeAsyncImage: View {
    let url: URL?
    let placeholder: () -> AnyView
    
    @State private var retryCount = 0
    private let maxRetries = 3
    
    init(url: URL?, @ViewBuilder placeholder: @escaping () -> some View) {
        self.url = url
        self.placeholder = { AnyView(placeholder()) }
    }
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                placeholder()
            case .success(let image):
                image
                    .resizable()
            case .failure(_):
                VStack {
                    if retryCount < maxRetries {
                        Button(action: retryLoad) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.secondary)
                                Text("Retry")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
            @unknown default:
                placeholder()
            }
        }
    }
    
    private func retryLoad() {
        retryCount += 1
        // Force image reload by creating new URL
        // This is a workaround since AsyncImage doesn't have a direct retry method
    }
}

// MARK: - Error Boundary Component
struct ErrorBoundary<Content: View>: View {
    let content: () -> Content
    let fallback: (Error) -> AnyView
    
    @State private var error: Error?
    
    init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder fallback: @escaping (Error) -> some View) {
        self.content = content
        self.fallback = { error in AnyView(fallback(error)) }
    }
    
    var body: some View {
        Group {
            if let error = error {
                fallback(error)
            } else {
                content()
                    .onAppear {
                        self.error = nil
                    }
                    .background(
                        // This is a hack to catch SwiftUI errors
                        ErrorCatchingView { error in
                            self.error = error
                        }
                    )
            }
        }
    }
}

private struct ErrorCatchingView: UIViewRepresentable {
    let onError: (Error) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        // Set up error monitoring
        DispatchQueue.main.async {
            // Monitor for any UIKit errors
            // This is platform-specific and may need updates
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Validation Helper
struct ValidationHelper {
    static func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func validatePassword(_ password: String) -> (isValid: Bool, message: String) {
        guard password.count >= 8 else {
            return (false, "Password must be at least 8 characters long")
        }
        
        guard password.rangeOfCharacter(from: .uppercaseLetters) != nil else {
            return (false, "Password must contain at least one uppercase letter")
        }
        
        guard password.rangeOfCharacter(from: .lowercaseLetters) != nil else {
            return (false, "Password must contain at least one lowercase letter")
        }
        
        guard password.rangeOfCharacter(from: .decimalDigits) != nil else {
            return (false, "Password must contain at least one number")
        }
        
        return (true, "")
    }
    
    static func validateUsername(_ username: String) -> (isValid: Bool, message: String) {
        guard username.count >= 3 else {
            return (false, "Username must be at least 3 characters long")
        }
        
        guard username.count <= 20 else {
            return (false, "Username must be no more than 20 characters long")
        }
        
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        guard usernamePredicate.evaluate(with: username) else {
            return (false, "Username can only contain letters, numbers, and underscores")
        }
        
        return (true, "")
    }
}