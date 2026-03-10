import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:petro_app/Screens/Station/ScanResultScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryDarkBlue = Color(0xFF1E40AF);

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Driver QR'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text('Camera Error: ${error.errorCode}'),
                    if (error.errorCode ==
                        MobileScannerErrorCode.permissionDenied)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () => openAppSettings(),
                          child: const Text('Open Settings'),
                        ),
                      ),
                  ],
                ),
              );
            },
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
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Place QR code inside the frame',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
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
        if (mounted)
          _showErrorDialog('Authentication error. Please log in again.');
        return;
      }

      final url = Uri.parse(
        'https://alhamarahomesbd.com/cashless-fuel-api/public/api/v1/station/scan',
      );

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
        if (mounted)
          _showErrorDialog(responseData['message'] ?? 'Invalid QR Code.');
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
        title: const Text('Scan Failed'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Try Again'),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _isProcessing = false;
              });
              controller.start();
            },
          ),
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
