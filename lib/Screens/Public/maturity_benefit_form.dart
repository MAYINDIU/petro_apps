import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ------------------------------------------------------------------
// 0. Constants and Formatters ⚙️
// ------------------------------------------------------------------

const String BASE_URL = 'https://nliuserapi.nextgenitltd.com/api'; 

// Taka currency formatters for English locale
final NumberFormat _takaCurrencyFormatter = NumberFormat.currency(
  symbol: '৳', 
  decimalDigits: 2, 
  locale: 'en_US' 
);
// Taka currency formatter for input display (without decimals)
final NumberFormat _takaInputFormatter = NumberFormat.currency(
  symbol: '৳', 
  decimalDigits: 0, 
  locale: 'en_US' 
);


// ------------------------------------------------------------------
// 1. Data Models 🏗️
// ------------------------------------------------------------------

class MaturityPlan {
  final String planId;
  final String planName;
  final String projectName;

  MaturityPlan({required this.planId, required this.planName, required this.projectName});
  factory MaturityPlan.fromJson(Map<String, dynamic> json) {
    return MaturityPlan(
      planId: json['plan_id'] as String? ?? '',
      planName: json['plan_name'] as String? ?? 'N/A',
      projectName: json['project_name'] as String? ?? 'N/A',
    );
  }
  @override
  // Display format for the dropdown selected value
  String toString() => '$planId - $planName'; 
}

class MaturityTerm {
  final String planId;
  final String termValue; 
  MaturityTerm({required this.planId, required this.termValue});
  factory MaturityTerm.fromJson(Map<String, dynamic> json) {
    return MaturityTerm(
      planId: json['plan_id'] as String? ?? '',
      termValue: json['term']?.toString() ?? '',
    );
  }
  @override
  String toString() => '$termValue Years'; 
}

class MaturityCalculationResult {
  final double survivalBenefit;
  final double maturityBenefit;
  final double maturityBonus;
  final double total;

  MaturityCalculationResult({
    required this.survivalBenefit,
    required this.maturityBenefit,
    required this.maturityBonus,
    required this.total,
  });

  factory MaturityCalculationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return MaturityCalculationResult(
      survivalBenefit: toDouble(data['survival_benefit']),
      maturityBenefit: toDouble(data['maturity_benefit']),
      maturityBonus: toDouble(data['maturity_Bonus']),
      total: toDouble(data['total']),
    );
  }
}

// ------------------------------------------------------------------
// 2. API Service 🌐
// ------------------------------------------------------------------

class MaturityBenefitService {
  final String _planApi = '$BASE_URL/maturity-plan';
  final String _termApiBase = '$BASE_URL/maturity-term';
  final String _calcApiBase = '$BASE_URL/maturity-bonous-calculate';

  Future<List<MaturityPlan>> fetchPlans() async {
    final response = await http.get(Uri.parse(_planApi));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
        return (jsonResponse['data'] as List)
            .map((item) => MaturityPlan.fromJson(item))
            .toList();
      }
      throw Exception('Invalid API response structure for plans.');
    } else {
      throw Exception('Failed to load plans: ${response.statusCode}');
    }
  }

  Future<List<MaturityTerm>> fetchTerms(String planId) async {
    final url = '$_termApiBase?plan_id=$planId'; 
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
        return (jsonResponse['data'] as List)
            .map((item) => MaturityTerm.fromJson(item))
            .toList();
      }
      throw Exception('Invalid API response structure for terms.');
    } else {
      throw Exception('Failed to load terms: ${response.statusCode}');
    }
  }

  Future<MaturityCalculationResult> calculateMaturityBenefit({
    required String planId,
    required String term,
    required int year,
    required double sumAssured,
  }) async {
    // API URL constructed with query parameters
    final url = '$_calcApiBase?plan_id=$planId&term=$term&year=$year&sum_assured=$sumAssured';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        return MaturityCalculationResult.fromJson(jsonResponse);
      }
      throw Exception('Calculation API returned success but no data for the provided parameters.');
    } else {
      throw Exception('Failed to calculate maturity benefit. Server responded with status code: ${response.statusCode}');
    }
  }
}

// ------------------------------------------------------------------
// 3. Main Form Widget 📱
// ------------------------------------------------------------------

class MaturityBenefitForm extends StatefulWidget {
  const MaturityBenefitForm({super.key});

  @override
  State<MaturityBenefitForm> createState() => _MaturityBenefitFormState();
}

