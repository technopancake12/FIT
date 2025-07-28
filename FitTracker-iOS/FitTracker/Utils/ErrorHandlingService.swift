import Foundation
import SwiftUI
import Network

class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published var currentError: AppError?
    @Published var isShowingError = false
    @Published var isNetworkAvailable = true
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var retryAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Error Handling
    func handleError(_ error: Error, context: String = "", shouldRetry: Bool = false, retryAction: (() async throws -> Void)? = nil) {
        let appError = mapToAppError(error, context: context)
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.isShowingError = true
        }
        
        // Log error for debugging
        logError(appError, context: context)
        
        // Attempt automatic retry for certain error types
        if shouldRetry, let retryAction = retryAction {
            attemptRetry(for: context, action: retryAction)
        }
    }
    
    private func mapToAppError(_ error: Error, context: String) -> AppError {
        switch error {
        case let appError as AppError:
            return appError
            
        case let nsError as NSError where nsError.domain == NSURLErrorDomain:
            return mapNetworkError(nsError)
            
        case let firestoreError where firestoreError.localizedDescription.contains("PERMISSION_DENIED"):
            return .unauthorized("You don't have permission to perform this action")
            
        case let firestoreError where firestoreError.localizedDescription.contains("UNAVAILABLE"):
            return .networkUnavailable("Service temporarily unavailable. Please try again.")
            
        case let firestoreError where firestoreError.localizedDescription.contains("DEADLINE_EXCEEDED"):
            return .timeout("Request timed out. Please check your connection.")
            
        default:
            return .unknown("An unexpected error occurred: \(error.localizedDescription)")
        }
    }
    
    private func mapNetworkError(_ error: NSError) -> AppError {
        switch error.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .networkUnavailable("No internet connection. Please check your network settings.")
        case NSURLErrorTimedOut:
            return .timeout("Request timed out. Please try again.")
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return .networkUnavailable("Cannot connect to server. Please try again later.")
        case NSURLErrorBadServerResponse:
            return .serverError("Server returned an invalid response.")
        default:
            return .networkError("Network error: \(error.localizedDescription)")
        }
    }
    
    private func logError(_ error: AppError, context: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = """
        [ERROR] \(timestamp)
        Context: \(context)
        Type: \(error.type)
        Message: \(error.message)
        Recovery: \(error.recoverySuggestion ?? "None")
        Network Available: \(isNetworkAvailable)
        ---
        """
        
        print(logMessage)
        
        // In production, send to analytics/crash reporting
        #if DEBUG
        // Additional debug logging
        #endif
    }
    
    // MARK: - Retry Logic
    private func attemptRetry(for context: String, action: @escaping () async throws -> Void) {
        let currentAttempts = retryAttempts[context, default: 0]
        
        guard currentAttempts < maxRetryAttempts else {
            DispatchQueue.main.async {
                self.currentError = .maxRetriesExceeded("Maximum retry attempts reached for \(context)")
                self.isShowingError = true
            }
            return
        }
        
        retryAttempts[context] = currentAttempts + 1
        
        // Exponential backoff
        let delay = pow(2.0, Double(currentAttempts))
        
        Task {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            do {
                try await action()
                // Success - reset retry count
                retryAttempts[context] = 0
                DispatchQueue.main.async {
                    self.currentError = nil
                    self.isShowingError = false
                }
            } catch {
                handleError(error, context: "\(context) (Retry \(currentAttempts + 1))", shouldRetry: true, retryAction: action)
            }
        }
    }
    
    func resetRetryCount(for context: String) {
        retryAttempts[context] = 0
    }
    
    // MARK: - User Actions
    func dismissError() {
        currentError = nil
        isShowingError = false
    }
    
    func retryLastAction() {
        // This would need to be implemented based on the specific retry action stored
        dismissError()
    }
}

// MARK: - App Error Types
enum AppError: Error, Identifiable {
    case networkUnavailable(String)
    case networkError(String)
    case timeout(String)
    case unauthorized(String)
    case serverError(String)
    case validationError(String)
    case dataCorruption(String)
    case storageError(String)
    case authenticationFailed(String)
    case permissionDenied(String)
    case quotaExceeded(String)
    case maxRetriesExceeded(String)
    case unknown(String)
    
    var id: String {
        return "\(type)_\(message.hashValue)"
    }
    
