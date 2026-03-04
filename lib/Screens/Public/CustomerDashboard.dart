import 'package:flutter/material.dart';
import 'package:petro_app/Screens/Public/AccountDeletionRequest.dart';
import 'package:petro_app/Screens/Public/Claim_payment_list_api_fetch.dart';
import 'package:petro_app/Screens/Public/ContactUsScreen.dart';
import 'package:petro_app/Screens/Public/apply_for_policy_screen.dart';
import 'package:petro_app/Screens/Public/Forms_download_live_api.dart';
import 'package:petro_app/Screens/Public/PolicyCategory.dart';
import 'package:petro_app/Screens/Public/change_password_screen.dart';
import 'package:petro_app/Screens/Public/TaxCertificate.dart';
import 'package:petro_app/Screens/Public/bonusRate.dart';
import 'package:petro_app/Screens/Public/dashboard.dart';
import 'package:petro_app/Screens/Public/maturity_benefit_form.dart';
import 'package:petro_app/Screens/Public/my_policies_screen.dart';
import 'package:petro_app/Screens/Public/nli_about_us.dart';
import 'package:petro_app/Screens/Public/premium_calculator_screen.dart';
import 'package:petro_app/Screens/Public/ssl_payment_webview.dart';
import 'package:petro_app/Screens/Public/PremiumCertificate.dart';
import 'package:petro_app/Screens/Public/terms_and_conditions.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:petro_app/Screens/login.dart';

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
const String _assetProductIconPath =
    'assets/icons/products.png'; // Placeholder path
const String _assetSSLCommerzPath =
    'assets/images/ssl_commerz.png'; // New path for the logo
bool _isLoading = false;
// --- Supporting Models and Placeholder Screens ---

class DashboardIconData {
  final String iconPath;
  final String title;
  const DashboardIconData(this.iconPath, this.title);
}

// ⚠️ Policy Model updated with total_install and total_paid_install
final class Policy {
  final String policyNo;
  final String customerName;
  final String planName;
  final String category;
  final String payMode;
  final String lifePremium;
  final String nextPayDate;
  final int totalInstall;
  final int paidInstall;
  final String maturityDt;

  // --- Newly Added Fields from JSON ---
  final String dataSchema;
  final String?
  paymentStatusErpSync; // Nullable as its utility may be backend-specific
  final String totalPremium;
  final int term; // Assuming term is better as an integer
  final String mobile;

  Policy({
    required this.policyNo,
    required this.customerName,
    required this.planName,
    required this.category,
    required this.payMode,
    required this.lifePremium,
    required this.nextPayDate,
    required this.totalInstall,
    required this.paidInstall,
    required this.maturityDt,
    // --- Newly Added Fields ---
    required this.dataSchema,
    this.paymentStatusErpSync,
    required this.totalPremium,
    required this.term,
    required this.mobile,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse string-like numbers to integers
    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      return int.tryParse(value.toString()) ?? 0;
    }

    return Policy(
      policyNo: json['policy_no'] ?? 'N/A',
      customerName: json['customer_name'] ?? 'N/A',
      planName: json['plan_name'] ?? 'N/A',
      category: json['category'] ?? 'N/A',
      payMode: json['pay_mode'] ?? 'N/A',
      lifePremium: json['lifeprem']?.toString() ?? '0',
      nextPayDate: json['npay_dt'] ?? 'No Date Available',
      totalInstall: safeParseInt(json['total_install']),
      paidInstall: safeParseInt(json['total_paid_install']),
      maturityDt: json['maturity_dt'] as String? ?? '',

      // --- Newly Mapped Fields ---
      dataSchema: json['data_schema'] ?? 'N/A',
      paymentStatusErpSync: json['payment_status_erp_sync']
          ?.toString(), // Kept as String/Nullable
      totalPremium: json['totalprem']?.toString() ?? '0',
      term: safeParseInt(json['term']),
      mobile: json['mobile'] ?? 'N/A',
    );
  }
}

