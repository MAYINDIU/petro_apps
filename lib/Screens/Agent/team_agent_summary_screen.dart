import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Constants ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kWhiteColor = Colors.white;
const Color kBlackColor = Colors.black;
const Color kScaffoldBackground = Color(0xFFF3F4F6);

class TeamAgentSummaryScreen extends StatefulWidget {
  const TeamAgentSummaryScreen({
    super.key,
    this.id,
    this.designation,
    this.phone,
    this.isBranch,
    required this.user, // Logged-in user's designation
    required this.branchName,
    required this.zoneName,
  });

  final String? id;
  final String? designation; // Clicked item's designation
  final String? phone;
  final int? isBranch;
  final String branchName;
  final String zoneName;
  final String user;

  @override
  State<TeamAgentSummaryScreen> createState() => _TeamAgentSummaryScreenState();
}

class _TeamAgentSummaryScreenState extends State<TeamAgentSummaryScreen> {
  bool isMonth = false;
  bool isYear = true;
  bool isPrevious = false;
  bool isCurrent = true;
  List<String> project = [];
  String? zoneName;
  String? zone;
  String? branch;
  String? agentName;
  String? agentId;
  String? agentDesignation;
  String um = "";
  String bm = "";
  String dc = "";
  double pfrtotla = 0;
  double pRrtotal = 0;
  double cfrtotla = 0;
  double cRrtotal = 0;
  Map<String, double> projectCurrentSumFR = {};
  Map<String, double> projectCurrentSumRR = {};
  Map<String, double> projectPreviousSumFR = {};
  Map<String, double> projectPreviousSumRR = {};
  Map<String, double> projectGrowthFR = {};
  Map<String, double> projectGrowthRR = {};
  double totalProjectGrowthFR = 0;
  double totalProjectGrowthRR = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getData(widget.id!, widget.designation!, widget.isBranch!);
  }

  void clearCache() {
    setState(() {
      project.clear();
      zoneName = "";
      agentName = "";
      agentId = "";
      agentDesignation = "";
      zone = "";
      branch = "";
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
    });
  }

  void clearCacheMonth() {
    setState(() {
      project.clear();
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
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  

  Future<void> getBranchMonthlyData({required String id, required String type}) async {
    setState(() => isLoading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    final uri = Uri.https("nliapi.nextgenitltd.com", "/api/monthly-zone-branch-business", {"id": id, "type": type});
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['success'] == true) {
        List<dynamic> dataProject = data["business"] ?? [];
        _processBusinessData(dataProject, isMonth: true);
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> getZoneBranchBusiness(String designation, String code) async {

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userDesignation = prefs.getString('designation') ?? "AREA HEAD";
        debugPrint("Designation: $userDesignation");
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    final uri = Uri.https("nliapi.nextgenitltd.com", "/api/zone-branch-business", {
      "designation": userDesignation,
      "code": code,
    });

    try {
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      debugPrint("Response: ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          List<dynamic> dataProject = data["business"] ?? data["branch"] ?? [];
          _processBusinessData(dataProject, isMonth: false);
        }
      }
    } catch (e) {
      debugPrint("Error in getZoneBranchBusiness: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> getData(String id, String designation, int isBranch) async {
    if (designation == 'ZONE' || designation == 'BRANCH') {
      setState(() {
        agentId = id;
      });
      await getZoneBranchBusiness(designation, id);
      return;
    }

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userDesignation = prefs.getString('designation') ?? widget.user;

    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    var queryParams = {"emp_id": id, "designation": designation};

    if (userDesignation == "AREA HEAD" || userDesignation == "MONITOR HEAD") {
      queryParams["isBranch"] = isBranch.toString();
    }

    final uri = Uri.https("nliapi.nextgenitltd.com", "/api/agent-business", queryParams);
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        agentName = data["emp_name"];
        agentId = data["emp_id"];
        agentDesignation = data["designation"];
        zone = "${data["details"]?["zone"] ?? ''}-${data["details"]?["zone_name"] ?? ''}";
        branch = "${data["details"]?["branch"] ?? ''}-${data["details"]?["branch_name"] ?? ''}";
        um = (data["designation"] == "FA" || data["designation"] == "UM") ? "${data["details"]?["um"] ?? ''}-${data["details"]?["um_name"] ?? ''}" : "";
        bm = (data["designation"] == "FA" || data["designation"] == "UM" || data["designation"] == "BM") ? "${data["details"]?["bm"] ?? ''}-${data["details"]?["bm_name"] ?? ''}" : "";
        dc = (data["designation"] == "FA" || data["designation"] == "UM" || data["designation"] == "BM") ? "${data["details"]?["dc"] ?? ''}-${data["details"]?["dc_name"] ?? ''}" : "";
      });

      List<dynamic> dataProject = data["business"] ?? [];
      _processBusinessData(dataProject, isMonth: false);
    }
    setState(() => isLoading = false);
  }

  void _processBusinessData(List<dynamic> dataProject, {required bool isMonth}) {
    final currentCategory = isMonth ? "CURRENT_MONTH" : "CURRENT_YEAR";
    final previousCategory = isMonth ? "PREVIOUS_MONTH" : "PREVIOUS_YEAR";

    final localProjects = dataProject.map((e) => e["project"] as String?).whereType<String>().toSet().toList();

    double tempPfrTotal = 0, tempPrrTotal = 0, tempCfrTotal = 0, tempCrrTotal = 0;
    Map<String, double> tempProjectCurrentSumFR = {};
    Map<String, double> tempProjectCurrentSumRR = {};
    Map<String, double> tempProjectPreviousSumFR = {};
    Map<String, double> tempProjectPreviousSumRR = {};
    Map<String, double> tempProjectGrowthFR = {};
    Map<String, double> tempProjectGrowthRR = {};

    for (var proj in localProjects) {
      double currentSumFR = 0, currentSumRR = 0, previousSumFR = 0, previousSumRR = 0;

      for (var re in dataProject) {
        if (re["project"] == proj) {
          double premiumPaid = double.tryParse(re["total_premium_paid_in_lacs"].toString()) ?? 0.0;
          if (re["year_category"] == previousCategory) {
            if (re["type"] == "FR") {
              tempPfrTotal += premiumPaid;
              previousSumFR += premiumPaid;
            } else if (re["type"] == "RR") {
              tempPrrTotal += premiumPaid;
              previousSumRR += premiumPaid;
            }
          } else if (re["year_category"] == currentCategory) {
            if (re["type"] == "FR") {
              tempCfrTotal += premiumPaid;
              currentSumFR += premiumPaid;
            } else if (re["type"] == "RR") {
              tempCrrTotal += premiumPaid;
              currentSumRR += premiumPaid;
            }
          }
        }
      }
      tempProjectCurrentSumFR[proj] = currentSumFR;
      tempProjectCurrentSumRR[proj] = currentSumRR;
      tempProjectPreviousSumFR[proj] = previousSumFR;
      tempProjectPreviousSumRR[proj] = previousSumRR;

      if (previousSumFR != 0) {
        tempProjectGrowthFR[proj] = ((currentSumFR - previousSumFR) / previousSumFR) * 100;
      }
      if (previousSumRR != 0) {
        tempProjectGrowthRR[proj] = ((currentSumRR - previousSumRR) / previousSumRR) * 100;
      }
    }

    setState(() {
      project = localProjects;
      pfrtotla = tempPfrTotal;
      pRrtotal = tempPrrTotal;
      cfrtotla = tempCfrTotal;
      cRrtotal = tempCrrTotal;
      projectCurrentSumFR = tempProjectCurrentSumFR;
      projectCurrentSumRR = tempProjectCurrentSumRR;
      projectPreviousSumFR = tempProjectPreviousSumFR;
      projectPreviousSumRR = tempProjectPreviousSumRR;
      projectGrowthFR = tempProjectGrowthFR;
      projectGrowthRR = tempProjectGrowthRR;

      if (pfrtotla != 0) {
        totalProjectGrowthFR = ((cfrtotla - pfrtotla) / pfrtotla) * 100;
      } else {
        totalProjectGrowthFR = 0;
      }
      if (pRrtotal != 0) {
        totalProjectGrowthRR = ((cRrtotal - pRrtotal) / pRrtotal) * 100;
      } else {
        totalProjectGrowthRR = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kWhiteColor,
        centerTitle: true,
        title: const Text("Business Summary"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeaderCard()),
                if (widget.isBranch == 1)
                  SliverToBoxAdapter(
                    child: _buildYearMonthToggle(),
                  ),
                SliverToBoxAdapter(child: _buildPeriodToggle()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Business Details",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kBlackColor),
                        ),
                        const SizedBox(height: 10),
                        _buildBusinessTable(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    String title = widget.branchName.isNotEmpty
        ? widget.branchName
        : widget.zoneName.isNotEmpty
            ? widget.zoneName
            : agentName ?? widget.user;

    return Container(
      padding: const EdgeInsets.all(12.0),
      color: kPrimaryDarkBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kWhiteColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildDetailRow("Code", agentId),
          if (widget.phone?.isNotEmpty ?? false) _buildDetailRow("Phone", widget.phone, isPhone: true),
          _buildDetailRow("Designation", widget.designation),
          if (um.isNotEmpty && um != "-") _buildDetailRow("UM", um),
          if (bm.isNotEmpty && bm != "-") _buildDetailRow("BM", bm),
          if (dc.isNotEmpty && dc != "-") _buildDetailRow("DC", dc),
          if ((zone?.isNotEmpty ?? false) && zone != "-") _buildDetailRow("Zone", zone),
          if ((branch?.isNotEmpty ?? false) && branch != "-") _buildDetailRow("Branch", branch),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? text, {bool isPhone = false}) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(color: kWhiteColor.withOpacity(0.8), fontSize: 11)),
          Expanded(child: Text(text, style: const TextStyle(color: kWhiteColor, fontSize: 12, fontWeight: FontWeight.w600))),
          if (isPhone)
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.green, size: 16),
              onPressed: () async {
                final Uri launchUri = Uri(scheme: 'tel', path: text);
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                }
              },
            )
        ],
      ),
    );
  }

  Widget _buildYearMonthToggle() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          _buildToggleChip("Yearly Business", isYear, (val) {
            if (val) {
              clearCache();
              setState(() {
                isYear = true;
                isMonth = false;
                isCurrent = true;
                isPrevious = false;
              });
              getData(widget.id!, widget.designation!, widget.isBranch!);
            }
          }),
          _buildToggleChip("Monthly Business", isMonth, (val) {
            if (val) {
              clearCacheMonth();
              setState(() {
                isMonth = true;
                isYear = false;
                isCurrent = true;
                isPrevious = false;
              });
              final type = widget.designation?.toUpperCase() == 'ZONE' ? 'ZONE' : 'BRANCH';
              getBranchMonthlyData(id: widget.id!, type: type);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          _buildToggleChip(isMonth ? "Current Month" : "Current Year", isCurrent, (val) {
            if (val) setState(() => {isCurrent = true, isPrevious = false});
          }),
          _buildToggleChip(isMonth ? "Previous Month" : "Previous Year", isPrevious, (val) {
            if (val) setState(() => {isPrevious = true, isCurrent = false});
          }),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isSelected, Function(bool) onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(true),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? kPrimaryDarkBlue : Colors.transparent, width: 3)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isSelected ? kPrimaryDarkBlue : kBlackColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessTable() {
    return Column(
      children: [
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: kPrimaryDarkBlue),
              children: [
                _tableHeader("Project"),
                _tableHeader("Premium (in Lac)"),
                _tableHeader("Growth %"),
              ],
            ),
            TableRow(
              decoration: const BoxDecoration(color: kPrimaryDarkBlue),
              children: [
                _tableSubHeader("", isExpanded: false),
                Row(children: [_tableSubHeader("First Yr"), _tableSubHeader("Ren Yr")]),
                Row(children: [_tableSubHeader("First Yr"), _tableSubHeader("Ren Yr")]),
              ],
            )
          ],
        ),
        if (project.isNotEmpty)
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              ...project.map((p) => _buildProjectDataRow(p)),
              _buildTotalRow(),
            ],
          )
        else
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: Text("No business data available.", style: TextStyle(fontSize: 12))),
          ),
      ],
    );
  }

  TableRow _buildProjectDataRow(String proj) {
    return TableRow(
      children: [
        _tableCell(proj, align: TextAlign.left, isHeader: true),
        _tableCell((isCurrent ? projectCurrentSumFR[proj] : projectPreviousSumFR[proj])?.toStringAsFixed(2) ?? "0.00"),
        _tableCell((isCurrent ? projectCurrentSumRR[proj] : projectPreviousSumRR[proj])?.toStringAsFixed(2) ?? "0.00"),
        _tableCell(isCurrent ? (projectGrowthFR[proj]?.toStringAsFixed(0) ?? "0") : "0", isGrowth: true),
        _tableCell(isCurrent ? (projectGrowthRR[proj]?.toStringAsFixed(0) ?? "0") : "0", isGrowth: true),
      ],
    );
  }

  TableRow _buildTotalRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.blue.shade50),
      children: [
        _tableCell("Total", isTotal: true, isHeader: true, align: TextAlign.left),
        _tableCell((isCurrent ? cfrtotla : pfrtotla).toStringAsFixed(2), isTotal: true),
        _tableCell((isCurrent ? cRrtotal : pRrtotal).toStringAsFixed(2), isTotal: true),
        _tableCell(isCurrent ? totalProjectGrowthFR.toStringAsFixed(0) : "0", isTotal: true, isGrowth: true),
        _tableCell(isCurrent ? totalProjectGrowthRR.toStringAsFixed(0) : "0", isTotal: true, isGrowth: true),
      ],
    );
  }

  Widget _tableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(color: kWhiteColor, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _tableSubHeader(String title, {bool isExpanded = true}) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(color: kWhiteColor.withOpacity(0.9), fontSize: 10),
      ),
    );
    return isExpanded ? Expanded(child: child) : child;
  }

  Widget _tableCell(String text, {bool isTotal = false, bool isHeader = false, bool isGrowth = false, TextAlign align = TextAlign.right}) {
    Color textColor = kBlackColor;
    FontWeight fontWeight = isHeader ? FontWeight.bold : FontWeight.normal;

    if (isTotal) {
      textColor = kPrimaryDarkBlue;
      fontWeight = FontWeight.bold;
    }

    if (isGrowth && isCurrent) {
      final value = double.tryParse(text) ?? 0.0;
      if (value > 0) textColor = Colors.green.shade700;
      if (value < 0) textColor = Colors.red.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Text(
        isGrowth ? "$text%" : text,
        textAlign: align,
        style: TextStyle(color: textColor, fontWeight: fontWeight, fontSize: 11),
      ),
    );
  }
}