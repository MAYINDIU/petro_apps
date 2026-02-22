import 'package:flutter/material.dart';
import 'package:nli_apps/Screens/Agent/DuePolicyList.dart';
import 'package:nli_apps/Screens/Agent/InforcePolicyList.dart';
import 'package:nli_apps/Screens/Agent/change_password_screen.dart';
import 'package:nli_apps/Screens/Agent/business_summary_screen.dart';
import 'package:nli_apps/Screens/Agent/business_summary_mh_new_screen.dart';
import 'package:nli_apps/Screens/Agent/business_performance_page.dart';
import 'package:nli_apps/Screens/Agent/AgentOnboarding.dart';
import 'package:nli_apps/Screens/Agent/complains_feedback_screen.dart';
import 'package:nli_apps/Screens/Agent/team_details_business_screen.dart';
import 'package:nli_apps/Screens/Agent/team_list_mh_screen.dart';
import 'package:nli_apps/Screens/Agent/second_year_ren_business_all_screen.dart';
import 'package:nli_apps/Screens/Agent/secondyearbusinessformh.dart';
import 'package:nli_apps/Screens/Agent/teamlist.dart';
import 'package:nli_apps/Screens/Public/Forms_download_live_api.dart'; 
import 'package:nli_apps/Screens/Public/PolicyCategory.dart';
import 'package:nli_apps/Screens/Agent/policy_search_screen.dart';
import 'package:nli_apps/Screens/Public/apply_for_policy_screen.dart';
import 'package:nli_apps/Screens/Public/bonusRate.dart';
import 'package:nli_apps/Screens/Public/Claim_payment_list_api_fetch.dart';
import 'package:nli_apps/Screens/Public/dashboard.dart';
import 'package:nli_apps/Screens/Public/maturity_benefit_form.dart';
import 'package:nli_apps/Screens/Public/premium_calculator_screen.dart';
import 'package:nli_apps/Screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nli_apps/Screens/Public/AccountDeletionRequest.dart';
// --- Constants ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kTextColorDark = Color(0xFF1F2937);

