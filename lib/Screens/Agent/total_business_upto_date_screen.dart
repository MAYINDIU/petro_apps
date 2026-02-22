import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nli_apps/Screens/Agent/business_summary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Constants (re-used for consistency) ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorDark = Color(0xFF1F2937);

// Base URL for API calls
const String BASE_URL = 'https://nliapi.nextgenitltd.com/api';

// Currency Formatter
final _currencyFormatter =
    NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);

// Placeholder for UserData.token
class AuthService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }
}

// --- Data Model ---
class TotalBusinessYearlyData {
  final String project;
  double previousFR = 0.0;
  double previousRR = 0.0;
  double currentFR = 0.0;
  double currentRR = 0.0;

  TotalBusinessYearlyData({required this.project});

  // Safely calculate FR growth
  double get frGrowth {
    if (previousFR == 0.0) {
      return currentFR > 0.0 ? 100.0 : 0.0; // Avoid division by zero
    }
    return ((currentFR - previousFR) / previousFR) * 100;
  }

  // Safely calculate RR growth
  double get rrGrowth {
    if (previousRR == 0.0) {
      return currentRR > 0.0 ? 100.0 : 0.0; // Avoid division by zero
    }
    return ((currentRR - previousRR) / previousRR) * 100;
  }
}

class TotalBusinessUptodateScreen extends StatefulWidget {
  const TotalBusinessUptodateScreen({super.key});

  @override
  State<TotalBusinessUptodateScreen> createState() =>
      _TotalBusinessUptodateScreenState();
}

