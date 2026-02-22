import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:nli_apps/Screens/login.dart'; // Ensure this path is correct if using for logout/auth redirection

// --- 🎨 Design System/Constants ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF); // A deep, professional blue
const Color kTextColorLight = Color(0xFFFFFFFF); // White text for dark backgrounds
const Color kScaffoldBackground = Color(0xFFF7F9FB); // Light, off-white background
const Color kTextColorDark = Color(0xFF1F2937); // Dark text
const Color kAccentColor = Color(0xFF3B82F6); // A brighter blue for accents

// --- 🔗 API Configuration ---
const String BASE_URL = 'https://nliapi.nextgenitltd.com/api';

// --- 📊 Data Model ---
class RenewalData {
  final String riskYear;
  final int prevQty;
  final int preQty;
  final int dueQty;
  final double qtyPrc;
  final double prevAmt;
  final double preAmt;
  final double dueAmt;
  final double amtPrc;
  final String processDate;

  RenewalData({
    required this.riskYear,
    required this.prevQty,
    required this.preQty,
    required this.dueQty,
    required this.qtyPrc,
    required this.prevAmt,
    required this.preAmt,
    required this.dueAmt,
    required this.amtPrc,
    required this.processDate,
  });

  factory RenewalData.fromJson(Map<String, dynamic> json) {
    // Robust parsing for dynamic types
    double toDouble(dynamic value) => double.tryParse(value?.toString() ?? '0.0') ?? 0.0;
    int toInt(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;

    return RenewalData(
      riskYear: json['risk_year'] ?? 'N/A',
      prevQty: toInt(json['prev_qty']),
      preQty: toInt(json['pre_qty']),
      dueQty: toInt(json['due_qty']),
      qtyPrc: toDouble(json['qty_prc']),
      prevAmt: toDouble(json['prev_amt']),
      preAmt: toDouble(json['pre_amt']),
      dueAmt: toDouble(json['due_amt']),
      amtPrc: toDouble(json['amt_prc']),
      processDate: json['process_date'] ?? '2000-01-01', // Use a default safe date
    );
  }
}

// --- 📱 Screen Implementation ---
class SecondYearRenBusinessAllScreen extends StatefulWidget {
  const SecondYearRenBusinessAllScreen({Key? key}) : super(key: key);

  @override
  _SecondYearRenBusinessAllScreenState createState() => _SecondYearRenBusinessAllScreenState();
}

class _SecondYearRenBusinessAllScreenState extends State<SecondYearRenBusinessAllScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, RenewalData> _data = {};

  // Formatters are heavy objects; initialize them once
  final _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '৳ ', decimalDigits: 2);
  final _numberFormatter = NumberFormat.decimalPattern('en_IN');
  final _dateFormatter = DateFormat('dd MMM, yyyy');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Reset state before fetching
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token missing. Please log in.';
          // Optionally: navigate to LoginScreen
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/second-year-renewal-all'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final dataMap = jsonResponse['data'] as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _data['total'] = RenewalData.fromJson(dataMap['total']);
              _data['akok'] = RenewalData.fromJson(dataMap['akok']);
              _data['jana'] = RenewalData.fromJson(dataMap['jana']);
              _isLoading = false;
            });
          }
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load data. API reported an issue.');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}. Please try again later.');
      }
    } catch (e) {
      print('Fetch Error: $e'); // Log the error for debugging
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error fetching data: Ensure you have a stable network connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('2nd Year Renewal Business', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
        elevation: 0, // Flat app bar for a modern look
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryDarkBlue));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: kPrimaryDarkBlue,
                  backgroundColor: kAccentColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use RefreshIndicator for professional UX (Pull-to-Refresh)
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: kPrimaryDarkBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_data['total'] != null) _buildDataCard('Total Business (All Projects)', _data['total']!),
            const SizedBox(height: 20),
            if (_data['akok'] != null) _buildDataCard('AKOK Project Business', _data['akok']!),
            const SizedBox(height: 20),
            if (_data['jana'] != null) _buildDataCard('JANA Project Business', _data['jana']!),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String title, RenewalData data) {
    return Card(
      elevation: 6, // Increased elevation for a 'lifted' Material look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Softer, modern corners
        side: const BorderSide(color: kAccentColor, width: 1.5), // A subtle border highlight
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kPrimaryDarkBlue,
              ),
            ),
            const Divider(height: 24, thickness: 2, color: kAccentColor),

            // Key Dates
            _buildInfoRow('Risk Year', data.riskYear, isHeader: true),
            _buildInfoRow('Process Date', _dateFormatter.format(DateTime.parse(data.processDate)), isHeader: true),
            const SizedBox(height: 16),

            // Policy Quantity Section
            _buildSectionHeader('Policy Quantity (No. of Policies)'),
            _buildInfoRow('Previous Qty', _numberFormatter.format(data.prevQty)),
            _buildInfoRow('Preserved Qty', _numberFormatter.format(data.preQty), isPreserved: true),
            _buildInfoRow('Due Qty', _numberFormatter.format(data.dueQty), isDue: true),
            _buildRateRow('Qty Preservation Rate', data.qtyPrc),
            const SizedBox(height: 20),

            // Premium Amount Section
            _buildSectionHeader('Premium Amount (in BDT)'),
            _buildInfoRow('Previous Amt', _currencyFormatter.format(data.prevAmt)),
            _buildInfoRow('Preserved Amt', _currencyFormatter.format(data.preAmt), isPreserved: true),
            _buildInfoRow('Due Amt', _currencyFormatter.format(data.dueAmt), isDue: true),
            _buildRateRow('Amt Preservation Rate', data.amtPrc),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: kTextColorDark.withOpacity(0.9),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHeader = false, bool isPreserved = false, bool isDue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHeader ? kPrimaryDarkBlue : Colors.grey.shade600,
              fontSize: 15,
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isPreserved ? Colors.green.shade700 : isDue ? Colors.red.shade700 : kTextColorDark,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(String label, double rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: kPrimaryDarkBlue, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kAccentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${rate.toStringAsFixed(2)}%',
              style: TextStyle(
                color: kAccentColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}