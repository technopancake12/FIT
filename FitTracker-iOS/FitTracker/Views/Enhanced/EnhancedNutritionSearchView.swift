import SwiftUI
import AVFoundation

struct EnhancedNutritionSearchView: View {
    @StateObject private var offService = OpenFoodFactsService.shared
    @State private var searchText = ""
    @State private var searchResults: [OFFProductDetails] = []
    @State private var isLoading = false
    @State private var showBarcodeScanner = false
    @State private var showProductDetail: OFFProductDetails?
    
    let mealType: String
    let onFoodSelected: (Food) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search header
                    VStack(spacing: 16) {
                        // Search bar with barcode scanner
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white.opacity(0.6))
                                
                                TextField("Search foods...", text: $searchText)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                    .onSubmit {
                                        performSearch()
                                    }
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            
                            Button(action: { showBarcodeScanner = true }) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.green.opacity(0.8))
                                    )
                            }
                        }
                        
                        // Quick category buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CategoryButton(title: "Popular", icon: "star.fill", color: .yellow) {
                                    loadPopularProducts()
                                }
                                CategoryButton(title: "Beverages", icon: "cup.and.saucer.fill", color: .blue) {
                                    searchByCategory("beverages")
                                }
                                CategoryButton(title: "Snacks", icon: "bag.fill", color: .orange) {
                                    searchByCategory("snacks")
                                }
                                CategoryButton(title: "Dairy", icon: "drop.fill", color: .purple) {
                                    searchByCategory("dairy")
                                }
                                CategoryButton(title: "Fruits", icon: "leaf.fill", color: .green) {
                                    searchByCategory("fruits")
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Results
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            
                            Text("Searching foods...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("No foods found")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Try searching with different keywords or scan a barcode")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(searchResults.enumerated()), id: \.element.productName) { index, product in
                                    FoodCard(product: product) {
                                        showProductDetail = product
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("Add to \(mealType)")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerSheet { barcode in
                handleScannedBarcode(barcode)
            }
        }
        .sheet(item: Binding<OFFProductDetails?>(
            get: { showProductDetail },
            set: { showProductDetail = $0 }
        )) { product in
            FoodDetailSheet(product: product, onAdd: { food in
                onFoodSelected(food)
                showProductDetail = nil
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: .productScanned)) { notification in
            if let product = notification.object as? OFFProduct {
                handleScannedProduct(product)
            }
        }
        .task {
            await loadPopularProducts()
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        Task {
            do {
                isLoading = true
                let response = try await offService.searchProducts(query: searchText)
                await MainActor.run {
                    self.searchResults = response.products
                    self.isLoading = false
                }
            } catch {
                print("Error searching products: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func searchByCategory(_ category: String) {
        Task {
            do {
                isLoading = true
                let response = try await offService.searchByCategory(category: category)
                await MainActor.run {
                    self.searchResults = response.products
                    self.isLoading = false
                }
            } catch {
                print("Error searching by category: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadPopularProducts() {
        Task {
            do {
                isLoading = true
                let response = try await offService.getPopularProducts()
                await MainActor.run {
                    self.searchResults = response.products
                    self.isLoading = false
                }
            } catch {
                print("Error loading popular products: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleScannedBarcode(_ barcode: String) {
        Task {
            do {
                isLoading = true
                if let product = try await offService.getProduct(barcode: barcode) {
                    await MainActor.run {
                        handleScannedProduct(product)
                    }
                }
                isLoading = false
            } catch {
                print("Error scanning barcode: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleScannedProduct(_ product: OFFProduct) {
        if let productDetails = product.product {
            showProductDetail = productDetails
        }
    }
}

struct CategoryButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(color.opacity(0.8))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FoodCard: View {
    let product: OFFProductDetails
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Product image
                AsyncImage(url: URL(string: product.imageFrontUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Product info
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.productName ?? "Unknown Product")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let brands = product.brands, !brands.isEmpty {
                        Text(brands)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    HStack {
                        if let calories = product.nutriments?.energyKcal100g {
                            Text("\(Int(calories)) cal/100g")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                        }
                        
                        if let grade = product.nutriscoreGrade {
                            NutriscoreGrade(grade: grade)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutriscoreGrade: View {
    let grade: String
    
    var gradeColor: Color {
        switch grade.uppercased() {
        case "A": return .green
        case "B": return Color(red: 0.5, green: 0.8, blue: 0.2)
        case "C": return .yellow
        case "D": return .orange
        case "E": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text(grade.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(
                Circle()
                    .fill(gradeColor)
            )
    }
}

// MARK: - Barcode Scanner Sheet
struct BarcodeScannerSheet: View {
    let onBarcodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                OpenFoodFactsService.shared.startBarcodeScanning()
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("Scan a barcode")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Position the barcode within the frame")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
                
                // Scanning frame overlay
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 280, height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.clear)
                    )
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .productScanned)) { notification in
            if let product = notification.object as? OFFProduct,
               let code = product.product?.productName {
                onBarcodeScanned(product.code)
                dismiss()
            }
        }
    }
}

#Preview {
    EnhancedNutritionSearchView(mealType: "Breakfast") { food in
        print("Selected food: \(food.name)")
    }
}