class _MaturityBenefitFormState extends State<MaturityBenefitForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MaturityBenefitService _service = MaturityBenefitService();
  late Future<List<MaturityPlan>> _plansFuture;

  MaturityPlan? _selectedPlan;
  DateTime? _selectedDate; // Stores the selected Policy Commencement Year (Jan 1st of that year)
  MaturityTerm? _selectedTerm;
  
  final TextEditingController _sumAssuredController = TextEditingController();
  
  List<MaturityTerm> _termOptions = [];
  bool _isLoadingTerms = false;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _plansFuture = _service.fetchPlans();
  }
  
  @override
  void dispose() {
    _sumAssuredController.dispose();
    super.dispose();
  }
  
  void _onPlanSelected(MaturityPlan? newPlan) {
    // Check if a new plan was actually selected
    if (_selectedPlan?.planId != newPlan?.planId) {
      setState(() {
        _selectedPlan = newPlan;
        // Reset dependent fields
        _selectedDate = null;
        _termOptions = [];
        _selectedTerm = null;
      });
      if (newPlan != null) {
        _fetchTerms(newPlan.planId);
      }
    }
  }

  Future<void> _fetchTerms(String planId) async {
    setState(() {
      _isLoadingTerms = true;
      _termOptions = [];
    });
    
    try {
      final terms = await _service.fetchTerms(planId);
      setState(() {
        _termOptions = terms;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load terms. Please check the plan and your connection.')),
        );
      }
    } finally {
      setState(() {
        _isLoadingTerms = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(1950);
    // Allow selection up to 50 years from now
    final DateTime lastDate = now.add(const Duration(days: 365 * 50));
    // Determine the date to highlight in the picker: previously selected or system year
    final DateTime selected = _selectedDate ?? now;

    // Show the custom dialog containing the YearPicker
    final selectedYear = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Policy Year"),
          content: SizedBox(
            width: 300, 
            height: 300,
            child: YearPicker(
              firstDate: firstDate,
              lastDate: lastDate,
              // selectedDate is used to highlight the current/initial selection
              selectedDate: selected,
              onChanged: (DateTime dateTime) {
                // YearPicker returns Jan 1st of the selected year.
                Navigator.pop(context, dateTime.year); 
              },
            ),
          ),
        );
      },
    );

    if (selectedYear != null) {
      // Reconstruct the date as Jan 1st of the selected year for storage
      final DateTime newDate = DateTime(selectedYear, 1, 1);
      
      // Update state only if the year has changed
      if (newDate.year != _selectedDate?.year) {
        setState(() {
          _selectedDate = newDate;
        });
      }
    }
  }
  
  void _calculateMaturity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    final String planId = _selectedPlan!.planId;
    // Extract only the numeric term value (e.g., '10 Years' -> '10')
    final String term = _selectedTerm!.termValue; 
    final int year = _selectedDate!.year;
    final double sumAssured = double.tryParse(_sumAssuredController.text) ?? 0.0;
    
    MaturityCalculationResult? result;
    String errorMessage = '';

    try {
      result = await _service.calculateMaturityBenefit(
        planId: planId,
        term: term,
        year: year,
        sumAssured: sumAssured,
      );
    } catch (e) {
      // Clean up the exception message
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.isEmpty) {
        errorMessage = 'Unknown error occurred during calculation.';
      }
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }

    // Show result dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        
          content: Builder( 
            builder: (context) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: result != null 
                  ? _buildCalculationResultContent(result, sumAssured, year)
                  : _buildErrorContent(errorMessage),
              );
            }
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  // Helper widget to display calculation results
  Widget _buildCalculationResultContent(MaturityCalculationResult result, double sumAssured, int year) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // --- Policy Details ---
        const Text('Policy Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 15)),
        const Divider(height: 5, thickness: 1),
        _buildInfoRow('Plan:', _selectedPlan!.toString()),
        _buildInfoRow('Year:', year.toString()),
        _buildInfoRow('Term:', _selectedTerm!.toString()),
        _buildInfoRow('Sum Assured:', _takaInputFormatter.format(sumAssured)),
        const SizedBox(height: 15),

        // --- Individual Payouts (Clean List) ---
        const Text('Projected Payout Components', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15)),
        const Divider(height: 5, thickness: 1, color: Colors.black12),
        
        // Use fontSize 13 for smaller component details
        _buildResultRow('Survival Benefit:', _takaCurrencyFormatter.format(result.survivalBenefit), isBold: false, fontSize: 13),
        _buildResultRow('Maturity Benefit:', _takaCurrencyFormatter.format(result.maturityBenefit), isBold: false, fontSize: 13),
        _buildResultRow('Maturity Bonus:', _takaCurrencyFormatter.format(result.maturityBonus), isBold: true, fontSize: 13),

        const SizedBox(height: 20),

        // --- TOTAL Payout Section (Prominent Card/Container) ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 2, 90, 223), 
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL PAYOUT', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _takaCurrencyFormatter.format(result.total), 
                style: const TextStyle(
                  fontWeight: FontWeight.w900, 
                  color: Colors.white,
                  fontSize: 15, // Keep total large for prominence
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget for displaying input details with alignment
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  // Helper widget for displaying calculation results rows with alignment
  Widget _buildResultRow(String label, String value, {bool isBold = false, Color? valueColor, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isBold ? Colors.green.shade700 : Colors.black),
            fontSize: fontSize,
          )),
        ],
      ),
    );
  }

  // Helper widget for displaying error messages
  Widget _buildErrorContent(String errorMessage) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'We were unable to complete the calculation.',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 10),
          const Text('Please check the input values and ensure the selected Plan and Term are valid.', style: TextStyle(color: Colors.black87)),
          const SizedBox(height: 15),
          if (errorMessage.isNotEmpty)
            Card(
              color: Colors.red.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Error Detail: $errorMessage', style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
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
        title: const Text('Maturity Benefit Calculator'),
        elevation: 0,
        backgroundColor: const Color(0xFF0D47A1), // Deep Blue
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.blueGrey.shade50, 
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              // --- ALL INPUTS WRAPPED IN A SINGLE CARD ---
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildPlanDropdown(),
                      const SizedBox(height: 16),
                      _buildTermDropdown(),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                      const SizedBox(height: 16),
                      _buildSumAssuredInput(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // --- Calculate Button ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: (_selectedPlan != null && _selectedDate != null && _selectedTerm != null && !_isCalculating) 
                    ? _calculateMaturity 
                    : null,
                  icon: _isCalculating ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  ) : const Icon(Icons.calculate),
                  label: Text(_isCalculating ? 'Calculating...' : 'Calculate Maturity Benefit'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF0D47A1), // Deep Blue
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Input Decoration for consistency
  InputDecoration _getInputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }


  Widget _buildPlanDropdown() {
    return FutureBuilder<List<MaturityPlan>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Error loading plans. Please try again.', style: TextStyle(color: Colors.red));
        }
        final plans = snapshot.data!;
        
        return DropdownButtonFormField<MaturityPlan>(
          decoration: _getInputDecoration('Select Policy Plan'),
          value: _selectedPlan,
          items: plans.map((plan) {
            return DropdownMenuItem(
              value: plan, 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  '${plan.planId} - ${plan.planName}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            );
          }).toList(),
          onChanged: _onPlanSelected,
          validator: (value) => value == null ? 'Please select a plan' : null,
          isExpanded: true,
        );
      },
    );
  }

 
  Widget _buildTermDropdown() {
    if (_isLoadingTerms) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final bool isEnabled = _selectedPlan != null && _termOptions.isNotEmpty;

    return DropdownButtonFormField<MaturityTerm>(
      decoration: _getInputDecoration('Select Policy Term (Years)'),
      value: _selectedTerm,
      items: isEnabled 
          ? _termOptions.map((term) {
              return DropdownMenuItem(
                value: term,
                child: Text(term.toString()),
              );
            }).toList()
          : null,
      
      onChanged: isEnabled ? (term) => setState(() => _selectedTerm = term) : null,
      validator: (value) => value == null ? 'Please select a term' : null,
      isExpanded: true,
      disabledHint: const Text('Select a Plan first'), 
    );
  }
  
   Widget _buildDatePicker() {
    final String dateText = _selectedDate == null 
        ? 'Select Policy Year (YYYY)' 
        : DateFormat('yyyy').format(_selectedDate!);
    
    return InkWell(
      onTap: () {
        // Only allow date picking if a term is selected
        if (_selectedTerm != null) {
          _selectDate(context);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a Plan and Term first.')),
          );
        }
      },
      child: InputDecorator(
        decoration: _getInputDecoration(
          'Policy Commencement Year', 
          suffixIcon: const Icon(Icons.calendar_today)
        ).copyWith(
          errorText: (_selectedDate == null && _formKey.currentState?.validate() == true) 
            ? 'Please select the year' 
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            // Highlight border if term is selected but year is missing
            borderSide: BorderSide(
              color: (_selectedTerm != null && _selectedDate == null) ? Colors.red : Colors.grey
            )
          )
        ),
        child: Text(
          dateText,
          style: TextStyle(
            color: _selectedDate == null ? Colors.grey[700] : Colors.black,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSumAssuredInput() {
    return TextFormField(
      controller: _sumAssuredController,
      decoration: _getInputDecoration(
        'Sum Assured Amount (৳)', 
      ).copyWith(
        hintText: 'e.g., 50000',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the Sum Assured';
        }
        // Use a simple integer/double check instead of complex formatting logic for validation
        if (double.tryParse(value) == null || double.parse(value) <= 0) {
          return 'Please enter a valid positive number';
        }
        return null;
      },
    );
  }
}

// ------------------------------------------------------------------
// 4. Main Entry Point 🚀
// ------------------------------------------------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maturity Benefit Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MaturityBenefitForm(),
    );
  }
}