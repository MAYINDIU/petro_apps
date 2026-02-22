import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// --- Constants ---
const String BASE_URL = 'https://nliapi.nextgenitltd.com/api';
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorDark = Color(0xFF1F2937);
const Color kThemeColor = Color.fromRGBO(19, 190, 190, 1);

// --- Models ---
class SecondYearRenewalBusinessMHResponseModel {
  final bool success;
  final String message;
  final List<dynamic> zone;
  final List<dynamic> data;

  SecondYearRenewalBusinessMHResponseModel({
    required this.success,
    required this.message,
    required this.zone,
    required this.data,
  });

  factory SecondYearRenewalBusinessMHResponseModel.fromJson(Map<String, dynamic> json) {
    return SecondYearRenewalBusinessMHResponseModel(
      success: json['success'] == true || json['success'] == 'true',
      message: json['message']?.toString() ?? '',
      zone: json['zone'] is List ? json['zone'] : [],
      data: json['data'] is List ? json['data'] : [],
    );
  }
}

class ZoneSecondYearRenewalBusinessMHResponseModel {
  final bool success;
  final String message;
  final List<dynamic> zone;
  final List<dynamic> data;

  ZoneSecondYearRenewalBusinessMHResponseModel({
    required this.success,
    required this.message,
    required this.zone,
    required this.data,
  });

  factory ZoneSecondYearRenewalBusinessMHResponseModel.fromJson(Map<String, dynamic> json) {
    return ZoneSecondYearRenewalBusinessMHResponseModel(
      success: json['success'] == true || json['success'] == 'true',
      message: json['message']?.toString() ?? '',
      zone: json['zone'] is List ? json['zone'] : [],
      data: json['data'] is List ? json['data'] : [],
    );
  }
}

// --- Service ---
class SecondYearRenewalService {
  Future<SecondYearRenewalBusinessMHResponseModel> getSecondYearRenewalBusinessResponse() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    
    try {
      var response = await http.get(
        Uri.parse("$BASE_URL/second-year-renewal"),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint("SecondYearRenewal Response: ${response.body}");
      
      if(response.statusCode == 200 || response.statusCode == 201){
        return SecondYearRenewalBusinessMHResponseModel.fromJson(jsonDecode(response.body));
      } else {
        return SecondYearRenewalBusinessMHResponseModel(success: false, message: "Server error: ${response.statusCode}", zone: [], data: []);
      }
    } catch (e) {
      return SecondYearRenewalBusinessMHResponseModel(success: false, message: "Network error: $e", zone: [], data: []);
    }
  }

  Future<ZoneSecondYearRenewalBusinessMHResponseModel> getZoneSecondYearRenewalBusinessResponse({required int zoneId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    
    try {
      var response = await http.get(
        Uri.parse("$BASE_URL/zone-second-year-renewal/$zoneId"),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint("ZoneSecondYearRenewal Response: ${response.body}");
      
      if(response.statusCode == 200 || response.statusCode == 201){
        return ZoneSecondYearRenewalBusinessMHResponseModel.fromJson(jsonDecode(response.body));
      } else {
        return ZoneSecondYearRenewalBusinessMHResponseModel(success: false, message: "Server error: ${response.statusCode}", zone: [], data: []);
      }
    } catch (e) {
      return ZoneSecondYearRenewalBusinessMHResponseModel(success: false, message: "Network error: $e", zone: [], data: []);
    }
  }
}

// --- Screen ---
class SecondYearBusinessForMHScreen extends StatefulWidget {
  const SecondYearBusinessForMHScreen({Key? key}) : super(key: key);

  @override
  State<SecondYearBusinessForMHScreen> createState() => _SecondYearBusinessForMHScreenState();
}

class _SecondYearBusinessForMHScreenState extends State<SecondYearBusinessForMHScreen> {
  final SecondYearRenewalService _service = SecondYearRenewalService();
  bool _isLoading = true;
  SecondYearRenewalBusinessMHResponseModel? _mainResponse;
  ZoneSecondYearRenewalBusinessMHResponseModel? _zoneResponse;
  String _errorMessage = '';
  String _designation = '';
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _designation = prefs.getString('designation') ?? '';
    });

