import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// --- 1. Data Model (Unchanged) ---
class FormItem {
  final String id;
  final String title;
  final String fileUrl;

  FormItem({
    required this.id,
    required this.title,
    required this.fileUrl,
  });

  factory FormItem.fromJson(Map<String, dynamic> json) {
    // Keep 'id' in the model for filtering/tracking, but don't display it.
    return FormItem(
      id: json['id'] as String,
      title: json['title'] as String,
      fileUrl: json['file_name'] as String,
    );
  }
}

// --- 2. Main Widget (Unchanged) ---
class FormsDownloadScreen extends StatefulWidget {
  final String apiUrl = "https://nliuserapi.nextgenitltd.com/api/forms";
  const FormsDownloadScreen({super.key});

  @override
  State<FormsDownloadScreen> createState() => _FormsDownloadScreenState();
}

class _FormsDownloadScreenState extends State<FormsDownloadScreen> {
  late Future<List<FormItem>> _formsFuture;
  List<FormItem> _allForms = []; 
  List<FormItem> _filteredForms = []; 
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formsFuture = _fetchForms().then((forms) {
      _allForms = forms;
      _filteredForms = forms;
      return forms; 
    });
    _searchController.addListener(_filterForms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- 3. API Fetching Method (Unchanged) ---
  Future<List<FormItem>> _fetchForms() async {
    try {
      final response = await http.get(Uri.parse(widget.apiUrl));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
          List<dynamic> dataList = jsonResponse['data'];
          return dataList.map((json) => FormItem.fromJson(json)).toList();
        } else {
          throw Exception('API call successful but failed to parse data.');
        }
      } else {
        throw Exception('Failed to load forms. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      rethrow;
    }
  }
  
  // --- Search Filter Method (Unchanged) ---
  void _filterForms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredForms = _allForms;
      } else {
        _filteredForms = _allForms.where((form) {
          return form.title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // --- 4. Download/Open Method (Unchanged) ---
  Future<void> _launchFile(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the file at $url')),
        );
      }
    }
  }

  // --- 5. UI Structure (ListView with Gradient) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Use a standard deep blue for consistency
        backgroundColor: Colors.blue.shade800, 
        foregroundColor: Colors.white,
        title: const Text('Forms Download', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 6.0, 
      ),
      body: Column(
        children: [
          // --- Search Bar (Refined Look) ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Documents',
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterForms();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0), 
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.blue.shade50, 
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              ),
            ),
          ),
          
          // --- List View ---
          Expanded(
            child: FutureBuilder<List<FormItem>>(
              future: _formsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blue));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error fetching data: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
                    ),
                  );
                } else if (_filteredForms.isEmpty) {
                  return const Center(child: Text('No forms found matching your search.', style: TextStyle(color: Colors.grey)));
                } else {
                  return ListView.builder(
                    itemCount: _filteredForms.length,
                    itemBuilder: (context, index) {
                      final form = _filteredForms[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                        child: InkWell(
                          onTap: () => _launchFile(form.fileUrl),
                          child: Container(
                            decoration: BoxDecoration(
                              // --- Gradient Color: Richer Blue/Grey Fade ---
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade50, // Lighter start
                                  Colors.grey.shade100, // Fade to white/grey for contrast
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3), 
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                              // Updated leading icon for a document look
                              leading: const Icon(Icons.description, color: Colors.blue, size: 30), 
                              // --- Only Title Displayed (ID Removed) ---
                              title: Text(
                                form.title, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                              ),
                              // Subtitle is removed for a cleaner look
                              trailing: IconButton(
                                icon: const Icon(Icons.download_for_offline, color: Colors.blue, size: 28), // Updated download icon
                                tooltip: 'Download/View File',
                                onPressed: () => _launchFile(form.fileUrl),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}