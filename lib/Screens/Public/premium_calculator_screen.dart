// Flutter and Dart standard imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/services.dart';

// -------------------------------------------------------------
// --- 1. Utility Constants and Models 📚 ----------------------
// -------------------------------------------------------------

// NOTE: Replace with your actual development or production URL.
const String BASE_URL = 'https://nliuserapi.nextgenitltd.com/api'; 
const MaterialColor kThemeColorSwatch = Colors.blue; 
const Color kThemeColor = kThemeColorSwatch; 
const Color kDisabledColor = Colors.grey; 
// New: Subtle background color for input fields
const Color kInputFillColor = Color(0xFFF7F7F7); 

// Mock LogDebugger for console logging
class LogDebugger {
  static final LogDebugger instance = LogDebugger._internal();
  LogDebugger._internal();
  void i(String message) {
    // ignore: avoid_print
    print('[INFO]: $message'); 
  }
  void e(dynamic message) {
    // ignore: avoid_print
    print('[ERROR]: $message');
  }
}

// Policy Plan Model
class PolicyPlan {
  final String planId;
  final String planName;
  final String projectName;

  PolicyPlan({
    required this.planId, 
    required this.planName, 
    required this.projectName,
  });
  
  factory PolicyPlan.fromJson(Map<String, dynamic> json) => PolicyPlan(
    planId: json['plan_id'] as String? ?? 'N/A',
    planName: json['plan_name'] as String? ?? 'No Name',
    projectName: json['project_name'] as String? ?? 'DEFAULT_PROJECT',
  );
}

// Term Model
class TermOfYearData { 
  final int termOfYear; 
  TermOfYearData({required this.termOfYear}); 
  factory TermOfYearData.fromJson(Map<String, dynamic> json) => TermOfYearData(
    termOfYear: int.tryParse(json['term'] as String? ?? '0') ?? 0, 
  );
}

// Installment Type Model
class InstallmentTypeData { 
  final String payMode; 
  InstallmentTypeData({required this.payMode}); 
  factory InstallmentTypeData.fromJson(Map<String, dynamic> json) => InstallmentTypeData(
    payMode: json['pay_mode'] as String? ?? 'N/A', 
  );
}

// Model for /Installment-Wise-calc response (Premium Factor)
class PremiumFactorResult {
  final String payMode;
  final double premiumFactor;

  PremiumFactorResult({required this.payMode, required this.premiumFactor});

  factory PremiumFactorResult.fromJson(Map<String, dynamic> json) {
    return PremiumFactorResult(
      payMode: json['pay_mode'] as String? ?? 'N/A',
      premiumFactor: double.tryParse(json['pay_mode_extra'] as String? ?? '1.0') ?? 1.0,
    );
  }
}

// Model for /rates-calculate response (Base Premium Rate)
class RatesCalculateResult {
  final double baseRate; 

  RatesCalculateResult({required this.baseRate});

  factory RatesCalculateResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? ratesList = json['data']?['rates'];
    final rateString = ratesList?.isNotEmpty == true 
                       ? (ratesList![0]['premium_rate'] ?? '0.05').toString() 
                       : '0.05';
    
    return RatesCalculateResult(
      baseRate: double.tryParse(rateString) ?? 0.05,
    );
  }
}

// Supplementary Data Model (for Profession dropdown)
class SupplementaryData {
  final String profession;
  final String gender;
  final String? status; // "Decline" or null

  SupplementaryData({
    required this.profession,
    required this.gender,
    this.status,
  });

  factory SupplementaryData.fromJson(Map<String, dynamic> json) {
    return SupplementaryData(
      profession: json['profession'] as String? ?? 'N/A',
      gender: json['gender'] as String? ?? 'N/A',
      status: json['status'] as String?,
    );
  }

  @override
  bool operator ==(Object other) => 
    identical(this, other) || 
    other is SupplementaryData && 
    runtimeType == other.runtimeType && 
    profession == other.profession &&
    gender == other.gender;

  @override
  int get hashCode => profession.hashCode ^ gender.hashCode;
}

// Final result model
class PremiumResult {
  final double premiumAmount;
  PremiumResult({required this.premiumAmount});
}