    final response = await _service.getSecondYearRenewalBusinessResponse();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          _mainResponse = response;
        } else {
          _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to load data.';
        }
      });
    }
  }

  Future<void> _fetchZoneData(int zoneId) async {
    // Show loading indicator for zone part if needed, or just update state
    final response = await _service.getZoneSecondYearRenewalBusinessResponse(zoneId: zoneId);
    if (mounted) {
      setState(() {
        if (response.success) {
          _zoneResponse = response;
        } else {
          // Handle zone fetch error if needed
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('2nd Year Renewal Business (MH)'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryDarkBlue))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        // --- Main Data List ---
        if (_mainResponse != null && _mainResponse!.data.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _mainResponse!.data[index];
                return _buildExpandableCard(item, isZoneData: false);
              },
              childCount: _mainResponse!.data.length,
            ),
          )
        else
          SliverToBoxAdapter(
            child: Container(
              height: MediaQuery.of(context).size.height / 4,
              alignment: Alignment.center,
              child: const Text(
                "No data available",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kThemeColor,
                ),
              ),
            ),
          ),

        // --- Zone Dropdown ---
        if (_mainResponse != null && _mainResponse!.zone.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black87, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<dynamic>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  hint: const Text("Select a zone", style: TextStyle(color: Colors.black)),
                  items: _mainResponse!.zone.map((zone) {
                    return DropdownMenuItem<dynamic>(
                      value: zone,
                      child: Text(
                        "${zone['zone_name'] ?? zone['zb_name'] ?? zone['name'] ?? ''} - ${zone['zone_code'] ?? zone['zb_code'] ?? zone['code'] ?? ''}",
                        style: const TextStyle(color: Colors.black87, fontSize: 15),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      var code = value['zone_code'] ?? value['zb_code'] ?? value['code'];
                      _fetchZoneData(int.tryParse(code.toString()) ?? 0);
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ),
              ),
            ),
          ),

        // --- Zone Data List ---
        if (_zoneResponse != null && _zoneResponse!.data.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _zoneResponse!.data[index];
                return _buildExpandableCard(item, isZoneData: true);
              },
              childCount: _zoneResponse!.data.length,
            ),
          )
        else if (_zoneResponse != null && _zoneResponse!.data.isEmpty)
          SliverToBoxAdapter(
            child: Container(
              height: 100,
              alignment: Alignment.center,
              child: const Text(
                "No zone data available",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandableCard(dynamic item, {required bool isZoneData}) {
    String titleText = "";
    if (isZoneData) {
      titleText = "Zone Code and Name: ${item['zone_name'] ?? ''} - ${item['zone_code'] ?? ''}";
    } else {
      if (_designation == "AREA HEAD") {
        titleText = "Area Code and Name: ${item['area_name'] ?? ''} - ${item['area_code'] ?? ''}";
      } else if (_designation == "MONITOR HEAD") {
        titleText = "Monitoring Code and Name: ${item['monitor_name'] ?? ''} - ${item['monitor_code'] ?? ''}";
      } else {
        titleText = "Zone Code and Name: ${item['zone_name'] ?? ''} - ${item['zone_code'] ?? ''}";
      }
    }

    String processDate = item['process_date'] != null
        ? DateFormat("dd/MM/yyyy").format(DateTime.parse(item['process_date']))
        : "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ExpansionTile(
          shape: Border.all(color: Colors.transparent),
          collapsedShape: Border.all(color: Colors.transparent),
          title: RichText(
            text: TextSpan(
              text: "$titleText\n",
              style: const TextStyle(
                color: kPrimaryDarkBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: "Data Process Date : $processDate",
                  style: const TextStyle(
                    color: kPrimaryDarkBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                )
              ],
            ),
          ),
          children: [
            if (isZoneData)
              _textAndLabelContainer("Zone Code and Name", "${item['zone_name'] ?? ''} - ${item['zone_code'] ?? ''}")
            else if (_designation == "MONITOR HEAD")
              _textAndLabelContainer("Monitoring Code and Name", "${item['monitor_name'] ?? ''} - ${item['monitor_code'] ?? ''}")
            else
              _textAndLabelContainer("Area Code and Name", "${item['area_code'] ?? ''} - ${item['area_name'] ?? ''}"),
            
            _textAndLabelContainer("Risk Year", item['risk_year']?.toString()),
            _textAndLabelContainer("Data Process Date", processDate),
            _textAndLabelContainer("Project", item['project']?.toString() ?? item['project_name']?.toString()),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "By Policy Quantity",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kThemeColor,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Divider(color: kThemeColor, thickness: 1),
            ),
            _textAndLabelContainer("Total New Policy", item['prev_qty']?.toString()),
            _textAndLabelContainer("2nd Year Renewal Deposit", item['pre_qty']?.toString()),
            _textAndLabelContainer("Due Policy Qty", item['due_qty']?.toString()),
            _textAndLabelContainer("Renewal Collection %", item['qty_prc']?.toString()),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "By Policy Premium",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kThemeColor,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Divider(color: kThemeColor, thickness: 1),
            ),
            _textAndLabelContainer("Total New Policy Prem", item['prev_amt']?.toString()),
            _textAndLabelContainer("2nd Year Renewal Deposit", item['pre_amt']?.toString()),
            _textAndLabelContainer("Due Policy Premium", item['due_amt']?.toString()),
            _textAndLabelContainer("Renewal Premium Collection %", item['amt_prc']?.toString()),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _textAndLabelContainer(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black))),
          const Expanded(flex: 1, child: Text(":", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black))),
          Expanded(flex: 4, child: Text(value ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black))),
        ],
      ),
    );
  }
}