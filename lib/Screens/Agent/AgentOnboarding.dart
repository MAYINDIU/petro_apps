import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nli_apps/Screens/Agent/video_tutorial_screen.dart';
import 'package:nli_apps/Screens/Agent/company_achievement_screen.dart';
import 'package:nli_apps/Screens/Agent/circular_screen.dart';


// Re-using constants from AgentDashboard for consistency
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kTextColorDark = Color(0xFF1F2937);

class AgentOnboardingScreen extends StatefulWidget {
  const AgentOnboardingScreen({super.key});

  @override
  State<AgentOnboardingScreen> createState() => _AgentOnboardingScreenState();
}

class _AgentOnboardingScreenState extends State<AgentOnboardingScreen> {
  String _username = 'Loading...';
  String _empId = '';
  String _designation = '';
  String _mobile = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgentInfo();
  }

  Future<void> _loadAgentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? 'Agent';
        _empId = prefs.getString('emp_id') ?? 'N/A';
        _designation = prefs.getString('designation') ?? 'N/A';
        _mobile = prefs.getString('mobile') ?? 'N/A';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('Agent Onboarding'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  Text(
                    'Resources',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextColorDark),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCards(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: kPrimaryDarkBlue.withOpacity(0.4),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryDarkBlue, kAccentBlue.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_pin_circle, size: 40, color: kPrimaryDarkBlue),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.badge_outlined, 'ID: $_empId'),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.work_outline, 'Designation: $_designation'),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.phone_android, 'Mobile: $_mobile'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCards() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildFeatureCard(icon: Icons.video_library, title: 'Video Tutorial'),
        _buildFeatureCard(icon: Icons.emoji_events, title: 'Achievement'),
        _buildFeatureCard(icon: Icons.article, title: 'Circular'),
      ],
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (title == 'Video Tutorial') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const VideoTutorialsScreen(),
              ),
            );
          } else if (title == 'Achievement') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CompanyAchievementScreen(),
              ),
            );
          } else if (title == 'Circular') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CircularScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title tapped!')),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: kPrimaryDarkBlue),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kTextColorDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}