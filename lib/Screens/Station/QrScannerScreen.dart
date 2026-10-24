import 'package:petro_app/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:petro_app/Screens/Station/ScanResultScreen.dart';
import 'package:petro_app/widgets/dashboard_widgets.dart';
import 'package:petro_app/widgets/fuel_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryDarkBlue = Color(0xFF1E40AF);

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;

  // Laser line moving inside the scan window
  late final AnimationController _laserController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  static const double _windowSize = 250;

  @override
  void dispose() {
    controller.dispose();
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            errorBuilder: (context, error) => _buildCameraError(error),
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScannedCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Dimmed overlay with a clear scan window
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(windowSize: _windowSize),
              ),
            ),
          ),

          // Animated corner brackets + laser
          Center(
            child: IgnorePointer(
              child: SizedBox(
                width: _windowSize,
                height: _windowSize,
                child: AnimatedBuilder(
                  animation: _laserController,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(
                      _laserController.value,
                    );
                    return Stack(
                      children: [
                        CustomPaint(
                          size: const Size(_windowSize, _windowSize),
                          painter: _ScanBracketsPainter(glow: 0.5 + t * 0.5),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          top: 16 + (_windowSize - 32) * t,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                colors: [
                                  kFuelAmber.withOpacity(0),
                                  kFuelAmber,
                                  kFuelAmber.withOpacity(0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kFuelAmber.withOpacity(0.7),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Scan Driver QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Cashless fuel payment',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GlassIconButton(
                    icon: _torchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    onTap: () async {
                      try {
                        await controller.toggleTorch();
                        if (mounted) setState(() => _torchOn = !_torchOn);
                      } catch (e) {
                        debugPrint('Torch not available: $e');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom instruction panel
          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kFuelAmber, kFuelOrange],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Place the QR code inside the frame',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Ask the driver to open 'My Fuel Pass'",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Verifying overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FuelTankLogo(size: 110),
                    SizedBox(height: 18),
                    Text(
                      'Verifying driver...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: kFuelDeepNavy,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              denied
                  ? Icons.no_photography_rounded
                  : Icons.videocam_off_rounded,
              color: kFuelAmber,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            denied ? 'Camera permission needed' : 'Camera unavailable',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            denied
                ? 'Allow camera access to scan driver QR codes.'
                : 'Camera Error: ${error.errorCode}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (denied) ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kFuelAmber,
                foregroundColor: kFuelDeepNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleScannedCode(String qrPayload) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    // Stop the camera effectively prevents further scans
    controller.stop();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        if (mounted) {
          _showErrorDialog('Authentication error. Please log in again.');
        }
        return;
      }

      final url = Uri.parse(ApiConfig.stationScan);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'qr_payload': qrPayload}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  ScanResultScreen(scanData: responseData['data']),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(responseData['message'] ?? 'Invalid QR Code.');
        }
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Network error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.qr_code_2_rounded,
            color: Colors.redAccent,
            size: 36,
          ),
        ),
        title: const Text(
          'Scan Failed',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryDarkBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _isProcessing = false;
              });
              controller.start();
            },
          ),
        ],
      ),
    );
  }
}

/// Darkens everything except a rounded square window in the center.
class _ScannerOverlayPainter extends CustomPainter {
  final double windowSize;
  _ScannerOverlayPainter({required this.windowSize});

  @override
  void paint(Canvas canvas, Size size) {
    final window = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: windowSize,
        height: windowSize,
      ),
      const Radius.circular(24),
    );
    final overlay = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(window),
    );
    canvas.drawPath(overlay, Paint()..color = const Color(0xA6061233));
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) =>
      old.windowSize != windowSize;
}

/// Glowing amber corner brackets around the scan window.
class _ScanBracketsPainter extends CustomPainter {
  final double glow;
  _ScanBracketsPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kFuelAmber
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2 + glow * 4);
    const len = 36.0, r = 22.0;
    final w = size.width, h = size.height;

    void corner(Offset o, double sx, double sy) {
      final path = Path()
        ..moveTo(o.dx, o.dy + sy * len)
        ..lineTo(o.dx, o.dy + sy * r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + sx * r, o.dy)
        ..lineTo(o.dx + sx * len, o.dy);
      canvas.drawPath(path, paint);
    }

    corner(const Offset(2, 2), 1, 1);
    corner(Offset(w - 2, 2), -1, 1);
    corner(Offset(2, h - 2), 1, -1);
    corner(Offset(w - 2, h - 2), -1, -1);
  }

  @override
  bool shouldRepaint(_ScanBracketsPainter old) => old.glow != glow;
}