class AgentToolData {
  final String iconPath;
  final String title;
  const AgentToolData(this.iconPath, this.title);
}

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  String _username = 'Loading...';
  String _empId = '';
  String _designation = '';
  String _mobile = '';
  bool _isLoading = true;

  final List<AgentToolData> agentTools = const [
    AgentToolData('assets/icons/apply_policy.png', 'Agent Onboarding'),
    AgentToolData('assets/icons/tracking.png', 'Business Performance'),
    AgentToolData('assets/icons/policy_advisor.png', 'Team List'),
    AgentToolData('assets/icons/claim.png', 'Policy Search'),
    AgentToolData('assets/icons/pay_with_proposal.png', 'Inforce Policy List'),
    AgentToolData('assets/icons/others.png', 'Due Policy List'),
    AgentToolData('assets/icons/claim.png', 'Maturity & Claim List'),
    AgentToolData('assets/icons/calculator.png', 'Premium Calculator'),
    AgentToolData('assets/icons/products.png', 'Our Product'),
    AgentToolData('assets/icons/bonus_rate.png', 'Bonus Rate'),
    AgentToolData('assets/icons/claim_payment.png', 'Claim Payment'),
    AgentToolData('assets/icons/form_download.png', 'Form Download'),
    AgentToolData('assets/icons/maturity_benifit.png', 'Maturity Benefit'),


    // AgentToolData('assets/icons/apply_policy.png', 'Apply for New Policy'),
  ];

  // New list for "COMMON" designation agents
  final List<AgentToolData> commonAgentTools = const [
    AgentToolData('assets/icons/apply_policy.png', 'Agent Onboarding'),
    AgentToolData('assets/icons/tracking.png', 'Business Summary'),
    AgentToolData('assets/icons/calculator.png', 'Premium Calculator'),
    AgentToolData('assets/icons/claim.png', 'Policy Search'),
    AgentToolData('assets/icons/products.png', 'Our Product'),
    AgentToolData('assets/icons/bonus_rate.png', 'Bonus Rate'),
    AgentToolData('assets/icons/claim_payment.png', 'Claim Payment'),
    AgentToolData('assets/icons/form_download.png', 'Form Download'),
     AgentToolData('assets/icons/ren.png', 'Second Year Ren Business All'),
    AgentToolData('assets/icons/others.png', 'Complains/feedback'), // Placeholder icon
    AgentToolData('assets/icons/maturity_benifit.png', 'Maturity Benefit'),
   
  ];

  // New list for "MONITOR HEAD" designation agents
  final List<AgentToolData> monitorHeadAgentTools = const [
    AgentToolData('assets/icons/apply_policy.png', 'Agent Onboarding'),
    AgentToolData('assets/icons/tracking.png', 'Business Summary MH'),
    AgentToolData('assets/icons/policy_advisor.png', 'Team List MH'),
    AgentToolData('assets/icons/claim.png', 'Policy Search'),
    AgentToolData('assets/icons/tracking.png', 'Team Details Business'), // Placeholder icon
    AgentToolData('assets/icons/others.png', '2nd Year Ren Business'), // Placeholder icon
    AgentToolData('assets/icons/calculator.png', 'Premium Calculator'),
    AgentToolData('assets/icons/products.png', 'Our Product'),
    AgentToolData('assets/icons/bonus_rate.png', 'Bonus Rate'),
    AgentToolData('assets/icons/claim_payment.png', 'Claim Payment'),
    AgentToolData('assets/icons/form_download.png', 'Form Download'),
    // AgentToolData('assets/icons/others.png', 'Complains/feedback'), // Placeholder icon
    AgentToolData('assets/icons/maturity_benifit.png', 'Maturity Benefit'),

  ];

  // New list for "ZONE HEAD" designation agents
  final List<AgentToolData> zoneHeadAgentTools = const [
    AgentToolData('assets/icons/apply_policy.png', 'Agent Onboarding'),
    AgentToolData('assets/icons/tracking.png', 'Business Performance ZH'),
    AgentToolData('assets/icons/policy_advisor.png', 'Team List ZH'),
    AgentToolData('assets/icons/claim.png', 'Policy Search'),
    AgentToolData('assets/icons/ren.png', 'Second Year Renewal Business'),
    AgentToolData('assets/icons/products.png', 'Our Product'),
    AgentToolData('assets/icons/bonus_rate.png', 'Bonus Rate'),
    AgentToolData('assets/icons/claim_payment.png', 'Claim Payment'),
    AgentToolData('assets/icons/form_download.png', 'Form Download'),
    AgentToolData('assets/icons/maturity_benifit.png', 'Maturity Benefit'),
    AgentToolData('assets/icons/apply_policy.png', 'Apply for New Policy'),
    AgentToolData('assets/icons/tracking.png', 'Team Details Business ZH'),
  ];

  // New list for "AREA HEAD" designation agents
  final List<AgentToolData> areaHeadAgentTools = const [
    AgentToolData('assets/icons/apply_policy.png', 'Agent Onboarding'),
    AgentToolData('assets/icons/tracking.png', 'Business Performance AH'),
    AgentToolData('assets/icons/policy_advisor.png', 'Team List AH'),
    AgentToolData('assets/icons/claim.png', 'Policy Search'),
    AgentToolData('assets/icons/ren.png', 'Second Year Renewal Business'),
    AgentToolData('assets/icons/calculator.png', 'Premium Calculator'),
    AgentToolData('assets/icons/products.png', 'Our Product'),
    AgentToolData('assets/icons/bonus_rate.png', 'Bonus Rate'),
    AgentToolData('assets/icons/claim_payment.png', 'Claim Payment'),
    AgentToolData('assets/icons/form_download.png', 'Form Download'),
    AgentToolData('assets/icons/maturity_benifit.png', 'Maturity Benefit'),
    AgentToolData('assets/icons/apply_policy.png', 'Apply for New Policy'),
    AgentToolData('assets/icons/tracking.png', 'Team Details Business'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAgentInfo();
  }

  Future<void> _loadAgentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Agent';
      _empId = prefs.getString('emp_id') ?? 'N/A';
      _designation = prefs.getString('designation') ?? 'N/A';
      _mobile = prefs.getString('mobile') ?? 'N/A';
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Dashboard()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      drawer: _buildAgentDrawer(),
      appBar: AppBar(
        title: Text('Agent Dashboard'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  Text(
                    'Agent Tools',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextColorDark),
                  ),
                  const SizedBox(height: 16),
                  _buildToolsGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: kPrimaryDarkBlue.withOpacity(0.4),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryDarkBlue, kAccentBlue.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_pin_circle, size: 40, color: kPrimaryDarkBlue),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.badge_outlined, 'ID: $_empId'),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.work_outline, 'Designation: $_designation'),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.phone_android, 'Mobile: $_mobile'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildToolsGrid() {
    final List<AgentToolData> tools;
    if (_designation == 'MONITOR HEAD') {
      tools = monitorHeadAgentTools;
    } else if (_designation == 'ZONE HEAD') {
      tools = zoneHeadAgentTools;
    } else if (_designation == 'AREA HEAD') {
      tools = areaHeadAgentTools;
    } else if (_designation == 'COMMON') {
      tools = commonAgentTools;
    } else {
      tools = agentTools;
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Changed to 3 for smaller cards
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9, // Adjusted for a more square look
      ),
      itemCount: tools.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildGridItem(tool);
      },
    );
  }

  Widget _buildGridItem(AgentToolData item) {
    return Card(
      elevation: 3, // Slightly increased elevation
      color: Colors.white, // Explicitly set to white
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      shadowColor: kPrimaryDarkBlue.withOpacity(0.1), // Subtle shadow color
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _onToolTapped(item.title),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              item.iconPath,
              height: 36, // Reduced icon size
              width: 36,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error, size: 36, color: Colors.red),
            ),
            const SizedBox(height: 8), // Reduced spacing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12, // Reduced font size
                  fontWeight: FontWeight.w500,
                  color: kTextColorDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentDrawer() {
    return Drawer(
      child: Column(
        children: [
          // --- Custom Drawer Header for Centering ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              color: kPrimaryDarkBlue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_pin,
                    size: 45,
                    color: kPrimaryDarkBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $_empId | Designation: $_designation',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // --- Navigation List ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset, color: kTextColorDark),
                  title: const Text('Change Password'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    _onToolTapped('Change Password');
                  },
                ),
                ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.grey.shade700),
                    title: Text('Account Deletion Request', style: TextStyle(color: Colors.grey.shade700)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountDeletionRequest()));
                    },
                  ),
              ],
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
            onTap: () {
              Navigator.pop(context); // Close drawer before logging out
              _logout();
            },
          ),
          // Safe area for bottom notches
          const SafeArea(bottom: true, top: false, child: SizedBox(height: 0)),
        ],
      ),
    );
  }

  void _onToolTapped(String title) {
    Widget destination;

    switch (title) {
      case 'Premium Calculator':
        destination = const PremiumCalculatorScreen();
        break;

      case 'Business Performance':
        destination = BusinessPerformancePage(
          empId: _empId,
          designation: _designation,
          empName: _username,
        );
      //   break;
      // case 'Business Performance ZH':
      //   destination = BusinessPerformancePage(
      //     empId: _empId,
      //     designation: _designation,
      //     empName: _username,
      //   );
        break;

        
      case 'Business Summary':
        destination = const BusinessSummaryScreen();
        break;

         case 'Team List':
        destination = const TeamListPage();
        break;
      // case 'Team List ZH':
      //   destination = const TeamListPage();
      //   break;

      case 'Due Policy List':
        destination = const DuePolicyListPage();
        break;

      case 'Inforce Policy List':
        destination = const InforcePolicyListPage();
        break;

      case 'Policy Search':
        destination = const PolicySearchScreen();
        break;

        
      case 'Our Product':
        destination = const PolicyCategoryScreen();
        break;
        
      case 'Bonus Rate':
        destination = const BonusRatePage();
        break;
      case 'Claim Payment':
        destination = const ClaimPaymentScreen();
        break;
      case 'Form Download':
        destination = const FormsDownloadScreen();
        break;
      case 'Maturity Benefit':
        destination = const MaturityBenefitForm();
        break;
      case '2nd Year Ren Business':
        destination = const SecondYearBusinessForMHScreen();
        break;
      case 'Second Year Renewal Business':
        destination = const SecondYearBusinessForMHScreen();
        break;

      case 'Apply for New Policy':
        destination = const ApplyForPolicyScreen();
        break;
      case 'Business Summary MH':
         case 'Business Performance ZH':
         case 'Business Performance AH':
        destination = const BusinessSummaryMhNewScreen();
        break;
      case 'Team List MH':
      case 'Team List ZH':
      case 'Team List AH':
        destination = const TeamListMhScreen();
        break;
      // Added cases for new Monitor Head tools that don't have navigation yet
      case 'Business Performance (MH)':
      case 'Team Details Business':
      case 'Team Details Business ZH':
        destination = const TeamDetailsBusinessScreen();
        break;
      case 'Agent Onboarding':
        destination = const AgentOnboardingScreen();
        break;
        case 'Second Year Ren Business All':
        destination = const SecondYearRenBusinessAllScreen();
        break;
   

        
        

        case 'Complains/feedback':
        destination = const ComplainsFeedbackScreen();
        break;





      default:
        if (title == 'Change Password') {
          destination = const ChangePasswordScreen();
          break;
        }
        destination = _buildPlaceholderScreen(title);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  Widget _buildPlaceholderScreen(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'The "$title" feature is under development.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: kTextColorDark),
              ),
              const SizedBox(height: 10),
              Text(
                'This screen will be available soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}