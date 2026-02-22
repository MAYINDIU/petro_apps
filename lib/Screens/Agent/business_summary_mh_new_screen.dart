import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

const Color kWhiteColor = Colors.white;
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kBlackColor = Colors.black;
const String BASE_URLNLI = 'https://nliapi.nextgenitltd.com/api';

class BusinessSummaryMhNewScreen extends StatefulWidget {
  const BusinessSummaryMhNewScreen({Key? key}) : super(key: key);

  @override
  State<BusinessSummaryMhNewScreen> createState() =>
      _BusinessSummaryMhNewScreenState();
}

class _BusinessSummaryMhNewScreenState
    extends State<BusinessSummaryMhNewScreen> {
  bool isCurrentYearSelected = true;
  bool isByYear = true;
  bool isLoading = true;
  final TimeNotifier _timeNotifier = TimeNotifier();
  String? _selectedZoneOrBranch;
  String _designation = 'N/A';
  String _employeeID = 'N/A';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _designation = prefs.getString('designation') ?? 'N/A';
        _employeeID = prefs.getString('emp_id') ?? 'N/A';
      });
    }
  }

  Future<void> _fetchData() async {
    await _loadUserInfo();
    await ApiDataCollection.getYearlyData();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    ApiDataCollection.clearCache();
    _timeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryDarkBlue,
        title: const Text("Business Summary"),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: BranchAndAgentDetailsCard(
                    designation: _designation,
                    employeeID: _employeeID,
                  ),
                ),
                // Time
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _timeNotifier.currentTime,
                    builder: (context, time, child) {
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          "As On $time",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 15),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: kPrimaryDarkBlue),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(children: [
                        _buildMainTabOption("By Year", true),
                        _buildMainTabOption("By Month", false),
                      ]),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                // Year Toggle
                SliverToBoxAdapter(
                  child: Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(245, 245, 245, 1),
                    ),
                    child: Row(children: [
                      _buildToggleOption(
                          isByYear ? "Current Year" : "Current Month", true),
                      _buildToggleOption(
                          isByYear ? "Previous Year" : "Previous Month", false),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ApiDataCollection.project.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  "Monitor Business",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: kBlackColor),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildTableHeader(),
                              _buildTableRows(isCurrentYearSelected),
                              _buildTableTotal(isCurrentYearSelected),
                              const SizedBox(height: 10),
                            ],
                          ),
                        )
                      : const Center(child: Text("No Data Available")),
                ),
                if (ApiDataCollection.zoneOrBranchList.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildZoneOrBranchDropdown(),
                  ),
              ],
            ),
    );
  }

  Future<void> _switchDataView(bool toYearView) async {
    // Avoid reloading if the tab is already selected
    if (isByYear == toYearView) return;

    setState(() {
      isLoading = true;
      isByYear = toYearView;
    });

    ApiDataCollection.clearCache();
    if (toYearView) {
      await ApiDataCollection.getYearlyData();
    } else {
      await ApiDataCollection.getMonthlyData();
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildMainTabOption(String title, bool isYear) {
    final isSelected = isByYear == isYear;
    return Expanded(
      child: InkWell(
        onTap: () => _switchDataView(isYear),
        child: Container(
          color: isSelected ? kPrimaryDarkBlue : Colors.white,
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : kPrimaryDarkBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(String title, bool isCurrent) {
    final isSelected = isCurrentYearSelected == isCurrent;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (isCurrentYearSelected != isCurrent) {
            setState(() {
              isCurrentYearSelected = isCurrent;
            });
          }
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? kPrimaryDarkBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? kPrimaryDarkBlue
                  : const Color.fromRGBO(44, 40, 62, 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneOrBranchDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Zone/Branch",
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: kBlackColor)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1))
                ]),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Select Zone/Branch"),
                value: _selectedZoneOrBranch,
                items: ApiDataCollection.zoneOrBranchList.map((zone) {
                  return DropdownMenuItem<String>(
                    value: zone.code,
                    child: Text(zone.name.trim()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedZoneOrBranch = newValue;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2.8),
        2: FlexColumnWidth(2.0),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(
          decoration: const BoxDecoration(color: kPrimaryDarkBlue),
          children: <Widget>[
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.fill,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  "Project",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            _buildHeaderColumn("Premium (Figure In Lac)"),
            _buildHeaderColumn("Growth%"),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderColumn(String title) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white24)),
          ),
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        Row(
          children: [
            Expanded(
                child: Container(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white24)),
              ),
              child: _buildSubHeader("First Yr"),
            )),
            Expanded(child: _buildSubHeader("Ren Yr")),
          ],
        )
      ],
    );
  }

  Widget _buildSubHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      ),
    );
  }

  Widget _buildTableRows(bool isCurrent) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.0),
        4: FlexColumnWidth(1.0),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        for (int index = 0; index < ApiDataCollection.project.length; index++)
          TableRow(
            decoration: BoxDecoration(
              color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                child: Text(ApiDataCollection.project[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF433E5B))),
              ),
              _buildCell(isCurrent
                  ? ApiDataCollection.projectCurrentSumFR[
                      ApiDataCollection.project[index]]
                  : ApiDataCollection.projectPreviousSumFR[
                      ApiDataCollection.project[index]]),
              _buildCell(isCurrent
                  ? ApiDataCollection.projectCurrentSumRR[
                      ApiDataCollection.project[index]]
                  : ApiDataCollection.projectPreviousSumRR[
                      ApiDataCollection.project[index]]),
              _buildCell(
                  isCurrent
                      ? ApiDataCollection
                          .projectGrowthFR[ApiDataCollection.project[index]]
                      : 0.0,
                  isGrowth: true),
              _buildCell(
                  isCurrent
                      ? ApiDataCollection
                          .projectGrowthRR[ApiDataCollection.project[index]]
                      : 0.0,
                  isGrowth: true),
            ],
          ),
      ],
    );
  }

  Widget _buildTableTotal(bool isCurrent) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.0),
        4: FlexColumnWidth(1.0),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(children: [
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
            child: Text("Total",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2196F3))),
          ),
          _buildCell(
              isCurrent ? ApiDataCollection.cfrtotla : ApiDataCollection.pfrtotla,
              isTotal: true,
              bgColor: Colors.blue.shade50),
          _buildCell(
              isCurrent ? ApiDataCollection.cRrtotal : ApiDataCollection.pRrtotal,
              isTotal: true,
              bgColor: Colors.blue.shade50),
          _buildCell(
              isCurrent ? ApiDataCollection.totalProjectGrowthFR : 0.0,
              isTotal: true,
              isGrowth: true,
              bgColor: Colors.blue.shade50),
          _buildCell(
              isCurrent ? ApiDataCollection.totalProjectGrowthRR : 0.0,
              isTotal: true,
              isGrowth: true,
              bgColor: Colors.blue.shade50),
        ]),
      ],
    );
  }

  Widget _buildCell(double? value,
      {bool isTotal = false, bool isGrowth = false, Color? bgColor}) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        isGrowth
            ? (value ?? 0.0).toStringAsFixed(0)
            : (value ?? 0.0).toStringAsFixed(2),
        textAlign: TextAlign.right,
        style: TextStyle(
            fontSize: 13,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isTotal ? const Color(0xFF2196F3) : const Color(0xFF433E5B)),
      ),
    );
  }
}

