import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- 1. Data Model ---
class ClaimPayment {
  final String claimYear;
  final String death;
  final String maturity;
  final String survival;
  final String surrenders;
  final String others;
  final String totalClaimAmt;
  final String status;
  final String audited;

  ClaimPayment({
    required this.claimYear,
    required this.death,
    required this.maturity,
    required this.survival,
    required this.surrenders,
    required this.others,
    required this.totalClaimAmt,
    required this.status,
    required this.audited,
  });

  factory ClaimPayment.fromJson(Map<String, dynamic> json) {
    return ClaimPayment(
      claimYear: json['claim_year'] as String,
      death: json['death'] as String,
      maturity: json['maturity'] as String,
      survival: json['survival'] as String,
      surrenders: json['surrenders'] as String,
      others: json['others'] as String,
      totalClaimAmt: json['total_claim_amt'] as String,
      status: json['status'] as String,
      audited: json['audited'] as String,
    );
  }
}

// --- 2. Utility Function: Locked to Lakh/Crore Format (2,2,3 grouping) ---
String formatCurrency(String amount) {
  // 1. Clean the input: Remove any non-digit characters (including existing commas)
  String cleanAmount = amount.replaceAll(RegExp(r'[^0-9]'), ''); 
  if (cleanAmount.isEmpty) return 'Tk 0';

  try {
    // 2. Convert to an integer and back to string for consistency
    String s = int.parse(cleanAmount).toString();

    // 3. Separate the last three digits (for the hundreds/thousands group)
    String lastThree = s.length < 3 ? s : s.substring(s.length - 3);
    String remaining = s.length < 3 ? '' : s.substring(0, s.length - 3);

    // 4. Format the 'remaining' part (lakh, crore, etc.)
    if (remaining.isNotEmpty) {
      // Regex applies comma every two digits from the right (for lakh/crore grouping)
      RegExp regExp = RegExp(r'\B(?=(\d{2})+(?!\d))');
      remaining = remaining.replaceAll(regExp, ',');
    }

    // 5. Combine and prefix with Taka symbol (Tk)
    String formatted = remaining + (remaining.isNotEmpty ? ',' : '') + lastThree;
    
    return 'Tk $formatted'; 
    
  } catch (e) {
    // Fallback: return original if parsing fails
    return amount;
  }
}

// --- 3. Main Widget (Stateful) ---
class ClaimPaymentScreen extends StatefulWidget {
  final String apiUrl = "https://nliuserapi.nextgenitltd.com/api/claim-payment"; 
  const ClaimPaymentScreen({super.key});

  @override
  State<ClaimPaymentScreen> createState() => _ClaimPaymentScreenState();
}

class _ClaimPaymentScreenState extends State<ClaimPaymentScreen> {
  late Future<List<ClaimPayment>> _claimsFuture;

  // 🎨 Palette
  final MaterialColor primaryMaterialColor = Colors.blue;
  final Color primaryColor = Colors.blue.shade800; // Deep Blue
  final Color accentColor = Colors.lightBlueAccent.shade400; // Bright Accent

  @override
  void initState() {
    super.initState();
    _claimsFuture = _fetchClaims();
  }

  // --- API Fetching Method (unchanged) ---
  Future<List<ClaimPayment>> _fetchClaims() async {
    try {
      final response = await http.get(Uri.parse(widget.apiUrl)); 
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
          List<dynamic> dataList = jsonResponse['data'];
          return dataList.map((json) => ClaimPayment.fromJson(json)).toList();
        } else {
          throw Exception('API call successful but failed to parse data.');
        }
      } else {
        throw Exception('Failed to load claim data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching data: $e');
      rethrow;
    }
  }

  // --- Helper Widget for Detail Items ---
  Widget _buildDetailItem(IconData icon, String label, String value, {Color iconColor = Colors.black54, Color valueColor = Colors.black}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 1), 
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with MediaQuery to fix text scale factor to 1.0.
    // This prevents layout breakage when system font size is increased.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        // --- APP BAR (Simplified) ---
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A237E), 
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Claim Payments List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          elevation: 0,
        ),
      // --- BODY: FutureBuilder for data fetching ---
      body: FutureBuilder<List<ClaimPayment>>(
        future: _claimsFuture,
        builder: (context, snapshot) {
          
          // >>> START: ENHANCED PROFESSIONAL LOADING SPINNER <<<
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 50),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: primaryColor, 
                        strokeWidth: 4,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Fetching Claim Data...',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Please wait while we load your records.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          // >>> END: ENHANCED PROFESSIONAL LOADING SPINNER <<<
          
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error connecting to server. Please try again later.\n${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No historical claim data available.', style: TextStyle(color: Colors.grey)));
          } 
          
          final List<ClaimPayment> claimList = snapshot.data!;
          
          // --- Data Display List ---
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), 
            itemCount: claimList.length,
            itemBuilder: (context, index) {
              final claim = claimList[index];
              
              final Color cardBaseColor = Colors.white;

              return Card(
                elevation: 4, 
                margin: const EdgeInsets.only(bottom: 20.0), 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: BorderSide(color: Colors.grey.shade200, width: 1.0), 
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBaseColor,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  padding: const EdgeInsets.all(16.0), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Claim Year and Status Header ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FY ${claim.claimYear}',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A237E),
                            ),
                          ),
                          // Audited Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: claim.audited == 'YES' ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  claim.audited == 'YES' ? Icons.check_circle : Icons.warning_rounded,
                                  size: 14,
                                  color: claim.audited == 'YES' ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  claim.audited == 'YES' ? 'AUDITED' : 'PENDING',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: claim.audited == 'YES' ? Colors.green.shade900 : Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10), 
                      
                      // --- Total Claim Amount (Clean Style) ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1A237E), // Deep Indigo
                              Colors.blue.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'TOTAL DISBURSED AMOUNT',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatCurrency(claim.totalClaimAmt),
                                style: const TextStyle(
                                  fontSize: 28, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // --- Breakdown List (Rows for responsiveness) ---
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildDetailItem(Icons.heart_broken_rounded, 'Death', formatCurrency(claim.death), iconColor: Colors.red.shade700, valueColor: Colors.red.shade900)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildDetailItem(Icons.schedule, 'Maturity', formatCurrency(claim.maturity), iconColor: Colors.blue.shade700, valueColor: Colors.blue.shade900)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildDetailItem(Icons.accessibility_new, 'Survival', formatCurrency(claim.survival), iconColor: Colors.green.shade700, valueColor: Colors.green.shade900)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildDetailItem(Icons.cancel_schedule_send, 'Surrenders', formatCurrency(claim.surrenders), iconColor: Colors.orange.shade800, valueColor: Colors.orange.shade900)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildDetailItem(Icons.category, 'Other Claims', formatCurrency(claim.others), iconColor: Colors.teal.shade700, valueColor: Colors.teal.shade900)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildDetailItem(Icons.trending_up, 'Status', claim.status, iconColor: Colors.indigo.shade700, valueColor: Colors.indigo.shade900)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}