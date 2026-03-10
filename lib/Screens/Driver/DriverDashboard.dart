import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:petro_app/Screens/Public/change_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:petro_app/Screens/login.dart';
import 'package:petro_app/Screens/Driver/DriverProfileScreen.dart';
import 'package:petro_app/Screens/Driver/DriverQrCodeScreen.dart';

// --- Constants (Colors and Paths) ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kCardBackground = Color(0xFFFFFFFF);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kTextColorDark = Color(0xFF1F2937);
const Color kHintColor = Color(0xFF9CA3AF);
const String _assetProfileIconPath =
    'assets/icons/icon.png'; // Placeholder path
// --- Supporting Models and Placeholder Screens ---

class DashboardIconData {
  final String iconPath;
  final String title;
  const DashboardIconData(this.iconPath, this.title);
}
// -------------------------------------------------------------------------
// 🔥 CustomerDashboard State Implementation
// -------------------------------------------------------------------------

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});
  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  // --- State Variables ---
  String _userName = 'Loading User...';
  String _userEmail = 'loading@app.com';
  String _userMobile = '00000000000';
  String _userRole = '';
  String? _accessToken;
  double _currentBalance = 0.00;
  bool _isLoading = true;
  Map<String, dynamic> _walletData = {
    "balance": 0,
    "spend_today": 0,
    "spend_week": 0,
  };

  // --- Dashboard Items List ---
  final List<DashboardIconData> dashboardItems = const [
    DashboardIconData('assets/icons/prfl.png', 'My Profile'),
    DashboardIconData('assets/icons/qr.png', 'QR CODE'),
    DashboardIconData('assets/icons/wallet.png', 'Wallet Summary'),
    DashboardIconData('assets/icons/tnlist.png', 'Transaction History'),
    DashboardIconData('assets/icons/search.png', 'Transaction By Id'),
    DashboardIconData('assets/icons/upload.png', 'Driver Transaction Meter'),
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
      _currentBalance = prefs.getDouble('current_balance') ?? 0.00;
    });
    debugPrint('Access Token Retrieved: $_accessToken');
  }

  Future<void> _fetchWalletSummary() async {
    if (_accessToken == null) return;
    try {
      final Uri url = Uri.parse(
        "https://alhamarahomesbd.com/cashless-fuel-api/public/api/v1/driver/wallet",
      );
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _walletData = data['data'];
          });
        }
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
        final Uri url = Uri.parse(
          "https://alhamarahomesbd.com/cashless-fuel-api/public/api/v1/auth/logout",
        );
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

  // --- UI Component Helpers ---

  Widget _buildWalletCard() {
    final double balance = (_walletData['balance'] is int)
        ? (_walletData['balance'] as int).toDouble()
        : (_walletData['balance'] as double? ?? 0.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: kPrimaryDarkBlue.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative Background Shapes
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset(
                            _assetProfileIconPath,
                            height: 40,
                            width: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                              _userName.isNotEmpty ? _userName[0] : 'U',
                              style: const TextStyle(
                                fontSize: 20,
                                color: kPrimaryDarkBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userRole == 'USER' ? 'Driver' : _userRole,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.3)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Current Balance",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ),

                  // Animated Counter
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: balance),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeOutExpo,
                    builder: (context, value, child) {
                      return Text(
                        "৳ ${value.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _buildMiniStat(
                        "Today",
                        "৳ ${_walletData['spend_today']}",
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.white30,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      _buildMiniStat(
                        "This Week",
                        "৳ ${_walletData['spend_week']}",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 3. Static Right Sidebar Content (unchanged)
  Widget _buildRightSidebarContent(BuildContext context) {
    return Container();
  }

  // 4. Main Dashboard Content (unchanged)
  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildWalletCard(),

        const Text(
          'Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColorDark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: dashboardItems.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = dashboardItems[index];
            return _AnimatedGridItem(
              item: item,
              index: index,
              onTap: () => _onItemTapped(item.title),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _onItemTapped(String title) {
    Widget destination;

    if (title == 'QR CODE') {
      destination = const DriverQrCodeScreen();
    } else if (title == 'My Profile') {
      destination = const DriverProfileScreen();
    } else {
      destination = _buildPlaceholderScreen(title);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  Widget _buildPlaceholderScreen(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            title.contains('Payment Gateway')
                ? 'Initiating Secure Payment with $title. \n(This is where the SSLCommerz web view would load.)'
                : 'Navigation for "$title" is not yet implemented.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: kPrimaryDarkBlue),
          ),
        ),
      ),
    );
  }

  // 5. The Professional Dark Blue Navigation Drawer (unchanged)

  Widget _buildLeftDrawer(BuildContext context) {
    // Defines the content for the account details (NID/Mobile)
    final Widget accountEmailWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Align details to center
      children: [
        Text(
          'Email: $_userEmail',
          style: TextStyle(
            color: kTextColorLight.withOpacity(0.8),
            fontSize: 13,
          ),
        ),
        Text(
          'Mobile: $_userMobile',
          style: TextStyle(
            color: kTextColorLight.withOpacity(0.8),
            fontSize: 13,
          ),
        ),
        if (_userRole.isNotEmpty)
          Text(
            'Role: ${_userRole == 'USER' ? 'Driver' : (_userRole == 'AGENT' ? 'Station' : _userRole)}',
            style: TextStyle(
              color: kTextColorLight.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
      ],
    );

    return Drawer(
      backgroundColor: kCardBackground,
      child: Column(
        // Main Column inside the Drawer
        // No need for crossAxisAlignment here, as the Card/Container below is full width
        children: <Widget>[
          // 🛑 FIX: Custom Header replaces UserAccountsDrawerHeader for centering 🛑
          Card(
            elevation: 8,
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.only(
                top: 40,
                bottom: 25,
                left: 20,
                right: 20,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryDarkBlue, kPrimaryDarkBlue.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                // 🔑 Centers all content (picture, name, email) horizontally
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Profile Picture (Centered with requested 8.0 Bottom Padding)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: kTextColorLight,
                      child: ClipOval(
                        child: Image.asset(
                          _assetProfileIconPath,
                          height: 70,
                          width: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            _userName.isNotEmpty ? _userName[0] : 'U',
                            style: const TextStyle(
                              fontSize: 28,
                              color: kPrimaryDarkBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Account Name (Centered)
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kTextColorLight,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 3. Account Email/Details (Centered)
                  accountEmailWidget,
                ],
              ),
            ),
          ),

          // --- Scrollable Content Section ---
          Expanded(
            child: SingleChildScrollView(
              // Makes the content scrollable
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.person, color: kPrimaryDarkBlue),
                    title: const Text(
                      'My Profile',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(
                        'My Profile',
                      ); // This will now navigate to DriverProfileScreen
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.qr_code_2,
                      color: kPrimaryDarkBlue,
                    ),
                    title: const Text(
                      'QR CODE',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped('QR CODE');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: kPrimaryDarkBlue,
                    ),
                    title: const Text(
                      'Wallet Summary',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped('Wallet Summary');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.receipt_long,
                      color: kPrimaryDarkBlue,
                    ),
                    title: const Text(
                      'Transaction History',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped('Transaction History');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.manage_search,
                      color: kPrimaryDarkBlue,
                    ),
                    title: const Text(
                      'Transaction By Id',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped('Transaction By Id');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.speed, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Driver Transaction Meter',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped('Driver Transaction Meter');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Change Password',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                      debugPrint('Change Password Tapped');
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Logout (Fixed at the Bottom) ---
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _clearUserSession();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Logging out...')));
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
          const SafeArea(bottom: true, top: false, child: SizedBox(height: 0)),
        ],
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: kScaffoldBackground,
        body: Center(child: CircularProgressIndicator(color: kPrimaryDarkBlue)),
      );
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor: kScaffoldBackground,
        drawer: isLargeScreen ? null : _buildLeftDrawer(context),

        // 🛑 FIX: Corrected the broken AppBar syntax 🛑
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Welcome, $_userName',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: kPrimaryDarkBlue,
          foregroundColor: kTextColorLight,
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: isLargeScreen
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Main Content (Takes up 65% of the width)
                    Expanded(flex: 7, child: _buildMainContent(context)),
                    const SizedBox(width: 20),
                    // Right Sidebar (Takes up 35% of the width)
                    Expanded(
                      flex: 3,
                      child: _buildRightSidebarContent(context),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Main Content for smaller screens
                    _buildMainContent(context),
                    const SizedBox(height: 25),
                    // Right Sidebar content moved below the main content on small screens
                    _buildRightSidebarContent(context),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AnimatedGridItem extends StatefulWidget {
  final DashboardIconData item;
  final int index;
  final VoidCallback onTap;

  const _AnimatedGridItem({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  _AnimatedGridItemState createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<_AnimatedGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (widget.index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered ? kPrimaryDarkBlue : Colors.transparent,
              width: 0.4,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? kPrimaryDarkBlue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              splashColor: kPrimaryDarkBlue.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(widget.item.iconPath, width: 40, height: 40),
                    const SizedBox(height: 8),
                    Text(
                      widget.item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kTextColorDark,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
