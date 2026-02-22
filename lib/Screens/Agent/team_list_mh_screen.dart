import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'business_performance_page.dart';
import 'team_agent_summary_screen.dart'; // Reusing TeamMember and navigation destination

// --- Constants ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kTextColorDark = Color(0xFF1F2937);
const String BASE_URL = 'https://nliapi.nextgenitltd.com/api';

// --- 1. Data Models ---

class TeamCount {
  final String fa;
  final String um;
  final String bm;
  final String dc;
  final String branch;
  final String zone;

  TeamCount({
    required this.fa,
    required this.um,
    required this.bm,
    required this.dc,
    required this.branch,
    required this.zone,
  });

  factory TeamCount.fromJson(Map<String, dynamic> json) {
    return TeamCount(
      fa: json['fa']?.toString() ?? '0',
      um: json['um']?.toString() ?? '0',
      bm: json['bm']?.toString() ?? '0',
      dc: json['dc']?.toString() ?? '0',
      branch: json['branch']?.toString() ?? '0',
      zone: json['zone']?.toString() ?? '0',
    );
  }
}

class TeamListApiResponse {
  final String name;
  final String id;
  final String designations;
  final TeamCount counts;
  final List<TeamMember> faList;
  final List<TeamMember> umList;
  final List<TeamMember> bmList;
  final List<TeamMember> dcList;
  final List<TeamMember> branchList;
  final List<TeamMember> zoneList;

  TeamListApiResponse({
    required this.name,
    required this.id,
    required this.designations,
    required this.counts,
    required this.faList,
    required this.umList,
    required this.bmList,
    required this.dcList,
    required this.branchList,
    required this.zoneList,
  });

  factory TeamListApiResponse.fromJson(Map<String, dynamic> json) {
    List<TeamMember> parseTeamList(Map<String, dynamic> teamsJson, String key, {String? forceDesignation}) {
      if (teamsJson.containsKey(key) && teamsJson[key] is List) {
        return (teamsJson[key] as List)
            .map((item) {
              final member = TeamMember.fromJson(item);
              if (forceDesignation != null) {
                return TeamMember(
                  empId: member.empId,
                  empName: member.empName,
                  mobile: member.mobile,
                  designation: forceDesignation,
                );
              }
              return member;
            }).toList();
      }
      return [];
    }

    final teamsData = json['teams'] as Map<String, dynamic>? ?? {};
    final countData = (json['count'] as List<dynamic>?)?.first as Map<String, dynamic>? ?? {};

    return TeamListApiResponse(
      name: json['name'] ?? 'N/A',
      id: json['id']?.toString() ?? 'N/A',
      designations: json['designations'] ?? 'N/A',
      counts: TeamCount.fromJson(countData),
      faList: parseTeamList(teamsData, 'falist'),
      umList: parseTeamList(teamsData, 'umlist'),
      bmList: parseTeamList(teamsData, 'bmlist'),
      dcList: parseTeamList(teamsData, 'dclist'),
      branchList: parseTeamList(teamsData, 'branchlist', forceDesignation: 'BRANCH'),
      zoneList: parseTeamList(teamsData, 'Zonelist', forceDesignation: 'ZONE'), // Note: 'Z' is capitalized in JSON
    );
  }
}

// --- 2. API Service ---
class TeamListApiService {
  Future<TeamListApiResponse> fetchTeamData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final uri = Uri.parse("$BASE_URL/teams");

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
        return TeamListApiResponse.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to load team data.');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}

// --- 3. UI Widget ---
class TeamListMhScreen extends StatefulWidget {
  const TeamListMhScreen({super.key});

  @override
  State<TeamListMhScreen> createState() => _TeamListMhScreenState();
}

class _TeamListMhScreenState extends State<TeamListMhScreen> {
  late Future<TeamListApiResponse> _teamDataFuture;
  final TeamListApiService _apiService = TeamListApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentUserDesignation = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserDesignation();
    _teamDataFuture = _apiService.fetchTeamData();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  Future<void> _loadCurrentUserDesignation() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserDesignation = prefs.getString('designation') ?? 'N/A';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('Team List'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
      ),
      body: FutureBuilder<TeamListApiResponse>(
        future: _teamDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryDarkBlue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No team data found.'));
          }

          final data = snapshot.data!;
          
          // Create a list of tabs that have data
          final List<Widget> tabs = [];
          final List<Widget> tabViews = [];

