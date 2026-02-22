// main.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ==================================================================
// 0. CONSTANTS
// ==================================================================

// --- API CONSTANTS ---
const String _apiUrlList = 'https://nliuserapi.nextgenitltd.com/api/user-policy';
const String _apiUrlDetails = 'https://nliuserapi.nextgenitltd.com/api/user-policy-details';
const String _mockAccessToken = 'mock_jwt_token_from_login_service';

// --- THEME CONSTANTS ---
const Color kPrimaryDarkBlue = Color(0xFF1A237E); 
const Color kAccentLightBlue = Color(0xFFE8EAF6);


// ==================================================================
// 1. POLICY DATA MODELS (WITH NULL-SAFE FIXES)
// ==================================================================

/// Represents a single insurance policy object from the API list response.
class Policy {
  final String policyNo;
  final String customerName;
  final String maturityDt;
  final String nextPayDt;
  final int totalInstall;
  final int totalPaidInstall;
  final double sofarPaidAmount;
  final String planName;
  final String category;
  final String riskDate;
  final String dataSchema;

  Policy({
    required this.policyNo,
    required this.customerName,
    required this.maturityDt,
    required this.nextPayDt,
    required this.totalInstall,
    required this.totalPaidInstall,
    required this.sofarPaidAmount,
    required this.planName,
    required this.category,
    required this.riskDate,
    required this.dataSchema,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      policyNo: json['policy_no'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      maturityDt: json['maturity_dt'] as String? ?? '',
      nextPayDt: json['next_pay_dt'] as String? ?? '',
      totalInstall: int.tryParse(json['total_install']?.toString() ?? '0') ?? 0,
      totalPaidInstall: int.tryParse(json['total_paid_install']?.toString() ?? '0') ?? 0,
      sofarPaidAmount: double.tryParse(json['sofarpaidamount']?.toString() ?? '0.0') ?? 0.0,
      planName: json['plan_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      riskDate: json['risk_date'] as String? ?? '',
      dataSchema: json['data_schema'] as String? ?? 'AKOK',
    );
  }
}

/// Represents a nominee for a policy. (FIXED)
class Nominee {
  final String name;
  final String relation;
  final String allocation;

  Nominee({
    required this.name,
    required this.relation,
    required this.allocation,
  });

  factory Nominee.fromJson(Map<String, dynamic> json) {
    return Nominee(
      name: json['NomineeName'] as String? ?? '',
      relation: json['NomineeRelation'] as String? ?? '',
      allocation: json['NomineeAllocation'] as String? ?? '',
    );
  }
}

/// Represents the detailed information from the Policy Details API. (FIXED)
class PolicyDetail {
  final String policyName;
  final String category;
  final String installmentTypeName;
  final String riskDate;
  final String termOfYear;
  final int totalNumberOfInstallments;
  final int totalInstallmentsPaid;
  final int dueInstallments;
  final int totalPolicyAmount;
  final double totalPremium;
  final double totalPremPay;
  final double soFarPaidAmount;
  final double totalPremDue;
  final String maturityDt;
  final String nextPayDt;
  final String applicantName;
  final String agentName;
  final String tableAndTerm;
  final String mobileNo;
  final String status;
  final List<Nominee> nominees;
  final String onMaturityBenefit;
  final String inCaseOfAssuredDeathBenefit;
  final int planId;
  final String supplementaryCover;
  final String specialBenefit;

  PolicyDetail({
    required this.policyName,
    required this.category,
    required this.installmentTypeName,
    required this.riskDate,
    required this.termOfYear,
    required this.totalNumberOfInstallments,
    required this.totalInstallmentsPaid,
    required this.dueInstallments,
    required this.totalPolicyAmount,
    required this.totalPremium,
    required this.totalPremPay,
    required this.soFarPaidAmount,
    required this.totalPremDue,
    required this.maturityDt,
    required this.nextPayDt,
    required this.applicantName,
    required this.agentName,
    required this.tableAndTerm,
    required this.mobileNo,
    required this.status,
    required this.nominees,
    required this.onMaturityBenefit,
    required this.inCaseOfAssuredDeathBenefit,
    required this.planId,
    required this.supplementaryCover,
    required this.specialBenefit,
  });

  factory PolicyDetail.fromJson(Map<String, dynamic> json) {
    // Safely access nested objects
    final policyDetails = json['PolicyInfo']['PolicyDetails'][0] as Map<String, dynamic>;
    final policyStatus = json['PolicyInfo']['PolicyStatus'][0] as Map<String, dynamic>;
    final nomineesData = json['PolicyInfo']['Nominee'] as List<dynamic>;
    final financialBenefits = json['FinancialBenefits']['OnDeath'][0] as Map<String, dynamic>;
    final overview = json['Overview'][0] as Map<String, dynamic>;

    // Helper to safely parse numbers that might be String, int, double, or null
    int _parseInt(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;
    double _parseDouble(dynamic value) => double.tryParse(value?.toString() ?? '0.0') ?? 0.0;

    return PolicyDetail(
      // --- Policy Details (Null-safe assignment) ---
      policyName: policyDetails['PolicyName'] as String? ?? '',
      category: policyDetails['Category'] as String? ?? '',
      installmentTypeName: policyDetails['InstallmentTypeName'] as String? ?? '',
      riskDate: policyDetails['riskDate'] as String? ?? '',
      termOfYear: policyDetails['TermOfYear'] as String? ?? '',
      totalNumberOfInstallments: _parseInt(policyDetails['TotalNumberOfInstallments']),
      totalInstallmentsPaid: _parseInt(policyDetails['TotalInstallmentsPaid']),
      dueInstallments: policyDetails['DueInstallments'] as int? ?? 0,
      totalPolicyAmount: policyDetails['TotalPolicyAmount'] as int? ?? 0,
      totalPremium: _parseDouble(policyDetails['TotPrem']),
      totalPremPay: _parseDouble(policyDetails['TotalPremPay']),
      soFarPaidAmount: _parseDouble(policyDetails['SoFarPaidAmount']),
      totalPremDue: _parseDouble(policyDetails['TotalPremDue']),
      maturityDt: policyDetails['maturity_dt'] as String? ?? '',
      nextPayDt: policyDetails['next_pay_dt'] as String? ?? '',
      
      // --- Policy Status (Null-safe assignment) ---
      applicantName: policyStatus['ApplicantNameEng'] as String? ?? '',
      agentName: (policyStatus['AgentName'] as String? ?? '').trim(), 
      tableAndTerm: policyStatus['TableAndTerm'] as String? ?? '',
      mobileNo: policyStatus['MobileNo'] as String? ?? '',
      status: policyStatus['Status'] as String? ?? 'N/A',

      // --- Nominees ---
      nominees: nomineesData.map((n) => Nominee.fromJson(n as Map<String, dynamic>)).toList(),
      
      // --- Financial Benefits (Null-safe assignment) ---
      onMaturityBenefit: financialBenefits['OnMaturity'] as String? ?? 'Not provided.',
      inCaseOfAssuredDeathBenefit: financialBenefits['InCaseOfAssuredDeath'] as String? ?? 'Not provided.',
      planId: _parseInt(overview['PlanId']),
      supplementaryCover: financialBenefits['SupplementaryCover'] as String? ?? 'N/A',
      specialBenefit: financialBenefits['SpecialBenefit'] as String? ?? 'Not Applicable.',
    );
  }
}

// --- SHARED API HELPER ---
/// Fetches policy details from the API. Used by both the Detail Screen and the Policy Card (for Next Due Date).
Future<PolicyDetail> _fetchPolicyDetailsFromApi(String policyNo, String dataSchema) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken') ?? _mockAccessToken;

  final response = await http.post(
    Uri.parse(_apiUrlDetails),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      "policyId": policyNo,
      "dataSchema": dataSchema,
    }),
  );

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);

    if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
      return PolicyDetail.fromJson(jsonResponse['data']);
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to load policy details.');
    }
  } else {
    throw Exception('Failed to load policy details. Status Code: ${response.statusCode}');
  }
}

