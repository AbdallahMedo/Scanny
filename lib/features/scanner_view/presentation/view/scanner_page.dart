import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_scanner/features/scanner_view/presentation/view/scanner_result.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  late BarcodeScanner _barcodeScanner;
  bool _isPermissionGranted = false;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  bool _shouldScan = true;
  bool _isFlashOn = false;
  late AnimationController _animationController;
  final double _scanAreaSize = 250.0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initCamera();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    setState(() => _isPermissionGranted = status.isGranted);

    if (!_isPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }

    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController.initialize();
      await _cameraController.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize camera: $e')),
      );
    }
  }

  Future<void> _toggleFlash() async {
    try {
      if (_isFlashOn) {
        await _cameraController.setFlashMode(FlashMode.off);
      } else {
        await _cameraController.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Flash error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle flash: $e')),
      );
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!_shouldScan || _isProcessing || !_isCameraReady || !mounted) return;

    _isProcessing = true;

    try {
      final inputImage = _createInputImage(image);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      debugPrint('Barcodes found: ${barcodes.length}');
      if (barcodes.isNotEmpty) {
        final barcode = barcodes.first;
        if (barcode.rawValue != null) {
          debugPrint('QR Code: ${barcode.rawValue}');
          _shouldScan = false;

          if (!mounted) return;
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ScannerResult(code: barcode.rawValue!),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Barcode scanning error: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      _isProcessing = false;
    }
  }

  InputImage _createInputImage(CameraImage image) {
    final WriteBuffer buffer = WriteBuffer();
    for (final plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: InputImageRotation.rotation90deg,
      format: InputImageFormat.yuv420,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final code = barcodes.first.rawValue;
        if (code != null && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScannerResult(code: code),
            ),
          );
        } else {
          _showNoQRFound();
        }
      } else {
        _showNoQRFound();
      }
    } catch (e) {
      debugPrint('Gallery QR error: $e');
      _showNoQRFound();
    }
  }

  void _showNoQRFound() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No QR code found in the selected image.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaOffset = Offset(
      (size.width - _scanAreaSize) / 2,
      (size.height - _scanAreaSize) / 2,
    );

    if (!_isPermissionGranted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Camera permission required'),
              ElevatedButton(
                onPressed: _initCamera,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   automaticallyImplyLeading: false,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.photo, color: Colors.white),
      //       tooltip: "Pick from gallery",
      //       onPressed: _pickImageFromGallery,
      //     ),
      //   ],
      // ),
      body: Stack(
        children: [
          SizedBox(
            width: size.width,
            height: size.height,
            child: CameraPreview(_cameraController),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0,horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: _toggleFlash,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.photo,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: scanAreaOffset.dx,
            top: scanAreaOffset.dy,
            child: Container(
              width: _scanAreaSize,
              height: _scanAreaSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * _scanAreaSize,
                        child: Container(
                          width: _scanAreaSize,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Align QR code within the frame\nor tap the gallery icon to load an image",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}