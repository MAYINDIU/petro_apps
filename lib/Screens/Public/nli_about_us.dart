import 'package:flutter/material.dart';

// --- Theme Constants ---
const Color kPrimaryDarkBlue = Color(0xFF0D47A1); // Deep Navy/Dark Blue
const Color kAccentBlue = Color(0xFF1E88E5);      // Medium Blue for accents
const Color kTextColorDark = Colors.black87;       // Standard text color
const Color kCardColorLight = Colors.white;       // White card background
const double kCardElevation = 3.0;

// =========================================================================
// SECTION 1: DATA MODEL (NLIAboutUs Class) - UNCHANGED
// =========================================================================

/// Represents the comprehensive 'About Us' data for National Life Insurance PLC.
class NLIAboutUs {
  // --- Corporate Identity ---
  final String entityName;
  final String businessAddress;
  final String registrationNumber;
  final String tradeLicence;
  final String tin;
  final String commencingDate;
  final int numberOfBranches;

  // --- Contact Information ---
  final String phone;
  final String callCentre;
  final String fax;
  final String website;
  final String email;

  // --- Governance & Structure ---
  final List<String> sponsorDirectors;
  final String subsidiary;
  final String auditors;

  // --- Executive Leadership ---
  final String ceo;
  final String additionalManagingDirector;
  final String cfoDmd;
  final String companySecretary;

  // --- Human Capital & Resources ---
  final String employeeRange;
  final String agentRange;

  // --- Financial Performance (in Million BDT) ---
  final int premiumIncome;
  final int lifeFund;
  final int assets;
  final int investment;
  final int grossClaim;

  const NLIAboutUs({
    required this.entityName,
    required this.businessAddress,
    required this.registrationNumber,
    required this.tradeLicence,
    required this.tin,
    required this.commencingDate,
    required this.numberOfBranches,
    required this.phone,
    required this.callCentre,
    required this.fax,
    required this.website,
    required this.email,
    required this.sponsorDirectors,
    required this.subsidiary,
    required this.auditors,
    required this.ceo,
    required this.additionalManagingDirector,
    required this.cfoDmd,
    required this.companySecretary,
    required this.employeeRange,
    required this.agentRange,
    required this.premiumIncome,
    required this.lifeFund,
    required this.assets,
    required this.investment,
    required this.grossClaim,
  });

  /// Static getter to provide the single instance of the company data.
  static const NLIAboutUs companyData = NLIAboutUs(
    entityName: 'National Life Insurance PLC',
    businessAddress:
        'NLI Tower, 54-55 Kazi Nazrul Islam Avenue, Karwan Bazar, Dhaka-1215.',
    registrationNumber: 'C-13734',
    tradeLicence: 'TRAD/DNCC/035795/2022',
    tin: '460810150961',
    commencingDate: '23rd April 1985',
    numberOfBranches: 658,
    phone: '09666706050, 41010123-8',
    callCentre: '16749',
    fax: '88-02-8144237',
    website: 'www.nlibd.com',
    email: 'info@nlibd.com',
    sponsorDirectors: [
      'Venture Investment Partners Bangladesh Ltd.',
      'National Housing and Investment Ltd.',
      'Industrial and Infrastructure Development Finance Co. Ltd.',
    ],
    subsidiary: 'NLI Securities Ltd.',
    auditors: 'M/S Mahfel Huq & Co. Chartered Accountants',
    ceo: 'Md. Kazim Uddin',
    additionalManagingDirector: 'Khasru Chowdhury',
    cfoDmd: 'Probir Chandra Das,FCA',
    companySecretary: 'Md. Abdul Wahab Mian',
    employeeRange: '4,900+',
    agentRange: '50,000+',
    premiumIncome: 197490, // Million BDT
    lifeFund: 61980, // Million BDT
    assets: 68510, // Million BDT
    investment: 58440, // Million BDT
    grossClaim: 116680, // Million BDT
  );
}

