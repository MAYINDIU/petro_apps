import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petro_app/Screens/login.dart';
import 'package:petro_app/widgets/fuel_animations.dart';
import 'package:petro_app/widgets/page_widgets.dart';

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
    setState(() {
      _errorMessage = null;
      if (_driverProfile == null) _isLoading = true;
    });
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
    final driver = _driverProfile?['driver'] as Map<String, dynamic>?;
    final name = driver?['name']?.toString() ?? '';

    return Scaffold(
      backgroundColor: kPageBackground,
      body: RefreshIndicator(
        onRefresh: _fetchDriverProfile,
        color: kPrimaryDarkBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FuelPageHeader(
                title: 'My Profile',
                subtitle: 'Account & assignment details',
                watermark: Icons.person_rounded,
                child: _isLoading || _errorMessage != null
                    ? null
                    : _buildProfileHeader(name, driver?['status']?.toString()),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: FuelLoadingView(message: 'Loading profile...'),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FuelStateView.error(
                  message: _errorMessage,
                  onRetry: _fetchDriverProfile,
                ),
              )
            else
              SliverToBoxAdapter(child: _buildProfileContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String? status) {
    return Row(
      children: [
        FuelAvatar(name: name, radius: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (status != null) FuelStatusBadge(status, onDark: true),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.local_shipping_rounded,
                    size: 14,
                    color: kFuelAmber,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Driver',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    final driver = _driverProfile!['driver'] as Map<String, dynamic>? ?? {};
    final assignment = _driverProfile!['assignment'] as Map<String, dynamic>?;
    final owner = assignment?['owner'] as Map<String, dynamic>?;
    final vehicle = assignment?['vehicle'] as Map<String, dynamic>?;
    final wallet =
        double.tryParse(_driverProfile!['wallet_balance']?.toString() ?? '') ??
        0;

    String text(dynamic v) =>
        (v == null || v.toString().isEmpty) ? 'N/A' : v.toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Column(
        children: [
          _walletTile(wallet),
          const SizedBox(height: 16),
          FuelSectionCard(
            title: 'Personal information',
            icon: Icons.badge_rounded,
            child: Column(
              children: [
                FuelInfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Full Name',
                  value: text(driver['name']),
                ),
                FuelInfoRow(
                  icon: Icons.alternate_email_rounded,
                  label: 'Email Address',
                  value: text(driver['email']),
                ),
                FuelInfoRow(
                  icon: Icons.phone_iphone_rounded,
                  label: 'Phone Number',
                  value: text(driver['phone']),
                ),
                FuelInfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Account Status',
                  value: text(driver['status']).toUpperCase(),
                  showDivider: false,
                ),
              ],
            ),
          ),
          if (assignment != null) ...[
            const SizedBox(height: 16),
            FuelSectionCard(
              title: 'Assignment',
              icon: Icons.directions_bus_rounded,
              child: Column(
                children: [
                  if (vehicle != null) ...[
                    const SizedBox(height: 6),
                    _plateBadge(text(vehicle['plate_number'])),
                    const SizedBox(height: 6),
                    FuelInfoRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Vehicle Model',
                      value: text(vehicle['model']),
                      showDivider: owner != null,
                    ),
                  ],
                  if (owner != null) ...[
                    FuelInfoRow(
                      icon: Icons.business_center_outlined,
                      label: 'Owner Name',
                      value: text(owner['name']),
                    ),
                    FuelInfoRow(
                      icon: Icons.support_agent_rounded,
                      label: 'Owner Contact',
                      value: text(owner['phone']),
                      showDivider: false,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Number-plate style badge for the assigned vehicle.
  Widget _plateBadge(String plate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kFuelAmber, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus_rounded, color: kFuelOrange),
          const SizedBox(width: 10),
          const Text(
            'PLATE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9A3412),
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            plate,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: kTextColorDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletTile(double balance) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kFuelAmber, kFuelOrange],
        ),
        boxShadow: [
          BoxShadow(
            color: kFuelOrange.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: kFuelDeepNavy,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Wallet Balance',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: kFuelDeepNavy,
                fontSize: 15,
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: balance),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutExpo,
            builder: (context, v, _) => Text(
              '৳ ${NumberFormat('#,##0.00').format(v)}',
              style: const TextStyle(
                color: kFuelDeepNavy,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
