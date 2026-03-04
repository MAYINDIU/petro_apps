import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
// import 'package:petro_app/Screens/login.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Constants ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kTextColorDark = Color(0xFF1F2937);

// --- Sorting Enum ---
enum _SortOption { newestFirst, oldestFirst }

// --- Data Model (Circular) ---
class Circular {
  final String id;
  final String title;
  final String fileUrl;
  final DateTime createdAt;

  Circular({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.createdAt,
  });

  factory Circular.fromJson(Map<String, dynamic> json) {
    return Circular(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'No Title',
      fileUrl: json['file_name'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// --- API Service Class ---
class ApiService {
  Future<List<Circular>> getCirculars() async {
    const String url = "https://nliuserapi.nextgenitltd.com/api/circuler";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
          final List<dynamic> dataList = jsonResponse['data'];
          return dataList.map((json) => Circular.fromJson(json)).toList();
        } else {
          throw Exception('API response format is incorrect.');
        }
      } else {
        throw Exception(
          'Failed to load circulars. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch circulars: ${e.toString()}');
    }
  }
}

// --- UI Screen (CircularScreen) ---

class CircularScreen extends StatefulWidget {
  const CircularScreen({super.key});

  @override
  State<CircularScreen> createState() => _CircularScreenState();
}

class _CircularScreenState extends State<CircularScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Circular>> _circularsFuture;
  List<Circular> _allCirculars = [];
  List<Circular> _filteredCirculars = [];
  final TextEditingController _searchController = TextEditingController();

  _SortOption _currentSortOption = _SortOption.newestFirst;

  // New state variables for date range filtering
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _circularsFuture = _apiService.getCirculars();

    _circularsFuture.then((data) {
      if (mounted) {
        _allCirculars = data;
        _sortCirculars();
      }
    });
    _searchController.addListener(_filterCirculars);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCirculars);
    _searchController.dispose();
    super.dispose();
  }

  // --- Date Picker Logic ---

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: isStartDate ? 'Select Start Date' : 'Select End Date',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryDarkBlue,
              onPrimary: kTextColorLight,
              onSurface: kTextColorDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: kPrimaryDarkBlue),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure startDate is not after endDate
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = null;
            _showSnackbar(
              "Start date cannot be after end date. End date cleared.",
            );
          }
        } else {
          _endDate = picked;
          // Ensure endDate is not before startDate
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = null;
            _showSnackbar(
              "End date cannot be before start date. Start date cleared.",
            );
          }
        }
        _filterCirculars(); // Re-filter results after date selection
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _filterCirculars(); // Re-filter to show all results
    });
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // --- Filtering Logic (Search Box + Date Range) ---
  void _filterCirculars() {
    final query = _searchController.text.toLowerCase();

    // 1. Apply both text and date filters to the primary list
    List<Circular> tempFilteredList = _allCirculars.where((c) {
      // Date Check: circular must be on or after startDate, and on or before endDate
      final bool dateMatch =
          (_startDate == null ||
              c.createdAt.isAtSameMomentAs(_startDate!) ||
              c.createdAt.isAfter(_startDate!)) &&
          (_endDate == null ||
              c.createdAt.isAtSameMomentAs(_endDate!) ||
              c.createdAt.isBefore(
                _endDate!.add(const Duration(days: 1)),
              )); // Add 1 day to include the entire end date

      // Text Check:
      final bool textMatch = c.title.toLowerCase().contains(query);

      return dateMatch && textMatch;
    }).toList();

    // 2. Sort the newly filtered list
    _sortList(tempFilteredList);

    setState(() {
      _filteredCirculars = tempFilteredList;
    });
  }

  // --- Sorting Logic (Date) ---
  void _sortCirculars() {
    _sortList(_allCirculars); // Sort the primary list
    _filterCirculars(); // Re-filter and update the UI with the newly sorted list
  }

  // Helper function to perform the actual sort operation
  void _sortList(List<Circular> list) {
    if (_currentSortOption == _SortOption.newestFirst) {
      // Sort in descending order (Newest first)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      // Sort in ascending order (Oldest first)
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  Future<void> _launchFile(String url) async {
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File URL is missing.')));
      }
      return;
    }

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the file at $url')),
        );
      }
    }
  }

  IconData _getFileIcon(String url) {
    if (url.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.png')) {
      return Icons.image;
    }
    return Icons.article;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('Circulars'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
        actions: [
          // --- Sort Dropdown Button ---
          Theme(
            data: Theme.of(context).copyWith(canvasColor: kPrimaryDarkBlue),
            child: DropdownButton<_SortOption>(
              value: _currentSortOption,
              icon: const Icon(Icons.sort, color: kTextColorLight),
              style: const TextStyle(color: kTextColorLight),
              underline: const SizedBox(),
              onChanged: (_SortOption? newValue) {
                if (newValue != null) {
                  setState(() {
                    _currentSortOption = newValue;
                    _sortCirculars();
                  });
                }
              },
              items: const [
                DropdownMenuItem(
                  value: _SortOption.newestFirst,
                  child: Text(
                    'Newest First',
                    style: TextStyle(color: kTextColorLight),
                  ),
                ),
                DropdownMenuItem(
                  value: _SortOption.oldestFirst,
                  child: Text(
                    'Oldest First',
                    style: TextStyle(color: kTextColorLight),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- Text Search Field ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search circulars by title...',
                prefixIcon: const Icon(Icons.search, color: kPrimaryDarkBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // --- Date Filter Controls ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateButton(
                  context,
                  isStartDate: true,
                  date: _startDate,
                  label: 'Start Date',
                ),
                _buildDateButton(
                  context,
                  isStartDate: false,
                  date: _endDate,
                  label: 'End Date',
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: _clearDateFilter,
                    tooltip: 'Clear Date Filter',
                  ),
              ],
            ),
          ),

          // --- Main List View ---
          Expanded(
            child: FutureBuilder<List<Circular>>(
              future: _circularsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryDarkBlue),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (_filteredCirculars.isEmpty) {
                  final hasQuery = _searchController.text.isNotEmpty;
                  final hasDateFilter = _startDate != null || _endDate != null;

                  String message = 'No circulars found.';
                  if (hasQuery || hasDateFilter) {
                    message = 'No results found matching your criteria.';
                  }

                  return Center(child: Text(message));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  itemCount: _filteredCirculars.length,
                  itemBuilder: (context, index) {
                    final circular = _filteredCirculars[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getFileIcon(circular.fileUrl),
                          color: kAccentBlue,
                          size: 30,
                        ),
                        title: Text(
                          circular.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: kTextColorDark,
                          ),
                        ),
                        subtitle: Text(
                          'Published on: ${DateFormat.yMMMd().format(circular.createdAt)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: const Icon(
                          Icons.open_in_new,
                          color: kPrimaryDarkBlue,
                        ),
                        onTap: () => _launchFile(circular.fileUrl),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for building the date selection button
  Widget _buildDateButton(
    BuildContext context, {
    required bool isStartDate,
    DateTime? date,
    required String label,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: OutlinedButton.icon(
          onPressed: () => _selectDate(context, isStartDate: isStartDate),
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(
            date == null ? label : DateFormat.yMd().format(date),
            style: TextStyle(
              fontSize: 12,
              color: date == null ? Colors.grey[700] : kPrimaryDarkBlue,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            side: BorderSide(
              color: date == null ? Colors.grey : kPrimaryDarkBlue,
            ),
          ),
        ),
      ),
    );
  }
}
