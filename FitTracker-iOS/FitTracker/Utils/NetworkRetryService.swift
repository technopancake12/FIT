import Foundation
import Network

class NetworkRetryService {
    static let shared = NetworkRetryService()
    
    private let maxRetryAttempts = 3
    private let baseDelay: TimeInterval = 1.0
    private let maxDelay: TimeInterval = 30.0
    private var retryAttempts: [String: Int] = [:]
    
    private init() {}
    
    // MARK: - Retry Logic
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        context: String,
        retryCondition: @escaping (Error) -> Bool = { _ in true }
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetryAttempts {
            do {
                let result = try await operation()
                // Success - reset retry count
                retryAttempts[context] = 0
                return result
            } catch {
                lastError = error
                
                // Check if we should retry this error
                guard retryCondition(error) else {
                    throw error
                }
                
                // Don't retry on the last attempt
                guard attempt < maxRetryAttempts - 1 else {
                    break
                }
                
                // Calculate delay with exponential backoff
                let delay = min(baseDelay * pow(2.0, Double(attempt)), maxDelay)
                
                // Add jitter to prevent thundering herd
                let jitter = Double.random(in: 0...0.1) * delay
                let totalDelay = delay + jitter
                
                print("Retry attempt \(attempt + 1) for \(context) after \(totalDelay)s delay")
                
                try await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))
            }
        }
        
        // All retries failed
        retryAttempts[context] = maxRetryAttempts
        throw lastError ?? AppError.maxRetriesExceeded("Max retries exceeded for \(context)")
    }
    
    // MARK: - Retry Conditions
    static func shouldRetryNetworkError(_ error: Error) -> Bool {
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorNotConnectedToInternet:
                return true
            default:
                return false
            }
        }
        
        if let appError = error as? AppError {
            switch appError {
            case .networkUnavailable, .timeout, .serverError:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    static func shouldRetryFirestoreError(_ error: Error) -> Bool {
        let errorString = error.localizedDescription.lowercased()
        
        return errorString.contains("unavailable") ||
               errorString.contains("deadline_exceeded") ||
               errorString.contains("internal") ||
               errorString.contains("resource_exhausted")
    }
    
    // MARK: - Circuit Breaker Pattern
    private var circuitState: [String: CircuitState] = [:]
    
    private enum CircuitState {
        case closed
        case open(Date)
        case halfOpen
    }
    
    private func isCircuitOpen(for service: String) -> Bool {
        guard let state = circuitState[service] else { return false }
        
        switch state {
        case .closed, .halfOpen:
            return false
        case .open(let openTime):
            // Circuit stays open for 30 seconds
            return Date().timeIntervalSince(openTime) < 30
        }
    }
    
    private func recordSuccess(for service: String) {
        circuitState[service] = .closed
    }
    
    private func recordFailure(for service: String) {
        let currentFailures = retryAttempts[service, default: 0] + 1
        retryAttempts[service] = currentFailures
        
        // Open circuit after 5 failures
        if currentFailures >= 5 {
            circuitState[service] = .open(Date())
        }
    }
    
    func executeWithCircuitBreaker<T>(
        operation: @escaping () async throws -> T,
        service: String
    ) async throws -> T {
        // Check if circuit is open
        if isCircuitOpen(for: service) {
            throw AppError.serverError("Service \(service) is temporarily unavailable")
        }
        
        do {
            let result = try await operation()
            recordSuccess(for: service)
            return result
        } catch {
            recordFailure(for: service)
            throw error
        }
    }
}

// MARK: - Request Deduplication
class RequestDeduplicationService {
    static let shared = RequestDeduplicationService()
    
    private var activeRequests: [String: Task<Any, Error>] = [:]
    private let queue = DispatchQueue(label: "RequestDeduplication", attributes: .concurrent)
    
    private init() {}
    
    func executeDeduplicatedRequest<T>(
        key: String,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) {
                // Check if request is already in progress
                if let existingTask = self.activeRequests[key] {
                    Task {
                        do {
                            let result = try await existingTask.value as! T
                            continuation.resume(returning: result)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                    return
                }
                
                // Create new request
                let task = Task<Any, Error> {
                    return try await operation()
                }
                
                self.activeRequests[key] = task
                
                Task {
                    do {
                        let result = try await task.value as! T
                        self.queue.async(flags: .barrier) {
                            self.activeRequests.removeValue(forKey: key)
                        }
                        continuation.resume(returning: result)
                    } catch {
                        self.queue.async(flags: .barrier) {
                            self.activeRequests.removeValue(forKey: key)
                        }
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

// MARK: - Offline Queue
class OfflineQueueService: ObservableObject {
    static let shared = OfflineQueueService()
    
    @Published var queuedOperations: [QueuedOperation] = []
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "OfflineQueueMonitor")
    
    private init() {
        loadQueuedOperations()
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                Task {
                    await self?.processQueuedOperations()
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    func queueOperation(_ operation: QueuedOperation) {
        queuedOperations.append(operation)
        saveQueuedOperations()
    }
    
    private func processQueuedOperations() async {
        let operations = queuedOperations
        
        for operation in operations {
            do {
                try await operation.execute()
                removeOperation(operation)
            } catch {
                print("Failed to execute queued operation: \(error)")
                // Keep operation in queue for retry
            }
        }
    }
    
    private func removeOperation(_ operation: QueuedOperation) {
        queuedOperations.removeAll { $0.id == operation.id }
        saveQueuedOperations()
    }
    
    private func saveQueuedOperations() {
        // In a real implementation, persist to disk
        UserDefaults.standard.set(queuedOperations.count, forKey: "queued_operations_count")
    }
    
    private func loadQueuedOperations() {
        // In a real implementation, load from disk
        let count = UserDefaults.standard.integer(forKey: "queued_operations_count")
        // Reconstruct operations if needed
    }
}

struct QueuedOperation: Identifiable {
    let id = UUID()
    let type: String
    let data: [String: Any]
    let timestamp: Date
    
    func execute() async throws {
        // Implementation would depend on the operation type
        switch type {
        case "createPost":
            // Execute create post operation
            break
        case "likePost":
            // Execute like post operation
            break
        default:
            break
        }
    }
}