/// Function to post payment data
Future<String?> postPayment({
  required String customerName,
  required String policyNo,
  required String dataSchema,
  required int tableTerm,
  required String lifePremium,
  required String mobile,
  required String payMode,
  required String nextPayDate,
}) async {
  final Uri url = Uri.parse("https://nliuserapi.nextgenitltd.com/api/pay");

  final Map<String, dynamic> body = {
    "CUSTOMER_NAME": customerName,
    "POLICY_NO": policyNo,
    "DATA_SCHEMA": dataSchema,
    "PROPOSAL_NO": "",
    "TABLE_TERM": tableTerm.toString(),
    "PREMIUM": double.tryParse(lifePremium) ?? 0,
    "MOBILENO": mobile,
    "EMAIL": "",
    "BRANCH_ID": "741",
    "PAY_METHOD": payMode,
    "FROM_ACC": mobile,
    "PAIDAMOUNT": lifePremium,
    "DUE_DATE": nextPayDate,
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final jsonResp = jsonDecode(response.body);
      print("Payment Response: $jsonResp");

      // Check if the response contains a payment URL
      if (jsonResp is String &&
          jsonResp.startsWith("https://epay-gw.sslcommerz.com/")) {
        return jsonResp;
      } else if (jsonResp['payment_url'] != null) {
        return jsonResp['payment_url']; // If API returns as JSON field
      } else {
        return null; // No URL found
      }
    } else {
      print("Server Error: ${response.statusCode}");
      print("Response Body: ${response.body}");
      return null;
    }
  } catch (e) {
    print("Exception occurred: $e");
    return null;
  }
}

// -------------------------------------------------------------------------
// 🔥 NEW WIDGET: Payment Confirmation Dialog
// -------------------------------------------------------------------------

class PaymentConfirmationDialog extends StatefulWidget {
  // Policy data passed to the dialog
  final Policy policy;
  // Function to execute when 'Pay Now' is confirmed
  final VoidCallback onConfirmPayment;
  // Context of the original button to re-show the dialog if a policy link is tapped
  final BuildContext parentContext;

  const PaymentConfirmationDialog({
    super.key,
    required this.policy,
    required this.onConfirmPayment,
    required this.parentContext,
  });

  @override
  State<PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

// Payment Dialog-----------------------------------------------------------------
class _PaymentConfirmationDialogState extends State<PaymentConfirmationDialog> {
  // State to track if the checkbox is checked
  bool _isTermsAccepted = false;

