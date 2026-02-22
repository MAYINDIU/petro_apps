import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. Data Models ---

/// Represents a policy item in the dropdown list.
class Policy {
  final String policyNo;
  final String customerName;
  final String dataSchema;
  final String planName;
  // --- Fields added to match the desired UI ---
  final String category;
  final String maturityDt;
  final int totalInstall;
  final int totalPaidInstall;
  final String sofarPaidAmount;
  final String riskDate;


  Policy({
    required this.policyNo,
    required this.customerName,
    required this.dataSchema,
    required this.planName,
    required this.category,
    required this.maturityDt,
    required this.totalInstall,
    required this.totalPaidInstall,
    required this.sofarPaidAmount,
    required this.riskDate,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      policyNo: json['policy_no'] ?? '',
      customerName: json['customer_name'] ?? '',
      dataSchema: json['data_schema'] ?? '',
      planName: json['plan_name'] ?? 'N/A',
      // --- Map new fields from JSON ---
      category: json['category'] ?? 'N/A',
      maturityDt: json['maturity_dt'] ?? 'N/A',
      totalInstall: int.tryParse(json['total_install']?.toString() ?? '0') ?? 0,
      totalPaidInstall: int.tryParse(json['total_paid_install']?.toString() ?? '0') ?? 0,
      sofarPaidAmount: json['sofarpaidamount']?.toString() ?? '0',
      riskDate: json['risk_date'] ?? 'N/A',
    );
  }
}

/// Represents the structure of the Premium Certificate data.
class PremiumCertificateData {
  final Map<String, dynamic> policyDetails;
  final List<dynamic> fprDetails;

  PremiumCertificateData({
    required this.policyDetails,
    required this.fprDetails,
  });

  factory PremiumCertificateData.fromJson(Map<String, dynamic> json) {
    return PremiumCertificateData(
      policyDetails: json['policyDetails'] ?? {},
      fprDetails: json['fprDetails'] ?? [],
    );
  }
}

// --- 2. API Service ---

class _ApiService {
  static const String _policyListUrl = 'https://nliuserapi.nextgenitltd.com/api/user-policy';
  static const String _premiumCertBaseUrl = 'https://nliuserapi.nextgenitltd.com/api/payment-certificate';

  Future<List<Policy>> fetchPolicyList() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? 'your_mock_token_here';

    final response = await http.get(
      Uri.parse(_policyListUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
        final dataList = jsonResponse['data'] as List;
        return dataList.map((i) => Policy.fromJson(i as Map<String, dynamic>)).toList();
      }
    }
    throw Exception('Failed to load policies');
  }

  Future<PremiumCertificateData> fetchPremiumCertificate({
    required String policyId,
    required String dataSchema,
  }) async {
    final encodedDataSchema = Uri.encodeComponent(dataSchema);
    final url = '$_premiumCertBaseUrl?policyId=$policyId&dataSchema=$encodedDataSchema';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return PremiumCertificateData.fromJson(jsonResponse);
      }
    }
    throw Exception('Failed to load premium certificate');
  }
}

// --- 3. Main Screen Widget ---

class PremiumCertificate extends StatefulWidget {
  const PremiumCertificate({super.key});

  @override
  State<PremiumCertificate> createState() => _PremiumCertificateState();
}

class _PremiumCertificateState extends State<PremiumCertificate> {
  final _ApiService _apiService = _ApiService();

  Future<List<Policy>>? _policyListFuture;
  // Use a map to track the download state for each policy card individually
  final Map<String, bool> _downloadingStates = {};

