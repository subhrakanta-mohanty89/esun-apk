/// ESUN QR Scanner Screen
///
/// Scans UPI QR codes and processes payment details.
/// Uses mobile_scanner package for camera-based QR scanning.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';

/// UPI data parsed from QR code
class UPIQRData {
  final String? pa; // payee VPA
  final String? pn; // payee name
  final String? am; // amount
  final String? cu; // currency
  final String? tn; // transaction note
  final String? tr; // transaction reference
  final String? mc; // merchant code

  UPIQRData({
    this.pa,
    this.pn,
    this.am,
    this.cu,
    this.tn,
    this.tr,
    this.mc,
  });

  /// Parse UPI URI into UPIQRData
  factory UPIQRData.fromUri(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return UPIQRData();
    
    return UPIQRData(
      pa: parsed.queryParameters['pa'],
      pn: parsed.queryParameters['pn'],
      am: parsed.queryParameters['am'],
      cu: parsed.queryParameters['cu'] ?? 'INR',
      tn: parsed.queryParameters['tn'],
      tr: parsed.queryParameters['tr'],
      mc: parsed.queryParameters['mc'],
    );
  }

  bool get isValid => pa != null && pa!.isNotEmpty;
}

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _torchEnabled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for camera
    if (_scannerController == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _scannerController?.start();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _scannerController?.stop();
        break;
      default:
        break;
    }
  }

  Future<void> _checkCameraPermission() async {
    setState(() => _isCheckingPermission = true);
    
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      _initializeScanner();
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        _initializeScanner();
        setState(() {
          _hasPermission = true;
          _isCheckingPermission = false;
        });
      } else {
        setState(() {
          _hasPermission = false;
          _isCheckingPermission = false;
          _errorMessage = 'Camera permission is required to scan QR codes';
        });
      }
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
        _errorMessage = 'Camera permission is permanently denied. Please enable it in settings.';
      });
    } else {
      setState(() {
        _isCheckingPermission = false;
        _hasPermission = false;
      });
    }
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? rawValue = barcode.rawValue;

    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Check if it's a UPI QR code
    if (rawValue.toLowerCase().startsWith('upi://')) {
      _processUPICode(rawValue);
    } else {
      // Try to parse as UPI anyway
      _processGenericQRCode(rawValue);
    }
  }

  void _processUPICode(String upiUri) {
    final upiData = UPIQRData.fromUri(upiUri);
    
    if (upiData.isValid) {
      _showPaymentBottomSheet(upiData);
    } else {
      _showErrorAndReset('Invalid UPI QR code');
    }
  }

  void _processGenericQRCode(String data) {
    // For non-UPI QR codes, show the raw data
    _showGenericQRResult(data);
  }

  void _showErrorAndReset(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  void _showGenericQRResult(String data) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.qr_code_2, size: 48, color: ESUNColors.primary),
            const SizedBox(height: 16),
            Text(
              'QR Code Scanned',
              style: ESUNTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data,
                style: ESUNTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isProcessing = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ESUNColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Scan Another', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  void _showPaymentBottomSheet(UPIQRData upiData) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => _PaymentConfirmationSheet(
        upiData: upiData,
        onConfirm: () {
          Navigator.pop(context);
          context.pop(); // Go back from scanner
          // Navigate to payment demo screen or process payment
          _navigateToPayment(upiData);
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() => _isProcessing = false);
        },
      ),
    );
  }

  void _navigateToPayment(UPIQRData upiData) {
    // For now, show a success message and go back
    // In production, this would navigate to a payment confirmation screen
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Initiating payment to ${upiData.pn ?? upiData.pa}'),
        backgroundColor: ESUNColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleTorch() {
    if (_scannerController == null) return;
    
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
    _scannerController!.toggleTorch();
  }

  void _switchCamera() {
    _scannerController?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scanner View
          if (_hasPermission && _scannerController != null)
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Error: ${error.errorCode}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            )
          else if (_isCheckingPermission)
            const Center(
              child: CircularProgressIndicator(color: ESUNColors.primary),
            )
          else
            _buildPermissionDeniedView(),

          // Overlay
          if (_hasPermission) _buildScannerOverlay(),

          // Top Bar
          _buildTopBar(),

          // Bottom Controls
          if (_hasPermission) _buildBottomControls(),

          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: ESUNColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Permission Required',
              style: ESUNTypography.headlineSmall.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Camera access is needed to scan QR codes for payments.',
              style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final status = await Permission.camera.status;
                if (status.isPermanentlyDenied) {
                  openAppSettings();
                } else {
                  _checkCameraPermission();
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ESUNColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        final verticalPadding = (constraints.maxHeight - scanAreaSize) / 2;

        return Stack(
          children: [
            // Darkened overlay
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: scanAreaSize,
                      width: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scan area border
            Center(
              child: Container(
                height: scanAreaSize,
                width: scanAreaSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ESUNColors.primary, width: 3),
                ),
              ),
            ),
            // Corner indicators
            Center(
              child: SizedBox(
                height: scanAreaSize,
                width: scanAreaSize,
                child: Stack(
                  children: [
                    // Top left
                    Positioned(
                      top: -2,
                      left: -2,
                      child: _buildCorner(true, true),
                    ),
                    // Top right
                    Positioned(
                      top: -2,
                      right: -2,
                      child: _buildCorner(true, false),
                    ),
                    // Bottom left
                    Positioned(
                      bottom: -2,
                      left: -2,
                      child: _buildCorner(false, true),
                    ),
                    // Bottom right
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: _buildCorner(false, false),
                    ),
                  ],
                ),
              ),
            ),
            // Scan instruction
            Positioned(
              bottom: verticalPadding - 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Point camera at QR code',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: ESUNColors.primary, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: ESUNColors.primary, width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: ESUNColors.primary, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: ESUNColors.primary, width: 4)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(24) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(24) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(24) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(24) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            Text(
              'Scan & Pay',
              style: ESUNTypography.titleLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(width: 48), // Balance for close button
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12,
          left: 32,
          right: 32,
          top: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: _torchEnabled ? Icons.flash_on : Icons.flash_off,
              label: 'Flash',
              onTap: _toggleTorch,
            ),
            _buildControlButton(
              icon: Icons.image_outlined,
              label: 'Gallery',
              onTap: () {
                // TODO: Implement gallery picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gallery scan coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildControlButton(
              icon: Icons.flip_camera_ios_outlined,
              label: 'Flip',
              onTap: _switchCamera,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Payment confirmation bottom sheet
class _PaymentConfirmationSheet extends StatelessWidget {
  final UPIQRData upiData;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PaymentConfirmationSheet({
    required this.upiData,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Success Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ESUNColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 40,
              color: ESUNColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'QR Code Scanned',
            style: ESUNTypography.headlineSmall,
          ),
          const SizedBox(height: 16),
          // Payee Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 32,
                  backgroundColor: ESUNColors.primary,
                  child: Text(
                    _getInitials(upiData.pn ?? upiData.pa ?? '?'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Name
                Text(
                  upiData.pn ?? 'Unknown',
                  style: ESUNTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // UPI ID
                Text(
                  upiData.pa ?? '',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (upiData.am != null && upiData.am!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Amount',
                    style: ESUNTypography.labelMedium.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${upiData.am}',
                    style: ESUNTypography.headlineMedium.copyWith(
                      color: ESUNColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (upiData.tn != null && upiData.tn!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Note: ${upiData.tn}',
                    style: ESUNTypography.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ESUNColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Proceed to Pay',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