  // Helper to build policy detail rows (Clean Alignment)
  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    // Assuming kTextColorDark is defined in the file scope
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: kTextColorDark),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? kTextColorDark,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build a clickable policy link (Aligned with Checkbox Text)
  Widget _buildPolicyLink(BuildContext context, String title, String type) {
    return InkWell(
      onTap: () {
        // 1. Close the current dialog
        Navigator.of(context).pop();

        // 2. Navigate to the policy screen
        Navigator.push(
          widget.parentContext, // Use parent context for navigation
          MaterialPageRoute(
            builder: (context) => TermsAndConditions(type: type),
          ),
        ).then((_) {
          // 3. Re-show the confirmation dialog when returning
          showDialog(
            context: widget.parentContext,
            builder: (BuildContext dialogContext) {
              return PaymentConfirmationDialog(
                policy: widget.policy,
                onConfirmPayment: widget.onConfirmPayment,
                parentContext: widget.parentContext,
              );
            },
          );
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          '• $title',
          style: const TextStyle(
            fontSize: 13,
            color: kPrimaryDarkBlue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Corrected Icon usage here:
    // ❌ Error: Icons.payment_checkout
    // ✅ Fix: Icons.payment (or Icons.check_circle, Icons.credit_card, etc.)

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Checkbox and Policy Links Section ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Padding(
                  padding: const EdgeInsets.only(top: 0.0),
                  child: Checkbox(
                    value: _isTermsAccepted,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _isTermsAccepted = newValue ?? false;
                      });
                    },
                    activeColor: kPrimaryDarkBlue,
                  ),
                ),

                // Agreement Text and Links
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'I acknowledge and agree to the following policies:',
                          style: TextStyle(fontSize: 14, color: kTextColorDark),
                        ),
                        // Links to Policies (using the custom helper for alignment)
                        _buildPolicyLink(
                          context,
                          'Terms & Conditions',
                          'terms',
                        ),
                        _buildPolicyLink(context, 'Privacy Policy', 'privacy'),
                        _buildPolicyLink(
                          context,
                          'Return/Refund Policy',
                          'refund',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- Payment Gateway Logo ---
            Center(
              child: Column(
                children: [
                  const Text(
                    'Secured Payment Gateway',
                    style: TextStyle(fontSize: 12, color: kHintColor),
                  ),
                  Image.asset(
                    _assetSSLCommerzPath,
                    height: 180,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'Payment Gateway (SSLCommerz)',
                      style: TextStyle(color: kHintColor),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 25),
          ],
        ),
      ),

      actions: <Widget>[
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: kTextColorDark)),
        ),
        ElevatedButton(
          onPressed: (_isTermsAccepted && !_isLoading)
              ? () async {
                  setState(() => _isLoading = true);

                  final paymentUrl = await postPayment(
                    customerName: widget.policy.customerName,
                    policyNo: widget.policy.policyNo,
                    dataSchema: widget.policy.dataSchema,
                    tableTerm: widget.policy.term,
                    lifePremium: widget.policy.lifePremium,
                    mobile: widget.policy.mobile,
                    payMode: widget.policy.payMode,
                    nextPayDate: widget.policy.nextPayDate,
                  );

                  setState(() => _isLoading = false);

                  if (paymentUrl != null) {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.all(10),
                        child: SizedBox(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: SSLPaymentWebViewscreen(
                            paymentUrl: paymentUrl,
                            title: "Online Payment",
                            onResult: (result) {
                              if (result.success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment successful!'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment failed!'),
                                  ),
                                );
                              }
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment initiation failed.'),
                      ),
                    );
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryDarkBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send_to_mobile, size: 18),
                    SizedBox(width: 6),
                    Text('Proceed to Pay'),
                  ],
                ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------------
// 🔥 CustomerDashboard State Implementation
// -------------------------------------------------------------------------

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});
  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  // --- State Variables ---
  String _userName = 'Loading User...';
  String _userEmail = 'loading@app.com';
  String _userMobile = '00000000000';
  String _userRole = '';
  String? _accessToken;
  double _currentBalance = 0.00;
  bool _isLoading = true;
  List<Policy> _policies = [];

  // --- API Endpoint Configuration ---
  static const String _policyApiUrl =
      'https://nliuserapi.nextgenitltd.com/api/policy-by-recent-pay-date';

  // Mock data for token simulation
  final Map<String, dynamic> _mockLoginResponse = {
    'accessToken':
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIwMDEiLCJpYXQiOjE2MjY4NjQ0NDd9.S_i_QkL_c3jQ9w-B_V7Q_MOCK_TOKEN',
    'user_name': 'Nargish Sultana',
    'nid': '1234567890',
    'mobile': '01914226420',
  };

  // --- Dashboard Items List ---
  final List<DashboardIconData> dashboardItems = const [
    DashboardIconData('assets/icons/apply_policy.png', 'My Policies'),
    DashboardIconData('assets/icons/bonus_rate.png', 'Bonus Rate'),
    DashboardIconData('assets/icons/maturity_benifit.png', 'Maturity Benefit'),
    DashboardIconData('assets/icons/products.png', 'Our Products'),
    DashboardIconData('assets/icons/form_download.png', 'Forms Download'),
    DashboardIconData('assets/icons/claim_payment.png', 'Claim Payment'),
    DashboardIconData('assets/icons/contact-us.png', 'Contact Us'),
    DashboardIconData('assets/icons/others.png', 'About us'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // --- Core Data Flow ---

  Future<void> _loadAllData() async {
    await _simulateSuccessfulLogin();
    await _loadUserInfo();
    await _fetchPolicyData();

    setState(() {
      _isLoading = false;
    });
  }

  // CONCEPTUAL LOGIN: Simulates saving the token received from a successful API response.
  Future<void> _simulateSuccessfulLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('accessToken') == null) {
      debugPrint('Simulating initial login and saving token.');

      await prefs.setString(
        'accessToken',
        _mockLoginResponse['accessToken'] ?? '',
      );

      await prefs.setString(
        'username',
        _mockLoginResponse['user_name'] ?? 'Guest',
      );
      await prefs.setString('nid', _mockLoginResponse['nid'] ?? 'N/A');
      await prefs.setString('mobile', _mockLoginResponse['mobile'] ?? 'N/A');
      await prefs.setDouble('current_balance', 75000.00);
    }
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

  // API FETCHER: Uses the retrieved token for the live API.
  Future<void> _fetchPolicyData() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      debugPrint(
        'Error: Access token is missing or invalid. Cannot fetch policy data.',
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(_policyApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken', // ⬅️ Using the saved token
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);

        if (decodedJson['success'] == true && decodedJson['data'] is List) {
          final List<dynamic> dataList = decodedJson['data'];

          setState(() {
            _policies = dataList.map((json) => Policy.fromJson(json)).toList();
          });
        } else {
          debugPrint(
            'API Error: Success was false. Message: ${decodedJson['message']}',
          );
        }
      } else {
        debugPrint(
          'Failed to load policy data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Network Error during policy data fetch: $e');
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

  // Helper function to map policy category to a color
  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'SAVINGS POLICY':
        return Colors.green.shade700;
      case 'ENDOWMENT':
        return Colors.indigo.shade700;
      case 'FDR':
        return Colors.orange.shade700;
      case 'TERM':
        return Colors.red.shade700;
      default:
        return kPrimaryDarkBlue;
    }
  }

  // Helper for consistent detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      // Padding for detail rows
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: kTextColorDark),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextColorDark,
            ),
          ),
        ],
      ),
    );
  }

  // --- Horizontal Policy List Builder (FIXED VERSION) ---
  Widget _buildHorizontalPolicyList() {
    // Filter out matured policies
    final activePolicies = _policies.where((policy) {
      if (policy.maturityDt.isNotEmpty) {
        try {
          final maturityDate = DateTime.parse(policy.maturityDt);
          return !maturityDate.isBefore(DateTime.now());
        } catch (e) {
          return true;
        }
      }
      return true;
    }).toList();

    if (activePolicies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No upcoming policy payments found.',
          style: TextStyle(color: kTextColorDark),
        ),
      );
    }

    // Builds a single horizontal policy card (FIXED VERSION)
    Widget _buildPolicyCard(Policy policy) {
      final Color categoryColor = _getCategoryColor(policy.category);
      final bool paymentDue = policy.nextPayDate != 'No Date Available';
      final int remainingInstallments =
          policy.totalInstall - policy.paidInstall;

      // --- NEW: Maturity Date Logic ---
      bool hasMatured = false;
      DateTime? maturityDate;
      if (policy.maturityDt.isNotEmpty) {
        try {
          maturityDate = DateTime.parse(policy.maturityDt);
          // A policy has matured if its maturity date is in the past.
          if (maturityDate.isBefore(DateTime.now())) {
            hasMatured = true;
          }
        } catch (e) {
          debugPrint('Could not parse maturity date: ${policy.maturityDt}');
        }
      }

      return Container(
        // Set fixed width for scrollable cards
        width: MediaQuery.of(context).size.width * 0.85,
        height: 370,
        // Margin between cards
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          color: kCardBackground,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: categoryColor.withOpacity(0.6), width: 2),
          ),
          child: Padding(
            // Consistent padding for all content inside the card
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Use MainAxisAlignment.start to stack content from top
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Header with Category Color
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    policy.planName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: kTextColorLight,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Policy Plan Name
                Text(
                  policy.customerName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10), // Increased spacing after title
                // Details
                _buildDetailRow('Policy No:', policy.policyNo),
                _buildDetailRow(
                  'Premium:',
                  'BDT ${policy.lifePremium} / ${policy.payMode}',
                ),

                // Payment Status (total_install / total_paid_install)
                const SizedBox(height: 5), // Spacer
                _buildDetailRow(
                  'Installments Paid:',
                  '${policy.paidInstall} / ${policy.totalInstall}',
                ),
                _buildDetailRow(
                  'Remaining:',
                  remainingInstallments > 0
                      ? '$remainingInstallments'
                      : 'Completed!',
                ),

                // --- NEW: Display Maturity Date ---
                if (maturityDate != null)
                  _buildDetailRow(
                    'Maturity Date:',
                    DateFormat.yMMMd().format(maturityDate),
                  ),

                const Divider(height: 20), // Divider with vertical space
                // Next Due Date (Moved below remaining installments)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Due Date:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kTextColorDark,
                      ),
                    ),
                    Text(
                      policy.nextPayDate,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: paymentDue ? Colors.red.shade600 : kAccentBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Spacing before the button
                // 💸 Pay Button (Conditional & Compact, full width at the bottom)
                if (remainingInstallments > 0 && !hasMatured)
                  SizedBox(
                    width: double.infinity, // Full width button
                    child: ElevatedButton(
                      onPressed: () {
                        // 🔑 NEW LOGIC: Show the confirmation dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return PaymentConfirmationDialog(
                              policy: policy,
                              parentContext:
                                  context, // Pass the dashboard context
                              onConfirmPayment: () {
                                Navigator.of(
                                  dialogContext,
                                ).pop(); // Close the dialog
                                debugPrint(
                                  'Accepted Terms. Navigating to SSLCommerz Sandbox for Policy: ${policy.policyNo}',
                                );

                                // 🎯 TODO: Implement actual SSLCommerz navigation here
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _buildPlaceholderScreen(
                                      'Payment Gateway (SSLCommerz) for Policy: ${policy.policyNo}',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 3, 71, 173),
                        foregroundColor: kTextColorLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // Optimized padding for a comfortable button click area
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        minimumSize: const Size(
                          0,
                          35,
                        ), // Minimum comfortable button height
                      ),
                      child: const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0, top: 16.0),
          child: Text(
            'Upcoming Policy Payments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryDarkBlue,
            ),
          ),
        ),
        SizedBox(
          // 🛑 FIX: Increased height from 290 to 330 to prevent overflow 🛑
          height: 370,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: activePolicies.length,
            itemBuilder: (context, index) {
              return _buildPolicyCard(activePolicies[index]);
            },
          ),
        ),
      ],
    );
  }

  // 1. Dashboard Grid Item Builder (unchanged)
  Widget _buildGridItem(DashboardIconData item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: kCardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onItemTapped(item.title),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                item.iconPath,
                height: 40,
                width: 40,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, size: 40, color: Colors.red),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextColorDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
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
        // Horizontal Policy List
        _buildHorizontalPolicyList(),

        const SizedBox(height: 25),

        // Dashboard Tools Grid
        const Text(
          'Quick Access & Tools',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColorDark,
          ),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: dashboardItems.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = dashboardItems[index];
            return _buildGridItem(item);
          },
        ),
      ],
    );
  }

  void _onItemTapped(String title) {
    Widget destination;

    if (title == 'Our Products' || title == 'Products') {
      destination = const PolicyCategoryScreen();
    } else if (title == 'About us') {
      destination = const AboutUsPage();
    } else if (title == 'My Policies') {
      destination = const PolicyListScreen();
    } else if (title == 'Bonus Rate') {
      destination = const BonusRatePage();
    } else if (title == 'Maturity Benefit') {
      destination = const MaturityBenefitForm();
    } else if (title == 'Forms Download') {
      destination = const FormsDownloadScreen();
    } else if (title == 'Claim Payment') {
      destination = const ClaimPaymentScreen();
    } else if (title == 'Contact Us') {
      destination = const ContactUsScreen();
    } else if (title == 'Policy Advisor') {
      destination = const PremiumCalculatorScreen();
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
                      radius: 35,
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
                    leading: const Icon(
                      Icons.lock_reset,
                      color: kPrimaryDarkBlue,
                    ),
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

                  // --- Policy & Payment Section ---
                  ListTile(
                    leading: Icon(Icons.policy, color: kPrimaryDarkBlue),
                    title: const Text(
                      'My Policies',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      // Close the drawer first
                      Navigator.pop(context);

                      // Navigate to the correct screen which fetches and displays the policies
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // FIX: Use PolicyListScreen(), which is the name of your Stateful screen
                          builder: (context) => const PolicyListScreen(),
                        ),
                      );
                    },
                  ),

                  // The modified ListTile for navigation
                  ListTile(
                    leading: const Icon(
                      Icons.attach_money,
                      color: kPrimaryDarkBlue,
                    ),
                    title: const Text(
                      'Tax Rebate Certificate',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      // 1. Close the drawer
                      Navigator.pop(context);
                      // 2. Navigate to the TaxRebateCertificate screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TaxRebateCertificate(), // This line performs the navigation
                        ),
                      );
                      debugPrint(
                        'Tax Rebate Tapped - Navigating to Certificate Screen',
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.description, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Premium Payment Certificate',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PremiumCertificate(),
                        ),
                      );
                      debugPrint('Payment Certificate Tapped');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.payment, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Apply for New Policy',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ApplyForPolicyScreen(),
                        ),
                      );
                      debugPrint('Apply for New Policy Tapped');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.calculate, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Premium Calculator',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      _onItemTapped('Policy Advisor');
                    },
                  ),

                  // --- Certificates & Reports ---
                  ListTile(
                    leading: Icon(Icons.receipt_long, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Transactions',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      debugPrint('Transactions Tapped');
                    },
                  ),

                  // --- Certificates & Reports Section ---
                  ListTile(
                    leading: Icon(Icons.trending_up, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Bonus Rate',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BonusRatePage(), // Navigate directly to the page
                        ),
                      );
                    },
                  ),

                  // --- Information & Resources ---
                  ListTile(
                    leading: Icon(Icons.shopping_bag, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Our Products',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PolicyCategoryScreen(), // Navigate directly to the page
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.download, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Form Download',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      _onItemTapped('Forms Download');
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.ac_unit, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Terms & Condition',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsAndConditions(
                            type: 'terms',
                          ), // Navigate directly to the page
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: Icon(Icons.info, color: kPrimaryDarkBlue),
                    title: const Text(
                      'About Us',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AboutUsPage(), // Navigate directly to the page
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.phone, color: kPrimaryDarkBlue),
                    title: const Text(
                      'Contact Us',
                      style: TextStyle(color: kTextColorDark),
                    ),
                    onTap: () {
                      _onItemTapped('Contact Us');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: Colors.grey.shade700,
                    ),
                    title: Text(
                      'Account Deletion Request',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountDeletionRequest(),
                        ),
                      );
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
