import 'package:flutter/material.dart';
import 'package:petro_app/Screens/Public/Claim_payment_list_api_fetch.dart';
import 'package:petro_app/Screens/Public/ContactUsScreen.dart';
import 'package:petro_app/Screens/Public/PolicyAdvisorOne.dart';
import 'package:petro_app/Screens/Public/apply_for_policy_screen.dart';
import 'package:petro_app/Screens/Public/Forms_download_live_api.dart';
import 'package:petro_app/Screens/Public/PolicyCategory.dart';
import 'package:petro_app/Screens/Public/claim_policy_search_screen.dart';
import 'package:petro_app/Screens/Public/nli_about_us.dart';
import 'package:petro_app/Screens/Public/premium_calculator_screen.dart';
import 'dart:async';
import 'package:petro_app/Screens/Public/bonusRate.dart';
import 'package:petro_app/Screens/Public/maturity_benefit_form.dart';
import 'package:petro_app/Screens/login.dart';
import 'package:petro_app/Screens/Public/TrackingCode.dart';

// ------------------- Helper Data Structure -------------------

/// Helper for the custom assets shown in the grid
class DashboardIconData {
  final String iconPath;
  final String title;

  const DashboardIconData(this.iconPath, String title) : title = title;
}

// ------------------- Main Dashboard Widget -------------------

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _PolishedDashboardState();
}

class _PolishedDashboardState extends State<Dashboard> {
  // --- Data for the Policy Grid (All 12 items) ---
  final List<DashboardIconData> dashboardItems = const [
    DashboardIconData('assets/icons/products.png', 'Our Products'),
    DashboardIconData('assets/icons/claim.png', 'Claim Policy'),
    DashboardIconData('assets/icons/bonus_rate.png', 'Bonus Rate'),
    DashboardIconData('assets/icons/maturity_benifit.png', 'Maturity Benefit'),

    DashboardIconData('assets/icons/form_download.png', 'Forms Download'),
    DashboardIconData('assets/icons/claim_payment.png', 'Claim Payment'),
    DashboardIconData('assets/icons/contact-us.png', 'Contact Us'),
    DashboardIconData('assets/icons/policy_advisor.png', 'Policy Advisor'),
    DashboardIconData('assets/icons/pay_with_proposal.png', 'Pay Proposal No'),
    DashboardIconData('assets/icons/apply_policy.png', 'Apply For Policy'),
    DashboardIconData('assets/icons/tracking.png', 'Use Tracking Code'),
    DashboardIconData('assets/icons/others.png', 'About Us'),
  ];

  // --- Slider State & Content ---
  final List<String> _sliderImages = const [
    'assets/images/banner.jpg',
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner.jpg',
  ];

  int _currentPage = 0;
  late PageController _pageController;
  late Timer _timer;

  // --- Tab State & Colors ---
  int _selectedIndex = 0;
  final Color _lightBackground = Colors.white;
  final Color _darkTextColor = Colors.black87;
  final Color _accentColor = const Color(0xFF007AFF); // Vibrant Blue accent

