import Foundation
import SwiftUI
import UIKit
import AVFoundation
import AudioToolbox

// MARK: - OpenFoodFacts API Models
struct OFFProduct: Codable {
    let code: String
    let product: OFFProductDetails?
    let status: Int
    let statusVerbose: String
    
    enum CodingKeys: String, CodingKey {
        case code, product, status
        case statusVerbose = "status_verbose"
    }
}

struct OFFProductDetails: Codable, Identifiable {
    let productName: String?
    let genericName: String?
    let brands: String?
    let categories: String?
    let imageUrl: String?
    let imageFrontUrl: String?
    let imageNutritionUrl: String?
    let nutriments: OFFNutriments?
    let ingredients: [OFFIngredient]?
    let nutriscoreGrade: String?
    let novaGroup: Int?
    let servingSize: String?
    let packagingTags: [String]?
    
    // Identifiable conformance
    var id: String {
        // Use a combination of productName and brands as a unique identifier
        return "\(productName ?? "unknown")_\(brands ?? "nobrand")_\(UUID().uuidString)"
    }
    
    enum CodingKeys: String, CodingKey {
        case genericName = "generic_name"
        case productName = "product_name"
        case brands, categories, ingredients
        case imageUrl = "image_url"
        case imageFrontUrl = "image_front_url"
        case imageNutritionUrl = "image_nutrition_url"
        case nutriments
        case nutriscoreGrade = "nutriscore_grade"
        case novaGroup = "nova_group"
        case servingSize = "serving_size"
        case packagingTags = "packaging_tags"
    }
}

struct OFFNutriments: Codable {
    let energyKcal100g: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let carbohydrates100g: Double?
    let sugars100g: Double?
    let fiber100g: Double?
    let proteins100g: Double?
    let salt100g: Double?
    let sodium100g: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case sugars100g = "sugars_100g"
        case fiber100g = "fiber_100g"
        case proteins100g = "proteins_100g"
        case salt100g = "salt_100g"
        case sodium100g = "sodium_100g"
    }
}

struct OFFIngredient: Codable {
    let id: String?
    let text: String?
    let rank: Int?
    let percent: Double?
}

struct OFFSearchResponse: Codable {
    let count: Int?
    let page: Int?
    let pageCount: Int?
    let pageSize: Int?
    let products: [OFFProductDetails]
    
    enum CodingKeys: String, CodingKey {
        case count, page, products
        case pageCount = "page_count"
        case pageSize = "page_size"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        count = try container.decodeIfPresent(Int.self, forKey: .count)
        page = try container.decodeIfPresent(Int.self, forKey: .page)
        pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount)
        pageSize = try container.decodeIfPresent(Int.self, forKey: .pageSize)
        
        // Handle products array, defaulting to empty array if missing
        products = (try? container.decode([OFFProductDetails].self, forKey: .products)) ?? []
    }
}

// MARK: - OpenFoodFacts API Service
class OpenFoodFactsService: ObservableObject {
    static let shared = OpenFoodFactsService()
    
    private let baseURL = "https://world.openfoodfacts.org/api/v0"
    private let session = URLSession.shared
    private let userAgent = "FitTracker-iOS/1.0"
    // Retry and deduplication services would be implemented separately
    private let maxRetries = 3
    
    @Published var searchResults: [OFFProductDetails] = []
    @Published var isLoading = false
    
    private var productCache: [String: OFFProduct] = [:]
    private var searchCache: [String: OFFSearchResponse] = [:]
    
    private init() {
        loadCachedData()
    }
    
