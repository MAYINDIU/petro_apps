import 'package:petro_app/api_config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:petro_app/Screens/login.dart';
import 'package:petro_app/Screens/Driver/DriverProfileScreen.dart';
import 'package:petro_app/Screens/Driver/DriverTransactionHistoryScreen.dart';
import 'package:petro_app/Screens/Driver/WalletSummaryScreen.dart';
import 'package:petro_app/Screens/Driver/DriverQrCodeScreen.dart';
import 'package:petro_app/widgets/dashboard_widgets.dart';
import 'package:petro_app/widgets/fuel_animations.dart';

// --- Constants (Colors and Paths) ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF1F5F9);
const Color kCardBackground = Color(0xFFFFFFFF);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kTextColorDark = Color(0xFF1F2937);
const Color kHintColor = Color(0xFF9CA3AF);

final NumberFormat _money = NumberFormat('#,##0.00');

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});
  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- State Variables ---
  String _userName = 'Loading User...';
  String _userEmail = 'loading@app.com';
  String _userMobile = '00000000000';
  String _userRole = '';
  String? _accessToken;
  bool _isLoading = true;
  Map<String, dynamic> _walletData = {
    "balance": 0,
    "spend_today": 0,
    "spend_week": 0,
  };

  // --- Dashboard Items List ---
  static const List<DashboardServiceItem> dashboardItems = [
    DashboardServiceItem(
      Icons.person_rounded,
      'My Profile',
      'Your account details',
      Color(0xFF3B82F6),
    ),
    DashboardServiceItem(
      Icons.account_balance_wallet_rounded,
      'Wallet Summary',
      'Balance & spending',
      Color(0xFF10B981),
    ),
    DashboardServiceItem(
      Icons.receipt_long_rounded,
      'Transaction History',
      'All fuel payments',
      Color(0xFF8B5CF6),
    ),
    DashboardServiceItem(
      Icons.manage_search_rounded,
      'Transaction By Id',
      'Find a payment',
      Color(0xFF0EA5E9),
    ),
    DashboardServiceItem(
      Icons.speed_rounded,
      'Driver Transaction Meter',
      'Meter readings',
      Color(0xFFF97316),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // --- Core Data Flow ---

  Future<void> _loadAllData() async {
    await _loadUserInfo();
    await _fetchWalletSummary();
    setState(() {
      _isLoading = false;
    });
  }

  // RETRIEVE USER INFO: Loads data from SharedPreferences into state.
  Future<void> _loadUserInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? tokenFromStorage = prefs.getString('accessToken');

    setState(() {
      _userName = prefs.getString('username') ?? 'Loading User...';
      _userEmail = prefs.getString('email') ?? 'loading@app.com';
      _userMobile = prefs.getString('mobile') ?? '00000000000';
      _userRole = prefs.getString('userType') ?? '';
      _accessToken = tokenFromStorage;
    });
    debugPrint('Access Token Retrieved: $_accessToken');
  }

  Future<void> _fetchWalletSummary() async {
    if (_accessToken == null) return;
    final ApiService apiService = ApiService();
    try {
      final response = await apiService.getDriverWalletSummary();

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _walletData = response['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching wallet summary: $e");
    }
  }

  Future<void> _clearUserSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Call Logout API
    final String? token = prefs.getString('accessToken');
    if (token != null) {
      try {
        final Uri url = Uri.parse(ApiConfig.logout);
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        debugPrint("Error logging out from server: $e");
      }
    }

    await prefs.clear();
    debugPrint('User session data cleared successfully.');
  }

  Future<void> _logout() async {
    await _clearUserSession();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logging out...')));
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  double _walletValue(String key) {
    final value = _walletData[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  String get _roleLabel {
    final role = _userRole.toLowerCase();
    if (role.isEmpty || role == 'user' || role == 'driver') return 'Driver';
    if (role == 'bus_owner') return 'Bus Owner';
    return _userRole;
  }

  // --- Navigation ---

  void _onItemTapped(String title) {
    Widget destination;

    if (title == 'QR CODE') {
      destination = const DriverQrCodeScreen();
    } else if (title == 'My Profile') {
      destination = const DriverProfileScreen();
    } else if (title == 'Transaction History') {
      destination = const DriverTransactionHistoryScreen();
    } else if (title == 'Wallet Summary') {
      destination = const WalletSummaryScreen();
    } else {
      destination = ComingSoonScreen(title: title);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  // --- UI: Header ---

  Widget _buildHeader() {
    return Stack(
      children: [
        const DashboardHeaderBackground(
          watermark: Icons.local_shipping_rounded,
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.menu_rounded,
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.local_gas_station_rounded,
                      color: kFuelAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'WMS CWallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    GlassIconButton(icon: Icons.logout_rounded, onTap: _logout),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '${timeOfDayGreeting()},',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _buildWalletCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- UI: Credit-card style fuel wallet ---

  Widget _buildWalletCard() {
    final balance = _walletValue('balance');
    return FuelPaymentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'FUEL WALLET',
                style: TextStyle(
                  color: kFuelAmber,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.contactless_rounded,
                color: Colors.white.withOpacity(0.85),
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const CardChip(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                      ),
                    ),
                    // Animated counter
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: balance),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeOutExpo,
                      builder: (context, value, child) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "৳ ${_money.format(value)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userMobile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kFuelAmber, kFuelOrange],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: kFuelDeepNavy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _roleLabel,
                      style: const TextStyle(
                        color: kFuelDeepNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI: Spending tiles ---

  Widget _buildSpendTile({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: kHintColor),
                ),
                const SizedBox(height: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: amount),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutExpo,
                  builder: (context, value, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "৳ ${_money.format(value)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextColorDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI: Main content ---

  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSpendTile(
                      icon: Icons.today_rounded,
                      label: 'Spent today',
                      amount: _walletValue('spend_today'),
                      color: kFuelOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSpendTile(
                      icon: Icons.date_range_rounded,
                      label: 'This week',
                      amount: _walletValue('spend_week'),
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PulsingActionCard(
                icon: Icons.qr_code_2_rounded,
                title: 'Show My QR Code',
                subtitle: 'Let the station scan it to pay for fuel',
                onTap: () => _onItemTapped('QR CODE'),
              ),
              const SizedBox(height: 24),
              const DashboardSectionTitle('Services'),
              DashboardServiceGrid(
                items: dashboardItems,
                onTap: (item) => _onItemTapped(item.title),
              ),
              const SizedBox(height: 24),
              const DashboardSectionTitle('How to pay'),
              const HowItWorksStrip(
                steps: [
                  (Icons.qr_code_2_rounded, 'Show QR'),
                  (Icons.local_gas_station_rounded, 'Station scans'),
                  (Icons.task_alt_rounded, 'Paid'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kScaffoldBackground,
        body: Center(child: CircularProgressIndicator(color: kPrimaryDarkBlue)),
      );
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: kScaffoldBackground,
        drawer: DashboardDrawer(
          name: _userName,
          email: _userEmail,
          mobile: _userMobile,
          roleLabel: _roleLabel,
          items: [
            (
              Icons.qr_code_2_rounded,
              'QR Code',
              () => _onItemTapped('QR CODE'),
            ),
            for (final item in dashboardItems)
              (item.icon, item.title, () => _onItemTapped(item.title)),
          ],
          footerItems: [
            (
              Icons.lock_outline_rounded,
              'Change Password',
              () => debugPrint('Change Password Tapped'),
            ),
          ],
          onLogout: _logout,
        ),
        body: RefreshIndicator(
          onRefresh: _loadAllData,
          color: kPrimaryDarkBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _buildMainContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
