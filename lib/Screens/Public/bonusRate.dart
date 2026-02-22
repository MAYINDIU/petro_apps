import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- 1. Data Models (FIXED) ---

class BonusYear {
  final String year;
  BonusYear({required this.year});

  factory BonusYear.fromJson(Map<String, dynamic> json) {
    return BonusYear(
      year: json['bonus_year'] as String,
    );
  }
}

class BonusRate {
  final String year;
  final String planId;
  final String term; 
  final String ratePerThousand;
  final String projectName;

  BonusRate({
    required this.year,
    required this.planId,
    required this.term, 
    required this.ratePerThousand,
    // 🧹 FIX: Removed the duplicate 'required' keyword here
    required this.projectName,
  });

  factory BonusRate.fromJson(Map<String, dynamic> json) {
    return BonusRate(
      year: json['bonus_year'] as String, 
      planId: json['plan_id'] as String? ?? 'N/A',
      term: json['premium_payment_term'] as String? ?? 'N/A', 
      ratePerThousand: json['bonus_rate_per_thousand'] as String? ?? '0',
      projectName: json['project_name'] as String? ?? 'N/A',
    );
  }
}

// --- 2. Main Widget ---

class BonusRatePage extends StatefulWidget {
  const BonusRatePage({super.key});

  @override
  State<BonusRatePage> createState() => _BonusRatePageState();
}

class _BonusRatePageState extends State<BonusRatePage> {
  static const String _baseUrl = 'https://nliuserapi.nextgenitltd.com/api';

  List<BonusYear> _availableYears = [];
  String? _selectedYear;
  List<BonusRate> _bonusRates = [];

  bool _isInitialLoading = true;
  bool _isRateLoading = false;
  String? _errorMessage;

  // Font Size 10.0 (XS) is used for maximum data density
  static const TextStyle _microTextStyle = TextStyle(fontSize: 10.0);
  static const TextStyle _microHeaderStyle = TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold);


  @override
  void initState() {
    super.initState();
    _fetchYears();
  }

// --- API Handlers ---

  Future<void> _fetchYears() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$_baseUrl/get-year'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
          _availableYears = (jsonResponse['data'] as List)
              .map((data) => BonusYear.fromJson(data))
              .toList();
          
          if (_availableYears.isNotEmpty) {
            _selectedYear = _availableYears.first.year;
            await _fetchBonusRates(_selectedYear!); 
          }
        } else {
          _errorMessage = 'Failed to parse years data.';
        }
      } else {
        _errorMessage = 'Failed to load years: Status ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _fetchBonusRates(String year) async {
    setState(() {
      _isRateLoading = true;
      _errorMessage = null;
      _bonusRates = [];
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/get-year-wise-bonous'),
        headers: {'Content-Type': 'application/json'},
        // Correct API key used
        body: jsonEncode({'year': year}), 
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
          _bonusRates = (jsonResponse['data'] as List)
              .map((data) => BonusRate.fromJson(data))
              .toList();
        } else {
          if (jsonResponse['data'] == null || (jsonResponse['data'] as List).isEmpty) {
             _errorMessage = null; 
          } else {
             _errorMessage = 'Failed to parse bonus rates.';
          }
        }
      } else {
        _errorMessage = 'Failed to load bonus rates: Status ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    } finally {
      setState(() {
        _isRateLoading = false;
      });
    }
  }

  // --- PDF Generation Handler (UNCHANGED) ---
  Future<void> _generatePdf(List<BonusRate> rates, String year) async {
    final pdf = pw.Document();

    final headers = ['Project', 'Plan ID', 'Term', 'Rate/1000'];
    final data = rates.map((rate) => [
      rate.projectName,
      rate.planId,
      rate.term, 
      rate.ratePerThousand,
    ]).toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Bonus Rates Report: $year',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0D47A1)),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                border: pw.TableBorder.all(color: PdfColors.grey500),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center, 
                  3: pw.Alignment.centerRight, 
                },
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(), 
      filename: 'Bonus_Rates_$year.pdf'
    );
  }

  // --- UI Builder Methods ---

  Widget _buildYearDropdown() {
    final bool isDisabled = _isInitialLoading || _errorMessage != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDisabled ? Colors.grey : Colors.blueAccent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          isExpanded: true,
          hint: const Text('Select Bonus Year'),
          icon: Icon(
            Icons.arrow_drop_down_circle_outlined, 
            color: isDisabled ? Colors.grey : Colors.blue
          ),
          style: const TextStyle(color: Colors.black, fontSize: 16),
          items: _availableYears.map((BonusYear year) {
            return DropdownMenuItem<String>(
              value: year.year,
              child: Text(year.year),
            );
          }).toList(),
          onChanged: isDisabled ? null : (String? newValue) {
            if (newValue != null && newValue != _selectedYear) {
              setState(() {
                _selectedYear = newValue;
              });
              _fetchBonusRates(newValue);
            }
          },
        ),
      ),
    );
  }

  // Font size is 10.0 for the DataTable
  Widget _buildBonusRateTable() {
    if (_bonusRates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No bonus rates found for year $_selectedYear.',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0), 
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, 
        child: DataTable(
          columnSpacing: 8, 
          dataRowHeight: 35, 
          headingRowColor: MaterialStateProperty.resolveWith((states) => const Color(0xFFE3F2FD)),
          border: TableBorder.all(color: Colors.grey.shade300, width: 1.0),
          
          // Columns use the micro font style
          columns: [
            DataColumn(label: Text('Project', style: _microHeaderStyle)),
            DataColumn(label: Text('Plan ID', style: _microHeaderStyle)),
            DataColumn(label: Text('Term', style: _microHeaderStyle)), 
            DataColumn(label: Text('Rate/1000', style: _microHeaderStyle.copyWith(color: Colors.green))),
          ],

          rows: _bonusRates.map((rate) {
            return DataRow(
              cells: [
                DataCell(
                  // Project Name (XS Font)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 60, maxWidth: 150), 
                    child: Text(rate.projectName, style: _microTextStyle.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
                DataCell(
                  // Plan ID (XS Font)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 70, maxWidth: 100),
                    child: Text(rate.planId, style: _microTextStyle),
                  ),
                ),
                DataCell( 
                  // Term (XS Font)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 70, maxWidth: 80),
                    child: Text(rate.term, style: _microTextStyle),
                  ),
                ),
                DataCell( 
                  // Rate (XS Font)
                  Text(
                    rate.ratePerThousand,
                    style: _microTextStyle.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                  )
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showFab = !_isInitialLoading && !_isRateLoading && _bonusRates.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bonus Rate'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Ensures the entire content scrolls vertically
      body: SingleChildScrollView( 
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dropdown Section
              _buildYearDropdown(),

              // Status/Loading/Results Section
              _isInitialLoading
                  ? const Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blueAccent),
                          SizedBox(height: 10),
                          Text('Loading available years...'),
                        ],
                      ),
                    )
                  : _errorMessage != null && _availableYears.isEmpty
                      ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)))
                      : _isRateLoading 
                          ? const Center(child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.blueAccent),
                                  SizedBox(height: 10),
                                  Text('Fetching bonus rates...'),
                                ],
                              ),
                            )
                          : _buildBonusRateTable(), 
            ],
          ),
        ),
      ),
      // Floating Action Button for PDF Export
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => _generatePdf(_bonusRates, _selectedYear!),
              label: const Text('Export to PDF'),
              icon: const Icon(Icons.picture_as_pdf),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}