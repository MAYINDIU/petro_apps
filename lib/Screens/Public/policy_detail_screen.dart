import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:nli_apps/Screens/Public/premium_calculator_screen.dart'; 

const String categoryApiBaseUrl = 'https://nliuserapi.nextgenitltd.com/api/category-wise-policy';
const Color _deepBlue = Color(0xFF0D47A1); 
const Color _lightBlue = Color(0xFF1977D2); 
const Color _whiteColor = Colors.white;

// --- Policy Model (Unchanged) ---
class Policy {
  final String planId;
  final String planName;
  final String category;
  final String termOfThePolicy;
  final String onMaturity;
  final String inCaseOfAssuredDeath;
  final String SupplementaryCovers;

  Policy({
    required this.planId,
    required this.planName,
    required this.category,
    required this.termOfThePolicy,
    required this.onMaturity,
    required this.inCaseOfAssuredDeath,
     required this.SupplementaryCovers,
    
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      planId: json['plan_id'] as String? ?? 'N/A',
      planName: json['plan_name'] as String? ?? 'No Name',
      category: json['category'] as String? ?? 'Unknown Category',
      termOfThePolicy: json['TermOfThePolicy'] as String? ?? 'N/A',
      onMaturity: json['OnMaturity'] as String? ?? 'N/A',
      inCaseOfAssuredDeath: json['InCaseOfAssuredDeath'] as String? ?? 'N/A',
       SupplementaryCovers: json['SupplementaryCover'] as String? ?? 'N/A',
    );
  }
}

// --- Data Fetching Function (Unchanged) ---
Future<List<Policy>> fetchCategoryPolicies(String categoryName) async {
  final encodedCategory = Uri.encodeComponent(categoryName);
  final url = '$categoryApiBaseUrl/$encodedCategory';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
      final List<dynamic> policyListJson = jsonResponse['data'];
      return policyListJson
          .map((json) => Policy.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('API Response Error: Missing or invalid "data" key in policy list.');
    }
  } else {
    throw Exception('Failed to load policies for $categoryName. Status Code: ${response.statusCode}');
  }
}

// --- Detail Screen Widget (Standard Accordion Behavior) ---
class PolicyDetailScreen extends StatefulWidget {
  final String categoryTitle;

  const PolicyDetailScreen({super.key, required this.categoryTitle});

  @override
  State<PolicyDetailScreen> createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends State<PolicyDetailScreen> {
  late Future<List<Policy>> _policiesFuture;
  
  String? _expandedPolicyId;
  List<Policy> _policies = []; 

  @override
  void initState() {
    super.initState();
    _policiesFuture = fetchCategoryPolicies(widget.categoryTitle);
  }

  // ⭐️ RESTORED: Standard Accordion Logic (Opening one closes others)
  void _setExpandedPolicyId(String policyId, bool isExpanded) {
    setState(() {
      // If the current item is expanding, set it as the expanded ID.
      // If it's collapsing, set the ID to null (no item is expanded).
      _expandedPolicyId = isExpanded ? policyId : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _deepBlue, 
        foregroundColor: _whiteColor, 
        title: Text(
          widget.categoryTitle,
          style: const TextStyle(color: _whiteColor), 
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_deepBlue, _lightBlue],
          ),
        ),
        child: FutureBuilder<List<Policy>>(
          future: _policiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _whiteColor));
            } else if (snapshot.hasError) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading policies: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _whiteColor),
                ),
              ));
            } else if (snapshot.hasData) {
              _policies = snapshot.data!;

              if (_policies.isEmpty) {
                return Center(child: Text('No policies found for ${widget.categoryTitle}.', style: const TextStyle(color: _whiteColor)));
              }
              
              // No need for initial expansion logic when restoring standard behavior

              return ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: _policies.length,
                itemBuilder: (context, index) {
                  final policy = _policies[index];
                  
                  return PolicyItemCard(
                    policy: policy,
                    // The item is expanded ONLY if its ID matches the stored expanded ID
                    isExpanded: policy.planId == _expandedPolicyId,
                    onExpansionChanged: (isExpanded) => _setExpandedPolicyId(policy.planId, isExpanded),
                  );
                },
              );
            } else {
              return const Center(child: Text('Start fetching data...', style: TextStyle(color: _whiteColor)));
            }
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PolicyItemCard Widget (Unchanged)
// -----------------------------------------------------------------------------
class PolicyItemCard extends StatelessWidget {
  final Policy policy;
  final bool isExpanded; 
  final ValueChanged<bool> onExpansionChanged; 

