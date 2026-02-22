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

  Policy({
    required this.policyNo,
    required this.customerName,
    required this.dataSchema,
    required this.planName,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      policyNo: json['policy_no'] ?? '',
      customerName: json['customer_name'] ?? '',
      dataSchema: json['data_schema'] ?? '',
      planName: json['plan_name'] ?? 'N/A',
    );
  }
}

/// Represents the structure of the Tax Certificate data.
class TaxCertificateData {
  final Map<String, dynamic> policyDetails;
  final List<dynamic> fprDetails;

  TaxCertificateData({
    required this.policyDetails,
    required this.fprDetails,
  });

  factory TaxCertificateData.fromJson(Map<String, dynamic> json) {
    return TaxCertificateData(
      policyDetails: json['policyDetails'] ?? {},
      fprDetails: json['fprDetails'] ?? [],
    );
  }
}

// --- 2. API Service (Mocking for external dependencies) ---

class _ApiService {
  static const String _policyListUrl = 'https://nliuserapi.nextgenitltd.com/api/user-policy';
  static const String _taxCertBaseUrl = 'https://nliuserapi.nextgenitltd.com/api/tax-certificate';
  // NOTE: In a real app, you would add authentication headers here.
  
  Future<List<Policy>> fetchPolicyList() async {
    final prefs = await SharedPreferences.getInstance();
    // Use a placeholder token for standalone testing if no real token is found.
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

  Future<TaxCertificateData> fetchTaxCertificate({
    required String policyId,
    required String dataSchema,
    required String year,
  }) async {
    final encodedDataSchema = Uri.encodeComponent(dataSchema);
    final url = '$_taxCertBaseUrl?policyId=$policyId&dataSchema=$encodedDataSchema&year=$year';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return TaxCertificateData.fromJson(jsonResponse);
      }
    }
    throw Exception('Failed to load tax certificate');
  }
}

// --- 3. Main Screen Widget ---

class TaxRebateCertificate extends StatefulWidget {
  const TaxRebateCertificate({super.key});

  @override
  State<TaxRebateCertificate> createState() => _TaxRebateCertificateState();
}

class _TaxRebateCertificateState extends State<TaxRebateCertificate> {
  final _ApiService _apiService = _ApiService();

  Future<List<Policy>>? _policyListFuture;
  Policy? _selectedPolicy;
  String _selectedYear = '2024-2025';

  TaxCertificateData? _certificateData;
  bool _isCertificateLoading = false;
  String? _certificateError;
  bool _isDownloadInProgress = false;

  final List<String> _availableYears = [
    '2024-2025',
    '2023-2024',
    '2022-2023',
    '2021-2022',
  ];

  @override
  void initState() {
    super.initState();
    _policyListFuture = _apiService.fetchPolicyList();
  }

  // --- Core Logic ---

  void _fetchCertificate() async {
    if (_selectedPolicy == null) {
      setState(() => _certificateError = 'Please select a policy.');
      return;
    }

    setState(() {
      _isCertificateLoading = true;
      _certificateError = null;
      _certificateData = null;
    });

    try {
      final data = await _apiService.fetchTaxCertificate(
        policyId: _selectedPolicy!.policyNo,
        dataSchema: _selectedPolicy!.dataSchema,
        year: _selectedYear,
      );
      setState(() {
        _certificateData = data;
      });
    } catch (e) {
      setState(() {
        _certificateError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isCertificateLoading = false;
      });
    }
  }