  // --- List of widgets for the BottomNavigationBar tabs ---
  late final List<Widget> _widgetOptions = <Widget>[
    // Index 0: Dashboard Content
    SingleChildScrollView(
      padding: EdgeInsets
          .zero, // Ensures no extra space at the top of the scroll view.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildWelcomeHeader(),
          _buildImageSlider(),
          // Padding adjusted to eliminate top margin/padding for the grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: _buildGridSection(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
    // Index 1: Premium Calculator Tab
    const PremiumCalculatorScreen(),
    // Index 2: Products/My Plans Tab (Using Placeholder)
    const PolicyCategoryScreen(),
    // Index 3: Login/Support Tab (Using Placeholder)
    // _buildPlaceholderScreen('Support / Login'),
    const LoginPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize PageController for a full-width slider.
    _pageController = PageController(initialPage: 0);

    _timer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (mounted) {
        // The setState call ensures the UI rebuilds for the automatic slide.
        setState(() {
          if (_currentPage < _sliderImages.length - 1) {
            _currentPage++;
          } else {
            _currentPage = 0;
          }
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeIn,
          );
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  // ------------------- Placeholder Screen Function -------------------

  /// Used for screens that are not fully built yet, replacing the 'TargetScreen'.
  Widget _buildPlaceholderScreen(String title) {
    return Scaffold(
      body: Center(
        child: Text(
          'Placeholder Screen for "$title" - Not Yet Implemented',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, color: Colors.black87),
        ),
      ),
    );
  }

  // ------------------- Navigation Logic -------------------

  void _onItemTapped(String title) {
    if (title == 'Pay Proposal No') {
      return;
    }
    Widget destination;

    // Map known grid items to their imported screens
    if (title == 'Our Products' || title == 'Products') {
      destination = const PolicyCategoryScreen();
    } else if (title == 'Bonus Rate') {
      destination = const BonusRatePage();
    } else if (title == 'Policy Advisor') {
      destination = const PolicyAdvisorOne();
    } else if (title == 'Use Tracking Code') {
      destination = const TrackingCodeScreen();
    } else if (title == 'Claim Policy') {
      destination = const ClaimPolicySearchScreen();
    } else if (title == 'Maturity Benefit') {
      destination = const MaturityBenefitForm();
    } else if (title == 'Forms Download') {
      destination = const FormsDownloadScreen();
    } else if (title == 'Claim Payment') {
      destination = const ClaimPaymentScreen();
    } else if (title == 'Contact Us') {
      destination = const ContactUsScreen();
    } else if (title == 'About Us') {
      destination = const AboutUsPage();
    } else if (title == 'Apply For Policy') {
      destination = const ApplyForPolicyScreen();
    } else if (title == 'Get Quote / Premium Calculator' ||
        title == 'Premium Calculator') {
      destination = const PremiumCalculatorScreen();
    } else {
      // Use placeholder for all other links
      destination = _buildPlaceholderScreen(title);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ------------------- Main Build Method -------------------

  @override
  Widget build(BuildContext context) {
    final List<String> tabTitles = const [
      'Dashboard',
      'Premium Calculator',
      'Products',
      'Login',
    ];

    return Scaffold(
      // MODIFICATION: AppBar is now always null
      appBar: null,

      backgroundColor: _lightBackground,

      // Displays the current tab content
      body: _widgetOptions.elementAt(_selectedIndex),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ------------------- Helper Widgets -------------------

  Widget _buildWelcomeHeader() {
    const LinearGradient blueGradient = LinearGradient(
      colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        50,
        20,
        0,
      ), // Set bottom padding to 0 to remove the gap.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icons/logo.png', // Ensure this asset exists
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return blueGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    );
                  },
                  child: const Text(
                    'National Life Insurance PLC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      shadows: [],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildImageSlider() {
    return Column(
      children: [
        SizedBox(
          // Increased height to accommodate the new design
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _sliderImages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage =
                    page; // This updates the state for both manual and automatic slides.
              });
            },
            itemBuilder: (context, index) {
              // Directly build the slider item without scaling animations for a clean, full-width look.
              return _buildSliderItem(_sliderImages[index], index);
            },
          ),
        ),
        // Re-introduce the dot indicators with spacing.
        const SizedBox(height: 10),
        // Dot indicators are now closer to the grid.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _sliderImages.length,
            (index) => _buildDotIndicator(index),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderItem(String imagePath, int index) {
    return Card(
      elevation: 4,
      // "p-2" is interpreted as a standard margin for a card-like appearance.
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        // onTap: () => _onItemTapped('Slider Promotion'),
        child: Container(
          decoration: const BoxDecoration(),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Text(
                        'Image asset not found',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              // Add a subtle gradient overlay for a more professional look.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Re-introduce the dot indicator widget with modern styling.
  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _currentPage == index ? 24.0 : 8.0, // Active dot is wider
      height: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: _currentPage == index ? _accentColor : Colors.grey.shade400,
      ),
    );
  }

  // Grid Section - ALL ITEMS, 3 COLUMNS
  Widget _buildGridSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 1.0,
          ),
          itemCount: dashboardItems.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildGridItem(context, item: dashboardItems[index]);
          },
        ),
      ],
    );
  }

  Widget _buildGridItem(
    BuildContext context, {
    required DashboardIconData item,
  }) {
    // ignore: unused_local_variable
    const Color iconBackgroundColor = Color.fromRGBO(255, 255, 255, 1);

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _onItemTapped(item.title),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(),
                child: Image.asset(
                  item.iconPath,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.error_outline,
                      size: 24,
                      color: Colors.red,
                    );
                  },
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _darkTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    const double iconSize = 24.0;

    final List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/icons/home.png',
          width: iconSize,
          height: iconSize,
        ),
        activeIcon: Image.asset(
          'assets/icons/home.png',
          width: iconSize,
          height: iconSize,
        ),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/icons/calculator.png',
          width: iconSize,
          height: iconSize,
        ),
        activeIcon: Image.asset(
          'assets/icons/calculator.png',
          width: iconSize,
          height: iconSize,
        ),
        label: 'Premium Calculator',
      ),
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/icons/products.png',
          width: iconSize,
          height: iconSize,
        ),
        activeIcon: Image.asset(
          'assets/icons/products.png',
          width: iconSize,
          height: iconSize,
        ),
        label: 'Products',
      ),
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/icons/login.png',
          width: iconSize,
          height: iconSize,
        ),
        activeIcon: Image.asset(
          'assets/icons/login.png',
          width: iconSize,
          height: iconSize,
        ),
        label: 'Login',
      ),
    ];

    return BottomNavigationBar(
      items: items,
      currentIndex: _selectedIndex,
      selectedItemColor: _accentColor,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      onTap: _onTabTapped,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      showUnselectedLabels: true,
      elevation: 10,
    );
  }
}