class _TotalBusinessUptodateScreenState
    extends State<TotalBusinessUptodateScreen> {
  List<TotalBusinessYearlyData> _businessData = [];
  double _totalPreviousFR = 0.0;
  double _totalPreviousRR = 0.0;
  double _totalCurrentFR = 0.0;
  double _totalCurrentRR = 0.0;

  bool isLoading = false;
  String dropdownvalue = "COMPANY TOTAL";
  List<String> Office = ["COMPANY TOTAL", "AKOK OFFICE", "JANA OFFICE"];
  bool isCurrentYear = true;

  @override
  void initState() {
    super.initState();
    getResponseFormApi(type: "TOTAL");
  }

  Future<void> getResponseFormApi({required String type}) async {
    setState(() {
      isLoading = true;
      _businessData.clear();
      _totalPreviousFR = 0.0;
      _totalPreviousRR = 0.0;
      _totalCurrentFR = 0.0;
      _totalCurrentRR = 0.0;
    });

    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found.')),
        );
      }
      setState(() => isLoading = false);
      return;
    }

    try {
      final uri = Uri.parse("$BASE_URL/update-total-business/?type=${type}");
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['branch'] is List) {
          List<dynamic> rawData = jsonResponse['branch'];

          Map<String, TotalBusinessYearlyData> dataMap = {};

          for (var entry in rawData) {
            final project = entry['project']?.toString();
            if (project == null) continue;

            dataMap.putIfAbsent(
                project, () => TotalBusinessYearlyData(project: project));

            final item = dataMap[project]!;
            final premium =
                double.tryParse(entry['premium_paid']?.toString() ?? '0.0') ??
                    0.0;

            if (entry['year_category'] == 'CURRENT_YEAR') {
              if (entry['type'] == 'FR') item.currentFR += premium;
              if (entry['type'] == 'RR') item.currentRR += premium;
            } else if (entry['year_category'] == 'PREVIOUS_YEAR') {
              if (entry['type'] == 'FR') item.previousFR += premium;
              if (entry['type'] == 'RR') item.previousRR += premium;
            }
          }

          _businessData = dataMap.values.toList();
          _businessData.sort((a, b) => a.project.compareTo(b.project));

          // Calculate totals
          for (var item in _businessData) {
            _totalCurrentFR += item.currentFR;
            _totalCurrentRR += item.currentRR;
            _totalPreviousFR += item.previousFR;
            _totalPreviousRR += item.previousRR;
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(jsonResponse['message'] ?? 'Failed to load data.')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return true;
      },
      child: Scaffold(
        backgroundColor: kScaffoldBackground,
        appBar: AppBar(
          backgroundColor: kPrimaryDarkBlue,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: kTextColorLight,
            iconSize: 20,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            "Total Business Upto Date",
            style: TextStyle(
              color: kTextColorLight,
              fontSize: 16,
            ),
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryDarkBlue))
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: kScaffoldBackground,
                    primary: false,
                    pinned: false,
                    floating: true,
                    collapsedHeight: MediaQuery.of(context).size.height / 5,
                    expandedHeight: MediaQuery.of(context).size.height / 5,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Office Type',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                value: dropdownvalue,
                                items: Office.map((String items) {
                                  return DropdownMenuItem(
                                    value: items,
                                    child: Text(items),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) async {
                                  if (newValue != null) {
                                    setState(() => dropdownvalue = newValue);
                                    if (newValue == "COMPANY TOTAL") {
                                      await getResponseFormApi(type: "TOTAL");
                                    } else if (newValue == "AKOK OFFICE") {
                                      await getResponseFormApi(type: "AKOK");
                                    } else if (newValue == "JANA OFFICE") {
                                      await getResponseFormApi(type: "JANA");
                                    }
                                  }
                                },
                              ),
                              ToggleButtons(
                                isSelected: [isCurrentYear, !isCurrentYear],
                                onPressed: (int index) {
                                  setState(() => isCurrentYear = index == 0);
                                },
                                borderRadius: BorderRadius.circular(8),
                                selectedColor: kTextColorLight,
                                color: kPrimaryDarkBlue,
                                fillColor: kPrimaryDarkBlue,
                                selectedBorderColor: kPrimaryDarkBlue,
                                borderColor: kPrimaryDarkBlue,
                                children: const [
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text('CURRENT YEAR'),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text('PREVIOUS YEAR'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    primary: true,
                    backgroundColor: kPrimaryDarkBlue,
                    automaticallyImplyLeading: false,
                    expandedHeight: 60,
                    flexibleSpace: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _buildHeaderCell("Project", width: 80, height: 60),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildHeaderCell("Premium", height: 30),
                                    Row(
                                      children: [
                                        Expanded(child: _buildHeaderCell("1st Year", height: 30, fontSize: 10)),
                                        Expanded(child: _buildHeaderCell("Renewal", height: 30, fontSize: 10)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildHeaderCell("Growth %", height: 30, fontSize: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _buildHeaderCell("1st Year", height: 30, fontSize: 10)),
                                        Expanded(child: _buildHeaderCell("Renewal", height: 30, fontSize: 10)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final item = _businessData[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              _buildDataCell(item.project, width: 80, isBold: true),
                              Expanded(
                                child: _buildDataCell(
                                    _currencyFormatter.format(isCurrentYear ? item.currentFR : item.previousFR),
                                    isNumeric: true),
                              ),
                              Expanded(
                                child: _buildDataCell(
                                    _currencyFormatter.format(isCurrentYear ? item.currentRR : item.previousRR),
                                    isNumeric: true),
                              ),
                              Expanded(
                                child: _buildDataCell(
                                  isCurrentYear ? '${item.frGrowth.toStringAsFixed(0)}%' : '0%',
                                  isNumeric: true,
                                ),
                              ),
                              Expanded(
                                child: _buildDataCell(
                                  isCurrentYear ? '${item.rrGrowth.toStringAsFixed(0)}%' : '0%',
                                  isNumeric: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: _businessData.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 4,
                        color: const Color.fromRGBO(24, 200, 45, .8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                alignment: Alignment.center,
                                child: const Text(
                                  "Total",
                                  style: TextStyle(
                                      color: kTextColorLight,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: _buildTotalCell(isCurrentYear
                                    ? _totalCurrentFR
                                    : _totalPreviousFR),
                              ),
                              Expanded(
                                child: _buildTotalCell(isCurrentYear
                                    ? _totalCurrentRR
                                    : _totalPreviousRR),
                              ),
                              Expanded(
                                child: _buildTotalCell(
                                    isCurrentYear
                                        ? ((_totalCurrentFR - _totalPreviousFR) /
                                                _totalPreviousFR) *
                                            100
                                        : 0,
                                    isPercentage: true),
                              ),
                              Expanded(
                                child: _buildTotalCell(
                                    isCurrentYear
                                        ? ((_totalCurrentRR - _totalPreviousRR) /
                                                _totalPreviousRR) *
                                            100
                                        : 0,
                                    isPercentage: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderCell(String title,
      {double? width, double? height, bool isNumeric = false, double fontSize = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: kTextColorLight, width: 0.5),
      ),
      alignment: isNumeric ? Alignment.centerRight : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
            color: kTextColorLight,
            fontWeight: FontWeight.bold,
            fontSize: fontSize),
      ),
    );
  }

  Widget _buildDataCell(String text,
      {double? width,
      bool isNumeric = false,
      bool isBold = false,
      bool isCenter = false}) {
    return Container(
      width: width,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      alignment: isNumeric
          ? Alignment.centerRight
          : (isCenter ? Alignment.center : Alignment.centerLeft),
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : null,
        style: TextStyle(
          color: kTextColorDark,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildTotalCell(double value, {bool isPercentage = false}) {
    String text;
    if (isPercentage) {
      if (value.isInfinite || value.isNaN) {
        text = '0%';
      } else {
        text = '${value.toStringAsFixed(0)}%';
      }
    } else {
      text = _currencyFormatter.format(value);
    }

    return Container(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(
            color: kTextColorLight, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}