  const PolicyItemCard({
    super.key, 
    required this.policy,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  String _stripHtmlTags(String htmlText) {
    final exp = RegExp(r'<[^>]*>|&[^;]+;', multiLine: true);
    return htmlText.replaceAll(exp, '').trim();
  }

  Widget _buildItemActionButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onPressed}) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: _deepBlue),
        label: FittedBox(
          child: Text(
            label, 
            style: const TextStyle(fontSize: 12, color: _deepBlue, fontWeight: FontWeight.w600),
          )
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final maturityContent = policy.onMaturity; 
    final deathContent = policy.inCaseOfAssuredDeath;

    return Card(
      elevation: 4, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
      ),
      margin: const EdgeInsets.only(bottom: 16), 
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(policy.planId), 
        // ⭐️ CONTROLLED BY PARENT STATE:
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged, 

        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        
        title: Text(
          policy.planName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87, 
          ),
        ),
      // ... inside PolicyItemCard's build method

            subtitle: _buildImmediateDetail(
              context, 
              Icons.play_circle, // Icon changed to play_circle
              'Plan ID: ${policy.planId}', // ⭐️ CORRECTION: Using string interpolation
            ),


        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.verified_user_outlined, 
            color: primaryColor,
            size: 24, 
          ),
        ),
        
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: <Widget>[
          const Divider(height: 1, thickness: 1, color: Colors.black12), 
          const SizedBox(height: 15),

          _buildDetailRow(context, Icons.fingerprint, 'Term:', policy.termOfThePolicy),
          
          const Divider(height: 30, thickness: 0.5, color: Colors.grey),
          
          _buildSectionHeader(context, Icons.trending_up, 'Maturity Benefits'), 
          _buildDetailContent(context, maturityContent),
          
          const Divider(height: 30, thickness: 0.5, color: Colors.grey),
          
          _buildSectionHeader(context, Icons.healing, 'Death Benefits'), 
          _buildDetailContent(context, deathContent),


          _buildDetailRow(context, Icons.fingerprint, 'Supplementary Cover:', policy.SupplementaryCovers),

          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildItemActionButton(
                context, 
                label: 'Prem Calculator', 
                icon: Icons.calculate, 
                  onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PremiumCalculatorScreen(), // Pass 'policy' if needed
                    ),
                  );
                },
              ),


              
              _buildItemActionButton(
                context, 
                label: 'Apply For Policy', 
                icon: Icons.assignment_turned_in, 
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Apply for Policy ${policy.planName}')),
                  );
                },
              ),
              _buildItemActionButton(
                context, 
                label: 'Brochure', 
                icon: Icons.file_download, 
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading Brochure for ${policy.planName}')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- Helper Widgets (Unchanged) ---
  Widget _buildImmediateDetail(BuildContext context, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.black54),
          ),
          const SizedBox(width: 5),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, String content) {
    final strippedContent = _stripHtmlTags(content);
    final isAvailable = strippedContent.isNotEmpty && strippedContent != 'N/A';
    final displayContent = isAvailable ? content : 'Details not provided/available.';
    
    const baseTextStyle = TextStyle(
      fontSize: 14, 
      color: Colors.black87, 
      height: 1.6, 
    );

    return Container(
      padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 4.0),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isAvailable ? Theme.of(context).primaryColor.withOpacity(0.5) : Colors.grey.shade300, 
            width: 4 
          )
        ), 
      ),
      child: SelectableRegion(
        selectionControls: MaterialTextSelectionControls(),
        focusNode: FocusNode(), 
        child: isAvailable 
            ? HtmlWidget(
                displayContent,
                textStyle: baseTextStyle,
              )
            : Text(
                displayContent,
                style: baseTextStyle.copyWith(color: Colors.grey.shade600),
              ),
      ),
    );
  }
}