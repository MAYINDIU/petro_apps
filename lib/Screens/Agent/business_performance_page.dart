import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Constants ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorDark = Color(0xFF1F2937);

// --- Currency Formatter ---
final _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '৳', decimalDigits: 0);

// Represents a single member in a team list (FA, UM, BM, etc.)
class TeamMember {
  final String empId;
  final String empName;
  final String? mobile;
  final String designation;

  TeamMember({
    required this.empId,
    required this.empName,
    this.mobile,
    required this.designation,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      empId: json['emp_id'] as String? ?? 'N/A',
      empName: (json['emp_name'] as String? ?? 'Unknown').trim(),
      mobile: json['mobile'] as String?,
      designation: json['designation'] as String? ?? 'N/A',
    );
  }
}

// --- 1. Data Models ---
class BusinessDetails {
  final String faName;
  final String umName;
  final String bmName;
  final String dcName;
  final String branchName;
  final String zoneName;
  final String areaName;
  final String umCode;
  final String bmCode;
  final String dcCode;
  final String branchCode;
  final String zoneCode;
  final String areaCode;

  BusinessDetails({
    required this.faName,
    required this.umName,
    required this.bmName,
    required this.dcName,
    required this.branchName,
    required this.zoneName,
    required this.areaName,
    required this.umCode,
    required this.bmCode,
    required this.dcCode,
    required this.branchCode,
    required this.zoneCode,
    required this.areaCode,
  });

  factory BusinessDetails.fromJson(Map<String, dynamic> json) {
    return BusinessDetails(
      faName: json['fa_name'] ?? 'N/A',
      umName: json['um_name'] ?? 'N/A',
      bmName: json['bm_name'] ?? 'N/A',
      dcName: json['dc_name'] ?? 'N/A',
      branchName: json['branch_name'] ?? 'N/A',
      zoneName: json['zone_name'] ?? 'N/A', 
      areaName: json['area_name'] ?? 'N/A',
      umCode: json['um'] ?? 'N/A', 
      bmCode: json['bm'] ?? 'N/A',
      dcCode: json['dc'] ?? 'N/A',
      branchCode: json['br_code'] ?? json['branch'] ?? 'N/A',
      zoneCode: json['zone_code'] ?? json['zone'] ?? 'N/A',
      areaCode: json['area_code'] ?? 'N/A',
    );
  }
}

class BusinessEntry {
  final String year;
  final String project;
  final String type;
  final String numberOfPolicy;
  final String totalPremium;
  final String yearCategory;

  BusinessEntry({
    required this.year,
    required this.project,
    required this.type,
    required this.numberOfPolicy,
    required this.totalPremium,
    required this.yearCategory,
  });

  factory BusinessEntry.fromJson(Map<String, dynamic> json) {
    return BusinessEntry(
      year: json['year'] ?? 'N/A',
      project: json['project'] ?? 'N/A',
      type: json['type'] ?? 'N/A',
      numberOfPolicy: json['number_of_policy'] ?? '0',
      totalPremium: json['total_premium_paid_in_lacs'] ?? '0',
      yearCategory: json['year_category'] ?? 'N/A',
    );
  }
}

class BusinessApiResponse {
  final BusinessDetails details;
  final String empName;
  final String empId;
  final String designation;
  final List<BusinessEntry> business;
  final List<TeamMember> faList;
  final List<TeamMember> umList;
  final List<TeamMember> bmList;
  final List<TeamMember> dcList;

  BusinessApiResponse({
    required this.details,
    required this.empName,
    required this.empId,
    required this.designation,
    required this.business,
    required this.faList,
    required this.umList,
    required this.bmList,
    required this.dcList,
  });

  factory BusinessApiResponse.fromJson(Map<String, dynamic> json) {
    List<TeamMember> parseTeamList(Map<String, dynamic> teamsJson, String key) {
      if (teamsJson.containsKey(key) && teamsJson[key] is List) {
        return (teamsJson[key] as List)
            .map((item) => TeamMember.fromJson(item))
            .toList();
      }
      return [];
    }

    final teamsData = json['teams'] as Map<String, dynamic>? ?? {};

    // The 'business' key might not exist in this new structure. Handle it gracefully.
    List<dynamic> businessData = [];
    if (json.containsKey('business') && json['business'] is List) {
      businessData = json['business'] as List;
    } else if (json.containsKey('details') && json['details'] is Map && (json['details'] as Map).containsKey('business') && json['details']['business'] is List) {
      // Fallback for a nested structure if needed, based on observation.
      businessData = json['details']['business'] as List;
    }
    var businessList = businessData
        .map((i) => BusinessEntry.fromJson(i))
        .toList();

    return BusinessApiResponse(
      details: BusinessDetails.fromJson(json['details'] ?? {}),
      empName: json['emp_name'] ?? 'N/A',
      empId: json['emp_id'] ?? 'N/A',
      designation: json['designation'] ?? 'N/A',
      business: businessList,
      faList: parseTeamList(teamsData, 'falist'),
      umList: parseTeamList(teamsData, 'umlist'),
      bmList: parseTeamList(teamsData, 'bmlist'),
      dcList: parseTeamList(teamsData, 'dclist'),
    );
  }
}