// ==================================================================
// 2. THE POLICY CARD WIDGET (LIST ITEM)
// ==================================================================

class PolicyCard extends StatefulWidget {
  final Policy policy;
  const PolicyCard({Key? key, required this.policy}) : super(key: key);

  @override
  State<PolicyCard> createState() => _PolicyCardState();
}

class _PolicyCardState extends State<PolicyCard> {
  late Future<String> _nextPayDtFuture;

  @override
  void initState() {
    super.initState();
    _nextPayDtFuture = _fetchNextPayDate();
  }

  /// Fetches the Next Due Date specifically from the details API
  Future<String> _fetchNextPayDate() async {
    try {
      final detail = await _fetchPolicyDetailsFromApi(widget.policy.policyNo, widget.policy.dataSchema);
      return detail.nextPayDt;
    } catch (e) {
      // Fallback to the list data if the detail fetch fails
      return widget.policy.nextPayDt;
    }
  }

  void _navigateToDetails(BuildContext context, Policy policy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PolicyDetailScreen(policy: policy),
      ),
    );
  }
  
  // Helper for info columns in the new design
  Widget _buildInfoColumn(String label, String value, {Color? valueColor, CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.policy.totalInstall > 0 ? widget.policy.totalPaidInstall / widget.policy.totalInstall : 0.0;
    final bool isCompleted = widget.policy.totalInstall > 0 && widget.policy.totalPaidInstall >= widget.policy.totalInstall;
    final Color progressColor = progress >= 1.0 ? Colors.green : kPrimaryDarkBlue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToDetails(context, widget.policy),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Plan Name & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kPrimaryDarkBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.security, color: kPrimaryDarkBlue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.policy.planName,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Policy No: ${widget.policy.policyNo}',
                                  style: TextStyle(fontSize: 12, color: const Color.fromARGB(255, 172, 3, 3), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kAccentLightBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.policy.category,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      
                      // Row 1: Customer & Risk Date
                      Row(
                        children: [
                          Expanded(child: _buildInfoColumn('Customer', widget.policy.customerName)),
                          Expanded(child: _buildInfoColumn('Risk Date', widget.policy.riskDate, align: CrossAxisAlignment.end)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Row 2: Total Paid & Next Due Date (Requested)
                      Row(
                        children: [
                          Expanded(child: _buildInfoColumn('Total Paid', 'BDT ${widget.policy.sofarPaidAmount.toStringAsFixed(0)}', valueColor: Colors.green.shade700)),
                          Expanded(child:
                            isCompleted
                              ? const SizedBox.shrink()
                              : FutureBuilder<String>(
                                future: _nextPayDtFuture,
                                builder: (context, snapshot) {
                                  String displayValue = '...';
                                  if (snapshot.connectionState == ConnectionState.done) {
                                    displayValue = (snapshot.data != null && snapshot.data!.isNotEmpty)
                                        ? snapshot.data!.split(' ')[0]
                                        : 'N/A';
                                  } else {
                                    displayValue = widget.policy.nextPayDt.isNotEmpty ? widget.policy.nextPayDt.split(' ')[0] : '...';
                                  }
                                  return _buildInfoColumn('Next Due Date', displayValue, align: CrossAxisAlignment.end, valueColor: Colors.orange.shade800);
                                },
                              ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 3: Maturity & Installments
                     Row(
                          children: [
                            // কিস্তি (Installments) এখন বাম দিকে
                            Expanded(
                              child: _buildInfoColumn(
                                'Installments', 
                                isCompleted ? 'Completed!' : '${widget.policy.totalPaidInstall} / ${widget.policy.totalInstall}',
                                align: CrossAxisAlignment.start,
                              ),
                            ),

                            // মেয়াদ উত্তীর্ণের তারিখ (Maturity Date) এখন ডান দিকে
                            Expanded(
                              child: _buildInfoColumn(
                                'Maturity Date', 
                                widget.policy.maturityDt.split(' ')[0],
                                align: CrossAxisAlignment.end,
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 16),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// 3. APPLICATION ENTRY POINT & ROOT WIDGET
// ==================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const PolicyApp());
}

class PolicyApp extends StatelessWidget {
  const PolicyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Policies',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryDarkBlue, 
          foregroundColor: Colors.white, 
        ),
      ),
      home: const PolicyListScreen(),
    );
  }
}

// ==================================================================
// 4. POLICY LIST SCREEN (API GET)
// ==================================================================

class PolicyListScreen extends StatefulWidget {
  const PolicyListScreen({Key? key}) : super(key: key);

  @override
  State<PolicyListScreen> createState() => _PolicyListScreenState();
}

class _PolicyListScreenState extends State<PolicyListScreen> {
  late Future<List<Policy>> _policiesFuture;

  @override
  void initState() {
    super.initState();
    _policiesFuture = _fetchUserPolicies();
  }

  /// Fetches the list of policies using the access token.
  Future<List<Policy>> _fetchUserPolicies() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? _mockAccessToken;

    if (token.isEmpty) {
      throw Exception('Access token is missing. Please log in.');
    }

    final response = await http.get(
      Uri.parse(_apiUrlList),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
        List<dynamic> dataList = jsonResponse['data'];
        return dataList.map((json) => Policy.fromJson(json)).toList();
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to load policies: Invalid data format.');
      }
    } else {
      throw Exception('Failed to load policies. Status Code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        appBar: AppBar(
           backgroundColor: kPrimaryDarkBlue, 
            foregroundColor: Colors.white, 
            centerTitle: true,
          title: const Text('My Policy List', style: TextStyle(fontWeight: FontWeight.bold)), 
        ),
        body: FutureBuilder<List<Policy>>(
          future: _policiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 10),
                      Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => setState(() => _policiesFuture = _fetchUserPolicies()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasData) {
              final policies = snapshot.data!;
              if (policies.isEmpty) {
                return const Center(child: Text('You have no active policies.', style: TextStyle(fontSize: 18)));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                itemCount: policies.length,
                itemBuilder: (context, index) => PolicyCard(policy: policies[index]),
              );
            }
            return const Center(child: Text('No data available.'));
          },
        ),
      ),
    );
  }
}

// ==================================================================
// 5. POLICY DETAIL SCREEN (API POST)
// ==================================================================

class PolicyDetailScreen extends StatefulWidget {
  final Policy policy;

  const PolicyDetailScreen({Key? key, required this.policy}) : super(key: key);

  @override
  State<PolicyDetailScreen> createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends State<PolicyDetailScreen> {
  late Future<PolicyDetail> _policyDetailFuture;

  @override
  void initState() {
    super.initState();
    // Use the shared API helper
    _policyDetailFuture = _fetchPolicyDetailsFromApi(widget.policy.policyNo, widget.policy.dataSchema);
  }

  // Helper function to build a consistent detail row for the detail screen
  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color, bool boldValue = false, bool boldLabel = false, VoidCallback? onTap}) {
    Widget rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color ?? kPrimaryDarkBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 14, 
                      color: Colors.grey.shade700, 
                      fontWeight: boldLabel ? FontWeight.bold : FontWeight.w500
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: boldValue ? FontWeight.bold : FontWeight.w500,
                      color: Colors.black87),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ]
        ],
      ),
    );
    
    if (onTap != null) {
      return InkWell(onTap: onTap, child: rowContent);
    }
    return rowContent;
  }

  // Helper for Nominee cards
  Widget _buildNomineeCard(Nominee nominee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: kAccentLightBlue.withOpacity(0.5),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nominee.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Relation: ${nominee.relation}'),
                Text('Share: ${nominee.allocation}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAndShowMaturityBonus(PolicyDetail detail) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String maturityYear = '';
      try {
        if (detail.maturityDt.isNotEmpty) {
          maturityYear = DateTime.parse(detail.maturityDt).year.toString();
        }
      } catch (_) {}

      // Sanitize term to ensure only digits are sent (e.g., "12 Years" -> "12")
      String term = detail.termOfYear.replaceAll(RegExp(r'[^0-9]'), '');
      if (term.isEmpty) term = '0';

      final uri = Uri.parse('https://nliuserapi.nextgenitltd.com/api/maturity-bonous-calculate')
          .replace(queryParameters: {
        'plan_id': detail.planId.toString().padLeft(2, '0'),
        'term': term,
        'year': maturityYear.isNotEmpty ? maturityYear : DateTime.now().year.toString(),
        'sum_assured': detail.totalPolicyAmount.toString(),
      });

      // debugPrint('Requesting Maturity Bonus: $uri');

      final response = await http.get(uri);
      Navigator.pop(context); // Dismiss loading

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if ((jsonResponse['success'] == true || jsonResponse['success'] == 'true') && jsonResponse['data'] != null) {
          _showMaturityModal(jsonResponse['data'], detail.planId.toString().padLeft(2, '0'));
        } else {
          debugPrint('Maturity Bonus API Error: ${jsonResponse['message']}');
          _showMessageDialog(jsonResponse['message'] ?? 'No Bonus Found For This Policy', detail.planId.toString().padLeft(2, '0'), isError: true);
        }
      } else if (response.statusCode == 404) {
        _showMessageDialog('No Bonus Found For This Policy', detail.planId.toString().padLeft(2, '0'), isError: true);
      } else {
        debugPrint('Maturity Bonus Server Error: ${response.statusCode}');
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Dismiss loading
      debugPrint('Maturity Bonus Exception: $e');
      _showError('An error occurred: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.red.shade700,
    ));
  }

  void _showMessageDialog(String message, String planId, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(isError ? Icons.info_outline : Icons.check_circle_outline, 
                 color: isError ? Colors.orange.shade800 : Colors.green, size: 48),
            const SizedBox(height: 10),
            Text(isError ? 'Notice' : 'Success', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Plan ID: $planId', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showMaturityModal(Map<String, dynamic> data, String planId) {
    final double width = MediaQuery.of(context).size.width;
    final double titleSize = width < 360 ? 16 : 18;
    final double contentSize = width < 360 ? 13 : 14;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Top Card with Plan ID ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryDarkBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimaryDarkBlue.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Text('Maturity Bonus Details', style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text('Plan ID: $planId', style: TextStyle(fontSize: contentSize - 1, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                _buildTableRow('Survival Benefit', data['survival_benefit'], fontSize: contentSize),
                _buildTableRow('Maturity Benefit', data['maturity_benefit'], fontSize: contentSize),
                _buildTableRow('Maturity Bonus', data['maturity_Bonus'], fontSize: contentSize),
                _buildTableRow('Total Amount', data['total'], isBold: true, bgColor: Colors.blue.shade50, fontSize: contentSize + 1),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, dynamic value, {bool isBold = false, Color? bgColor, double fontSize = 14}) {
    return TableRow(
      decoration: BoxDecoration(color: bgColor),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            'BDT ${value?.toString() ?? '0'}',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: isBold ? kPrimaryDarkBlue : Colors.black87),
          ),
        ),
      ],
    );
  }

  TableRow _buildGenericTableRow(String label, String value, {bool isBold = false, Color? bgColor, double fontSize = 13}) {
    return TableRow(
      decoration: BoxDecoration(color: bgColor),
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            value,
            style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.w400, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  void _showDeathBenefitDialog(PolicyDetail detail) {
    final double width = MediaQuery.of(context).size.width;
    final double contentSize = width < 360 ? 12 : 13;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.deepOrange),
            SizedBox(width: 10),
            Expanded(child: Text('Death Benefit Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(1.3),
                1: FlexColumnWidth(2),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              children: [
                _buildGenericTableRow('Policy ID', detail.planId.toString().padLeft(2, '0'), fontSize: contentSize),
                _buildGenericTableRow('Policy Name', detail.policyName, fontSize: contentSize),
                _buildGenericTableRow('Category', detail.category, fontSize: contentSize),
                _buildGenericTableRow('Term', '${detail.termOfYear} Years', fontSize: contentSize),
                _buildGenericTableRow('Supplementary Cover', detail.supplementaryCover, fontSize: contentSize, isBold: true),
                _buildGenericTableRow('On Maturity', detail.onMaturityBenefit, fontSize: contentSize),
                _buildGenericTableRow('In Case of Death', detail.inCaseOfAssuredDeathBenefit, fontSize: contentSize, bgColor: Colors.orange.shade50),
                _buildGenericTableRow('Special Benefit', detail.specialBenefit, fontSize: contentSize),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        appBar: AppBar(
           backgroundColor: kPrimaryDarkBlue, 
            foregroundColor: Colors.white, 
            centerTitle: true,
            title: Text('${widget.policy.planName} Details', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        body: FutureBuilder<PolicyDetail>(
          future: _policyDetailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        'Error loading details: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                      onPressed: () => setState(() => _policyDetailFuture = _fetchPolicyDetailsFromApi(widget.policy.policyNo, widget.policy.dataSchema)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasData) {
              final detail = snapshot.data!;
              final bool isCompleted = detail.totalInstallmentsPaid >= detail.totalNumberOfInstallments;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Policy & Status Header Card ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.policyName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Policy No: ${widget.policy.policyNo}', style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: detail.status == 'Active' ? Colors.green.shade100 : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    detail.status,
                                    style: TextStyle(
                                      color: detail.status == 'Active' ? Colors.green.shade800 : Colors.red.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
  
                    // --- Financial Summary ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Financial Summary 💰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const Divider(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildDetailRow(Icons.paid, 'Sum Assured', 'BDT ${detail.totalPolicyAmount.toStringAsFixed(2)}', color: Colors.green.shade700, boldValue: true)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildDetailRow(Icons.attach_money, '${detail.installmentTypeName} Premium', 'BDT ${detail.totalPremium.toStringAsFixed(2)}', color: Colors.blue.shade700, boldValue: true)),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildDetailRow(Icons.account_balance_wallet, 'Total Paid', 'BDT ${detail.soFarPaidAmount.toStringAsFixed(2)}', color: Colors.orange.shade700, boldValue: true)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildDetailRow(Icons.money_off, 'Total Due', 'BDT ${detail.totalPremDue.toStringAsFixed(2)}', color: Colors.red.shade700, boldValue: true)),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                    Icons.payments,
                                    'Installments',
                                    isCompleted ? 'Completed!' : '${detail.totalInstallmentsPaid} / ${detail.totalNumberOfInstallments}',
                                    color: kPrimaryDarkBlue
                                  )
                                ),
                                if (!isCompleted) ...[
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildDetailRow(Icons.event_note, 'Next Due Date', detail.nextPayDt.split(' ')[0])),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
  
                    // --- Policy Details ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Policy Details 📄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const Divider(height: 20),
                            _buildDetailRow(Icons.category, 'Category', detail.category),
                            _buildDetailRow(Icons.calendar_today, 'Term & Type', '${detail.termOfYear} Years / ${detail.installmentTypeName}'),
                            _buildDetailRow(Icons.person, 'Applicant Name', detail.applicantName.trim()),
                            _buildDetailRow(Icons.phone, 'Mobile', detail.mobileNo),
                            _buildDetailRow(Icons.location_city, 'Agent Name', detail.agentName.trim()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
  
                    // --- Nominees ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nominees 🧑‍🤝‍🧑', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const Divider(height: 20),
                            if (detail.nominees.isNotEmpty)
                              ...detail.nominees.map(_buildNomineeCard).toList()
                            else
                              const Text('No nominee details available.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
  
                    // --- Benefits ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Policy Benefits ✨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const Divider(height: 20),
                            _buildDetailRow(
                              Icons.sentiment_satisfied_alt, 
                              'On Maturity', 
                              detail.onMaturityBenefit, 
                              color: Colors.purple,
                              onTap: () => _fetchAndShowMaturityBonus(detail),
                              boldLabel: true,
                            ),
                            _buildDetailRow(
                              Icons.health_and_safety, 
                              'In Case of Assured Death', 
                              detail.inCaseOfAssuredDeathBenefit, 
                              color: Colors.deepOrange,
                              onTap: () => _showDeathBenefitDialog(detail),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to List'),
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: kPrimaryDarkBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('An unknown error occurred.'));
          },
        ),
      ),
    );
  }
}