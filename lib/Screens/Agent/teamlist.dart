import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nli_apps/Screens/Agent/business_performance_page.dart';
import 'package:nli_apps/Screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Constants for consistent styling ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorDark = Color(0xFF1F2937);

// --- 1. Data Models ---
// Represents a generic entity in a list, which can be a person, branch, or zone.
class TeamEntity {
  final String id;
  final String name;
  final String? mobile;
  final String? designation;

  TeamEntity({
    required this.id,
    required this.name,
    this.mobile,
    this.designation,
  });

  factory TeamEntity.fromJson(Map<String, dynamic> json) {
    return TeamEntity(
      id: json['emp_id']?.toString() ?? json['id']?.toString() ?? 'N/A',
      // Trim whitespace from names which might have trailing spaces
      name: (json['emp_name'] as String? ?? json['name'] as String? ?? 'Unknown').trim(),
      mobile: json['mobile'] as String?,
      designation: json['designation'] as String? ?? 'N/A',
    );
  }
}

// Represents the counts of different team roles
class TeamCounts {
  final String fa;
  final String um;
  final String bm;
  final String dc;
  final String branch;
  final String zone;

  TeamCounts({required this.fa, required this.um, required this.bm, required this.dc, required this.branch, required this.zone});

  factory TeamCounts.fromJson(Map<String, dynamic> json) {
    return TeamCounts(
      fa: json['fa'] as String? ?? '0',
      um: json['um'] as String? ?? '0',
      bm: json['bm'] as String? ?? '0',
      dc: json['dc'] as String? ?? '0',
      branch: json['branch'] as String? ?? '0',
      zone: json['zone'] as String? ?? '0',
    );
  }
}

// Represents the entire successful API response payload
class TeamApiResponse {
  final String name;
  final String id;
  final String designations;
  final TeamCounts counts;
  final List<TeamEntity> faList;
  final List<TeamEntity> umList;
  final List<TeamEntity> bmList;
  // Assuming a dclist might exist based on the 'count' object
  final List<TeamEntity> dcList;
  final List<TeamEntity> branchList;
  final List<TeamEntity> zoneList;

  TeamApiResponse({
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

  factory TeamApiResponse.fromJson(Map<String, dynamic> json) {
    // Helper to parse a list of team entities safely
    List<TeamEntity> parseTeamList(Map<String, dynamic> teamsJson, String key) {
      if (teamsJson.containsKey(key) && teamsJson[key] is List) {
        return (teamsJson[key] as List)
            .map((item) => TeamEntity.fromJson(item))
            .toList();
      }
      return []; // Return an empty list if the key is missing or not a list
    }

    final teamsData = json['teams'] as Map<String, dynamic>? ?? {};

    return TeamApiResponse(
      name: json['name'] as String? ?? 'N/A',
      id: json['id'] as String? ?? 'N/A',
      designations: json['designations'] as String? ?? 'N/A',
      counts: TeamCounts.fromJson((json['count'] as List?)?.first ?? {}),
      faList: parseTeamList(teamsData, 'falist'),
      umList: parseTeamList(teamsData, 'umlist'),
      bmList: parseTeamList(teamsData, 'bmlist'),
      dcList: parseTeamList(teamsData, 'dclist'),
      branchList: parseTeamList(teamsData, 'branchlist'),
      zoneList: parseTeamList(teamsData, 'zonelist'),
    );
  }
}

// --- 2. API Service (Unchanged) ---
class TeamApiService {
  static const String _apiUrl = "https://nliapi.nextgenitltd.com/api/teams";

  Future<TeamApiResponse> fetchTeamData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return TeamApiResponse.fromJson(jsonResponse);
        } else {
          throw Exception(jsonResponse['message'] ?? 'API returned failure but no error message.');
        }
      } else {
        throw Exception('Failed to load team data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Re-throw the exception to be handled by the FutureBuilder
      rethrow;
    }
  }
}

// --- 3. Main UI Widget ---
class TeamListPage extends StatefulWidget {
  const TeamListPage({super.key});

