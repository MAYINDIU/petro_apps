import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:nli_apps/Screens/Agent/business_summary_screen.dart';

// --- Constants (re-used for consistency) ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorDark = Color(0xFF1F2937);

// Base URL for API calls
const String BASE_URL = 'https://nliapi.nextgenitltd.com/api';

// Currency Formatter
final _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);

// Placeholder for UserData.token
class AuthService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }
}

// --- Data Model ---
class AreaBusinessData {
  final String areaCode;
  final String areaName;
  double previousFR = 0.0;
  double previousRR = 0.0;
  double currentFR = 0.0;
  double currentRR = 0.0;

  AreaBusinessData({required this.areaCode, required this.areaName});
}

class AreaBusinessScreen extends StatefulWidget {
  const AreaBusinessScreen({Key? key}) : super(key: key);

  @override
  _AreaBusinessScreenState createState() => _AreaBusinessScreenState();
}

class _AreaBusinessScreenState extends State<AreaBusinessScreen> {
  List<AreaBusinessData> _areaData = [];
  double _totalPreviousFR = 0.0;
  double _totalPreviousRR = 0.0;
  double _totalCurrentFR = 0.0;
  double _totalCurrentRR = 0.0;

  bool isLoading = false;
  String dropdownvalue = "AKOK OFFICE";
  List<String> Office = ["AKOK OFFICE", "JANA OFFICE"];
  TextEditingController searchValue = TextEditingController();
  bool isCurrentYear = true;

  @override
  void initState() {
    super.initState();
    getResponseFormApi(office_type: "AKOK OFFICE", searchValue: "");
  }

  @override
  void dispose() {
    searchValue.dispose();
    super.dispose();
  }

  Future<void> getResponseFormApi({required String office_type, required String searchValue}) async {
    setState(() {
      isLoading = true;
      _areaData.clear();
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
      final uri = Uri.parse("$BASE_URL/area-business/?office_type=${office_type}");
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['branch'] is List) {
          List<dynamic> rawData = jsonResponse['branch'];

          var filteredData = rawData.where((element) {
            final areaName = element["area_name"]?.toString().toLowerCase() ?? '';
            return areaName.contains(this.searchValue.text.toLowerCase());
          }).toList();

          Map<String, AreaBusinessData> dataMap = {};

          for (var entry in filteredData) {
            final areaCode = entry['area_code']?.toString();
            if (areaCode == null) continue;

            dataMap.putIfAbsent(areaCode, () => AreaBusinessData(areaCode: areaCode, areaName: entry['area_name'] ?? 'N/A'));

            final item = dataMap[areaCode]!;
            final premium = double.tryParse(entry['premium_paid']?.toString() ?? '0.0') ?? 0.0;

            if (entry['year_category'] == 'CURRENT_YEAR') {
              if (entry['type'] == 'FR') item.currentFR += premium;
              if (entry['type'] == 'RR') item.currentRR += premium;
            } else if (entry['year_category'] == 'PREVIOUS_YEAR') {
              if (entry['type'] == 'FR') item.previousFR += premium;
              if (entry['type'] == 'RR') item.previousRR += premium;
            }
          }

          _areaData = dataMap.values.toList();
          // Sort by area name as per screen title
          _areaData.sort((a, b) => a.areaName.compareTo(b.areaName));

          // Calculate totals
          for (var item in _areaData) {
            _totalCurrentFR += item.currentFR;
            _totalCurrentRR += item.currentRR;
            _totalPreviousFR += item.previousFR;
            _totalPreviousRR += item.previousRR;
          }

        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(jsonResponse['message'] ?? 'Failed to load data.')),
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
    return WillPopScope(onWillPop: () async {
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
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BusinessSummaryScreen()));
            },
          ),
          title: const Text(
            "Area Business Yearly (By Area Name)",
            style: TextStyle(
              color: kTextColorLight,
              fontSize: 14,
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryDarkBlue))
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: kScaffoldBackground,
                    primary: false,
                    pinned: false,
                    floating: true,
                    collapsedHeight: MediaQuery.of(context).size.height / 4,
                    expandedHeight: MediaQuery.of(context).size.height / 4,
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
                                    await getResponseFormApi(
                                        office_type: newValue,
                                        searchValue: searchValue.text);
                                  }
                                },
                              ),
                              TextFormField(
                                controller: searchValue,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    hintText: "Search by area name",
                                    labelText: 'Search',
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.search,
                                          color: kPrimaryDarkBlue),
                                      onPressed: () async {
                                        await getResponseFormApi(
                                            office_type: dropdownvalue,
                                            searchValue: searchValue.text);
                                      },
                                    )),
                                onFieldSubmitted: (value) async {
                                  await getResponseFormApi(
                                      office_type: dropdownvalue,
                                      searchValue: value);
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
                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text('CURRENT YEAR'),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
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
                    expandedHeight: MediaQuery.of(context).size.height / 15,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          _buildHeaderCell("Code", width: 70),
                          Expanded(child: _buildHeaderCell("Name")),
                          _buildHeaderCell("First Yr", width: 90, isNumeric: true),
                          _buildHeaderCell("Ren Yr", width: 90, isNumeric: true),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final item = _areaData[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              _buildDataCell(item.areaCode, width: 70, isBold: true, isCenter: true),
                              Expanded(child: _buildDataCell(item.areaName, isCenter: true)),
                              _buildDataCell(_currencyFormatter.format(isCurrentYear ? item.currentFR : item.previousFR), width: 90, isNumeric: true),
                              _buildDataCell(_currencyFormatter.format(isCurrentYear ? item.currentRR : item.previousRR), width: 90, isNumeric: true),
                            ],
                          ),
                        );
                      },
                      childCount: _areaData.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 4,
                        color: const Color.fromARGB(255, 20, 57, 143),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 70), // Spacer for Code
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    "Total",
                                    style: TextStyle(
                                        color: kTextColorLight,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: Center(
                                  child: Text(
                                    isCurrentYear
                                        ? _currencyFormatter.format(_totalCurrentFR)
                                        : _currencyFormatter.format(_totalPreviousFR),
                                    style: const TextStyle(
                                        color: kTextColorLight,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: Center(
                                  child: Text(
                                    isCurrentYear
                                        ? _currencyFormatter.format(_totalCurrentRR)
                                        : _currencyFormatter.format(_totalPreviousRR),
                                    style: const TextStyle(
                                        color: kTextColorLight,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
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

  Widget _buildHeaderCell(String title, {double? width, bool isNumeric = false}) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: isNumeric ? Alignment.centerRight : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(color: kTextColorLight, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDataCell(String text, {double? width, bool isNumeric = false, bool isBold = false, bool isCenter = false}) {
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
}