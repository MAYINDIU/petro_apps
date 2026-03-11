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
  String? _errorMessage;
  Map<String, dynamic>? _qrData;
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
            _qrData = response['data'];
          } else {
            _errorMessage = response['message'] ?? 'Failed to load QR Code.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = 'Connection error. Please try again.';
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
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (_qrData == null) {
      return _buildErrorState(message: 'No QR data available.');
    }

    final qrPayload = _qrData!['qr_payload'] as String?;
    final driver = _qrData!['driver'] as Map<String, dynamic>?;
    final assignment = _qrData!['assignment'] as Map<String, dynamic>?;
    final vehicle = assignment?['vehicle'] as Map<String, dynamic>?;
    final wallet = _qrData!['wallet'] as Map<String, dynamic>?;

    final driverName = driver?['name'] ?? 'Driver';
    final plateNumber = vehicle?['plate_number'] ?? 'N/A';
    final balance = wallet?['balance']?.toString() ?? '0';

    if (qrPayload == null) {
      return _buildErrorState(message: 'QR payload could not be generated.');
    }

    return Column(
      children: [
        // Top section with visual context
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
          decoration: BoxDecoration(
            color: kPrimaryDarkBlue,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Text(
                  driverName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  plateNumber,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Show this to the station attendant",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        // QR Code Container
        Transform.translate(
          offset: const Offset(0, -40),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // QR Code Image
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: QrImageView(
                    data: qrPayload,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 20),

                // Wallet Balance
                _buildWalletInfo(balance),

                const SizedBox(height: 20),

                // Refresh Button
                OutlinedButton.icon(
                  onPressed: _fetchQrCode,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Code"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryDarkBlue,
                    side: BorderSide(color: kPrimaryDarkBlue.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletInfo(String balance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Available Balance",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kTextColorDark,
            ),
          ),
          Text(
            "৳ $balance",
            style: TextStyle(
              color: kPrimaryDarkBlue,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({String? message}) {
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
