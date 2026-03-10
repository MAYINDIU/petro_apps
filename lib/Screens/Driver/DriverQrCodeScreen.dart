import 'package:flutter/material.dart';
import 'package:petro_app/Screens/login.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DriverQrCodeScreen extends StatefulWidget {
  const DriverQrCodeScreen({super.key});

  @override
  State<DriverQrCodeScreen> createState() => _DriverQrCodeScreenState();
}

class _DriverQrCodeScreenState extends State<DriverQrCodeScreen> {
  final ApiService _apiService = ApiService();
  String? _qrPayload;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQrCode();
  }

  Future<void> _fetchQrCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiService.getDriverQrCode();
      if (mounted) {
        setState(() {
          if (response['success'] == true && response['data'] != null) {
            _qrPayload = response['data']['qr_payload'];
          } else {
            _errorMessage = response['message'] ?? 'Failed to load QR.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = 'Connection error.';
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fuel Authentication',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor:
            Colors.white, // Standardized white for back button/title
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryDarkBlue),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) return _buildErrorState();

    return Column(
      children: [
        // Top section with visual context
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
          decoration: BoxDecoration(
            color: kPrimaryDarkBlue,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 50,
                color: Colors.white70,
              ),
              const SizedBox(height: 15),
              const Text(
                "Your Digital Fuel Pass",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Show this to the station attendant",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),

        // QR Code Container
        Transform.translate(
          offset: const Offset(0, -30),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: QrImageView(
                    data: _qrPayload!,
                    version: QrVersions.auto,
                    size: 220.0,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "Valid until current session ends",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _fetchQrCode,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Code"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryDarkBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 60),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_errorMessage!, textAlign: TextAlign.center),
          ),
          ElevatedButton(onPressed: _fetchQrCode, child: const Text("Retry")),
        ],
      ),
    );
  }
}
