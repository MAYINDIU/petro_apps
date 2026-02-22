import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 

// --- CONSTANTS ---
const Color kPrimarySeedColor = Color(0xFF1E40AF); 
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kScaffoldBackground = Color(0xFFF3F4F6); 
const Color kTextColorDark = Color(0xFF1F2937);

// --- 1. DATA MODEL (CompanyAchievement) ---
class CompanyAchievement {
  final String id;
  final String title;
  final String imageUrl;

  CompanyAchievement({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  factory CompanyAchievement.fromJson(Map<String, dynamic> json) {
    return CompanyAchievement(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'No Title',
      imageUrl: json['image'] ?? '', 
    );
  }
}

// --- 2. API SERVICE CLASS ---
class ApiService {
  final String _apiUrl = "https://nliuserapi.nextgenitltd.com/api/achivement";

  Future<List<CompanyAchievement>> getCompanyAchievements() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body); 
        
        if (jsonResponse['success'] == true && jsonResponse['data'] is List) {
          final List<dynamic> dataList = jsonResponse['data'];
          return dataList.map((json) => CompanyAchievement.fromJson(json)).toList();
        } else {
          throw Exception('API response format is incorrect or data is missing.');
        }
      } else {
        throw Exception('Failed to load achievements. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch achievements: ${e.toString()}');
    }
  }
}

// --- 3. UI SCREEN (CompanyAchievementScreen) ---

class CompanyAchievementScreen extends StatefulWidget {
  const CompanyAchievementScreen({super.key});

  @override
  State<CompanyAchievementScreen> createState() => _CompanyAchievementScreenState();
}

class _CompanyAchievementScreenState extends State<CompanyAchievementScreen> {
  late final Future<List<CompanyAchievement>> _achievementsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _achievementsFuture = _apiService.getCompanyAchievements();
  }

  void _showAchievementDetails(CompanyAchievement achievement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Achievement Details',
            textAlign: TextAlign.center,
            style: TextStyle(color: kPrimarySeedColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    achievement.imageUrl,
                    fit: BoxFit.contain,
                    height: 280, 
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        height: 280,
                        child: Center(
                            child: CircularProgressIndicator(
                                color: kPrimarySeedColor,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null)),
                      );
                    },
                    errorBuilder: (context, error, stack) {
                      return const SizedBox(
                          height: 280,
                          child: Center(
                              child: Icon(Icons.photo_library_outlined, color: Colors.grey, size: 80)));
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextColorDark),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('CLOSE', style: TextStyle(color: kPrimarySeedColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('Our Achievements 🏆'),
        backgroundColor: kPrimarySeedColor,
        foregroundColor: kTextColorLight,
        elevation: 0, 
      ),
      body: FutureBuilder<List<CompanyAchievement>>(
        future: _achievementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimarySeedColor));
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final achievements = snapshot.data!;
          
          return GridView.builder(
            padding: const EdgeInsets.all(16.0), 
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0, 
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.72, 
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _buildAchievementCard(achievement);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.grey, size: 60),
            const SizedBox(height: 16),
            const Text('Connection Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Could not fetch data. Please check your network.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _achievementsFuture = _apiService.getCompanyAchievements();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimarySeedColor, foregroundColor: kTextColorLight),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey, size: 60),
          SizedBox(height: 16),
          Text('No Achievements Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Check back later for new company achievements.'),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(CompanyAchievement achievement) {
    // *** FIXED: Reduced height slightly to create more vertical space ***
    const double imageContainerHeight = 170.0; 
    
    return Material(
      color: kTextColorLight,
      elevation: 6, 
      borderRadius: BorderRadius.circular(16), 
      child: InkWell(
        onTap: () => _showAchievementDetails(achievement),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- IMAGE CONTAINER (Fixed Height: 170.0) ---
            SizedBox(
              height: imageContainerHeight, 
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  achievement.imageUrl,
                  fit: BoxFit.cover, 
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) {
                      return child; 
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: kPrimarySeedColor,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) {
                    return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40));
                  },
                ),
              ),
            ),
            // --- TITLE AREA ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0), 
                child: Text(
                  achievement.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextColorDark), 
                  maxLines: 3, 
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}