// -------------------------------------------------------------
// --- 2. API Service Wrapper 🌐 (Unchanged) --------------------
// -------------------------------------------------------------
class PremiumApiServices {
  
  // Helper for API calls
  Future<Map<String, dynamic>> _fetchData(String endpoint) async {
    final uri = Uri.parse(endpoint);
    LogDebugger.instance.i('API Call: $endpoint');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      
      if (data['success'] == true || data.containsKey('data')) {
        return data;
      } else {
        throw Exception('API returned failure: ${data['message'] ?? 'Unknown API Error'}');
      }
    } else {
      throw Exception('Failed to load data. Status: ${response.statusCode}');
    }
  }

  // 2.1 Fetch All Policy List
  Future<List<PolicyPlan>> fetchAllPolicyList({required int age}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final data = await _fetchData('$BASE_URL/all-policy-list?age=$age');
    final List<dynamic> policyData = data['data'];

    if (policyData.isEmpty) {
      throw Exception('Policy list API returned no data for age $age.');
    }
    
    return policyData.map((e) => PolicyPlan.fromJson(e)).toList();
  }

  // 2.2 Fetch Terms
  Future<List<TermOfYearData>> fetchTerms({required String productId, required int age}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final data = await _fetchData('$BASE_URL/term-of-year?productid=$productId&age=$age');
    final List<dynamic> termData = data['data'];
    return termData.map((e) => TermOfYearData.fromJson(e)).toList();
  }

  // 2.3 Fetch Installment Types
  Future<List<InstallmentTypeData>> fetchInstallmentTypes({required String productId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final data = await _fetchData('$BASE_URL/InstallmentType?productid=$productId');
    final List<dynamic> installmentData = data['data'];
    return installmentData.map((e) => InstallmentTypeData.fromJson(e)).toList();
  }

  // 2.4 Age calculation
  Future<int> calculateAge({required String dob}) async {
    final parsed = DateTime.parse(dob);
    final today = DateTime.now();
    int age = today.year - parsed.year;
    if (today.month < parsed.month || (today.month == parsed.month && today.day < parsed.day)) {
      age--;
    }
    if (age < 0) return 0;
    await Future.delayed(const Duration(milliseconds: 300));
    return age; 
  }

  // 2.5 Fetch Premium Factor from /Installment-Wise-calc
  Future<PremiumFactorResult> fetchPremiumFactor({
    required String planId, 
    required String installmentType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final endpoint = '$BASE_URL/Installment-Wise-calc?planId=$planId&installmentType=$installmentType';
    final data = await _fetchData(endpoint);
    if (data['data'] is! Map<String, dynamic>) {
      throw Exception('Premium Factor data format error.');
    }
    return PremiumFactorResult.fromJson(data['data']);
  }
  
  // 2.6 Fetch Base Premium Rate from /rates-calculate
  Future<RatesCalculateResult> fetchRatesCalculate({
    required String productId,
    required int term,
    required int age,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final endpoint = '$BASE_URL/rates-calculate?productid=$productId&term=$term&age=$age';
    final data = await _fetchData(endpoint);
    return RatesCalculateResult.fromJson(data);
  }

  // 2.7 Fetch Supplementary Check (Professions)
  Future<List<SupplementaryData>> fetchSupplementaryCheck({required String gender}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final data = await _fetchData('$BASE_URL/supplementry-check?gender=${gender.toUpperCase()}');
    if (data['data'] is List) {
      final List<dynamic> supplementaryDataList = data['data'];
      return supplementaryDataList.map((e) => SupplementaryData.fromJson(e)).toList();
    }
    throw Exception('Supplementary data format error.');
  }
}


// -------------------------------------------------------------
// --- 3. Main Application and Screen 📱 ----------------------
// -------------------------------------------------------------

void main() {
  runApp(const PremiumCalculatorApp());
}

class PremiumCalculatorApp extends StatelessWidget {
  const PremiumCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Premium Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: kThemeColorSwatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey.shade50, 
      ),
      home: const PremiumCalculatorScreen(),
    );
  }
}

class PremiumCalculatorScreen extends StatefulWidget {
  final bool isFromPolicyAdvisor;
  const PremiumCalculatorScreen({super.key, this.isFromPolicyAdvisor = false});

