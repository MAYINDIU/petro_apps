import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


// --- Placeholder/Mock Implementations ---
// These classes are created based on the provided API function to make the code runnable.

const String USERAPP_URL = 'https://nliuserapi.nextgenitltd.com/api';

class LogDebugger {
  static final LogDebugger instance = LogDebugger._internal();
  LogDebugger._internal();
  void i(String message) => debugPrint('[INFO]: $message');
  void e(dynamic message) => debugPrint('[ERROR]: $message');
}

enum ResponseCode { SUCCESSFUL, FAILED }

class ResponseObject {
  final dynamic object;
  final ResponseCode id;
  final String? errorMessage;
  final bool success;

  ResponseObject({required this.object, required this.id, this.errorMessage, this.success = false});
}

class BaseAPICaller {
  static Future<ResponseObject> getRequest(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ResponseObject(object: data, id: ResponseCode.SUCCESSFUL, success: true);
        } else {
          return ResponseObject(object: null, id: ResponseCode.FAILED, success: false, errorMessage: data['message'] ?? 'API returned failure');
        }
      } else {
        return ResponseObject(object: null, id: ResponseCode.FAILED, success: false, errorMessage: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      return ResponseObject(object: null, id: ResponseCode.FAILED, success: false, errorMessage: e.toString());
    }
  }
}

extension ResponseObjectExtension on ResponseObject {
  dynamic get returnValue => object;
}

class AdminSearchModel {
  final String policyNo;
  final String policyStatus;
  final String customerName;
  final String mobile;
  final String? birthDate;
  final String? gender;
  final String planName;
  final String? category;
  final String? sumAssured;
  final String? totalPremium;
  final String? modeOfPay;
  final String? riskDate;
  final String? maturityDate;
  final String? lastPaidDate;
  final String? totalPaidInstallments;
  final String? totalInstallments;
  final String? agentName;
  final String? nomineeName;
  final String? nomineeRelation;
  final String? onMaturityDetails; // HTML content
  final String? onDeathDetails; // HTML content

  AdminSearchModel({
    required this.policyNo,
    required this.policyStatus,
    required this.customerName,
    required this.mobile,
    this.birthDate,
    this.gender,
    required this.planName,
    this.category,
    this.sumAssured,
    this.totalPremium,
    this.modeOfPay,
    this.riskDate,
    this.maturityDate,
    this.lastPaidDate,
    this.totalPaidInstallments,
    this.totalInstallments,
    this.agentName,
    this.nomineeName,
    this.nomineeRelation,
    this.onMaturityDetails,
    this.onDeathDetails,
  });

  // Helper to format date strings or return 'N/A'
  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM, yyyy').format(dt);
    } catch (e) {
      return dateStr; // Return original string if parsing fails
    }
  }

  factory AdminSearchModel.fromJson(Map<String, dynamic> json) {
    // --- Correction: Handle 'data' as a Map, not a List ---
    final Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Policy data object not found in the API response.');
    }

    return AdminSearchModel(
      policyNo: data['policy_no']?.toString() ?? 'N/A',
      policyStatus: data['policy_status'] == '1' ? 'Active' : 'Inactive',
      customerName: data['customer_name']?.toString() ?? 'N/A',
      mobile: data['mobile']?.toString() ?? 'N/A',
      birthDate: _formatDate(data['birth_date']?.toString()),
      gender: data['gender']?.toString(),
      planName: data['plan_name']?.toString() ?? 'N/A',
      category: data['category']?.toString(),
      sumAssured: data['sum_assured']?.toString(),
      totalPremium: data['totalprem']?.toString(),
      modeOfPay: data['mode_of_pay']?.toString(),
      riskDate: _formatDate(data['risk_date']?.toString()),
      maturityDate: _formatDate(data['maturity_dt']?.toString()),
      lastPaidDate: _formatDate(data['lastpaid']?.toString()),
      totalPaidInstallments: data['total_paid_install']?.toString(),
      totalInstallments: data['total_install']?.toString(),
      agentName: data['agent_name']?.toString().trim(),
      nomineeName: data['nom_name']?.toString(),
      nomineeRelation: data['nom_rel']?.toString(),
      onMaturityDetails: data['onamturitydetails']?.toString(),
      onDeathDetails: data['assuarancedeathdetails']?.toString(),
    );
  }
}