// --- 2. API Service ---
class BusinessApiService {
  static const String _apiUrl = "https://nliapi.nextgenitltd.com/api/agent-business";

  Future<BusinessApiResponse> fetchBusinessData(String empId, String designation) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final isBranchOrZone = (designation.toUpperCase() == 'BRANCH' || designation.toUpperCase() == 'ZONE');

    final queryParams = {
      "emp_id": empId,
      "designation": designation,
      "isBranch": isBranchOrZone ? '1' : '0',
    };

    final uri = Uri.https("nliapi.nextgenitltd.com", "/api/agent-business", queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('Received an empty response from the server.');
      }
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      if (jsonResponse['success'] == true) {
        return BusinessApiResponse.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to load business data.');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}

// --- 3. UI Widget ---
class BusinessPerformancePage extends StatefulWidget {
  final String empId;
  final String designation;
  final String empName;

  const BusinessPerformancePage({
    super.key,
    required this.empId,
    required this.designation,
    required this.empName,
  });

  @override
  State<BusinessPerformancePage> createState() => _BusinessPerformancePageState();
}

class _BusinessPerformancePageState extends State<BusinessPerformancePage> with SingleTickerProviderStateMixin {
  late Future<BusinessApiResponse> _businessDataFuture;
  final BusinessApiService _apiService = BusinessApiService();

  // State variables for calculated performance metrics
  double _totalCurrentFR = 0;
  double _totalCurrentRR = 0;
  double _totalPreviousFR = 0;
  double _totalPreviousRR = 0;
  double _growthFR = 0;
  double _growthRR = 0;
  bool _canCalculateGrowth = false;

  // New state variables for project-specific metrics
  List<String> _uniqueProjects = [];
  Map<String, double> _projectCurrentFR = {};
  Map<String, double> _projectCurrentRR = {};
  Map<String, double> _projectPreviousFR = {};
  Map<String, double> _projectPreviousRR = {};
  Map<String, double> _projectGrowthFR = {};
  Map<String, double> _projectGrowthRR = {};

  @override
  void initState() {
    super.initState();
    _businessDataFuture = _apiService.fetchBusinessData(widget.empId, widget.designation);
    _businessDataFuture.then((data) {
      if (mounted) {
        _calculatePerformanceMetrics(data.business);
      }
    });
  }

  void _calculatePerformanceMetrics(List<BusinessEntry> businessList) {
    // --- Overall Totals ---
    double totalCurrentFR = 0;
    double totalCurrentRR = 0;
    double totalPreviousFR = 0;
    double totalPreviousRR = 0;

    // --- Project-Specific Metrics ---
    final uniqueProjects = businessList.map((e) => e.project).toSet().toList();
    Map<String, double> projectCurrentFR = {};
    Map<String, double> projectCurrentRR = {};
    Map<String, double> projectPreviousFR = {};
    Map<String, double> projectPreviousRR = {};
    Map<String, double> projectGrowthFR = {};
    Map<String, double> projectGrowthRR = {};

    for (var project in uniqueProjects) {
      double pCurrentFR = 0, pCurrentRR = 0, pPreviousFR = 0, pPreviousRR = 0;

      for (var entry in businessList) {
        if (entry.project == project) {
          double premium = double.tryParse(entry.totalPremium) ?? 0.0;
          if (entry.yearCategory == 'CURRENT_YEAR') {
            if (entry.type == 'FR') pCurrentFR += premium;
            if (entry.type == 'RR') pCurrentRR += premium;
          } else if (entry.yearCategory == 'PREVIOUS_YEAR') {
            if (entry.type == 'FR') pPreviousFR += premium;
            if (entry.type == 'RR') pPreviousRR += premium;
          }
        }
      }

      // Store project-specific sums
      projectCurrentFR[project] = pCurrentFR;
      projectCurrentRR[project] = pCurrentRR;
      projectPreviousFR[project] = pPreviousFR;
      projectPreviousRR[project] = pPreviousRR;

      // Calculate and store project-specific growth
      if (pPreviousFR > 0) projectGrowthFR[project] = ((pCurrentFR - pPreviousFR) / pPreviousFR) * 100;
      if (pPreviousRR > 0) projectGrowthRR[project] = ((pCurrentRR - pPreviousRR) / pPreviousRR) * 100;

      // Add to overall totals
      totalCurrentFR += pCurrentFR;
      totalCurrentRR += pCurrentRR;
      totalPreviousFR += pPreviousFR;
      totalPreviousRR += pPreviousRR;
    }

    setState(() {
      // Set overall state
      _totalCurrentFR = totalCurrentFR;
      _totalCurrentRR = totalCurrentRR;
      _totalPreviousFR = totalPreviousFR;
      _totalPreviousRR = totalPreviousRR;
      _canCalculateGrowth = totalPreviousFR > 0 || totalPreviousRR > 0;
      if (totalPreviousFR > 0) _growthFR = ((totalCurrentFR - totalPreviousFR) / totalPreviousFR) * 100;
      if (totalPreviousRR > 0) _growthRR = ((totalCurrentRR - totalPreviousRR) / totalPreviousRR) * 100;

      // Set project-specific state
      _uniqueProjects = uniqueProjects;
      _projectCurrentFR = projectCurrentFR;
      _projectCurrentRR = projectCurrentRR;
      _projectPreviousFR = projectPreviousFR;
      _projectPreviousRR = projectPreviousRR;
      _projectGrowthFR = projectGrowthFR;
      _projectGrowthRR = projectGrowthRR;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.empName),
            Text(
              'Business Performance',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
      body: FutureBuilder<BusinessApiResponse>(
        future: _businessDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryDarkBlue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No business data found.'));
          }

          final data = snapshot.data!;
          final currentYearBusiness = data.business.where((b) => b.yearCategory == 'CURRENT_YEAR').toList();
          final previousYearBusiness = data.business.where((b) => b.yearCategory == 'PREVIOUS_YEAR').toList();
          final hasTeamData = data.faList.isNotEmpty || data.umList.isNotEmpty || data.bmList.isNotEmpty || data.dcList.isNotEmpty;
          final hasBusinessData = currentYearBusiness.isNotEmpty || previousYearBusiness.isNotEmpty;

          // Determine the number of tabs needed
          final tabCount = (hasBusinessData ? 1 : 0) + (hasTeamData ? 1 : 0);

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
                child: _buildHierarchyCard(data),
              ),
              _buildPerformanceSummaryCard(),
              if (_uniqueProjects.isNotEmpty) _buildProjectDetailsCard(),              
              if (tabCount > 0)
                DefaultTabController(
                  length: tabCount,
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: kPrimaryDarkBlue,
                        labelColor: kPrimaryDarkBlue,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          if (hasBusinessData) const Tab(text: 'BUSINESS DETAILS'),
                          if (hasTeamData) const Tab(text: 'TEAM MEMBERS'),
                        ],
                      ),
                      SizedBox(
                        // Adjust height dynamically or use a more flexible layout
                        height: 600, 
                        child: TabBarView(
                          children: [
                            if (hasBusinessData)
                              DefaultTabController(
                                length: 2,
                                child: Column(
                                  children: [
                                     const TabBar(
                                      indicatorColor: kAccentBlue,
                                      labelColor: kAccentBlue,
                                      unselectedLabelColor: Colors.grey,
                                      tabs: [
                                        Tab(text: 'CURRENT YEAR'),
                                        Tab(text: 'PREVIOUS YEAR'),
                                      ],
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        children: [
                                          _buildBusinessDataTable(currentYearBusiness),
                                          _buildBusinessDataTable(previousYearBusiness),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (hasTeamData)
                              ListView(
                                children: [
                                  _buildTeamExpansionTile('Financial Associates (FA)', data.faList),
                                  _buildTeamExpansionTile('Unit Managers (UM)', data.umList),
                                  _buildTeamExpansionTile('Branch Managers (BM)', data.bmList),
                                  _buildTeamExpansionTile('Development Chiefs (DC)', data.dcList),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHierarchyCard(BusinessApiResponse data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             // Agent's own info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: kPrimaryDarkBlue.withOpacity(0.1),
                  child: Text(
                    data.empName.isNotEmpty ? data.empName[0] : 'A',
                    style: const TextStyle(fontSize: 22, color: kPrimaryDarkBlue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.empName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
                    const SizedBox(height: 2),
                    Text('ID: ${data.empId} | ${data.designation}', style: const TextStyle(fontSize: 13, color: kTextColorDark)),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            _buildHierarchySection(data),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchySection(BusinessApiResponse data) {
    final details = data.details;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hierarchy & Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
        const SizedBox(height: 8),
        _buildHierarchyRow('Area', details.areaName, details.areaCode),
        _buildHierarchyRow('Zone', details.zoneName, details.zoneCode),
        _buildHierarchyRow('Branch', details.branchName, details.branchCode),
        const SizedBox(height: 8),
        _buildHierarchyRow('DC', details.dcName, details.dcCode),
        _buildHierarchyRow('BM', details.bmName, details.bmCode),
        _buildHierarchyRow('UM', details.umName, details.umCode),
        if (data.designation == 'FA')
          _buildHierarchyRow('FA', details.faName, data.empId),
      ],
    );
  }

  Widget _buildHierarchyRow(String title, String name, String code) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$title:', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Flexible(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
          const SizedBox(width: 4),
          if (code.isNotEmpty && code != 'N/A')
            Text('[$code]', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummaryCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
            const Divider(height: 20),
            _buildPerformanceDetailRow(isHeader: true),
            const Divider(height: 1),
            _buildPerformanceDetailRow(title: 'First Year (FR)', currentValue: _totalCurrentFR, previousValue: _totalPreviousFR, growthValue: _growthFR),
            _buildPerformanceDetailRow(title: 'Renewal (RR)', currentValue: _totalCurrentRR, previousValue: _totalPreviousRR, growthValue: _growthRR),
            const Divider(height: 1),
            _buildPerformanceDetailRow(isTotal: true, title: 'Total', currentValue: _totalCurrentFR + _totalCurrentRR, previousValue: _totalPreviousFR + _totalPreviousRR,
            growthValue: _totalPreviousFR + _totalPreviousRR > 0 ? (((_totalCurrentFR + _totalCurrentRR) - (_totalPreviousFR + _totalPreviousRR)) / (_totalPreviousFR + _totalPreviousRR)) * 100 : 0
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceDetailRow({
    bool isHeader = false,
    bool isTotal = false,
    String title = '',
    double currentValue = 0,
    double previousValue = 0,
    double? growthValue,
  }) {
    final headerStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kTextColorDark);
    final bodyStyle = TextStyle(fontSize: 12, color: Colors.grey.shade800);
    final totalStyle = const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue);

    Widget growthWidget(double? value) {
      if (value == null || !value.isFinite || !_canCalculateGrowth) return Text('N/A', style: isHeader ? headerStyle : bodyStyle, textAlign: TextAlign.right);
      final color = value >= 0 ? Colors.green.shade700 : Colors.red.shade700;
      return Text('${value.round()}%', style: (isTotal ? totalStyle : bodyStyle).copyWith(color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.right);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(isHeader ? 'Category' : title, style: isHeader || isTotal ? headerStyle : bodyStyle)),
          Expanded(flex: 3, child: Text(isHeader ? 'Current Year' : _currencyFormatter.format(currentValue), style: isTotal ? totalStyle : (isHeader ? headerStyle : bodyStyle), textAlign: TextAlign.right)),
          Expanded(flex: 3, child: Text(isHeader ? 'Previous Year' : _currencyFormatter.format(previousValue), style: isTotal ? totalStyle : (isHeader ? headerStyle : bodyStyle), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: isHeader ? Text('Growth', style: headerStyle, textAlign: TextAlign.right) : growthWidget(growthValue)),
        ],
      ),
    );
  }

 Widget _buildProjectDetailsCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Project-wise Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
            ),
            const Divider(height: 20),
            // Table Header
            _buildProjectRow(
              isHeader: true,
              project: 'Project',
              frPremium: 'FY Premium',
              rrPremium: 'RR Premium',
              frGrowth: 'FY Growth',
              rrGrowth: 'RR Growth',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(height: 1, thickness: 1),
            ),
            // Table Body
            ..._uniqueProjects.map((project) => _buildProjectRow(
                  project: project,
                  frPremium: _currencyFormatter.format(_projectCurrentFR[project] ?? 0),
                  rrPremium: _currencyFormatter.format(_projectCurrentRR[project] ?? 0),
                  frGrowthValue: _projectGrowthFR[project],
                  rrGrowthValue: _projectGrowthRR[project],
                )),
            // Table Footer
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(height: 20, thickness: 1),
            ),
            _buildProjectRow(
              isHeader: true, // Use header style for totals
              project: 'Total',
              frPremium: _currencyFormatter.format(_totalCurrentFR),
              rrPremium: _currencyFormatter.format(_totalCurrentRR),
              frGrowthValue: _growthFR,
              rrGrowthValue: _growthRR,
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for a row in the project performance table
  Widget _buildProjectRow({
    bool isHeader = false,
    required String project,
    String? frPremium,
    String? rrPremium,
    String? frGrowth,
    String? rrGrowth,
    double? frGrowthValue,
    double? rrGrowthValue,
  }) {
    final style = isHeader
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kTextColorDark)
        : const TextStyle(fontSize: 12);

    Widget growthWidget(double? value, String? text) {
      if (text != null) return Text(text, style: style, textAlign: TextAlign.right);
      if (value == null || !value.isFinite) return Text('N/A', style: style.copyWith(color: Colors.grey), textAlign: TextAlign.right);
      
      final color = value >= 0 ? Colors.green.shade700 : Colors.red.shade700;
      return Text('${value.round()}%', style: style.copyWith(color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.right);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(project, style: style.copyWith(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(frPremium ?? '', style: style, textAlign: TextAlign.right)),
          Expanded(flex: 3, child: Text(rrPremium ?? '', style: style, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: growthWidget(frGrowthValue, frGrowth)),
          Expanded(flex: 2, child: growthWidget(rrGrowthValue, rrGrowth)),
        ],
      ),
    );
  }

  Widget _buildBusinessDataTable(List<BusinessEntry> businessList) {
    if (businessList.isEmpty) {
      return const Center(
        child: Text(
          'No business data for this period.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // --- Calculate Totals for the Footer Row ---
    int totalPolicies = 0;
    double totalPremium = 0;

    for (var entry in businessList) {
      totalPolicies += int.tryParse(entry.numberOfPolicy) ?? 0;
      totalPremium += double.tryParse(entry.totalPremium) ?? 0.0;
    }

    final footerStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    final rows = businessList.map((entry) => DataRow(
      cells: [
        DataCell(Text(entry.project)),
        DataCell(Text(entry.type, style: TextStyle(color: entry.type == 'FR' ? Colors.green.shade700 : Colors.blue.shade700, fontWeight: FontWeight.w500))),
        DataCell(Text(entry.numberOfPolicy)),
        DataCell(Text(_currencyFormatter.format(double.tryParse(entry.totalPremium) ?? 0))),
      ],
    )).toList();

    // --- Add the Footer Row ---
    rows.add(
      DataRow(
        cells: [
          DataCell(Text('Total', style: footerStyle)),
          DataCell.empty, // Empty cell for 'Type' column
          DataCell(Text(totalPolicies.toString(), style: footerStyle)),
          DataCell(Text(_currencyFormatter.format(totalPremium), style: footerStyle)),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: MaterialStateProperty.all(kAccentBlue.withOpacity(0.1)),
        columns: const [
          DataColumn(label: Text('Project', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Policies', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Premium', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        ],
        rows: rows,
      ),
    );
  }

  // Widget for the expandable list of team members
  Widget _buildTeamExpansionTile(String title, List<TeamMember> members) {
    if (members.isEmpty) {
      // If there are no members, don't show the expansion tile.
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        // Header of the expansion tile
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        // Trailing count badge
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: kAccentBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            members.length.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDarkBlue),
          ),
        ),
        // Leading icon
        leading: const Icon(Icons.people_outline, color: kAccentBlue),
        // List of members shown when expanded
        children: members.map((member) => _buildMemberTile(member)).toList(),
      ),
    );
  }

  // Widget for a single member item in the list
  Widget _buildMemberTile(TeamMember member) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 2),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => BusinessPerformancePage(
              empId: member.empId,
              designation: member.designation,
              empName: member.empName,
            )),
          );
        },
        title: Text(member.empName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('ID: ${member.empId}'),
        leading: CircleAvatar(
          backgroundColor: kPrimaryDarkBlue,
          foregroundColor: Colors.white,
          child: Text(
            member.empName.isNotEmpty ? member.empName[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        trailing: (member.mobile != null && member.mobile!.isNotEmpty)
            ? IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                tooltip: 'Call ${member.mobile}',
                onPressed: () async {
                  final Uri launchUri = Uri(scheme: 'tel', path: member.mobile);
                  if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
                },
              ) : null,
      ),
    );
  }
}