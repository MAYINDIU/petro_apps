import 'package:flutter/material.dart';
import 'package:petro_app/Screens/login.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _driverProfile;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverProfile();
  }

  Future<void> _fetchDriverProfile() async {
    try {
      final response = await _apiService.getDriverProfile();
      if (mounted) {
        setState(() {
          if (response['success'] == true && response['data'] != null) {
            _driverProfile = response['data'];
          } else {
            _errorMessage = response['message'] ?? 'Failed to load profile.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F7FA,
      ), // Light grey background for professional look
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        // Setting foregroundColor to white handles both the back button and the title text
        foregroundColor: Colors.white,
        backgroundColor: kPrimaryDarkBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final driver = _driverProfile!['driver'];
    final assignment = _driverProfile!['assignment'];
    final wallet = _driverProfile!['wallet_balance']?.toString() ?? '0.00';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Professional Header Section
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: kPrimaryDarkBlue,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Profile Details Card
          Transform.translate(
            offset: const Offset(0, -30),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _infoTile(Icons.person_outline, "Full Name", driver['name']),
                  _infoTile(
                    Icons.email_outlined,
                    "Email Address",
                    driver['email'],
                  ),
                  _infoTile(
                    Icons.phone_outlined,
                    "Phone Number",
                    driver['phone'],
                  ),
                  _infoTile(
                    Icons.verified_user_outlined,
                    "Account Status",
                    driver['status'],
                  ),
                  if (assignment != null) ...[
                    const Divider(height: 30, thickness: 1),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        "Assignment Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryDarkBlue,
                        ),
                      ),
                    ),
                    if (assignment['owner'] != null) ...[
                      _infoTile(
                        Icons.business_center_outlined,
                        "Owner Name",
                        assignment['owner']['name'] ?? 'N/A',
                      ),
                      _infoTile(
                        Icons.support_agent,
                        "Owner Contact",
                        assignment['owner']['phone'] ?? 'N/A',
                      ),
                    ],
                    if (assignment['vehicle'] != null) ...[
                      _infoTile(
                        Icons.directions_bus_outlined,
                        "Vehicle Plate",
                        assignment['vehicle']['plate_number'] ?? 'N/A',
                      ),
                      _infoTile(
                        Icons.info_outline,
                        "Vehicle Model",
                        assignment['vehicle']['model'] ?? 'N/A',
                      ),
                    ],
                  ],
                  const Divider(height: 30),
                  _walletTile(wallet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryDarkBlue, size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletTile(String balance) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Wallet Balance",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "৳ $balance",
            style: TextStyle(
              color: kPrimaryDarkBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 60,
            color: Colors.orange,
          ),
          const SizedBox(height: 10),
          Text(_errorMessage!),
          ElevatedButton(
            onPressed: _fetchDriverProfile,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