class PolicySearchService {
  Future<ResponseObject> getAdmin({required String policyno, String? dob, String? mobile, String? riskDate}) async {
    try {
      if (policyno.isNotEmpty == true && dob != null && dob.isNotEmpty == true) {
        print("dob");
        final _response = await BaseAPICaller.getRequest('$USERAPP_URL/policy-details-by-admin?policy_no=$policyno&dob=$dob');
        if (_response.success) {
          var adminType = AdminSearchModel.fromJson(_response.returnValue);
          return ResponseObject(object: adminType, id: ResponseCode.SUCCESSFUL);
        } else {
          return ResponseObject(object: _response.errorMessage, id: ResponseCode.FAILED);
        }
      } else if (policyno.isNotEmpty == true && mobile != null && mobile.isNotEmpty == true) {
        print("mobile");
        final _response = await BaseAPICaller.getRequest('$USERAPP_URL/policy-details-by-admin?policy_no=$policyno&mobile=$mobile');
        if (_response.success) {
          var adminType = AdminSearchModel.fromJson(_response.returnValue);
          return ResponseObject(object: adminType, id: ResponseCode.SUCCESSFUL);
        } else {
          return ResponseObject(object: _response.errorMessage, id: ResponseCode.FAILED);
        }
      } else if (policyno.isNotEmpty == true && riskDate != null && riskDate.isNotEmpty == true) {
        print("Risk date");
        final _response = await BaseAPICaller.getRequest('$USERAPP_URL/policy-details-by-admin?policy_no=$policyno&riskdate=$riskDate');
        if (_response.success) {
          var adminType = AdminSearchModel.fromJson(_response.returnValue);
          return ResponseObject(object: adminType, id: ResponseCode.SUCCESSFUL);
        } else {
          return ResponseObject(object: _response.errorMessage, id: ResponseCode.FAILED);
        }
      } else {
        return ResponseObject(object: "Invalid search criteria.", id: ResponseCode.FAILED);
      }
    } catch (e) {
      LogDebugger.instance.e(e);
      return ResponseObject(object: e.toString(), id: ResponseCode.FAILED);
    }
  }
}

// --- UI Implementation ---

class PolicySearchScreen extends StatefulWidget {
  const PolicySearchScreen({super.key});

  @override
  State<PolicySearchScreen> createState() => _PolicySearchScreenState();
}

