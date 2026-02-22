import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// NOTE: Ensure 'url_launcher' is in your pubspec.yaml file!

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  // --- Corporate Color Palette ---
  static const Color primaryBlue = Color(0xFF0D47A1); // Deep Corporate Blue
  static const Color accentCyan = Color(0xFF00ACC1); // Bright Accent Cyan
  static const Color backgroundGrey = Color(0xFFF5F5F5); // Light Page Background
  static const Color addressBgColor = Color(0xFFF0F0F0); // Light Grey Background for Address

  // Function to launch URLs (phone, email, etc.)
  Future<void> _launchUrl(String urlType, String target) async {
    Uri uri;
    // Clean the target for phone numbers
    String cleanedTarget = target.replaceAll(RegExp(r'[^0-9+]+'), ''); 
    
    if (urlType == 'tel') {
      uri = Uri(scheme: 'tel', path: cleanedTarget);
    } else if (urlType == 'mailto') {
      uri = Uri(scheme: 'mailto', path: target);
    } else {
      return;
    }
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // ignore: avoid_print
      print('Could not launch $uri');
    }
  }

  // Helper widget to build individual clickable/non-clickable detail tiles
  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    String? urlType, // 'tel' or 'mailto'
  }) {
    final bool isClickable = urlType != null;
    final bool isAddress = label == 'Address';
    
    // Custom appearance for the address tile
    if (isAddress) {
      return Container(
        color: addressBgColor, // Apply the different background color
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryBlue, size: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36.0), // Align with the text of other tiles
              child: Text(
                value,
                textAlign: TextAlign.justify, // Apply justify alignment
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Default ListTile for other details
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: primaryBlue, size: 24),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          color: isClickable ? accentCyan : Colors.black87,
          fontWeight: FontWeight.w700,
          decoration: isClickable ? TextDecoration.underline : TextDecoration.none,
          decorationColor: accentCyan,
        ),
      ),
      onTap: isClickable && value.isNotEmpty
          ? () => _launchUrl(urlType!, value)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
    );
  }

  // Helper widget for office card structure
  Widget _buildOfficeCard(String title, List<Widget> contactDetails) {
    return Card(
      elevation: 8, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Custom Header/Banner ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            decoration: const BoxDecoration(
              color: primaryBlue,
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // --- Contact Details List ---
          ...contactDetails,
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey, 
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Corporate Contact Center', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --- HEAD OFFICE CARD ---
            _buildOfficeCard(
              'Head Office',
              [
                // Address - Uses custom color and justification
                _buildDetailTile(
                  icon: Icons.map_rounded,
                  label: 'Address',
                  value: 'NLI Tower, 54, Kazi Nazrul Islam Avenue, Karwan Bazar, Dhaka-1215, Bangladesh',
                ),
                // Phone
                _buildDetailTile(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Main Phone Lines',
                  value: '58151271, 58151089, 58151490',
                  urlType: 'tel',
                ),
                // Hotline
                _buildDetailTile(
                  icon: Icons.support_agent_rounded,
                  label: '24/7 Hotline',
                  value: '16749 / 09666706050',
                  urlType: 'tel',
                ),
                // Fax
                _buildDetailTile(
                  icon: Icons.fax_rounded,
                  label: 'Fax',
                  value: '88-02-8144237',
                ),
                // Email
                _buildDetailTile(
                  icon: Icons.mail_rounded,
                  label: 'Email Support',
                  value: 'info@nlibd.com',
                  urlType: 'mailto',
                ),
                // Hours
                _buildDetailTile(
                  icon: Icons.access_time_filled_rounded,
                  label: 'Office Hours',
                  value: '10:00 AM – 6:00 PM',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- MOTIJHEEL OFFICE CARD ---
            _buildOfficeCard(
              'Motijheel Office',
              [
                // Address - Uses custom color and justification
                _buildDetailTile(
                  icon: Icons.map_rounded,
                  label: 'Address',
                  value: '79, Motijheel Commercial Area, Dhaka-1000, Bangladesh',
                ),
                // Phone
                _buildDetailTile(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Phone Line',
                  value: '9560241',
                  urlType: 'tel',
                ),
                // Fax
                _buildDetailTile(
                  icon: Icons.fax_rounded,
                  label: 'Fax',
                  value: '88-02-9560244',
                ),
                // Hours
                _buildDetailTile(
                  icon: Icons.access_time_filled_rounded,
                  label: 'Office Hours',
                  value: '10:00 AM – 6:00 PM',
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}