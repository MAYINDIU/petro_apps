import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- Constants ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kScaffoldBackground = Color(0xFFF3F4F6);

class TeamDetailsBusinessScreen extends StatefulWidget {
  const TeamDetailsBusinessScreen({super.key});

  @override
  State<TeamDetailsBusinessScreen> createState() => _TeamDetailsBusinessScreenState();
}

class _TeamDetailsBusinessScreenState extends State<TeamDetailsBusinessScreen> {
  late Future<TeamDetailsResponse> _dataFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<TeamDetailsResponse> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse('https://nliapi.nextgenitltd.com/api/employee-agent-business');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return TeamDetailsResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load data (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  List<TeamBusinessData> _filterList(List<TeamBusinessData> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((item) {
      final q = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(q) || item.code.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TeamDetailsResponse>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Team Details Business'), backgroundColor: kPrimaryDarkBlue),
            body: const Center(child: CircularProgressIndicator(color: kPrimaryDarkBlue)),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Team Details Business'), backgroundColor: kPrimaryDarkBlue),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final response = snapshot.data!;
        final dataMap = response.data;
        
        // Filter categories that actually have data (FA, UM, BM, DC)
        final activeCategories = ['fa', 'um', 'bm', 'dc']
            .where((key) => dataMap.containsKey(key) && dataMap[key]!.isNotEmpty)
            .toList();

        return DefaultTabController(
          length: activeCategories.length,
          child: Scaffold(
            backgroundColor: kScaffoldBackground,
            appBar: AppBar(
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search by Name or Code...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    )
                  : const Text('Team Details Business'),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = '';
                        _searchController.clear();
                      }
                    });
                  },
                ),
              ],
              backgroundColor: kPrimaryDarkBlue,
              foregroundColor: Colors.white,
              bottom: TabBar(
                isScrollable: false,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: activeCategories.map((cat) => Tab(text: cat.toUpperCase())).toList(),
              ),
            ),
            body: TabBarView(
              children: activeCategories.map((cat) => _buildNestedTabs(_filterList(dataMap[cat]!))).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNestedTabs(List<TeamBusinessData> list) {
    final frList = list.where((item) => item.type == 'FR').toList();
    final rrList = list.where((item) => item.type == 'RR').toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: kPrimaryDarkBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kPrimaryDarkBlue,
              tabs: [
                Tab(text: 'First Year'),
                Tab(text: 'Renewal'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(frList),
                _buildList(rrList),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TeamBusinessData> list) {
    if (list.isEmpty) {
      return const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: kPrimaryDarkBlue.withOpacity(0.1),
              child: Text(item.desig, style: const TextStyle(color: kPrimaryDarkBlue, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('Code: ${item.code}'),
            trailing: Text(
              item.totalPremium,
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildInfoRow('Branch', item.branchName),
                    _buildInfoRow('Zone', item.zoneName),
                    _buildInfoRow('Year', item.year),
                    _buildInfoRow('Type', item.type),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}

// --- Models (Keep your existing models or use these slightly cleaned versions) ---

class TeamBusinessData {
  final String desig;
  final String year;
  final String type;
  final String code;
  final String name;
  final String branchName;
  final String zoneName;
  final String totalPremium;

  TeamBusinessData({
    required this.desig, required this.year, required this.type,
    required this.code, required this.name, required this.branchName,
    required this.zoneName, required this.totalPremium,
  });

  factory TeamBusinessData.fromJson(Map<String, dynamic> json) {
    return TeamBusinessData(
      desig: json['desig']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? '',
      zoneName: json['zone_name']?.toString() ?? '',
      totalPremium: json['total_premium']?.toString() ?? '0',
    );
  }
}

class TeamDetailsResponse {
  final bool success;
  final Map<String, List<TeamBusinessData>> data;

  TeamDetailsResponse({required this.success, required this.data});

  factory TeamDetailsResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = <String, List<TeamBusinessData>>{};
    if (json['data'] != null && json['data'] is Map) {
      json['data'].forEach((key, value) {
        if (value is List) {
          dataMap[key] = value.map((e) => TeamBusinessData.fromJson(e)).toList();
        }
      });
    }
    return TeamDetailsResponse(
      success: json['success'] ?? false,
      data: dataMap,
    );
  }
}