  @override
  State<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends State<TeamListPage> {
  late Future<TeamApiResponse> _teamDataFuture;
  TeamApiResponse? _allTeamData;
  TeamApiResponse? _filteredTeamData;

  final TeamApiService _apiService = TeamApiService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _fetchData() {
    _teamDataFuture = _apiService.fetchTeamData();
    _teamDataFuture.then((data) {
      if (mounted) {
        setState(() {
          _allTeamData = data;
          _filteredTeamData = data;
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _searchController.clear(); // Clear search on refresh
      _fetchData();
    });
  }

  void _onSearchChanged() {
    if (_allTeamData == null) return;

    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredTeamData = _allTeamData;
      });
      return;
    }

    // Filter each list based on the query
    final filteredFaList = _allTeamData!.faList.where((entity) {
      return entity.name.toLowerCase().contains(query) || entity.id.contains(query);
    }).toList();

    final filteredUmList = _allTeamData!.umList.where((entity) {
      return entity.name.toLowerCase().contains(query) || entity.id.contains(query);
    }).toList();

    final filteredBmList = _allTeamData!.bmList.where((entity) {
      return entity.name.toLowerCase().contains(query) || entity.id.contains(query);
    }).toList();

    final filteredDcList = _allTeamData!.dcList.where((entity) {
      return entity.name.toLowerCase().contains(query) || entity.id.contains(query);
    }).toList();

    setState(() {
      _filteredTeamData = TeamApiResponse(
        name: _allTeamData!.name,
        id: _allTeamData!.id,
        designations: _allTeamData!.designations,
        counts: _allTeamData!.counts, // Show original counts
        faList: filteredFaList,
        umList: filteredUmList,
        bmList: filteredBmList,
        dcList: filteredDcList,
        branchList: _allTeamData!.branchList, // Branch/Zone lists are not filtered
        zoneList: _allTeamData!.zoneList,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('My Team'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: kPrimaryDarkBlue,
        child: FutureBuilder<TeamApiResponse>(
          future: _teamDataFuture,
          builder: (context, snapshot) {
            // Loading State
            if (snapshot.connectionState == ConnectionState.waiting && _allTeamData == null) {
              return const Center(child: CircularProgressIndicator(color: kPrimaryDarkBlue));
            }

            // Error State
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            // Success State (but data might be null initially)
            if (_filteredTeamData != null) {
              final data = _filteredTeamData!;
              final bool isSearching = _searchController.text.isNotEmpty;
              final bool noResults = data.faList.isEmpty && data.umList.isEmpty && data.bmList.isEmpty && data.dcList.isEmpty && data.branchList.isEmpty && data.zoneList.isEmpty;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeaderCard(data)),
                  SliverToBoxAdapter(child: _buildTeamCountSummary(data.counts)),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  if (isSearching && noResults)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No members found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTeamExpansionTile('Financial Associates (FA)', data.faList, data.counts.fa, isSearching: isSearching),
                        _buildTeamExpansionTile('Unit Managers (UM)', data.umList, data.counts.um, isSearching: isSearching),
                        _buildTeamExpansionTile('Branch Managers (BM)', data.bmList, data.counts.bm, isSearching: isSearching),
                        _buildTeamExpansionTile('Development Chiefs (DC)', data.dcList, data.counts.dc, isSearching: isSearching),
                        _buildTeamExpansionTile('Branches', data.branchList, data.counts.branch, isSearching: isSearching, icon: Icons.store_mall_directory),
                        _buildTeamExpansionTile('Zones', data.zoneList, data.counts.zone, isSearching: isSearching, icon: Icons.travel_explore),
                      ]),
                    ),
                ],
              );
            }

            // Default empty state
            return const Center(child: Text('No data available.'));
          },
        ),
      ),
    );
  }

  // Widget for the top header card showing user info
  Widget _buildHeaderCard(TeamApiResponse data) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: kTextColorDark),
                const SizedBox(width: 8),
                Text('ID: ${data.id}', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                const Icon(Icons.star_border, size: 16, color: kTextColorDark),
                const SizedBox(width: 8),
                Text('Role: ${data.designations}', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCountSummary(TeamCounts counts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          Expanded(child: _buildCountCard('Branches', counts.branch, Icons.store_mall_directory_outlined, Colors.orange)),
          Expanded(child: _buildCountCard('Zones', counts.zone, Icons.travel_explore_outlined, Colors.purple)),
        ],
      ),
    );
  }

  Widget _buildCountCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColorDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by Name or ID...',
          prefixIcon: const Icon(Icons.search, color: kAccentBlue),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        ),
      ),
    );
  }

  // Widget for the expandable list of team members
  Widget _buildTeamExpansionTile(String title, List<TeamEntity> members, String count, {bool isSearching = false, IconData icon = Icons.people_outline}) {
    if (members.isEmpty) {
      // If there are no members, don't show the expansion tile.
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: isSearching, // Keep tiles expanded when searching
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
            count,
            style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDarkBlue),
          ),
        ),
        // Leading icon
        leading: Icon(icon, color: kAccentBlue),
        // List of members shown when expanded
        children: members.map((member) => _buildMemberTile(member)).toList(),
      ),
    );
  }

  // Widget for a single member item in the list
  Widget _buildMemberTile(TeamEntity member) {
    bool isPerson = member.designation != null && member.designation != 'N/A';

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 2),
      child: ListTile(
        onTap: isPerson ? () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => BusinessPerformancePage(
              empId: member.id, 
              designation: member.designation!, // Add '!' to assert non-null
              empName: member.name,
            )),
          );
        } : null, // Disable tap for non-person entities like branches/zones
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('ID: ${member.id}'),
        leading: CircleAvatar(
          backgroundColor: kPrimaryDarkBlue,
          foregroundColor: Colors.white,
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        trailing: (isPerson && member.mobile != null && member.mobile!.isNotEmpty)
            ? IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                tooltip: 'Call ${member.mobile}',
                onPressed: () async {
                  final Uri launchUri = Uri(
                    scheme: 'tel',
                    path: member.mobile,
                  );
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch call to ${member.mobile}')),
                    );
                  }
                },
              )
            : null,
      ),
    );
  }
}