  @override
  void initState() {
    super.initState();
    _policyListFuture = _apiService.fetchPolicyList();
  }
  void _generateAndDownloadPdf(Policy policy) async {
    setState(() {
      _downloadingStates[policy.policyNo] = true;
    });

    try {
      // Fetch the certificate data for the specific policy
      final value = await _apiService.fetchPremiumCertificate(
        policyId: policy.policyNo,
        dataSchema: policy.dataSchema,
      );

      double totalAmount = 0.0;
      for (var element in value.fprDetails) {
        totalAmount += (double.tryParse(element['premium_paid']?.toString() ?? '0') ?? 0);
      }

      final pdf = pw.Document();
      final img = await rootBundle.load('assets/images/pdf/National_Is__1_-removebg-preview 1.png');
      final imageBytes = img.buffer.asUint8List();
      final micro = await rootBundle.load('assets/images/pdf/MicrosoftTeams-image (79) 1.png');
      final microBytes = micro.buffer.asUint8List();
      // The 'base' logo is loaded but not used in the reference code, so we'll omit it for now.
      final font = await PdfGoogleFonts.interBold();
      final lightFont = await PdfGoogleFonts.interRegular();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          footer: (pw.Context context) {
            return pw.Container(
                alignment: pw.Alignment.center,
                margin: const pw.EdgeInsets.only(top: 15),
                child: pw.Column(children: [
                  pw.Divider(color: PdfColor.fromHex('#2D3192')),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "Note: The statement is computer generated and does not required signature unless further altered. please Call 0966706050 / 16749 or visit your nearest Customer Service Center for any query.",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Head office: NLI Tower,54-55 Kazi Nazrul Islam Avenue,Karwan Bazar,Dhaka-1215,Bangladesh',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#2D3192')),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Phone (PABX): 09666706050,41010123-8 | Fax: 88-02-41010103 | info@nlibd.com | www.nlibd.com',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#2D3192')),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
                  ),
                ]));
          },
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                height: 45,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Image(pw.MemoryImage(imageBytes), width: 35, height: 35),
                        pw.SizedBox(width: 10),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              "National Life Insurance Co. Ltd.",
                              style: pw.TextStyle(
                                fontSize: 13,
                                color: PdfColor.fromHex('#2D3192'),
                                fontWeight: pw.FontWeight.bold,
                                font: font,
                              ),
                            ),
                            pw.Text(
                              "A Guarantee for a Planned Future",
                              style: pw.TextStyle(fontSize: 10, color: PdfColors.blue200, font: lightFont),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Image(pw.MemoryImage(microBytes), width: 65, height: 35, fit: pw.BoxFit.contain),
                  ],
                ),
              ),
              pw.Divider(color: PdfColor.fromHex('#2D3192')),
              pw.SizedBox(height: 20),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("Date: ${DateFormat("dd-MM-yyyy").format(DateTime.now())}", style: pw.TextStyle(font: font, fontSize: 10)),
              ),
              pw.SizedBox(height: 10),
              // Title
              pw.Center(
                child: pw.Text(
                  "Premium Payment Certificate",
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#2d3192'),
                    fontWeight: pw.FontWeight.bold,
                    font: font,
                    fontSize: 16,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Policy Details
              _buildPdfDetailRow("Policy Holder's Name", value.policyDetails['customer_name']?.trim() ?? 'N/A', font, lightFont),
              _buildPdfDetailRow("Policy Number", value.policyDetails['policy_no'] ?? 'N/A', font, lightFont),
              _buildPdfDetailRow("Risk Date", DateFormat('dd-MM-yyyy').format(DateTime.parse(value.policyDetails['risk_date'])), font, lightFont),
              _buildPdfDetailRow("Maturity Date", DateFormat('dd-MM-yyyy').format(DateTime.parse(value.policyDetails['maturity_dt'])), font, lightFont),
              _buildPdfDetailRow("Sum Assured", "BDT ${value.policyDetails['sum_assured'] ?? '0'}", font, lightFont),
              _buildPdfDetailRow("Mode of Payment", value.policyDetails['mode_of_pay'] ?? 'N/A', font, lightFont),
              _buildPdfDetailRow("Last Paid Date", DateFormat('dd-MM-yyyy').format(DateTime.parse(value.policyDetails['lastpaid'])), font, lightFont),
              _buildPdfDetailRow("Total Paid Amount", "BDT ${value.policyDetails['sofarpaidamount'] ?? '0.0'}", font, lightFont),

              pw.SizedBox(height: 30),

              // Table Header
              pw.Text(
                "Payment History",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 14),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Data Table
              pw.Table.fromTextArray(
                headers: ['Date', 'Receipt No.', 'Installment Range', 'Amount (BDT)'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white, font: font),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#2D3192')),
                cellStyle: pw.TextStyle(fontSize: 8, font: lightFont),
                cellAlignment: pw.Alignment.center,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                },
                border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
                data: value.fprDetails.map((fpr) {
                  return [
                    DateFormat('dd-MM-yyyy').format(DateTime.parse(fpr['fpr_or_date'])),
                    fpr['fpr_or_no'] ?? 'N/A',
                    '${fpr['install_from']} - ${fpr['install_to']}',
                    (double.tryParse(fpr['premium_paid']?.toString() ?? '0') ?? 0).toStringAsFixed(2),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 15),

              // Total Amount Row
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 250,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('Total Paid Premium:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 10)),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        'BDT ${totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, fontSize: 10, color: PdfColor.fromHex('#2D3192')),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 50),
             
            ];
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/premium_payment_certificate.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      OpenFile.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      setState(() {
        _downloadingStates[policy.policyNo] = false;
      });
    }
  }

  pw.Widget _buildPdfDetailRow(String label, String value, pw.Font boldFont, pw.Font regularFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: boldFont, fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(font: regularFont, fontSize: 10)),
        ],
      ),
    );
  }

  // --- UI Components ---

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
        return Colors.indigo;
    }
  }

  Widget _buildPolicyCard(Policy policy) {
    final isDownloading = _downloadingStates[policy.policyNo] ?? false;
    final Color categoryColor = _getCategoryColor(policy.category);
    final int remainingInstallments = policy.totalInstall - policy.totalPaidInstall;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: categoryColor.withOpacity(0.6), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Category Color
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                policy.category,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),

            // Policy Plan Name
            Text(
              policy.planName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: categoryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10), // Increased spacing after title

            // Details
            _buildDetailRow(Icons.confirmation_number_outlined, 'Policy No', policy.policyNo),
            _buildDetailRow(Icons.person_outline, 'Holder Name', policy.customerName),

            const SizedBox(height: 5),
            _buildDetailRow(Icons.event_available_outlined, 'Risk Date', policy.riskDate),
            _buildDetailRow(Icons.event_busy_outlined, 'Maturity Date', policy.maturityDt),

            // Payment Status
            const SizedBox(height: 5), // Spacer
            _buildDetailRow(
                Icons.payment,
                'Installments Paid',
                '${policy.totalPaidInstall} / ${policy.totalInstall}'
            ),
            _buildDetailRow(
                Icons.hourglass_empty,
                'Remaining',
                remainingInstallments > 0 ? '$remainingInstallments' : 'Completed!'
            ),

            const Divider(height: 20), // Divider with vertical space

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isDownloading ? null : () => _generateAndDownloadPdf(policy),
                icon: isDownloading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(isDownloading ? 'Generating...' : 'Download Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Payment Certificate'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Policy>>(
        future: _policyListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No policies found.'));
          }

          final policies = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: policies.length,
            itemBuilder: (context, index) {
              final policy = policies[index];
              return _buildPolicyCard(policy);
            },
          );
        },
      ),
    );
  }
}