class ZoneOrBranch {
  final String code;
  final String name;

  ZoneOrBranch({required this.code, required this.name});

  factory ZoneOrBranch.fromJson(Map<String, dynamic> json) {
    return ZoneOrBranch(
      code: json['zb_code'] as String,
      name: json['zb_name'] as String,
    );
  }
}

class ApiDataCollection {
  static List<String> project = [];
  static String? zoneName;
  static double pfrtotla = 0;
  static double pRrtotal = 0;
  static double cfrtotla = 0;
  static double cRrtotal = 0;
  static Map<String, double> projectCurrentSumFR = {};
  static Map<String, double> projectCurrentSumRR = {};
  static Map<String, double> projectPreviousSumFR = {};
  static Map<String, double> projectPreviousSumRR = {};
  static Map<String, double> projectGrowthFR = {};
  static Map<String, double> projectGrowthRR = {};
  static double totalProjectGrowthFR = 0;
  static double totalProjectGrowthRR = 0;
  static List<ZoneOrBranch> zoneOrBranchList = [];

  static void clearCache() {
    project.clear();
    zoneName = "";
    pfrtotla = 0;
    pRrtotal = 0;
    cfrtotla = 0;
    cRrtotal = 0;
    projectCurrentSumFR.clear();
    projectCurrentSumRR.clear();
    projectPreviousSumFR.clear();
    projectPreviousSumRR.clear();
    projectGrowthFR.clear();
    projectGrowthRR.clear();
    totalProjectGrowthFR = 0;
    totalProjectGrowthRR = 0;
    zoneOrBranchList.clear();
  }