    // MARK: - Product Lookup
    func getProduct(barcode: String) async throws -> OFFProduct? {
        // Check cache first
        if let cachedProduct = productCache[barcode] {
            return cachedProduct
        }
        
        // Validate barcode
        guard !barcode.isEmpty, barcode.allSatisfy({ $0.isNumber }) else {
            throw OpenFoodFactsError.invalidBarcode
        }
        
        guard let url = URL(string: "\(baseURL)/product/\(barcode).json") else {
            throw OpenFoodFactsError.invalidURL
        }
        
        let request = createRequest(for: url)
        
        let (data, response) = try await session.data(for: request)
        
        // Validate HTTP response
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                break
            case 404:
                return nil // Product not found
            case 429:
                throw OpenFoodFactsError.rateLimitExceeded
            case 500...599:
                throw OpenFoodFactsError.serverError
            default:
                throw OpenFoodFactsError.networkError
            }
        }
        
        // Validate response data
        guard !data.isEmpty else {
            throw OpenFoodFactsError.emptyResponse
        }
        
        do {
            let product = try JSONDecoder().decode(OFFProduct.self, from: data)
            
            // Cache the result
            productCache[barcode] = product
            await saveCachedData()
            
            return product
        } catch {
            throw OpenFoodFactsError.parsingError
        }
    }
    
    // MARK: - Product Search
    func searchProducts(query: String, page: Int = 1, pageSize: Int = 20) async throws -> OFFSearchResponse {
        let cacheKey = "\(query)_\(page)_\(pageSize)"
        if let cachedResponse = searchCache[cacheKey] {
            return cachedResponse
        }
        
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize)),
            URLQueryItem(name: "sort_by", value: "popularity"),
            URLQueryItem(name: "json", value: "1")
        ]
        
        let request = createRequest(for: components.url!)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        
        // Cache the results
        searchCache[cacheKey] = response
        await saveCachedData()
        
        return response
    }
    
    // MARK: - Category Search
    func searchByCategory(category: String, page: Int = 1) async throws -> OFFSearchResponse {
        let cacheKey = "category_\(category)_\(page)"
        if let cachedResponse = searchCache[cacheKey] {
            return cachedResponse
        }
        
        var components = URLComponents(string: "\(baseURL)/category/\(category).json")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "sort_by", value: "popularity")
        ]
        
        let request = createRequest(for: components.url!)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        
        // Cache the results
        searchCache[cacheKey] = response
        await saveCachedData()
        
        return response
    }
    
    // MARK: - Popular Products
    func getPopularProducts(page: Int = 1) async throws -> OFFSearchResponse {
        let cacheKey = "popular_\(page)"
        if let cachedResponse = searchCache[cacheKey] {
            return cachedResponse
        }
        
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "sort_by", value: "popularity"),
            URLQueryItem(name: "json", value: "1")
        ]
        
        let request = createRequest(for: components.url!)
        let (data, _) = try await session.data(for: request)
        
        let response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        
        // Cache the results
        searchCache[cacheKey] = response
        await saveCachedData()
        
        return response
    }
    
    // MARK: - Barcode Scanning
    func startBarcodeScanning() -> OFFBarcodeScannerView {
        return OFFBarcodeScannerView { [weak self] barcode in
            Task {
                await self?.handleScannedBarcode(barcode)
            }
        }
    }
    
    @MainActor
    private func handleScannedBarcode(_ barcode: String) async {
        do {
            isLoading = true
            let product = try await getProduct(barcode: barcode)
            // Handle the scanned product
            NotificationCenter.default.post(
                name: .productScanned,
                object: product
            )
        } catch {
            print("Error scanning barcode: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Helper Methods
    private func createRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    // MARK: - Caching
    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: "off_products_cache"),
           let cache = try? JSONDecoder().decode([String: OFFProduct].self, from: data) {
            productCache = cache
        }
        
        if let data = UserDefaults.standard.data(forKey: "off_search_cache"),
           let cache = try? JSONDecoder().decode([String: OFFSearchResponse].self, from: data) {
            searchCache = cache
        }
    }
    
    private func saveCachedData() async {
        if let data = try? JSONEncoder().encode(productCache) {
            UserDefaults.standard.set(data, forKey: "off_products_cache")
        }
        
        if let data = try? JSONEncoder().encode(searchCache) {
            UserDefaults.standard.set(data, forKey: "off_search_cache")
        }
    }
    
    func clearCache() {
        productCache.removeAll()
        searchCache.removeAll()
        
        UserDefaults.standard.removeObject(forKey: "off_products_cache")
        UserDefaults.standard.removeObject(forKey: "off_search_cache")
    }
}

// MARK: - Extensions
extension OFFProductDetails {
    func toLocalFood() -> Food {
        return Food(
            name: productName ?? genericName ?? "Unknown Product",
            brand: brands,
            calories: nutriments?.energyKcal100g ?? 0,
            protein: nutriments?.proteins100g ?? 0,
            carbs: nutriments?.carbohydrates100g ?? 0,
            fat: nutriments?.fat100g ?? 0,
            imageUrl: imageFrontUrl
        )
    }
    
    private var servingSizeInGrams: Double {
        guard let servingSize = servingSize else { return 100 }
        
        // Parse serving size string (e.g., "30g", "1 cup (240ml)", etc.)
        let numbers = servingSize.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Double($0) }
        return numbers.first ?? 100
    }
}


// MARK: - Barcode Scanner View
struct OFFBarcodeScannerView: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> OFFBarcodeScannerViewController {
        let scanner = OFFBarcodeScannerViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: OFFBarcodeScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned)
    }
    
    class Coordinator: NSObject, OFFBarcodeScannerDelegate {
        let onBarcodeScanned: (String) -> Void
        
        init(onBarcodeScanned: @escaping (String) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
        }
        
        func barcodeScanned(_ barcode: String) {
            onBarcodeScanned(barcode)
        }
    }
}

// MARK: - Barcode Scanner Implementation
protocol OFFBarcodeScannerDelegate: AnyObject {
    func barcodeScanned(_ barcode: String)
}

class OFFBarcodeScannerViewController: UIViewController {
    weak var delegate: OFFBarcodeScannerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .code128]
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
}

extension OFFBarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.barcodeScanned(stringValue)
        }
    }
}

// MARK: - OpenFoodFacts Error Types
enum OpenFoodFactsError: Error, LocalizedError {
    case invalidBarcode
    case invalidURL
    case rateLimitExceeded
    case serverError
    case networkError
    case emptyResponse
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            return "Invalid barcode format"
        case .invalidURL:
            return "Invalid URL"
        case .rateLimitExceeded:
            return "Rate limit exceeded for OpenFoodFacts API"
        case .serverError:
            return "OpenFoodFacts server error"
        case .networkError:
            return "Network error occurred"
        case .emptyResponse:
            return "Empty response from OpenFoodFacts API"
        case .parsingError:
            return "Failed to parse OpenFoodFacts response"
        }
    }
}