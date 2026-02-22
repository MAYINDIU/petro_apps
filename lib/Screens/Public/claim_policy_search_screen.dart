import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nli_apps/Screens/Public/claim_request.dart';

// --- Enhanced Constants ---
const Color kPrimaryColor = Color(0xFF1E40AF); // Deep Blue
const Color kAccentColor = Color(0xFFF97316);  // Orange
const Color kBgColor = Color(0xFFF8FAFC);      // Light Grey/Blue background
const Color kCardColor = Colors.white;

const String _baseUrl = 'https://nliuserapi.nextgenitltd.com/api';

// --- Models ---
// (Keeping your logic, but cleaned up the factory for better null safety)
class SearchPolicyModel {
  final bool success;
  final List<PolicyData>? data;
  final String? message;

  SearchPolicyModel({this.success = false, this.data, this.message});

  factory SearchPolicyModel.fromJson(Map<String, dynamic> json) {
    return SearchPolicyModel(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] != null ? (json['data'] as List).map((i) => PolicyData.fromJson(i)).toList() : [],
    );
  }
}

class PolicyData {
  final String? customerName, policyNo, dataSchema, planName, projectName;
  PolicyData({this.customerName, this.policyNo, this.dataSchema, this.planName, this.projectName});

  factory PolicyData.fromJson(Map<String, dynamic> json) {
    return PolicyData(
      customerName: json['customer_name']?.toString(),
      policyNo: json['policy_no']?.toString(),
      dataSchema: json['data_schema']?.toString(),
      planName: json['plan_name']?.toString(),
      projectName: json['project_name']?.toString(),
    );
  }
}

// --- Main Screen ---
class ClaimPolicySearchScreen extends StatefulWidget {
  const ClaimPolicySearchScreen({super.key});
  @override
  State<ClaimPolicySearchScreen> createState() => _ClaimPolicySearchScreenState();
}

class _ClaimPolicySearchScreenState extends State<ClaimPolicySearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  SearchPolicyModel? _searchResult;
  String? _errorMessage;

  Future<void> _searchPolicy() async {
    final policyNo = _controller.text.trim();
    if (policyNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a policy number"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      final response = await http.get(
        Uri.parse("$_baseUrl/search-policy?policy_no=$policyNo"),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = SearchPolicyModel.fromJson(jsonDecode(response.body));
        setState(() {
          _searchResult = result;
          if (!result.success || (result.data?.isEmpty ?? true)) {
            _errorMessage = result.message ?? "No policy found.";
          }
        });
      } else {
        setState(() => _errorMessage = "Server Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _errorMessage = "Connection failed. Please check your internet.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text("Policy Inquiry", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Find your policy", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter Policy Number",
                prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                suffixIcon: IconButton(
                  onPressed: _isLoading ? null : _searchPolicy,
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_rounded, color: kAccentColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) return _buildStatusMsg(_errorMessage!, Icons.error_outline, Colors.redAccent);
    if (_searchResult == null && !_isLoading) return _buildStatusMsg("Search for a policy to view details", Icons.policy_outlined, Colors.grey);
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final list = _searchResult?.data ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildModernCard(list[index]),
    );
  }

  Widget _buildStatusMsg(String msg, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: color.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(msg, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildModernCard(PolicyData policy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: kAccentColor, width: 5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: kPrimaryColor.withOpacity(0.1), child: const Icon(Icons.person, color: kPrimaryColor)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(policy.customerName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("ID: ${policy.policyNo}", style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.layers_outlined, "Schema", policy.dataSchema ?? 'Standard'),
    
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplyClaimPolicy(policyNo: policy.policyNo ?? ''),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text("PROCEED TO CLAIM"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}