  @override
  State<PremiumCalculatorScreen> createState() => _PremiumCalculatorScreenState();
}

class _PremiumCalculatorScreenState extends State<PremiumCalculatorScreen> {
  // --- State Variables ---
  final PremiumApiServices _apiServices = PremiumApiServices();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _dob;
  int? _calculatedAge;
  
  String? _selectedGender; 
  final List<String> _genderOptions = const ['Select Gender','MALE', 'FEMALE']; 
  
  List<SupplementaryData> _supplementaryList = [];
  SupplementaryData? _selectedProfession; 

  List<PolicyPlan> _policyList = [];
  PolicyPlan? _selectedPolicy;

  List<TermOfYearData> _termList = [];
  int? _selectedTerm;

  List<InstallmentTypeData> _installmentTypeList = [];
  String? _selectedInstallmentType;

  // Controllers for Sum Assured and Premium Amount
  final TextEditingController _sumAssuredController = TextEditingController();
  final TextEditingController _premiumAmountController = TextEditingController();

  PremiumResult? _premiumResult;
  String? _premiumErrorMessage;

  bool _isLoading = false;
  bool _isSaving = false;
  
  // --- Debounce Timer for automatic calculation ---
  Timer? _debounce; 

  // --- Lifecycle and Utility Functions (Unchanged in Logic) ---

  @override
  void dispose() {
    _sumAssuredController.dispose();
    _premiumAmountController.dispose();
    if (_debounce?.isActive ?? false) _debounce!.cancel(); 
    super.dispose();
  }

  void _resetDependentFields({required bool clearAge}) {
    if (_debounce?.isActive ?? false) _debounce!.cancel(); 
    if (clearAge) _calculatedAge = null;
    _selectedGender = null;
    _supplementaryList.clear();
    _selectedProfession = null;
    _policyList.clear();
    _selectedPolicy = null;
    _selectedTerm = null;
    _selectedInstallmentType = null;
    _termList.clear();
    _installmentTypeList.clear();
    _premiumResult = null;
    _premiumErrorMessage = null;
    _premiumAmountController.clear();
    _sumAssuredController.clear();
  }
  
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _resetPolicyFields() {
    if (_debounce?.isActive ?? false) _debounce!.cancel(); 
    _selectedPolicy = null;
    _selectedTerm = null;
    _selectedInstallmentType = null;
    _policyList.clear();
    _termList.clear();
    _installmentTypeList.clear();
    _premiumResult = null; 
    _premiumErrorMessage = null;
    _premiumAmountController.clear();
  }

  // --- Data Handlers (Unchanged in Logic) ---

  Future<void> _handleDOBSelection(DateTime pickedDate) async {
    setState(() {
      _dob = pickedDate;
      _resetDependentFields(clearAge: true);
      _isLoading = true;
    });

    try {
      final dobString = DateFormat('yyyy-MM-dd').format(pickedDate);
      final age = await _apiServices.calculateAge(dob: dobString); 
      
      setState(() {
        _calculatedAge = age;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showSnackBar('Failed to calculate age: ${e.toString().split(':').last.trim()}');
      });
    }
  }

  Future<void> _handleGenderChange(String? newGender) async {
    if (newGender == null || newGender == _selectedGender) return;
    
    _resetPolicyFields(); 

    setState(() {
      _selectedGender = newGender;
      _supplementaryList.clear();
      _selectedProfession = null;
      _isLoading = true;
    });
    
    try {
      final supplementaryData = await _apiServices.fetchSupplementaryCheck(gender: newGender);
      
      setState(() {
        _supplementaryList = supplementaryData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showSnackBar('Failed to load professions: ${e.toString().split(':').last.trim()}');
      });
    }
  }