  void _viewPdf() async {
    if (_certificateData == null) return;

    setState(() {
      _isDownloadInProgress = true;
    });

    try {
      final value = _certificateData!;
      double totalAmount = 0.0;
      value.fprDetails.forEach((element) {
        totalAmount = (totalAmount + double.parse(element['premium_paid']!));
      });

     final pdf = pw.Document();
                    final img = await rootBundle.load('assets/images/pdf/National_Is__1_-removebg-preview 1.png');
                    final imageBytes = img.buffer.asUint8List();
                    final micro = await rootBundle.load('assets/images/pdf/MicrosoftTeams-image (79) 1.png');
                    final microBytes = micro.buffer.asUint8List();
                    final base = await rootBundle.load('assets/images/pdf/National_Is__1_-removebg-preview 2.png');
                    final baseBytes = base.buffer.asUint8List();
                    final font = await PdfGoogleFonts.interBold();
                    final lightFont = await PdfGoogleFonts.interLight();

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
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey,
                    ),
                  ),
                ]));
          },
          build: (pw.Context context) {
            return [ // Return a list of widgets for MultiPage to lay out
              //header
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 17),
                child: pw.Container(
                    height: 45,
                    width: 794,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              pw.Container(
                                  height: 35,
                                  child: pw.Row(
                                      mainAxisAlignment: pw.MainAxisAlignment.start,
                                      children: [
                                        pw.Container(
                                            height: 25,
                                            width: 25,
                                            decoration: pw.BoxDecoration(
                                                image: pw.DecorationImage(
                                              image: pw.MemoryImage(imageBytes),
                                            ))),
                                        pw.SizedBox(width: 10),
                                        pw.Container(
                                            height: 20,
                                            child: pw.Align(
                                                alignment: pw.Alignment.centerLeft,
                                                child: pw.RichText(
                                                    text: pw.TextSpan(
                                                        text: "National Life Insurance Co. Ltd.\n",
                                                        style: pw.TextStyle(
                                                          fontSize: 13,
                                                          color: PdfColor.fromHex('#2D3192'),
                                                          fontWeight: pw.FontWeight.bold,
                                                          fontBold: font,
                                                        ),
                                                        children: [
                                                          pw.TextSpan(
                                                            text: "A Guarantee for a Planned Future",
                                                            style: pw.TextStyle(
                                                                fontSize: 12.5,
                                                                color: PdfColors.blue200,
                                                                fontBold: lightFont),
                                                          )
                                                        ]))))
                                      ])),
                            ]),
                        pw.Container(
                            height: 35,
                            width: 65,
                            decoration: pw.BoxDecoration(
                                image: pw.DecorationImage(
                                    image: pw.MemoryImage(microBytes),
                                    fit: pw.BoxFit.contain))),
                      ],
                    )),
              ),

              //tax rebate certificate pdf
              pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 17),
                  child: pw.Container(
                      height: 30,
                      width: 794,
                      margin: pw.EdgeInsets.only(top: 20),
                      child: pw.Align(
                          alignment: pw.Alignment.bottomCenter,
                          child: pw.Text("Tax Rebate Certificate",
                              style: pw.TextStyle(
                                  color: PdfColor.fromHex('#2d3192'),
                                  fontBold: font,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 15))))),

              pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 17),
                  child: pw.Container(
                      height: 10,
                      width: 794,
                      margin: pw.EdgeInsets.only(top: 20),
                      child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text("Date : ${DateFormat("dd-MM-yyyy").format(DateTime.now())}",
                              style: pw.TextStyle(
                                  color: PdfColor.fromHex('#1e1e1e'),
                                  fontBold: font,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))))),

              //date section of pdf
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(horizontal: 17),
                child: pw.Container(
                    width: 794,
                    margin: pw.EdgeInsets.only(top: 20),
                    child: pw.RichText(
                        textAlign: pw.TextAlign.justify,
                        text: pw.TextSpan(
                            text: "This is to Certify that Mr./Ms ",
                            style: pw.TextStyle(color: PdfColor.fromHex('#1e1e1e'), fontBold: font, fontSize: 10),
                            children: [
                              pw.TextSpan(
                                text: "${value.policyDetails['customer_name']}".toUpperCase().trim(),
                                style: pw.TextStyle(color: PdfColor.fromHex('#1e1e1e'), fontBold: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
                              ),
                              pw.TextSpan(
                                text: " is a policy owner of our Company. His/Her ",
                                style: pw.TextStyle(color: PdfColor.fromHex('#1e1e1e'), fontBold: font, fontSize: 10),
                              ),
                              pw.TextSpan(
                                text: "Policy No. ${value.policyDetails['policy_no']},",
                                style: pw.TextStyle(color: PdfColor.fromHex('#1e1e1e'), fontBold: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
                              ),
                              pw.TextSpan(
                                text: "Sum Assured = ",
                                style: pw.TextStyle(color: PdfColor.fromHex('#1e1e1e'), fontBold: font, fontSize: 10),
                              ),
                              pw.TextSpan(
                                text: "${value.policyDetails['sum_assured']}",
                                style: pw.TextStyle(color: PdfColor.fromHex('#1e1e1e'), fontBold: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
                              ),
                              pw.TextSpan(
                                text: " and Total Life Insurance Permium Paid Amount = ",
                                style: pw.TextStyle(color: PdfColor.fromHex('#1e1e1e'), fontBold: font, fontSize: 10),
                              ),
                              pw.TextSpan(
                                text: "$totalAmount",
                                style: pw.TextStyle(color: PdfColor.fromHex('#1e1e1e'), fontBold: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
                              ),
                              pw.TextSpan(
                                text: " Taka during the financial year $_selectedYear, details of which are as following: ",
                                style: pw.TextStyle(color: PdfColor.fromHex('#1e1e1e'), fontBold: font, fontSize: 10),
                              )
                            ]))),
              ),
              pw.SizedBox(height: 20),
              // --- Data Table ---
              pw.Table.fromTextArray(
                headers: ['PR OR Date', 'PR OR NO', 'Total Amount (BDT)'],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#2D3192'),
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.center,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                },
                border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
                data: value.fprDetails.map((fpr) {
                  return [
                    fpr['fpr_or_date'] ?? 'N/A',
                    fpr['fpr_or_no'] ?? 'N/A',
                    (double.tryParse(fpr['premium_paid']?.toString() ?? '0') ?? 0).toStringAsFixed(2),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 15),
              // --- Total Amount Row ---
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 250,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('Total Paid Premium:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        'BDT ${totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('#2D3192')),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/tax_rebate_certificate.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    } finally {
      setState(() {
        _isDownloadInProgress = false;
      });
    }
  }

  // --- UI Components ---

  Widget _buildPolicyDropdown(List<Policy> policies) {
    return DropdownButtonFormField<Policy>(
      decoration: const InputDecoration(
        labelText: 'Select Policy',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      value: _selectedPolicy,
      hint: const Text('Select a policy'),
      isExpanded: true,
      items: policies.map((policy) {
        return DropdownMenuItem<Policy>(
          value: policy,
          child: Text(
            '${policy.policyNo} - ${policy.customerName}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (Policy? newValue) {
        setState(() {
          _selectedPolicy = newValue;
          // Clear previous results when selection changes
          _certificateData = null;
          _certificateError = null;
        });
      },
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Select Financial Year',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      value: _selectedYear,
      hint: const Text('Select Year'),
      isExpanded: true,
      items: _availableYears.map((year) {
        return DropdownMenuItem<String>(
          value: year,
          child: Text(year),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedYear = newValue!;
          // Clear previous results when selection changes
          _certificateData = null;
          _certificateError = null;
        });
      },
    );
  }
  
  // Custom Card for displaying a key detail
  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatePreview() {
    if (_isCertificateLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_certificateError != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text(
                'Could Not Load Certificate',
                style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _certificateError! == 'No certificate data found for this policy.' ? 'You have no certificate for the selected policy and year.' : _certificateError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
          ),
        ),
      );
    }
    if (_certificateData == null) {
      return const Center(
        child: Text(
          'Select a policy and year, then click "View Certificate".',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    final details = _certificateData!.policyDetails;
    final fprList = _certificateData!.fprDetails;
    
    // Calculate total paid premium for the year (simple sum of premium_paid from FPR list)
    double totalPaid = 0;
    for (var fpr in fprList) {
      totalPaid += double.tryParse(fpr['premium_paid'].toString()) ?? 0;
    }

   return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Policy Summary Header


 

    // Premium Payment Records Header
    const Text(
      'Premium Payment Records (FPR Details)',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
    ),
    const Divider(),

    // Data Table for FPR Details wrapped in a Card for Material look
    Card(
      elevation: 2,
      margin: EdgeInsets.zero, // Remove outer margin for clean look
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          // Material Design Styling for Table
          columnSpacing: 20,
          horizontalMargin: 10, // Add a small margin inside the Card
          dataRowMinHeight: 35,
          dataRowMaxHeight: 40,
          headingRowHeight: 45,
          border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),

          columns: const [
            DataColumn(label: Text(
              'Date', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0) // 14.0 font size
            )),
            DataColumn(label: Text(
              'Premium Paid', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0), // 14.0 font size
              textAlign: TextAlign.right
            )),
            DataColumn(label: Text(
              'Business Year', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0) // 14.0 font size
            )),
          ],
          rows: fprList.map((fpr) {
            return DataRow(cells: [
              DataCell(Text(
                fpr['fpr_or_date'].toString(),
                style: const TextStyle(fontSize: 12.0), // 12.0 font size
              )),
              DataCell(Text(
                (double.tryParse(fpr['premium_paid'].toString()) ?? 0).toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green, fontSize: 12.0), // 12.0 font size
              )),
              DataCell(Text(
                fpr['business_year'].toString(),
                style: const TextStyle(fontSize: 12.0), // 12.0 font size
              )),
            ]);
          }).toList(),
        ),
      ),
    ),

    const SizedBox(height: 30),

    // Conditionally display the Download Button
    if (fprList.isNotEmpty)
      Center(
        child: ElevatedButton.icon(
          onPressed: _isDownloadInProgress ? null : _viewPdf,
          icon: _isDownloadInProgress
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: Text(_isDownloadInProgress ? 'Generating...' : 'View as PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
  ],
);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Rebate Certificate'),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Card view for selection controls
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildPolicyDropdown(policies),
                        const SizedBox(height: 20.0),
                        _buildYearDropdown(),
                        const SizedBox(height: 25.0),
                        ElevatedButton.icon(
                          onPressed: _isCertificateLoading ? null : _fetchCertificate,
                          icon: _isCertificateLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.visibility),
                          label: Text(_isCertificateLoading ? 'Loading...' : 'View Certificate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            minimumSize: const Size(double.infinity, 50), // Make button full width
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25.0),

                // Certificate Preview Section
                _buildCertificatePreview(),
              ],
            ),
          );
        },
      ),
    );
  }
}
// NOTE: To run this file, you would typically wrap the TaxRebateCertificate widget
// in a MaterialApp (e.g., inside the main() function or a higher-level widget).