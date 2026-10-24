import 'package:petro_app/api_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:petro_app/Screens/login.dart';
import 'package:petro_app/Screens/Station/QrScannerScreen.dart';
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

class StationDashboard extends StatefulWidget {
  const StationDashboard({super.key});
  @override
  State<StationDashboard> createState() => _StationDashboardState();
}

class _StationDashboardState extends State<StationDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- State Variables ---
  String _userName = 'Loading User...';
  String _userEmail = 'loading@app.com';
  String _userMobile = '00000000000';
  String _userRole = '';
  String? _accessToken;
  bool _isLoading = true;

  // --- Dashboard Items List ---
  static const List<DashboardServiceItem> dashboardItems = [
    DashboardServiceItem(
      Icons.local_gas_station_rounded,
      'Fuel Entry',
      'Record a fuel sale',
      Color(0xFFF97316),
    ),
    DashboardServiceItem(
      Icons.request_quote_rounded,
      'Create Settlement',
      'Settle your balance',
      Color(0xFF10B981),
    ),
    DashboardServiceItem(
      Icons.insights_rounded,
      'Report Summary',
      'Sales overview',
      Color(0xFF8B5CF6),
    ),
    DashboardServiceItem(
      Icons.today_rounded,
      'Daily Report',
      "Today's transactions",
      Color(0xFF0EA5E9),
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

  String get _roleLabel {
    final role = _userRole.toLowerCase();
    if (role == 'agent' || role == 'station') return 'Station Partner';
    return _userRole.isEmpty ? 'Station Partner' : _userRole;
  }

  // --- Navigation ---

  void _onItemTapped(String title) {
    final Widget destination = title == 'Scan Driver'
        ? const QrScannerScreen()
        // All other items navigate to a placeholder screen for now.
        : ComingSoonScreen(title: title);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  // --- UI: Header ---

  Widget _buildHeader() {
    return Stack(
      children: [
        const DashboardHeaderBackground(),
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
                _buildStationCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- UI: Credit-card style station pass ---

  Widget _buildStationCard() {
    return FuelPaymentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'STATION PASS',
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
          const SizedBox(height: 12),
          const CardChip(),
          const Spacer(),
          Text(
            _userName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardInfo(Icons.mail_outline_rounded, _userEmail),
                    const SizedBox(height: 3),
                    _cardInfo(Icons.phone_iphone_rounded, _userMobile),
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

  Widget _cardInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // --- UI: Main content ---

  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PulsingActionCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan Driver QR',
                subtitle:
                    "Scan the driver's code to start a cashless fuel sale",
                onTap: () => _onItemTapped('Scan Driver'),
              ),
              const SizedBox(height: 24),
              const DashboardSectionTitle('Services'),
              DashboardServiceGrid(
                items: dashboardItems,
                onTap: (item) => _onItemTapped(item.title),
              ),
              const SizedBox(height: 24),
              const DashboardSectionTitle('How it works'),
              const HowItWorksStrip(
                steps: [
                  (Icons.qr_code_2_rounded, 'Scan QR'),
                  (Icons.local_gas_station_rounded, 'Enter fuel'),
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
              Icons.qr_code_scanner_rounded,
              'Scan Driver',
              () => _onItemTapped('Scan Driver'),
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