  Future<void> _handleProfessionChange(SupplementaryData? newProfession) async {
    if (newProfession == null || _calculatedAge == null || newProfession == _selectedProfession) return;

    _resetPolicyFields(); 

    if (newProfession.status == 'Decline') {
      setState(() {
        _selectedProfession = newProfession;
        _showSnackBar('${newProfession.profession} is a Declined profession.');
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _selectedProfession = newProfession;
      _isLoading = true;
    });

    try {
      final policies = await _apiServices.fetchAllPolicyList(age: _calculatedAge!);
      
      setState(() {
        _policyList = policies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showSnackBar('Failed to load policies: ${e.toString().split(':').last.trim()}');
      });
    }
  }


  Future<void> _handlePolicyChange(PolicyPlan? policy) async {
    if (policy == null || _calculatedAge == null) return;

    // Reset Term/Installment when policy changes
    _selectedTerm = null;
    _selectedInstallmentType = null;
    _termList.clear();
    _installmentTypeList.clear();
    _premiumResult = null; 
    _premiumErrorMessage = null;
    _premiumAmountController.clear();
    if (_debounce?.isActive ?? false) _debounce!.cancel();


    setState(() {
      _selectedPolicy = policy;
      _isLoading = true;
    });

    try {
      final termsFuture = _apiServices.fetchTerms(productId: policy.planId, age: _calculatedAge!);
      final installmentFuture = _apiServices.fetchInstallmentTypes(productId: policy.planId);

      final results = await Future.wait([termsFuture, installmentFuture]);
      final terms = results[0] as List<TermOfYearData>;
      final installments = results[1] as List<InstallmentTypeData>;

      setState(() {
        _termList = terms;
        _installmentTypeList = installments;
        _isLoading = false;
      });
      
      // Trigger calculation immediately if sum assured is already entered
      if (_sumAssuredController.text.isNotEmpty) {
        _calculatePremiumOnChange(_sumAssuredController.text);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showSnackBar('Failed to load terms/installments: ${e.toString().split(':').last.trim()}');
      });
    }
  }

  // --- Automatic Calculation Logic (Unchanged in Logic) ---
  Future<void> _calculatePremiumOnChange(String sumAssuredValue) async {
    // 1. Check if all required fields are selected
    if (_selectedPolicy == null || _selectedInstallmentType == null || _selectedTerm == null || _calculatedAge == null || _selectedProfession == null || _selectedProfession?.status == 'Decline') {
      _premiumAmountController.clear();
      return;
    }

    // 2. Sum Assured Parsing and basic check
    final double sumAssured;
    final value = sumAssuredValue.replaceAll(RegExp(r'[^0-9.]'), '');
    
    try {
      sumAssured = double.parse(value);
      if (sumAssured <= 0) throw const FormatException();
    } catch (_) {
      _premiumAmountController.clear();
      setState(() => _premiumErrorMessage = 'Enter a valid Sum Assured.');
      return;
    }

    setState(() {
      _isLoading = true;
      _premiumErrorMessage = null;
      _premiumAmountController.text = 'Calculating...';
    });
    
    try {
      // API Calls for calculation components
      final factorResult = await _apiServices.fetchPremiumFactor(
        planId: _selectedPolicy!.planId, 
        installmentType: _selectedInstallmentType!,
      );
      
      final ratesResult = await _apiServices.fetchRatesCalculate(
        productId: _selectedPolicy!.planId, 
        term: _selectedTerm!,
        age: _calculatedAge!,
      );

      // --- Premium Calculation with Conditional Logic ---
      final double baseRate = ratesResult.baseRate;
      final double factor = factorResult.premiumFactor;
      
      // LOGIC: Add 1.0 to base rate if Sum Assured is 100,000 or less.
      final bool sumAssuredSpecialCase = (sumAssured <= 100000.0);
      final double adjustedBaseRate = sumAssuredSpecialCase ? (baseRate + 1.0) : baseRate;
      
      final double rawPremium = (sumAssured * adjustedBaseRate / 1000) * factor;
      final int finalPremium = rawPremium.round(); 
      
      final formattedPremium = NumberFormat('###,###').format(finalPremium);

      setState(() {
        _premiumResult = PremiumResult(premiumAmount: finalPremium.toDouble());
        _premiumAmountController.text = formattedPremium; 
        _isLoading = false;
        _premiumErrorMessage = null;
      });

    } catch (e) {
      LogDebugger.instance.e('Auto Calculation error: $e');
      setState(() {
        _isLoading = false;
        _premiumAmountController.text = 'Error';
        _premiumErrorMessage = 'Calculation failed: ${e.toString().split(':').last.trim()}';
      });
    }
  }

