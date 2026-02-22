import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart'; 
// import 'package:url_launcher/url_launcher.dart'; 

// --- Dummy Replacements (Keep these for a standalone file) ---
class UserData { static String type = "USER"; } 
class UserHomeWithLogin extends StatelessWidget { const UserHomeWithLogin({super.key}); @override Widget build(BuildContext context) => const Center(child: Text('User Admin Home')); }
class HomeWithLogin extends StatelessWidget { const HomeWithLogin({super.key}); @override Widget build(BuildContext context) => const Center(child: Text('User Home')); }
// --- End Dummy Replacements ---

// --- Material Design Color/Style Constants (Customize these) ---
const Color kPrimaryColor = Color(0xFF0D47A1); // Deep Blue
const Color kPrimaryDarkBlue = Color(0xFF1976D2); 
const Color kTextColorDark = Colors.black87; 
const Color kErrorColor = Colors.redAccent;
// Alternating Card Background Colors
const Color kCardBgLight = Color(0xFFF5F5F5); // Light Gray
const Color kCardBgWhite = Colors.white; 

class TermsAndConditions extends StatefulWidget {
  final String type; 
  const TermsAndConditions({Key? key, required this.type}) : super(key: key);

  @override
  State<TermsAndConditions> createState() => _TermsAndConditionsState();
}

class _TermsAndConditionsState extends State<TermsAndConditions> {
  late Future<Map<String, dynamic>> _fetchContentFuture;
  static const String _apiUrl = 'https://nliuserapi.nextgenitltd.com/api/terms-condition';

  @override
  void initState() {
    super.initState();
    _fetchContentFuture = _fetchTermsAndConditions();
  }

  Future<Map<String, dynamic>> _fetchTermsAndConditions() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        final List<dynamic> dataList = jsonResponse['data'] ?? [];
        final contentMap = dataList.firstWhere(
          (element) => element['category'] == widget.type, 
          orElse: () => null,
        );

        if (contentMap != null) {
          return {
            'title': contentMap['title'] as String? ?? 'Policy',
            'html': contentMap['terms_condition'] as String? ?? '<h1>Content not found.</h1>'
          };
        } else {
          return {
            'title': 'Error',
            'html': '<html><body><h1>Category Not Found</h1><p>The content type ${widget.type} was not found in the server response.</p></body></html>'
          };
        }

      } else {
        throw Exception('Failed to load terms (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('API Error: $e'); 
      return {
        'title': 'Error',
        'html': '<html><body><h1>Connection Error</h1><p>Could not fetch data from the server. Check your network connection.</p></body></html>'
      };
    }
  }

  // --- Widget for showing errors and allowing retry (Material Design Focus) ---
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: kErrorColor, size: 48),
            const SizedBox(height: 16),
            Text(
              "Error Loading Content",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: kTextColorDark),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _fetchContentFuture = _fetchTermsAndConditions(); // Retry the fetch
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, 
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔑 MODIFIED FUNCTION: Splits HTML by Heading tags and returns a list of Card widgets.
  List<Widget> _buildHtmlSections(String htmlContent) {
    // 1. Split the content by any heading tag (<h2 or <h3) to create sections
    // This regex pattern splits before a heading tag, keeping the tag in the result array
    // This assumes the API content starts either with a heading or the introductory paragraph.
    final RegExp splitRegex = RegExp(r'(?=<h[23])', caseSensitive: false);
    final List<String> sections = htmlContent.split(splitRegex).where((s) => s.isNotEmpty).toList();

    // If there are no obvious heading splits, treat the whole content as one card.
    if (sections.isEmpty) {
        sections.add(htmlContent);
    }
    
    // 2. Build a Card for each section
    return sections.asMap().entries.map((entry) {
      int index = entry.key;
      String sectionHtml = entry.value;
      
      // Determine alternating background color based on section index
      final Color cardColor = index.isEven ? kCardBgWhite : kCardBgLight;
      
      // Padding and margin for consistent spacing between the new cards
      const EdgeInsets cardPadding = EdgeInsets.all(16.0);
      const EdgeInsets cardMargin = EdgeInsets.only(bottom: 12.0);

      return Padding(
        padding: cardMargin,
        child: Card(
          elevation: 2, 
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: cardPadding,
            child: Html(
              data: sectionHtml,
              // Apply styling, adjusting font size up slightly for better readability
              style: {
                // Ensure headings inside the cards are well-styled
                "h2, h3": Style(
                  color: kPrimaryDarkBlue,
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 0, bottom: 5),
                  fontSize: FontSize(18.0),
                ),
                "body": Style(
                  fontSize: FontSize(16.0), // Standard body text size
                  lineHeight: LineHeight(1.5),
                  color: kTextColorDark,
                  padding: HtmlPaddings.zero,
                  margin: Margins.zero,
                  fontFamily: 'Roboto',
                ),
                "p": Style(
                  margin: Margins.only(bottom: 10),
                ),
                "li": Style(
                    margin: Margins.only(bottom: 5),
                ),
              },
              onLinkTap: (url, attributes, element) {
                if (url != null) {
                  print('Tapped on link: $url');
                  // launchUrl(Uri.parse(url)); 
                }
              },
            ),
          ),
        ),
      );
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true; 
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryColor, 
          foregroundColor: Colors.white,
          elevation: 4, 
          leading: IconButton(
            onPressed: () => Navigator.pop(context), 
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            widget.type.replaceAll('_', ' ').toTitleCase(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ), 
          actions: [
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/images/logo.png', height: 40, errorBuilder: (c, e, s) => const Icon(Icons.info, color: Colors.white))
            )
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _fetchContentFuture,
          builder: (context, snapshot) {
            // --- 1. Loading State ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              );
            }

            // --- 2. Error State Handling ---
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final Map<String, dynamic> data = snapshot.data ?? {
                'title': 'Load Failed',
                'html': '<html><body><h1>Unknown Error</h1><p>An unexpected error occurred.</p></body></html>'
            };
            
            final String htmlContent = data['html']!;

            if (htmlContent.contains('Connection Error') || htmlContent.contains('Category Not Found')) {
                String message = htmlContent.replaceAll(RegExp(r'<[^>]*>|&.*?;'), '').trim();
                return _buildErrorState(message);
            }

            // --- 3. Success State (Render Main Title & Cards) ---
            return SingleChildScrollView( 
              padding: const EdgeInsets.all(8.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔑 NEW: Main title displayed OUTSIDE of any card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
                  
                  ),
                  // Render the list of styled Cards
                  ..._buildHtmlSections(htmlContent),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Simple extension to clean up the title (optional)
extension StringCasingExtension on String {
  String toTitleCase() => split(RegExp(r'(_|\s)'))
      .map((word) => word.isNotEmpty 
          ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' 
          : '')
      .join(' ');
}