          if (data.faList.isNotEmpty) {
            tabs.add(const Tab(text: 'FA'));
            tabViews.add(_buildTeamMemberList(data.faList));
          }
          if (data.umList.isNotEmpty) {
            tabs.add(const Tab(text: 'UM'));
            tabViews.add(_buildTeamMemberList(data.umList));
          }
          if (data.bmList.isNotEmpty) {
            tabs.add(const Tab(text: 'BM'));
            tabViews.add(_buildTeamMemberList(data.bmList));
          }
          if (data.dcList.isNotEmpty) {
            tabs.add(const Tab(text: 'DC'));
            tabViews.add(_buildTeamMemberList(data.dcList));
          }
          if (data.branchList.isNotEmpty) {
            tabs.add(const Tab(text: 'Branch'));
            tabViews.add(_buildTeamMemberList(data.branchList, isNavigable: true));
          }
          if (data.zoneList.isNotEmpty) {
            tabs.add(const Tab(text: 'Zone'));
            tabViews.add(_buildTeamMemberList(data.zoneList, isNavigable: true));
          }

          return DefaultTabController(
            length: tabs.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(child: _buildProfileCard(data)),
                  SliverToBoxAdapter(child: _buildCountGrid(data.counts)),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: kScaffoldBackground,
                    toolbarHeight: 0,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: TabBar(
                        isScrollable: true,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: kPrimaryDarkBlue,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: kTextColorDark,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        padding: const EdgeInsets.only(bottom: 10, left: 0, right: 10),
                        tabs: tabs,
                      ),
                    ),
                  )
                ];
              },
              body: TabBarView(
                children: tabViews,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(TeamListApiResponse data) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: kPrimaryDarkBlue.withOpacity(0.1),
                child: Text(
                  data.name.isNotEmpty ? data.name[0] : 'A',
                  style: const TextStyle(fontSize: 24, color: kPrimaryDarkBlue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
                  const SizedBox(height: 4),
                  Text('ID: ${data.id} | ${data.designations}', style: const TextStyle(fontSize: 14, color: kTextColorDark)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountGrid(TeamCount counts) {
    final countItems = {
      'FA': counts.fa,
      'UM': counts.um,
      'BM': counts.bm,
      'DC': counts.dc,
      'Branch': counts.branch,
      'Zone': counts.zone,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.8,
        ),
        itemCount: countItems.length,
        itemBuilder: (context, index) {
          final title = countItems.keys.elementAt(index);
          final count = countItems.values.elementAt(index);
          return _buildCountCard(title, count);
        },
      ),
    );
  }

  Widget _buildCountCard(String title, String count) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: kTextColorDark, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by Name or ID...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildTeamMemberList(List<TeamMember> members, {bool isNavigable = true}) {
    final filteredMembers = _searchQuery.isEmpty
        ? members
        : members.where((member) {
            final nameLower = member.empName.toLowerCase();
            final idLower = member.empId.toLowerCase();
            final searchLower = _searchQuery.toLowerCase().trim();
            return nameLower.contains(searchLower) || idLower.contains(searchLower);
          }).toList();

    if (filteredMembers.isEmpty) {
      return Center(
          child: Text(
        _searchQuery.isEmpty ? 'No members in this category.' : 'No results found.',
        style: const TextStyle(color: Colors.grey),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        return _buildMemberTile(member, isNavigable: isNavigable);
      },
    );
  }

  Widget _buildMemberTile(TeamMember member, {required bool isNavigable}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: ListTile(
        onTap: isNavigable && member.designation != 'N/A'
            ? () {
                final isBranchFlag = (member.designation.toUpperCase() == 'BRANCH' ||
                        member.designation.toUpperCase() == 'ZONE')
                    ? 1
                    : 0;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TeamAgentSummaryScreen(
                      id: member.empId,
                      designation: member.designation,
                      phone: member.mobile,
                      isBranch: isBranchFlag,
                      user: _currentUserDesignation,
                      branchName: member.designation.toUpperCase() == 'BRANCH' ? member.empName : '',
                      zoneName: member.designation.toUpperCase() == 'ZONE' ? member.empName : '',
                    ),
                  ),
                );
              }
            : null,
        leading: CircleAvatar(
          backgroundColor: kPrimaryDarkBlue,
          foregroundColor: Colors.white,
          child: Text(
            member.empName.isNotEmpty ? member.empName[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(member.empName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('ID: ${member.empId} | ${member.designation}'),
        trailing: (member.mobile != null && member.mobile!.isNotEmpty)
            ? IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                tooltip: 'Call ${member.mobile}',
                onPressed: () async {
                  final Uri launchUri = Uri(scheme: 'tel', path: member.mobile);
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  }
                },
              )
            : null,
      ),
    );
  }
}