  static Future<void> getMonthlyData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      debugPrint("Authorization token not found!");
      return;
    }
    var response = await http.get(Uri.parse("$BASE_URLNLI/monthly-business-summery"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      zoneName = data["ZoneorAreaname"];
      List<dynamic> dataProject = data["business"] ?? [];
      List<dynamic> dataZoneOrBranch = data["ZoneOrBranch"] ?? [];

      if (dataZoneOrBranch.isNotEmpty) {
        zoneOrBranchList = dataZoneOrBranch
            .map((item) => ZoneOrBranch.fromJson(item))
            .toList();
      }

      // Initialize project-specific sums
      for (var e in dataProject) {
        final proj = e["project"];
        if (proj != null && !project.contains(proj)) {
          project.add(proj);
          projectCurrentSumFR[proj] = 0;
          projectCurrentSumRR[proj] = 0;
          projectPreviousSumFR[proj] = 0;
          projectPreviousSumRR[proj] = 0;
          projectGrowthFR[proj] = 0;
          projectGrowthRR[proj] = 0;
        }
      }

      // Single pass to calculate all sums
      for (var re in dataProject) {
        final proj = re["project"];
        if (proj == null) continue;

        double premiumPaid =
            double.tryParse(re["total_premium_paid_in_lacs"].toString()) ?? 0.0;

        if (re["year_category"] == "PREVIOUS_MONTH") {
          if (re["type"] == "FR") {
            pfrtotla += premiumPaid;
            projectPreviousSumFR[proj] =
                (projectPreviousSumFR[proj] ?? 0) + premiumPaid;
          } else if (re["type"] == "RR") {
            pRrtotal += premiumPaid;
            projectPreviousSumRR[proj] =
                (projectPreviousSumRR[proj] ?? 0) + premiumPaid;
          }
        } else if (re["year_category"] == "CURRENT_MONTH") {
          if (re["type"] == "FR") {
            cfrtotla += premiumPaid;
            projectCurrentSumFR[proj] =
                (projectCurrentSumFR[proj] ?? 0) + premiumPaid;
          } else if (re["type"] == "RR") {
            cRrtotal += premiumPaid;
            projectCurrentSumRR[proj] =
                (projectCurrentSumRR[proj] ?? 0) + premiumPaid;
          }
        }
      }

      // Calculate growth after all sums are computed
      for (var u in project) {
        double currentSumFR = projectCurrentSumFR[u] ?? 0;
        double previousSumFR = projectPreviousSumFR[u] ?? 0;
        if (previousSumFR != 0) {
          projectGrowthFR[u] =
              ((currentSumFR - previousSumFR) / previousSumFR) * 100;
        }

        double currentSumRR = projectCurrentSumRR[u] ?? 0;
        double previousSumRR = projectPreviousSumRR[u] ?? 0;
        if (previousSumRR != 0) {
          projectGrowthRR[u] =
              ((currentSumRR - previousSumRR) / previousSumRR) * 100;
        }
      }

      if (pfrtotla != 0) {
        totalProjectGrowthFR = ((cfrtotla - pfrtotla) / pfrtotla) * 100;
      }
      if (pRrtotal != 0) {
        totalProjectGrowthRR = ((cRrtotal - pRrtotal) / pRrtotal) * 100;
      }
    }
  }

  static Future<void> getYearlyData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      debugPrint("Authorization token not found!");
      return;
    }
    var response = await http.get(Uri.parse("$BASE_URLNLI/business-summery"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });
    
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      zoneName = data["ZoneorAreaname"];      
      List<dynamic> dataProject = data["business"] ?? [];
      List<dynamic> dataZoneOrBranch = data["ZoneOrBranch"] ?? [];

      if (dataZoneOrBranch.isNotEmpty) {
        zoneOrBranchList = dataZoneOrBranch
            .map((item) => ZoneOrBranch.fromJson(item))
            .toList();
      }

      // Initialize project-specific sums
      for (var e in dataProject) {
        final proj = e["project"];
        if (proj != null && !project.contains(proj)) {
          project.add(proj);
          projectCurrentSumFR[proj] = 0;
          projectCurrentSumRR[proj] = 0;
          projectPreviousSumFR[proj] = 0;
          projectPreviousSumRR[proj] = 0;
          projectGrowthFR[proj] = 0;
          projectGrowthRR[proj] = 0;
        }
      }

      // Single pass to calculate all sums
      for (var re in dataProject) {
        final proj = re["project"];
        if (proj == null) continue;

        double premiumPaid =
            double.tryParse(re["total_premium_paid_in_lacs"].toString()) ?? 0.0;

        if (re["year_category"] == "PREVIOUS_YEAR") {
          if (re["type"] == "FR") {
            pfrtotla += premiumPaid;
            projectPreviousSumFR[proj] =
                (projectPreviousSumFR[proj] ?? 0) + premiumPaid;
          } else if (re["type"] == "RR") {
            pRrtotal += premiumPaid;
            projectPreviousSumRR[proj] =
                (projectPreviousSumRR[proj] ?? 0) + premiumPaid;
          }
        } else if (re["year_category"] == "CURRENT_YEAR") {
          if (re["type"] == "FR") {
            cfrtotla += premiumPaid;
            projectCurrentSumFR[proj] =
                (projectCurrentSumFR[proj] ?? 0) + premiumPaid;
          } else if (re["type"] == "RR") {
            cRrtotal += premiumPaid;
            projectCurrentSumRR[proj] =
                (projectCurrentSumRR[proj] ?? 0) + premiumPaid;
          }
        }
      }

      // Calculate growth after all sums are computed
      for (var u in project) {
        double currentSumFR = projectCurrentSumFR[u] ?? 0;
        double previousSumFR = projectPreviousSumFR[u] ?? 0;
        if (previousSumFR != 0) {
          projectGrowthFR[u] =
              ((currentSumFR - previousSumFR) / previousSumFR) * 100;
        }

        double currentSumRR = projectCurrentSumRR[u] ?? 0;
        double previousSumRR = projectPreviousSumRR[u] ?? 0;
        if (previousSumRR != 0) {
          projectGrowthRR[u] =
              ((currentSumRR - previousSumRR) / previousSumRR) * 100;
        }
      }
      if (pfrtotla != 0) {
        totalProjectGrowthFR = ((cfrtotla - pfrtotla) / pfrtotla) * 100;
      }
      if (pRrtotal != 0) {
        totalProjectGrowthRR = ((cRrtotal - pRrtotal) / pRrtotal) * 100;
      }
    }
  }
}

class BranchAndAgentDetailsCard extends StatelessWidget {
  final String designation;
  final String employeeID;

  const BranchAndAgentDetailsCard(
      {Key? key, required this.designation, required this.employeeID})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimaryDarkBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Designation',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: kWhiteColor)),
                    const SizedBox(height: 4),
                    Text(designation,
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: kWhiteColor)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Employee ID',
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: kWhiteColor)),
                    const SizedBox(height: 4),
                    Text(employeeID,
                        maxLines: 2,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: kWhiteColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Monitor Name",
                        style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: kWhiteColor)),
                    const SizedBox(height: 4),
                    Text(ApiDataCollection.zoneName ?? "N/A",
                        maxLines: 2,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: kWhiteColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TimeNotifier {
  ValueNotifier<String> currentTime = ValueNotifier<String>('');
  late Timer _timer;

  TimeNotifier() {
    currentTime.value = _getCurrentFormattedTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentTime.value = _getCurrentFormattedTime();
    });
  }

  String _getCurrentFormattedTime() {
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy hh:mm:ss a');
    return formatter.format(now);
  }

  void dispose() {
    _timer.cancel();
    currentTime.dispose();
  }
}