    var type: String {
        switch self {
        case .networkUnavailable: return "network_unavailable"
        case .networkError: return "network_error"
        case .timeout: return "timeout"
        case .unauthorized: return "unauthorized"
        case .serverError: return "server_error"
        case .validationError: return "validation_error"
        case .dataCorruption: return "data_corruption"
        case .storageError: return "storage_error"
        case .authenticationFailed: return "authentication_failed"
        case .permissionDenied: return "permission_denied"
        case .quotaExceeded: return "quota_exceeded"
        case .maxRetriesExceeded: return "max_retries_exceeded"
        case .unknown: return "unknown"
        }
    }
    
    var message: String {
        switch self {
        case .networkUnavailable(let message),
             .networkError(let message),
             .timeout(let message),
             .unauthorized(let message),
             .serverError(let message),
             .validationError(let message),
             .dataCorruption(let message),
             .storageError(let message),
             .authenticationFailed(let message),
             .permissionDenied(let message),
             .quotaExceeded(let message),
             .maxRetriesExceeded(let message),
             .unknown(let message):
            return message
        }
    }
    
    var title: String {
        switch self {
        case .networkUnavailable: return "Connection Issue"
        case .networkError: return "Network Error"
        case .timeout: return "Request Timeout"
        case .unauthorized: return "Access Denied"
        case .serverError: return "Server Error"
        case .validationError: return "Invalid Data"
        case .dataCorruption: return "Data Error"
        case .storageError: return "Storage Error"
        case .authenticationFailed: return "Authentication Failed"
        case .permissionDenied: return "Permission Denied"
        case .quotaExceeded: return "Quota Exceeded"
        case .maxRetriesExceeded: return "Retry Limit Reached"
        case .unknown: return "Unexpected Error"
        }
    }
    
    var icon: String {
        switch self {
        case .networkUnavailable, .networkError, .timeout: return "wifi.exclamationmark"
        case .unauthorized, .permissionDenied: return "lock.shield"
        case .serverError: return "server.rack"
        case .validationError: return "exclamationmark.triangle"
        case .dataCorruption, .storageError: return "externaldrive.badge.exclamationmark"
        case .authenticationFailed: return "person.badge.key"
        case .quotaExceeded: return "gauge.badge.minus"
        case .maxRetriesExceeded: return "arrow.clockwise.circle"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .unauthorized, .permissionDenied:
            return "Please log out and log back in."
        case .serverError:
            return "Our servers are experiencing issues. Please try again later."
        case .validationError:
            return "Please check your input and try again."
        case .quotaExceeded:
            return "You've reached your usage limit. Please try again later."
        case .maxRetriesExceeded:
            return "Multiple attempts failed. Please check your connection and try again."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
    
    var shouldShowRetryButton: Bool {
        switch self {
        case .networkUnavailable, .networkError, .timeout, .serverError, .maxRetriesExceeded:
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Alert View
struct ErrorAlertView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            Image(systemName: error.icon)
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            // Error Title
            Text(error.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Error Message
            Text(error.message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                if error.shouldShowRetryButton, let onRetry = onRetry {
                    Button("Retry") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("OK") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: 300)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

// MARK: - Network Status View
struct NetworkStatusView: View {
    @EnvironmentObject private var errorHandler: ErrorHandlingService
    
    var body: some View {
        if !errorHandler.isNetworkAvailable {
            HStack {
                Image(systemName: "wifi.exclamationmark")
                    .foregroundColor(.white)
                
                Text("No Internet Connection")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red)
            .animation(.easeInOut, value: errorHandler.isNetworkAvailable)
        }
    }
}

// MARK: - Retry Wrapper
struct RetryableView<Content: View>: View {
    let context: String
    let content: () -> Content
    let retryAction: () async throws -> Void
    
    @EnvironmentObject private var errorHandler: ErrorHandlingService
    @State private var isLoading = false
    
    var body: some View {
        content()
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .onTapGesture {
                if !isLoading {
                    performAction()
                }
            }
    }
    
    private func performAction() {
        isLoading = true
        
        Task {
            do {
                try await retryAction()
                await MainActor.run {
                    isLoading = false
                    errorHandler.resetRetryCount(for: context)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorHandler.handleError(error, context: context, shouldRetry: true, retryAction: retryAction)
                }
            }
        }
    }
}