// =========================================================================
// SECTION 2: FLUTTER WIDGETS (AboutUsPage, _MissionGrowthCard)
// =========================================================================

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  // --- Helper Methods ---
  
  // Builds a row for non-list key-value pairs (Dark Text)
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColorDark),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            // Justification is not usually applied to short key-value text
            child: Text(value, style: const TextStyle(fontSize: 12.0, color: kTextColorDark)),
          ),
        ],
      ),
    );
  }

  // Helper method for the Financial Performance table (Standard colors)
  Widget _buildFinancialTable(NLIAboutUs data) {
    final List<Map<String, dynamic>> financialData = [
      {'title': 'Premium Income', 'value': data.premiumIncome},
      {'title': 'Life Fund', 'value': data.lifeFund},
      {'title': 'Assets', 'value': data.assets},
      {'title': 'Investment', 'value': data.investment},
      {'title': 'Gross Claim', 'value': data.grossClaim},
    ];

    return DataTable(
      columnSpacing: 16.0,
      headingRowColor: MaterialStateProperty.all(kAccentBlue.withOpacity(0.1)), 
      
      columns: const [
        DataColumn(label: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDarkBlue))),
        DataColumn(label: Text('Amount (Mn BDT)', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)), numeric: true),
      ],
      rows: financialData
          .map(
            (item) => DataRow(cells: [
              DataCell(Text(item['title'] as String, style: const TextStyle(color: kTextColorDark))),
              DataCell(Text('${item['value']}', style: const TextStyle(color: kTextColorDark))),
            ]),
          )
          .toList(),
    );
  }

  // Generic Card builder for sections - NO BG COLOR
  Widget _buildInfoCard(BuildContext context, {required String title, required List<Widget> children, bool isTable = false}) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: kCardColorLight, // White card background (No color removed)
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kPrimaryDarkBlue, // Dark blue title
                  ),
            ),
            const Divider(color: Colors.grey, height: 20),
            // For tables, wrap content in a scrollable view
            isTable 
                ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: Column(children: children))
                : Column(children: children),
          ],
        ),
      ),
    );
  }

  // --- Widget Build Method ---

  @override
  Widget build(BuildContext context) {
    final NLIAboutUs nli = NLIAboutUs.companyData;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Subtle background tint
      appBar: AppBar(
        title: const Text('About National Life Insurance PLC', style: TextStyle(color: kCardColorLight)),
        backgroundColor: kPrimaryDarkBlue, // Dark Blue AppBar
        iconTheme: const IconThemeData(color: kCardColorLight), // White back arrow
        elevation: 8.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Header Section ---
            Center(
              child: Text(
                nli.entityName,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimaryDarkBlue),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 5),
            Center(
              child: Text('Commencing Date: ${nli.commencingDate}',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: kTextColorDark)),
            ),
            const Divider(height: 30, thickness: 1),

            // --- Mission & Growth Card ---
            const _MissionGrowthCard(),
            const SizedBox(height: 20),

            // --- Corporate Details Card ---
            _buildInfoCard(
              context,
              title: '📌 Corporate Details',
              children: [
                _buildDetailRow('Headquarters', nli.businessAddress),
                _buildDetailRow('Branches', '${nli.numberOfBranches}'),
                _buildDetailRow('Registration No.', nli.registrationNumber),
                _buildDetailRow('TIN', nli.tin),
              ],
            ),
            const SizedBox(height: 15),

            // --- Executive Leadership Card ---
            _buildInfoCard(
              context,
              title: '🧑‍💼 Executive Leadership',
              children: [
                _buildDetailRow('CEO', nli.ceo),
                _buildDetailRow('CFO & DMD', nli.cfoDmd),
                _buildDetailRow('Company Secretary', nli.companySecretary),
                _buildDetailRow('Employees/Agents', '${nli.employeeRange} / ${nli.agentRange}'),
              ],
            ),
            const SizedBox(height: 15),

            // --- Financial Performance Card ---
            _buildInfoCard(
              context,
              title: '📊 Financial Performance',
              isTable: true,
              children: [
                _buildFinancialTable(nli),
              ],
            ),
            const SizedBox(height: 15),

            // --- Contact Information Card ---
            _buildInfoCard(
              context,
              title: '📞 Contact Information',
              children: [
                _buildDetailRow('Phone/Fax', '${nli.phone}, Fax: ${nli.fax}'),
                _buildDetailRow('Email', nli.email),
                _buildDetailRow('Website', nli.website),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Widget for the Mission & Growth Statement (Justified Text) ---
class _MissionGrowthCard extends StatelessWidget {
  const _MissionGrowthCard();
  
  final String missionStatement = 
      "The company has grown & developed massively and substantially over a period of about 41 years. "
      "The company has diversified its products to match customers' needs and preferences. "
      "Currently it provides multifarious life assurance products to cater the aspirations & needs as well as religious beliefs of the clients. "
      "Benefits to the policyholder of NLI are high as they are now enjoying high level rate of policy bonus compared to other competent companies.";

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: kCardElevation * 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: kAccentBlue, // Still using Accent blue for the mission statement to make it prominent
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Our Legacy & Commitment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: kCardColorLight, // White text
              ),
            ),
            const Divider(color: Colors.white70, height: 20),
            Text(
              missionStatement,
              textAlign: TextAlign.justify, // APPLYING JUSTIFICATION HERE
              style: TextStyle(
                fontSize: 15,
                color: kCardColorLight.withOpacity(0.95), // Slightly transparent white
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// SECTION 3: EXAMPLE USAGE (Main function to run the app - uncomment to run)
// =========================================================================

/*
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NLI About Us Justified Theme',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AboutUsPage(),
    );
  }
}
*/