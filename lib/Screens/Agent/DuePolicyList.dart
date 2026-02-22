import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Constants ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorDark = Color(0xFF1F2937);
const Color kErrorColor = Colors.redAccent;

// --- Formatters ---
final _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '৳', decimalDigits: 0);

// --- 1. Data Models ---
class DuePolicy {
  final String policyNo;
  final String customerName;
  final String? mobile;
  final String modeOfPay;
  final String sumAssured;
  final String premiumDue;
  final String nextPaymentDate;
  final String agentName;
  final String project;
  final String riskDate;
  final String maturityDate;
  final String totalPaidInstall;
  final String sofarPaidAmount;
  final DateTime? npayDt; // For date filtering

  DuePolicy({
    required this.policyNo,
    required this.customerName,
    this.mobile,
    required this.modeOfPay,
    required this.sumAssured,
    required this.premiumDue,
    required this.nextPaymentDate,
    required this.agentName,
    required this.project,
    required this.riskDate,
    required this.maturityDate,
    required this.totalPaidInstall,
    required this.sofarPaidAmount,
    this.npayDt,
  });

  factory DuePolicy.fromJson(Map<String, dynamic> json) {
    // Helper to format date strings safely
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return 'N/A';
      try {
        return DateFormat('dd MMM, yyyy').format(DateTime.parse(dateStr));
      } catch (e) {
        return dateStr; // Return original string if parsing fails
      }
    }

    return DuePolicy(
      policyNo: json['policy_no'] ?? 'N/A',
      customerName: (json['customer_name'] as String? ?? 'Unknown').trim(),
      mobile: (json['mobile'] as String? ?? '').trim(),
      modeOfPay: json['mode_of_pay'] ?? 'N/A',
      sumAssured: json['sum_assured'] ?? '0',
      premiumDue: json['premium_due'] ?? '0',
      nextPaymentDate: formatDate(json['npay_dt']),
      agentName: (json['agent_name'] as String? ?? 'N/A').trim(),
      project: json['project'] ?? 'N/A',
      riskDate: formatDate(json['risk_date']),
      maturityDate: formatDate(json['maturity_dt']),
      totalPaidInstall: json['total_paid_install'] ?? '0',
      sofarPaidAmount: json['sofarpaidamount'] ?? '0',
      npayDt: json['npay_dt'] != null ? DateTime.tryParse(json['npay_dt']) : null,
    );
  }
}

class DuePolicyApiResponse {
  final String agentName;
  final String empId;
  final List<DuePolicy> policies;

  DuePolicyApiResponse({
    required this.agentName,
    required this.empId,
    required this.policies,
  });

  factory DuePolicyApiResponse.fromJson(Map<String, dynamic> json) {
    final policyList = (json['policyList'] as List? ?? [])
        .map((item) => DuePolicy.fromJson(item))
        .toList();

    return DuePolicyApiResponse(
      agentName: json['name'] ?? 'N/A',
      empId: json['emp_id'] ?? 'N/A',
      policies: policyList,
    );
  }
}

// --- 2. API Service ---
class DuePolicyApiService {
  static const String _apiUrl = "https://nliapi.nextgenitltd.com/api/due-list";

  Future<DuePolicyApiResponse> fetchDuePolicies() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('Received an empty response from the server.');
      }
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return DuePolicyApiResponse.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to load due policies.');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}

// --- 3. UI Widget ---
class DuePolicyListPage extends StatefulWidget {
  const DuePolicyListPage({super.key});

  @override
  State<DuePolicyListPage> createState() => _DuePolicyListPageState();
}

class _DuePolicyListPageState extends State<DuePolicyListPage> {
  late Future<DuePolicyApiResponse> _apiFuture;
  List<DuePolicy> _allPolicies = [];
  List<DuePolicy> _filteredPolicies = [];
  final TextEditingController _searchController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedProject;
  List<String> _uniqueProjects = [];

