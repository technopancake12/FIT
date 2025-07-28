"use client";

import { useState, useRef, useCallback, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Alert, AlertDescription } from "@/components/ui/alert";
import {
  Camera,
  X,
  RotateCcw,
  Flashlight,
  FlashlightOff,
  Scan,
  AlertCircle,
  CheckCircle,
  Loader2
} from "lucide-react";
import { Food, nutritionTracker } from "@/lib/nutrition";

interface BarcodeScannerProps {
  isOpen: boolean;
  onClose: () => void;
  onFoodFound: (food: Food) => void;
  onManualEntry: () => void;
}

export function BarcodeScanner({ isOpen, onClose, onFoodFound, onManualEntry }: BarcodeScannerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [flashlightOn, setFlashlightOn] = useState(false);
  const [scannedCode, setScannedCode] = useState<string>("");
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string>("");
  const [stream, setStream] = useState<MediaStream | null>(null);

  useEffect(() => {
    if (isOpen) {
      startCamera();
    } else {
      stopCamera();
    }

    return () => stopCamera();
  }, [isOpen]);

  const startCamera = async () => {
    try {
      setError("");

      // Check if camera is available
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error("Camera not supported in this browser");
      }

      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: "environment", // Use back camera
          width: { ideal: 1280 },
          height: { ideal: 720 }
        }
      });

      setStream(mediaStream);
      setHasPermission(true);

      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
        videoRef.current.play();
        setIsScanning(true);
      }

      // Start barcode detection
      startBarcodeDetection();

    } catch (err: any) {
      console.error("Camera error:", err);
      setHasPermission(false);
      setError(err.message || "Failed to access camera");
    }
  };

  const stopCamera = () => {
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      setStream(null);
    }
    setIsScanning(false);
    setFlashlightOn(false);
  };

  const startBarcodeDetection = () => {
    if (!videoRef.current || !canvasRef.current) return;

    const detectBarcode = () => {
      if (!isScanning || !videoRef.current || !canvasRef.current) return;

      const video = videoRef.current;
      const canvas = canvasRef.current;
      const ctx = canvas.getContext('2d');

      if (!ctx || video.videoWidth === 0) {
        requestAnimationFrame(detectBarcode);
        return;
      }

      // Set canvas size to match video
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;

      // Draw current frame
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

      // Try to detect barcode using Web API (if available)
      if ('BarcodeDetector' in window) {
        const barcodeDetector = new (window as any).BarcodeDetector({
          formats: ['ean_13', 'ean_8', 'upc_a', 'upc_e', 'code_128', 'code_39']
        });

        barcodeDetector.detect(canvas)
          .then((barcodes: any[]) => {
            if (barcodes.length > 0) {
              const barcode = barcodes[0];
              handleBarcodeDetected(barcode.rawValue);
              return;
            }
            requestAnimationFrame(detectBarcode);
          })
          .catch(() => {
            // Fallback to manual detection or continue scanning
            requestAnimationFrame(detectBarcode);
          });
      } else {
        // Fallback: Use a simple pattern detection or third-party library
        // For demo purposes, we'll simulate barcode detection
        simulateBarcodeDetection();
        requestAnimationFrame(detectBarcode);
      }
    };

    detectBarcode();
  };

  const simulateBarcodeDetection = () => {
    // This is a demo implementation - in a real app you'd use a library like QuaggaJS or ZXing
    // For now, we'll just simulate finding a barcode after a few seconds
    if (Math.random() < 0.01) { // 1% chance per frame
      const sampleBarcodes = [
        "0123456789012", // Sample EAN-13
        "1234567890123",
        "2345678901234"
      ];
      const randomBarcode = sampleBarcodes[Math.floor(Math.random() * sampleBarcodes.length)];
      handleBarcodeDetected(randomBarcode);
    }
  };

  const handleBarcodeDetected = async (code: string) => {
    if (isProcessing) return;

    setIsProcessing(true);
    setScannedCode(code);

    try {
      // Look up the barcode in our database
      const food = nutritionTracker.scanBarcode(code);

      if (food) {
        onFoodFound(food);
        onClose();
      } else {
        // Try to fetch from external API (like OpenFoodFacts)
        const externalFood = await fetchFoodFromAPI(code);
        if (externalFood) {
          onFoodFound(externalFood);
          onClose();
        } else {
          setError(`No food found for barcode: ${code}`);
        }
      }
    } catch (err) {
      console.error("Error processing barcode:", err);
      setError("Failed to process barcode");
    } finally {
      setIsProcessing(false);
    }
  };

  const fetchFoodFromAPI = async (barcode: string): Promise<Food | null> => {
    try {
      // This would call OpenFoodFacts API or similar
      const response = await fetch(`https://world.openfoodfacts.org/api/v0/product/${barcode}.json`);
      const data = await response.json();

      if (data.status === 1 && data.product) {
        const product = data.product;

        return {
          id: `barcode-${barcode}`,
          name: product.product_name || 'Unknown Product',
          brand: product.brands,
          barcode: barcode,
          calories: product.nutriments?.['energy-kcal_100g'] || 0,
          protein: product.nutriments?.proteins_100g || 0,
          carbs: product.nutriments?.carbohydrates_100g || 0,
          fat: product.nutriments?.fat_100g || 0,
          fiber: product.nutriments?.fiber_100g,
          sugar: product.nutriments?.sugars_100g,
          sodium: product.nutriments?.sodium_100g,
          category: product.categories_tags?.[0] || 'Unknown',
          servingSize: product.serving_size ? parseInt(product.serving_size) : 100,
          isVerified: false
        };
      }

      return null;
    } catch (error) {
      console.error("API Error:", error);
      return null;
    }
  };

  const toggleFlashlight = async () => {
    if (!stream) return;

    try {
      const track = stream.getVideoTracks()[0];
      const capabilities = track.getCapabilities();

      if ((capabilities as any).torch) {
        await track.applyConstraints({
          advanced: [{ torch: !flashlightOn } as any]
        });
        setFlashlightOn(!flashlightOn);
      }
    } catch (err) {
      console.error("Flashlight error:", err);
    }
  };

  const handleManualEntry = () => {
    onClose();
    onManualEntry();
  };

  if (!isOpen) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md p-0 overflow-hidden">
        <div className="relative">
          {/* Header */}
          <DialogHeader className="p-4 bg-background border-b">
            <div className="flex items-center justify-between">
              <div>
                <DialogTitle className="flex items-center gap-2">
                  <Scan className="h-5 w-5" />
                  Scan Barcode
                </DialogTitle>
                <DialogDescription>
                  Point camera at product barcode
                </DialogDescription>
              </div>
              <Button variant="ghost" size="icon" onClick={onClose}>
                <X className="h-4 w-4" />
              </Button>
            </div>
          </DialogHeader>

          {/* Camera View */}
          <div className="relative aspect-[4/3] bg-black">
            {hasPermission === false ? (
              <div className="absolute inset-0 flex items-center justify-center bg-muted">
                <div className="text-center space-y-4">
                  <AlertCircle className="h-12 w-12 mx-auto text-muted-foreground" />
                  <div>
                    <p className="font-medium">Camera Access Required</p>
                    <p className="text-sm text-muted-foreground">
                      Please allow camera access to scan barcodes
                    </p>
                  </div>
                  <Button onClick={startCamera}>
                    <Camera className="h-4 w-4 mr-2" />
                    Enable Camera
                  </Button>
                </div>
              </div>
            ) : (
              <>
                <video
                  ref={videoRef}
                  className="w-full h-full object-cover"
                  playsInline
                  muted
                />
                <canvas
                  ref={canvasRef}
                  className="hidden"
                />

                {/* Scanning Overlay */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="relative">
                    {/* Scanning Frame */}
                    <div className="w-64 h-32 border-2 border-white rounded-lg relative">
                      <div className="absolute top-0 left-0 w-6 h-6 border-t-4 border-l-4 border-primary rounded-tl-lg"></div>
                      <div className="absolute top-0 right-0 w-6 h-6 border-t-4 border-r-4 border-primary rounded-tr-lg"></div>
                      <div className="absolute bottom-0 left-0 w-6 h-6 border-b-4 border-l-4 border-primary rounded-bl-lg"></div>
                      <div className="absolute bottom-0 right-0 w-6 h-6 border-b-4 border-r-4 border-primary rounded-br-lg"></div>

                      {/* Scanning Line Animation */}
                      <div className="absolute inset-x-0 top-1/2 h-0.5 bg-primary animate-pulse"></div>
                    </div>

                    <p className="text-white text-center mt-4 text-sm bg-black/50 px-3 py-1 rounded">
                      Position barcode within frame
                    </p>
                  </div>
                </div>

                {/* Controls */}
                <div className="absolute bottom-4 left-0 right-0 flex justify-center gap-4">
                  <Button
                    variant="secondary"
                    size="icon"
                    onClick={toggleFlashlight}
                    className="bg-black/50 hover:bg-black/70"
                  >
                    {flashlightOn ? (
                      <FlashlightOff className="h-4 w-4" />
                    ) : (
                      <Flashlight className="h-4 w-4" />
                    )}
                  </Button>

                  <Button
                    variant="secondary"
                    size="icon"
                    onClick={startCamera}
                    className="bg-black/50 hover:bg-black/70"
                  >
                    <RotateCcw className="h-4 w-4" />
                  </Button>
                </div>

                {/* Processing Overlay */}
                {isProcessing && (
                  <div className="absolute inset-0 bg-black/80 flex items-center justify-center">
                    <div className="text-center text-white">
                      <Loader2 className="h-8 w-8 animate-spin mx-auto mb-2" />
                      <p>Processing barcode...</p>
                      {scannedCode && (
                        <p className="text-sm text-muted-foreground mt-1">{scannedCode}</p>
                      )}
                    </div>
                  </div>
                )}
              </>
            )}
          </div>

          {/* Footer */}
          <div className="p-4 space-y-4">
            {error && (
              <Alert>
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}

            <div className="flex gap-2">
              <Button variant="outline" onClick={handleManualEntry} className="flex-1">
                Manual Entry
              </Button>
              <Button onClick={onClose} className="flex-1">
                Cancel
              </Button>
            </div>

            <div className="text-center text-xs text-muted-foreground">
              <p>Having trouble? Try manual entry or ensure good lighting</p>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

// Mock some sample foods with barcodes for demo
const sampleFoodsWithBarcodes: Food[] = [
  {
    id: "barcode-0123456789012",
    name: "Greek Yogurt Natural",
    brand: "Organic Valley",
    barcode: "0123456789012",
    calories: 100,
    protein: 18,
    carbs: 6,
    fat: 0,
    category: "Dairy",
    servingSize: 170,
    isVerified: true
  },
  {
    id: "barcode-1234567890123",
    name: "Whole Grain Bread",
    brand: "Nature's Own",
    barcode: "1234567890123",
    calories: 80,
    protein: 4,
    carbs: 14,
    fat: 1,
    fiber: 3,
    category: "Grains",
    servingSize: 28,
    isVerified: true
  }
];

// Add sample foods to the nutrition tracker
sampleFoodsWithBarcodes.forEach(food => {
  // This would normally be done in the database initialization
  if ((nutritionTracker as any).addFoodToDatabase) {
    (nutritionTracker as any).addFoodToDatabase(food);
  }
});
