// main.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
// 💡 IMPORTANT: You must ensure this file exists and contains the PolicyDetailScreen widget.
import 'policy_detail_screen.dart'; 

const String apiUrl = 'https://nliuserapi.nextgenitltd.com/api/policy-category';

void main() {
  runApp(const PolicyCategoryApp());
}

// ... (PolicyCategory and fetchCategories unchanged) ...

class PolicyCategory {
  final String category;
  PolicyCategory(this.category); 

  factory PolicyCategory.fromJson(Map<String, dynamic> json) {
    return PolicyCategory(json['category'] as String);
  }
}

Future<List<PolicyCategory>> fetchCategories() async {
  final response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
      return (jsonResponse['data'] as List)
          .map((json) => PolicyCategory.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('API Response Error: Missing or invalid "data" key.');
    }
  } else {
    throw Exception('Failed to load categories. Status Code: ${response.statusCode}');
  }
}


class PolicyCategoryApp extends StatelessWidget {
  const PolicyCategoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Policy Categories',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PolicyCategoryScreen(),
    );
  }
}

class PolicyCategoryScreen extends StatefulWidget {
  const PolicyCategoryScreen({super.key});

  @override
  State<PolicyCategoryScreen> createState() => _PolicyCategoryScreenState();
}

class _PolicyCategoryScreenState extends State<PolicyCategoryScreen> {
  late Future<List<PolicyCategory>> _categoriesFuture;
  
  final List<String> imageNames = const [
    'child.png', 'deposit.png', 'fdr.png', 'pension.png', 'pa.png', 'si.png', 'sbb.png', 'whole_life.png'
  ];

  @override
  void initState() {
    super.initState();
    _categoriesFuture = fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Categories'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<PolicyCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center));
          } else if (snapshot.hasData) {
            final List<PolicyCategory> policyData = snapshot.data!;
            
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: policyData.length,
                itemBuilder: (context, index) {
               final int imageIndex = index >= imageNames.length ? imageNames.length - 1 : index;
        final String imagePath = "assets/images/${imageNames[imageIndex]}";
        final String title = policyData[index].category;

                  return PolicyCard(
                    imagePath: imagePath,
                    title: title,
                    onTap: () {
                      // 🚀 THE KEY CHANGE: Navigate and pass the category title
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PolicyDetailScreen(categoryTitle: title),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          } else {
            return const Center(child: Text('No categories found.'));
          }
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Define the PolicyCard Widget (Unchanged)
// -----------------------------------------------------------------------------

class PolicyCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback? onTap;

  const PolicyCard({
    super.key,
    required this.imagePath,
    required this.title,
    this.onTap,
  });

@override
Widget build(BuildContext context) {
  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // 🖼️ Focused Image/Icon Area
            SizedBox(
              width: 48,
              height: 48,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback Icon
                  return Icon(
                    Icons.policy_rounded,
                    size: 64,
                    color: Colors.teal.shade700,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Policy Title
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}