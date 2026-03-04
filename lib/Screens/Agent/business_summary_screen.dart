import 'package:flutter/material.dart';
import 'package:petro_app/Screens/Agent/zone_business_yearly_by_zone_name_screen.dart';
import 'package:petro_app/Screens/Agent/zone_business_top_first_year_screen.dart';
import 'package:petro_app/Screens/Agent/zone_business_monthly_top_first_year_screen.dart';
import 'package:petro_app/Screens/Agent/area_business_yearly_by_area_name_screen.dart';
import 'package:petro_app/Screens/Agent/area_business_yearly_top_first_year_screen.dart';
import 'package:petro_app/Screens/Agent/area_business_monthly_top_first_year_screen.dart';
import 'package:petro_app/Screens/Agent/total_business_upto_date_monthly_screen.dart';
import 'package:petro_app/Screens/Agent/total_business_upto_date_screen.dart';
import 'package:petro_app/Screens/Agent/total_business_yearly_screen.dart';

// --- Constants (re-used for consistency) ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorDark = Color(0xFF1F2937);

class BusinessSummaryScreen extends StatelessWidget {
  const BusinessSummaryScreen({super.key});

  // List of report titles as requested
  final List<String> _reportTitles = const [
    'Zone Wise Business (By Zone Name)',
    'Zone Wise Business (By Top First year)',
    'Zone Business Monthly (Top First year)',
    'Area Business Yearly (By Area Name)',
    'Area Business Yearly top First Year',
    'Area Business Monthly top First Year',
    'Total Business Upto date Monthly',
    'Total Business Upto date',
    'Total Business Yearly',
  ];

  // Helper to navigate to a placeholder screen
  void _navigateToReportScreen(BuildContext context, String title) {
    Widget destinationScreen;
    if (title == 'Zone Wise Business (By Zone Name)') {
      destinationScreen = const ZoneBusinessScreen();
    } else if (title == 'Zone Wise Business (By Top First year)') {
      destinationScreen = const ZoneBusinessTopFirstYearScreen();
    } else if (title == 'Zone Business Monthly (Top First year)') {
      destinationScreen = const ZoneBusinessMonthlyScreen();
    } else if (title == 'Area Business Yearly (By Area Name)') {
      destinationScreen = const AreaBusinessScreen();
    } else if (title == 'Area Business Yearly top First Year') {
      destinationScreen = const AreaBusinessTopFirstYearScreen();
    } else if (title == 'Area Business Monthly top First Year') {
      destinationScreen = const AreaBusinessMonthlyTopFirstYearScreen();
    } else if (title == 'Total Business Upto date Monthly') {
      destinationScreen = const TotalBusinessUptoDateMonthlyScreen();
    } else if (title == 'Total Business Upto date') {
      destinationScreen = const TotalBusinessUptodateScreen();
    } else if (title == 'Total Business Yearly') {
      destinationScreen = const TotalBusinessYearlyScreen();
    } else {
      destinationScreen = _buildPlaceholderScreen(context, title);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('Business Summary'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.2, // Adjust for better text fit
        ),
        itemCount: _reportTitles.length,
        itemBuilder: (context, index) {
          final title = _reportTitles[index];
          return _buildReportCard(context, title);
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToReportScreen(context, title),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/businesss.png', height: 40, width: 40),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextColorDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Re-usable placeholder screen
  Widget _buildPlaceholderScreen(BuildContext context, String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
      ),
      body: const Center(
        child: Text(
          'This report is under development.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