class _PolicySearchScreenState extends State<PolicySearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _policySearchService = PolicySearchService();

  final _policyNoController = TextEditingController();
  final _mobileController = TextEditingController();
  DateTime? _dob;
  DateTime? _riskDate;

  bool _isLoading = false;
  AdminSearchModel? _searchResult;
  bool _isDownloading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _policyNoController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _performSearch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResult = null;
    });

    final policyNo = _policyNoController.text;
    ResponseObject response;

    switch (_tabController.index) {
      case 0: // DOB
        if (_dob == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Please select a Date of Birth.";
          });
          return;
        }
        final dobString = DateFormat('yyyy-MM-dd').format(_dob!);
        response = await _policySearchService.getAdmin(policyno: policyNo, dob: dobString);
        break;
      case 1: // Mobile
        response = await _policySearchService.getAdmin(policyno: policyNo, mobile: _mobileController.text);
        break;
      case 2: // Risk Date
        if (_riskDate == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Please select a Risk Date.";
          });
          return;
        }
        final riskDateString = DateFormat('yyyy-MM-dd').format(_riskDate!);
        response = await _policySearchService.getAdmin(policyno: policyNo, riskDate: riskDateString);
        break;
      default:
        return;
    }

    setState(() {
      _isLoading = false;
      if (response.id == ResponseCode.SUCCESSFUL) {
        _searchResult = response.object as AdminSearchModel;
      } else {
        _errorMessage = response.object?.toString() ?? "An unknown error occurred.";
      }
    });
  }

  Future<void> _generateAndSavePdf() async {
    if (_searchResult == null) return;

    setState(() => _isDownloading = true);

    try {
      final result = _searchResult!;
      final pdf = pw.Document();

      // Load assets
      final font = await PdfGoogleFonts.interBold();
      final lightFont = await PdfGoogleFonts.interLight();
      final logoBytes = (await rootBundle.load('assets/images/pdf/National_Is__1_-removebg-preview 1.png')).buffer.asUint8List();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // --- Header ---
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(children: [
                      pw.Image(pw.MemoryImage(logoBytes), width: 40, height: 40),
                      pw.SizedBox(width: 10),
                      pw.Text('National Life Insurance Co. Ltd.', style: pw.TextStyle(font: font, fontSize: 14, color: PdfColor.fromHex('#1E40AF'))),
                    ]),
                    pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}', style: pw.TextStyle(font: lightFont, fontSize: 10)),
                  ],
                ),
                pw.Divider(height: 20, thickness: 2, color: PdfColor.fromHex('#1E40AF')),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text('Policy Search Details', style: pw.TextStyle(font: font, fontSize: 18)),
                ),
                pw.SizedBox(height: 20),

                // --- Sections ---
                _buildPdfSection(
                  title: 'Policy & Customer Details',
                  font: font,
                  children: [
                    _buildPdfRow('Policy No:', result.policyNo, font: font),
                    _buildPdfRow('Status:', result.policyStatus, font: font),
                    _buildPdfRow('Customer Name:', result.customerName, font: font),
                    _buildPdfRow('Mobile:', result.mobile, font: font),
                    _buildPdfRow('Date of Birth:', result.birthDate ?? 'N/A', font: font),
                    _buildPdfRow('Gender:', result.gender ?? 'N/A', font: font),
                  ],
                ),
                _buildPdfSection(
                  title: 'Financial Information',
                  font: font,
                  children: [
                    _buildPdfRow('Sum Assured:', result.sumAssured ?? 'N/A', font: font),
                    _buildPdfRow('Total Premium:', result.totalPremium ?? 'N/A', font: font),
                    _buildPdfRow('Payment Mode:', result.modeOfPay ?? 'N/A', font: font),
                    _buildPdfRow('Last Paid Date:', result.lastPaidDate ?? 'N/A', font: font),
                    _buildPdfRow('Installments Paid:', '${result.totalPaidInstallments ?? 'N/A'} / ${result.totalInstallments ?? 'N/A'}', font: font),
                  ],
                ),
                _buildPdfSection(
                  title: 'Agent & Nominee',
                  font: font,
                  children: [
                    _buildPdfRow('Agent:', result.agentName ?? 'N/A', font: font),
                    _buildPdfRow('Nominee:', result.nomineeName ?? 'N/A', font: font),
                    _buildPdfRow('Nominee Relation:', result.nomineeRelation ?? 'N/A', font: font),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/policy_details_${result.policyNo}.pdf");
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to ${file.path}')),
      );
      OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  pw.Widget _buildPdfSection({required String title, required pw.Font font, required List<pw.Widget> children}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: font, fontSize: 14, color: PdfColor.fromHex('#1E40AF'))),
        pw.Divider(color: PdfColors.grey400),
        pw.Column(children: children),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildPdfRow(String label, String value, {required pw.Font font}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(label, style: pw.TextStyle(font: font)), pw.Text(value)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Policy Search'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _policyNoController,
              decoration: const InputDecoration(
                labelText: 'Policy Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.policy),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Policy number is required' : null,
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1E40AF),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'By DOB'),
                Tab(text: 'By Mobile'),
                Tab(text: 'By Risk Date'),
              ],
            ),
            SizedBox(
              height: 120,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDatePicker((date) => setState(() => _dob = date), _dob, 'Date of Birth'),
                  _buildMobileInput(),
                  _buildDatePicker((date) => setState(() => _riskDate = date), _riskDate, 'Risk Date'),
                ],
              ),
            ),
            const SizedBox(height: 2),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _performSearch,
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.search),
              label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            if (_searchResult != null) _buildResultCard(_searchResult!),
            if (_errorMessage != null) _buildErrorCard(_errorMessage!),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(Function(DateTime) onDateSelected, DateTime? selectedDate, String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(selectedDate == null ? 'No date selected' : DateFormat('yyyy-MM-dd').format(selectedDate)),
          TextButton(
            onPressed: () => _selectDate(context, onDateSelected),
            child: Text('Select $label'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: TextFormField(
        controller: _mobileController,
        decoration: const InputDecoration(
          labelText: 'Mobile Number',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.phone),
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (_tabController.index == 1 && (value == null || value.isEmpty)) {
            return 'Mobile number is required for this search';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildResultCard(AdminSearchModel result) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Policy & Customer Details',
            icon: Icons.policy,
            initiallyExpanded: true,
            children: [
              _buildResultRow('Policy No:', result.policyNo, isHighlight: true),
              _buildResultRow('Status:', result.policyStatus, valueColor: result.policyStatus == 'Active' ? Colors.green.shade700 : Colors.red.shade700),
              _buildResultRow('Customer Name:', result.customerName),
              _buildResultRow('Mobile:', result.mobile),
              _buildResultRow('Date of Birth:', result.birthDate ?? 'N/A'),
              _buildResultRow('Gender:', result.gender ?? 'N/A'),
            ],
          ),
          _buildSectionCard(
            title: 'Financial Information',
            icon: Icons.account_balance_wallet,
            children: [
              _buildResultRow('Sum Assured:', result.sumAssured ?? 'N/A'),
              _buildResultRow('Total Premium:', result.totalPremium ?? 'N/A'),
              _buildResultRow('Payment Mode:', result.modeOfPay ?? 'N/A'),
              _buildResultRow('Last Paid Date:', result.lastPaidDate ?? 'N/A'),
              _buildResultRow('Installments Paid:', '${result.totalPaidInstallments ?? 'N/A'} / ${result.totalInstallments ?? 'N/A'}'),
            ],
          ),
          _buildSectionCard(
            title: 'Agent & Nominee',
            icon: Icons.people,
            children: [
              _buildResultRow('Agent:', result.agentName ?? 'N/A'),
              _buildResultRow('Nominee:', result.nomineeName ?? 'N/A'),
              _buildResultRow('Nominee Relation:', result.nomineeRelation ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isDownloading ? null : _generateAndSavePdf,
            icon: _isDownloading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf),
            label: Text(_isDownloading ? 'Generating PDF...' : 'Download as PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669), // A green color for download
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: const Color(0xFF1E40AF)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: children,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHighlight = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black87,
                fontSize: isHighlight ? 15 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 16),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}