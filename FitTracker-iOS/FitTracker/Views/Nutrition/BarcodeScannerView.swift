import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @StateObject private var offService = OpenFoodFactsService.shared
    @State private var scannedCode: String = ""
    @State private var scannedFood: Food?
    @State private var isScanning = false
    @State private var showManualEntry = false
    @State private var manualBarcode = ""
    @State private var showFoodDetail = false
    @State private var scannerError: String?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                headerSection
                
                if isScanning {
                    // Camera Scanner
                    cameraScannerSection
                } else {
                    // Manual Entry / Instructions
                    instructionsSection
                }
                
                // Manual entry option
                manualEntrySection
                
                // Recent scans
                recentScansSection
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .sheet(item: $scannedFood) { food in
            FoodDetailView(food: food, mealType: "Scanned")
        }
        .alert("Scanner Error", isPresented: .constant(scannerError != nil)) {
            Button("OK") { scannerError = nil }
        } message: {
            if let error = scannerError {
                Text(error)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.green)
                
                Text("Barcode Scanner")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Scan US product barcodes for instant nutrition info")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var cameraScannerSection: some View {
        VStack(spacing: 16) {
            // Camera Preview Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Position barcode in the frame")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green, lineWidth: 2)
                    )
                
                // Scanning overlay
                if isScanning {
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 200, height: 100)
                        .overlay(
                            Rectangle()
                                .stroke(Color.green, lineWidth: 2)
                        )
                }
            }
            
            Button(action: { isScanning.toggle() }) {
                HStack(spacing: 12) {
                    Image(systemName: isScanning ? "stop.circle.fill" : "camera.fill")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text(isScanning ? "Stop Scanning" : "Start Camera")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isScanning ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var instructionsSection: some View {
        VStack(spacing: 20) {
            // Instructions Card
            VStack(spacing: 16) {
                Image(systemName: "barcode")
                    .font(.system(size: 48))
                    .foregroundColor(.green.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("Scan US Product Barcodes")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Get instant nutrition information from our US food database")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    InstructionStep(number: "1", text: "Tap 'Start Camera' to begin scanning")
                    InstructionStep(number: "2", text: "Point camera at product barcode")
                    InstructionStep(number: "3", text: "View nutrition info and add to log")
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            Button(action: { isScanning = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Start Camera Scanner")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.8))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual Barcode Entry")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                TextField("Enter barcode number", text: $manualBarcode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Button("Search") {
                    searchManualBarcode()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.8))
                )
                .disabled(manualBarcode.isEmpty)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Scans")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                Text("No recent scans")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Scanned products will appear here for quick access")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func searchManualBarcode() {
        guard !manualBarcode.isEmpty else { return }
        
        Task {
            do {
                        if let product = try await offService.getUSProduct(barcode: manualBarcode),
           let productDetails = product.product {
            scannedFood = productDetails.toFood()
        } else {
                    scannerError = "Product not found in US database"
                }
            } catch {
                scannerError = "Error searching for product: \(error.localizedDescription)"
            }
        }
    }
}

struct InstructionStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.green.opacity(0.8))
                )
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

#Preview {
    BarcodeScannerView()
}