  @override
  void initState() {
    super.initState();
    _apiFuture = DuePolicyApiService().fetchDuePolicies();
    _apiFuture.then((data) {
      setState(() {
        _allPolicies = data.policies;
        _filteredPolicies = data.policies;
        _uniqueProjects = data.policies.map((p) => p.project).toSet().toList();
      });
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPolicies = _allPolicies.where((policy) {
        // Text search filter
        final textMatch = query.isEmpty ||
            policy.customerName.toLowerCase().contains(query) ||
            policy.policyNo.contains(query);

        // Date range filter
        final dateMatch = (_fromDate == null || (policy.npayDt != null && !policy.npayDt!.isBefore(_fromDate!))) &&
                          (_toDate == null || (policy.npayDt != null && !policy.npayDt!.isAfter(_toDate!)));

        // Project filter
        final projectMatch = _selectedProject == null || policy.project == _selectedProject;

        return textMatch && dateMatch && projectMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('Due Policy List'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DuePolicyApiResponse>(
        future: _apiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _allPolicies.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryDarkBlue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: kErrorColor)));
          }

          return Column(
            children: [
              _buildFilterSection(),
              Expanded(
                child: _filteredPolicies.isEmpty
                    ? const Center(child: Text('No policies match your criteria.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _filteredPolicies.length,
                        itemBuilder: (context, index) {
                          return _buildPolicyExpansionTile(_filteredPolicies[index]);
                        },
                      ),
              ),
              if (_allPolicies.isNotEmpty)
                _buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: TextFormField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by Customer Name or Policy No...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          filled: true,
          fillColor: kAccentBlue.withOpacity(0.5),
          border: OutlineInputBorder( 
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: kPrimaryDarkBlue,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          _buildSearchBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(child: _buildDateFilter('From', _fromDate, (date) => setState(() { _fromDate = date; _applyFilters(); }))),
                const SizedBox(width: 8),
                Expanded(child: _buildDateFilter('To', _toDate, (date) => setState(() { _toDate = date; _applyFilters(); }))),
                const SizedBox(width: 8),
                Expanded(child: _buildProjectFilter()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(String label, DateTime? date, Function(DateTime) onDateSelected) {
    return ElevatedButton.icon(
      onPressed: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          onDateSelected(pickedDate);
        }
      },
      icon: const Icon(Icons.calendar_today, size: 14),
      label: Text(date == null ? label : DateFormat('dd-MM-yy').format(date), style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccentBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildProjectFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kAccentBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProject,
          isExpanded: true,
          hint: const Text('Project', style: TextStyle(color: Colors.white, fontSize: 12)),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: kPrimaryDarkBlue,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Projects')),
            ..._uniqueProjects.map((project) => DropdownMenuItem(value: project, child: Text(project))),
          ],
          onChanged: (value) {
            setState(() {
              _selectedProject = value;
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  Widget _buildPolicyExpansionTile(DuePolicy policy) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(policy.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
        subtitle: Text('Policy: ${policy.policyNo}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_currencyFormatter.format(double.tryParse(policy.premiumDue) ?? 0), style: const TextStyle(color: kErrorColor, fontWeight: FontWeight.bold)),
            Text(policy.nextPaymentDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(height: 1),
                _buildDetailRow('Premium Due:', _currencyFormatter.format(double.tryParse(policy.premiumDue) ?? 0), isAmount: true),
                _buildDetailRow('Next Payment:', policy.nextPaymentDate),
                _buildDetailRow('Sum Assured:', _currencyFormatter.format(double.tryParse(policy.sumAssured) ?? 0)),
                _buildDetailRow('Payment Mode:', policy.modeOfPay),
                _buildDetailRow('Project:', policy.project),
                _buildDetailRow('Agent:', policy.agentName),
                _buildDetailRow('Risk Date:', policy.riskDate),
                _buildDetailRow('Maturity Date:', policy.maturityDate),
                _buildDetailRow('Installments Paid:', policy.totalPaidInstall),
                _buildDetailRow('Total Paid:', _currencyFormatter.format(double.tryParse(policy.sofarPaidAmount) ?? 0)),
                if (policy.mobile != null && policy.mobile!.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      label: Text('Call ${policy.mobile}', style: const TextStyle(color: Colors.green)),
                      onPressed: () async {
                        final Uri launchUri = Uri(scheme: 'tel', path: policy.mobile);
                        if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isAmount ? kErrorColor : kTextColorDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: kPrimaryDarkBlue.withOpacity(0.1),
      child: Text(
        'Showing ${_filteredPolicies.length} of ${_allPolicies.length} policies',
        textAlign: TextAlign.center,
        style: const TextStyle(color: kTextColorDark, fontWeight: FontWeight.w500),
      ),
    );
  }
}