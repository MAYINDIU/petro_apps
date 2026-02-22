import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color kPrimaryColor = Color(0xFF1E40AF);
const Color kBackgroundColor = Color(0xFFF3F4F6);

class TrackingCodeScreen extends StatefulWidget {
  const TrackingCodeScreen({Key? key}) : super(key: key);

  @override
  State<TrackingCodeScreen> createState() => _TrackingCodeScreenState();
}

class _TrackingCodeScreenState extends State<TrackingCodeScreen> {
  final TextEditingController _trackingController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _trackingData;
  String? _errorMessage;

  Future<void> _fetchTrackingData() async {
    final code = _trackingController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a tracking code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _trackingData = null;
    });

    try {
      // Using GET method with query parameter as requested
      final uri = Uri.parse('https://nliuserapi.nextgenitltd.com/api/get-policy-advisor')
          .replace(queryParameters: {'trackingCode': code});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          setState(() {
            _trackingData = jsonResponse['data'];
          });
        } else {
          setState(() {
            _errorMessage = jsonResponse['message'] ?? 'No data found for this tracking code.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load data. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _cleanHtml(String? html) {
    if (html == null) return 'N/A';
    // Simple unescape and tag removal
    String text = html
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
    // Remove HTML tags
    return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Tracking Information'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter Tracking Code',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _trackingController,
                      decoration: InputDecoration(
                        hintText: 'e.g. NLI-eCRjNmjYjy',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _fetchTrackingData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Search'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800))),
                  ],
                ),
              ),

            // Result Data
            if (_trackingData != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          _trackingData!['plan_name'] ?? 'Plan Details',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                      const Divider(height: 30, thickness: 1),
                      _buildDetailRow('Tracking Code', _trackingData!['tracking_code']),
                      _buildDetailRow('Category', _trackingData!['category']),
                      _buildDetailRow('Project', _trackingData!['project_name']),
                      _buildDetailRow('Profession', _trackingData!['profession']),
                      _buildDetailRow('Gender', _trackingData!['gender']),
                      _buildDetailRow('Age', _trackingData!['age']),
                      _buildDetailRow('DOB', _trackingData!['dob']),
                      const Divider(),
                      _buildDetailRow('Sum Assured', 'BDT ${_trackingData!['sum_assured']}'),
                      _buildDetailRow('Term', '${_trackingData!['term']} Years'),
                      _buildDetailRow('Payment Mode', _trackingData!['payment_mode']),
                      _buildDetailRow('Total Premium', 'BDT ${_trackingData!['total_premium']}'),
                      const Divider(),
                      const Text('Maturity Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(_cleanHtml(_trackingData!['onamturitydetails'])),
                      const SizedBox(height: 10),
                      const Text('Death Assurance Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(_cleanHtml(_trackingData!['assuarancedeathdetails'])),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}