  Future<void> _savePolicyAdvisorData(BuildContext dialogContext) async {
    final url = Uri.parse('https://nliuserapi.nextgenitltd.com/api/policy-advisor-save');
    
    double sumAssured = double.tryParse(_sumAssuredController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    
    final Map<String, dynamic> body = {
      "PlanId": _selectedPolicy?.planId ?? "",
      "PaymentMode": _selectedInstallmentType ?? "",
      "TermOfYear": _selectedTerm ?? 0,
      "Dob": _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : "",
      "Age": _calculatedAge ?? 0,
      "Profession": _selectedProfession?.profession ?? "",
      "Gender": _selectedGender ?? "",
      "Sumassured": sumAssured,
      "SupplementryAmount": 0.0,
      "BasicAmount": _premiumResult?.premiumAmount ?? 0.0,
      "ExtraPremium": 0.0,
      "SuppType": "",
      "SuppRate": "0",
      "OERate": "0",
      "OthersPremium": 0.0,
      "PremiumAmount": _premiumResult?.premiumAmount ?? 0.0
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        Navigator.of(dialogContext).pop(); // Close dialog
        _showSnackBar(jsonResponse['message'] ?? "Application saved successfully!");
      } else {
        _showSnackBar("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  Future<void> _submitCalculation() async {
    if (_sumAssuredController.text.isNotEmpty) {
      await _calculatePremiumOnChange(_sumAssuredController.text);
    }

    if (!_formKey.currentState!.validate() || _premiumResult == null) {
      _showSnackBar('Please ensure all fields are selected and Sum Assured is valid.');
      return;
    }
    
    if (_premiumResult != null) {
        _showResultDialog();
    }
  }


  // --- Professional Result Modal (Unchanged) ---
  void _showResultDialog() {
    if (_premiumResult == null || _selectedPolicy == null || _selectedProfession == null) return;

    double rawSumAssured = double.tryParse(_sumAssuredController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    String sumAssuredText = NumberFormat.currency(locale: 'en_US', symbol: 'BDT', decimalDigits: 0).format(rawSumAssured);
    String premiumText = NumberFormat.currency(locale: 'en_US', symbol: 'BDT', decimalDigits: 0).format(_premiumResult!.premiumAmount); 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Card( 
          elevation: 8.0, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: kThemeColor, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Premium Calculation Result',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: kThemeColorSwatch.shade800
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 25, thickness: 2, color: kThemeColor),

                // Main Premium Result
                Column(
                  children: [
                    const Text(
                      'ESTIMATED ANNUAL PREMIUM',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      premiumText,
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.w900, 
                        color: kThemeColorSwatch.shade900
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
                
                // Detailed Summary (using ListTile for structure)
                _buildResultDetailTile(
                  title: 'Policy Plan', 
                  subtitle: '${_selectedPolicy!.planId} - ${_selectedPolicy!.planName}', 
                  icon: Icons.policy
                ),
                _buildResultDetailTile(
                  title: 'Sum Assured', 
                  subtitle: sumAssuredText, 
                  icon: Icons.attach_money,
                ),
                _buildResultDetailTile(
                  title: 'Policy Term', 
                  subtitle: '$_selectedTerm Years', 
                  icon: Icons.access_time
                ),
                _buildResultDetailTile(
                  title: 'Payment Mode', 
                  subtitle: _selectedInstallmentType!, 
                  icon: Icons.repeat
                ),
                _buildResultDetailTile(
                  title: 'Insured Details', 
                  subtitle: 'Age: $_calculatedAge | Profession: ${_selectedProfession!.profession}', 
                  icon: Icons.person
                ),

                const SizedBox(height: 20),

                // Apply Now Button
                if (widget.isFromPolicyAdvisor) ...[
                ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    setStateDialog(() => _isSaving = true);
                    await _savePolicyAdvisorData(context);
                    if (mounted) {
                      setStateDialog(() => _isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Apply Now', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                ],

                // Close Button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kThemeColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
        }
      ),
    );
  }

  // Helper function for result details
  Widget _buildResultDetailTile({required String title, required String subtitle, required IconData icon}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: kThemeColor, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }

  // --- 4. UI Building Methods 🎨 ---
  @override
  Widget build(BuildContext context) {
    final bool canSelectPolicy = _selectedProfession != null && _selectedProfession!.status != 'Decline' && _calculatedAge != null;
    final bool canEnableSumAssured = _selectedInstallmentType != null;
    
    final bool canSubmit = _selectedTerm != null && 
                            canSelectPolicy && 
                            _selectedInstallmentType != null &&
                            !_isLoading &&
                            _sumAssuredController.text.isNotEmpty; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Calculator'),
        backgroundColor: kThemeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0), // Consistent vertical padding
        // Main Card for a professional look (white background, shadow)
        child: Card( 
          color: Colors.white, 
          elevation: 6.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0), 
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. Basic Details
                  _buildDobInput(),
                  const SizedBox(height: 20), // Reduced spacing slightly
                  _buildGenderDropdown(isEnabled: _calculatedAge != null),
                  const SizedBox(height: 20),
                  _buildProfessionDropdown(isEnabled: _selectedGender != null && _supplementaryList.isNotEmpty),
                  const SizedBox(height: 30),

                  // 2. Policy Details
                  _buildPolicyDropdown(isEnabled: canSelectPolicy && _policyList.isNotEmpty),
                  const SizedBox(height: 20),
                  _buildTermDropdown(isEnabled: _selectedPolicy != null && _termList.isNotEmpty),
                  const SizedBox(height: 20),
                  _buildInstallmentTypeDropdown(isEnabled: _selectedTerm != null && _installmentTypeList.isNotEmpty),
                  const SizedBox(height: 30),
                  
                  // 3. Premium Input/Output
                  _buildSumAssuredInput(isEnabled: canEnableSumAssured),
                  const SizedBox(height: 20),
                  _buildPremiumOutput(),
                  const SizedBox(height: 30),
                  
                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.only(bottom: 15.0),
                      child: CircularProgressIndicator(color: kThemeColor),
                    )),
                  
                  ElevatedButton(
                    onPressed: canSubmit ? _submitCalculation : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kThemeColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 4, 
                    ),
                    child: const Text('Premium Calculator', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  
                  if (_premiumErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _premiumErrorMessage!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Input Field Builders (Refined for Professional Look) ---

  Widget _buildDobInput() {
    return Stack( 
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth (Required)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            // 🎯 Icon color set to kThemeColor for professional look
            suffixIcon: const Icon(Icons.calendar_today, color: kThemeColor), 
            helperText: _calculatedAge != null ? 'Calculated Age: **$_calculatedAge years**' : 'Select DOB to calculate age and fetch policies.',
            helperStyle: TextStyle(color: _calculatedAge != null ? kThemeColorSwatch.shade700 : kDisabledColor),
            // 🎯 Subtle fill color for professional look
            filled: true,
            fillColor: kInputFillColor,
          ),
          child: Text(
            _dob == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_dob!),
            style: TextStyle(
              color: _dob == null ? kDisabledColor : Colors.black,
              fontSize: 16,
            ),
          ),
        ),

        Positioned.fill(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dob ?? DateTime(2000),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: ColorScheme.light(
                        primary: kThemeColor, 
                        onPrimary: Colors.white, 
                        onSurface: Colors.black, 
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: kThemeColor, 
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != _dob) {
                _handleDOBSelection(picked);
              }
            },
            child: Container(color: Colors.transparent), 
          ),
        ),
      ],
    );
  }
  
  Widget _buildDropdown<T>({
    required bool isEnabled,
    required String labelText,
    required String hintText,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required String? Function(T?) validator,
    String? disabledMessage,
    String? extraHelperText,
  }) {
    final Color effectiveColor = isEnabled ? kThemeColor : kDisabledColor;
    final String actualHint = isEnabled ? hintText : (disabledMessage ?? 'Please complete the previous step');

    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: labelText,
        // 🎯 Apply subtle fill color
        filled: true,
        fillColor: kInputFillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: Icon(
          Icons.arrow_drop_down, 
          color: effectiveColor,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent), // Border blends with fill
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kThemeColor, width: 2), borderRadius: BorderRadius.circular(8)),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: kDisabledColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: TextStyle(color: effectiveColor),
        helperText: extraHelperText,
        helperStyle: TextStyle(color: kThemeColorSwatch.shade700),
      ),
      value: value,
      hint: Text(actualHint, style: TextStyle(color: effectiveColor)),
      items: isEnabled ? items : [], 
      onChanged: isEnabled ? onChanged : null,
      validator: isEnabled ? validator : (_) => null,
      isExpanded: true,
      menuMaxHeight: 300,
      iconEnabledColor: kThemeColor,
      iconDisabledColor: kDisabledColor,
    );
  }

  Widget _buildGenderDropdown({required bool isEnabled}) {
    return _buildDropdown<String>(
      isEnabled: isEnabled,
      labelText: 'Select Gender',
      hintText: 'Choose your gender (MALE/FEMALE)',
      value: _selectedGender,
      items: _genderOptions.map((gender) {
        return DropdownMenuItem<String>(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      onChanged: _handleGenderChange,
      validator: (value) => value == null ? 'Gender selection is required' : null,
    );
  }

  Widget _buildProfessionDropdown({required bool isEnabled}) {
    String? disabledMessage;
    if (_selectedGender == null) {
      disabledMessage = 'Please select Gender first.';
    } else if (_supplementaryList.isEmpty && _selectedGender != null && _calculatedAge != null && _isLoading == false) {
      disabledMessage = 'No professions loaded for selected gender/age.';
    } else if (_selectedProfession?.status == 'Decline') {
      disabledMessage = 'Selected profession is Declined.';
    } else if (_calculatedAge == null) {
      disabledMessage = 'Please select Date of Birth first.';
    }
    
    return _buildDropdown<SupplementaryData>(
      isEnabled: isEnabled,
      labelText: 'Select Profession',
      hintText: 'Choose your profession',
      value: _selectedProfession,
      items: _supplementaryList.map((data) {
        final style = TextStyle(
          color: data.status == 'Decline' ? Colors.red : Colors.black,
          fontWeight: data.status == 'Decline' ? FontWeight.bold : FontWeight.normal,
        );
        return DropdownMenuItem<SupplementaryData>(
          value: data,
          child: Text(
            '${data.profession}${data.status == 'Decline' ? ' (Declined)' : ''}', 
            style: style
          ),
        );
      }).toList(),
      onChanged: _handleProfessionChange, 
      validator: (value) {
        if (value == null) return 'Profession selection is required';
        if (value.status == 'Decline') return 'This profession is declined.';
        return null;
      },
      disabledMessage: disabledMessage,
    );
  }


  Widget _buildPolicyDropdown({required bool isEnabled}) {
    String? disabledMessage;
    if (_selectedProfession == null) {
      disabledMessage = 'Please select Profession first.';
    } else if (_selectedProfession?.status == 'Decline') {
      disabledMessage = 'Cannot select policy for a Declined profession.';
    } else if (_policyList.isEmpty && _calculatedAge != null && _selectedProfession != null && _isLoading == false) {
      disabledMessage = 'No policies found for age $_calculatedAge.';
    } else if (_calculatedAge == null) {
      disabledMessage = 'Please select Date of Birth first.';
    }
    
    return _buildDropdown<PolicyPlan>(
      isEnabled: isEnabled,
      labelText: 'Select Policy Plan',
      hintText: 'Choose an insurance plan',
      value: _selectedPolicy,
      items: _policyList.map((policy) {
        return DropdownMenuItem<PolicyPlan>(
          value: policy,
          child: Text('${policy.planId} - ${policy.planName} (${policy.projectName})'),
        );
      }).toList(),
      onChanged: _handlePolicyChange,
      validator: (value) => value == null ? 'Policy selection is required' : null,
      disabledMessage: disabledMessage,
    );
  }

  Widget _buildTermDropdown({required bool isEnabled}) {
    String? disabledMessage = _selectedPolicy == null ? 'Please select Policy first.' : 'No terms found for this policy.';
    return _buildDropdown<int>(
      isEnabled: isEnabled,
      labelText: 'Select Policy Term (Years)',
      hintText: 'Choose policy duration',
      value: _selectedTerm,
      items: _termList.map((term) {
        return DropdownMenuItem<int>(
          value: term.termOfYear,
          child: Text('${term.termOfYear} Years'),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedTerm = newValue;
          _premiumResult = null; 
          _premiumErrorMessage = null;
          _premiumAmountController.clear();
        });
        // Recalculate if all necessary fields are set
        if (newValue != null && _selectedInstallmentType != null && _sumAssuredController.text.isNotEmpty) {
          _calculatePremiumOnChange(_sumAssuredController.text);
        }
      },
      validator: (value) => value == null ? 'Term selection is required' : null,
      disabledMessage: disabledMessage,
    );
  }

  Widget _buildInstallmentTypeDropdown({required bool isEnabled}) {
    String? disabledMessage = _selectedTerm == null ? 'Please select Term first.' : 'No installment types found.';
    return _buildDropdown<String>(
      isEnabled: isEnabled,
      labelText: 'Select Installment Type',
      hintText: 'Choose payment frequency',
      value: _selectedInstallmentType,
      items: _installmentTypeList.map((type) {
        return DropdownMenuItem<String>(
          value: type.payMode,
          child: Text(type.payMode),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedInstallmentType = newValue;
          _premiumResult = null; 
          _premiumErrorMessage = null;
          _premiumAmountController.clear();
        });
        // Recalculate if sum assured is already entered
        if (newValue != null && _selectedTerm != null && _sumAssuredController.text.isNotEmpty) {
          _calculatePremiumOnChange(_sumAssuredController.text);
        }
      },
      validator: (value) => value == null ? 'Installment type is required' : null,
      disabledMessage: disabledMessage,
    );
  }

  // --- Sum Assured Input with Debounce Logic ---
  Widget _buildSumAssuredInput({required bool isEnabled}) {
    final Color effectiveColor = isEnabled ? kThemeColor : kDisabledColor;
    return TextFormField(
      controller: _sumAssuredController,
      enabled: isEnabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), 
      ],
      onChanged: (value) {
        // --- Debounce Logic for Automatic Calculation ---
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        
        // Clear previous results while typing
        _premiumAmountController.clear();
        _premiumResult = null;
        _premiumErrorMessage = null;
        setState(() {});

        // Only start the timer if the input is not empty and the field is enabled
        if (value.isNotEmpty && isEnabled) {
          // Wait 500ms after the last keystroke before calculating
          _debounce = Timer(const Duration(milliseconds: 500), () {
            _calculatePremiumOnChange(value);
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'Sum Assured (Required)',
        hintText: isEnabled ? 'e.g., 500000' : 'Select Installment Type first',
        labelStyle: TextStyle(color: effectiveColor),
        // 🎯 Apply subtle fill color
        filled: true,
        fillColor: kInputFillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.transparent), borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kThemeColor, width: 2), borderRadius: BorderRadius.circular(8)),
        disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: kDisabledColor.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
        prefixText: 'BDT ',
        prefixStyle: TextStyle(color: effectiveColor, fontWeight: FontWeight.bold),
      ),
      validator: (value) {
        if (!isEnabled) return null;
        if (value == null || value.isEmpty) {
          return 'Sum Assured is required.';
        }
        if (int.tryParse(value) == null || int.parse(value) <= 0) {
            return 'Please enter a valid amount (e.g., 100000).';
        }
        return null;
      },
    );
  }
  
  Widget _buildPremiumOutput() {
    // This field uses the primary theme color to clearly display the calculated result.
    return TextFormField(
      controller: _premiumAmountController,
      enabled: false, 
      decoration: InputDecoration(
        labelText: 'Estimated Total Premium (Result)',
        hintText: 'Enter Sum Assured to see result',
        labelStyle: const TextStyle(color: kThemeColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        // 🎯 Use kThemeColor border to highlight the result
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: kThemeColor.withOpacity(0.7), width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        // 🎯 Apply subtle fill color for professionalism
        filled: true,
        fillColor: kInputFillColor,
        prefixText: 'BDT ',
        prefixStyle: const TextStyle(color: kThemeColor, fontWeight: FontWeight.bold),
      ),
      style: TextStyle(color: kThemeColor, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}