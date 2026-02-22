import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Constants ---
const Color kPrimaryColor = Color(0xFF1E40AF);
const Color kWhiteColor = Colors.white;
const Color kThemeColor = Color(0xFF1E40AF);
const Color kBlackColor = Colors.black87;
const Color kGreyColor = Colors.grey;
const Color kBgColor = Color(0xFFF8FAFC);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const String _baseUrl = 'https://nliuserapi.nextgenitltd.com/api';

// --- Models ---

class ClaimTypeModel {
  final bool success;
  final List<ClaimTypeData>? data;

  ClaimTypeModel({this.success = false, this.data});

  factory ClaimTypeModel.fromJson(Map<String, dynamic> json) {
    return ClaimTypeModel(
      success: json['success'] == true,
      data: json['data'] != null
          ? (json['data'] as List).map((i) => ClaimTypeData.fromJson(i)).toList()
          : [],
    );
  }
}

class ClaimTypeData {
  final String? claimId;
  final String? claimName;

  ClaimTypeData({this.claimId, this.claimName});

  factory ClaimTypeData.fromJson(Map<String, dynamic> json) {
    return ClaimTypeData(
      claimId: json['claim_id']?.toString(),
      claimName: json['claim_name']?.toString(),
    );
  }
}

class PolicyDetailModel {
  final String? customerName;
  final String? mobile;
  final String? dataSchema;

  PolicyDetailModel({this.customerName, this.mobile, this.dataSchema});

  factory PolicyDetailModel.fromJson(Map<String, dynamic> json) {
    return PolicyDetailModel(
      customerName: json['customer_name']?.toString(),
      mobile: json['mobile']?.toString(),
      dataSchema: json['data_schema']?.toString(),
    );
  }
}

// --- Main Screen ---

class ApplyClaimPolicy extends StatefulWidget {
  final String policyNo;

  const ApplyClaimPolicy({super.key, required this.policyNo});

  @override
  State<ApplyClaimPolicy> createState() => _ApplyClaimPolicyWithLogInState();
}

class _ApplyClaimPolicyWithLogInState extends State<ApplyClaimPolicy> {
  // Controllers
  final TextEditingController _detailsController = TextEditingController();
  
  // State Variables
  bool _isLoading = false;
  List<ClaimTypeData> _claimTypes = [];
  String? _selectedClaimType; // Stores claim_name as per input logic, or ID if API requires
  String? _selectedDeathDate;
  XFile? _selectedImage;
  Uint8List? _webImageBytes;
  PolicyDetailModel? _policyDetails;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchClaimTypes(),
      _fetchPolicyDetails(),
    ]);
    setState(() => _isLoading = false);
  }

  // 1. Fetch Claim Types
  Future<void> _fetchClaimTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/claim-type'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = ClaimTypeModel.fromJson(jsonDecode(response.body));
        if (data.success && data.data != null) {
          setState(() {
            _claimTypes = data.data!;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching claim types: $e");
    }
  }

  // 2. Fetch Policy Details (to get customer name, mobile, schema)
  Future<void> _fetchPolicyDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/search-policy?policy_no=${widget.policyNo}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null && (json['data'] as List).isNotEmpty) {
          setState(() {
            _policyDetails = PolicyDetailModel.fromJson(json['data'][0]);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching policy details: $e");
    }
  }

  // 3. Submit Claim
  Future<void> _submitClaim() async {
    if (_selectedClaimType == null || _detailsController.text.isEmpty || _selectedDeathDate == null) {
      _showMsg("Please fill all mandatory fields (Type, Details, Date)");
      return;
    }

    if (_policyDetails == null) {
      _showMsg("Policy details not loaded. Cannot submit.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String documentData = '';
      if (_selectedImage != null) {
        documentData = _selectedImage!.name;
      }

      final Map<String, dynamic> body = {
        'claim_type': _selectedClaimType ?? '',
        'policy_no': widget.policyNo,
        'data_schema': _policyDetails?.dataSchema ?? '',
        'customer_name': _policyDetails?.customerName ?? '',
        'death_reason': _detailsController.text,
        'death_date': _selectedDeathDate ?? '',
        'contact_person': _policyDetails?.customerName ?? '',
        'contact_mobile': _policyDetails?.mobile ?? '',
        'document': documentData,
      };

      debugPrint("Submitting Claim Request...");

      final response = await http.post(
        Uri.parse('$_baseUrl/claim-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      debugPrint("Claim Response Code: ${response.statusCode}");
      debugPrint("Claim Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true || json['success'] == 'true') {
          _showMsg(json['message'] ?? "Claim Request Submitted Successfully");
          if (mounted) Navigator.pop(context);
        } else {
          _showMsg(json['message'] ?? "Claim Request Failed");
        }
      } else {
        debugPrint("Server Error: ${response.statusCode} - ${response.body}");
        _showMsg("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Claim Submission Exception: $e");
      _showMsg("Submission Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _webImageBytes = bytes);
      }
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground, // Using consistent background
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        iconTheme: const IconThemeData(color: kThemeColor),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kThemeColor),
        titleSpacing: 0,
        title: const Text("Apply Claim Policy"),
        actions: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('images/nli.jpg', errorBuilder: (_, __, ___) => const SizedBox()),
          )
        ],
      ),
      body: _isLoading && _claimTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Claim Type
                    const Text("Claim Type", style: TextStyle(fontWeight: FontWeight.w600, color: kThemeColor)),
                    const SizedBox(height: 10),
                    Container(
                      height: 50,
                      decoration: _boxDecoration(),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.only(right: 5, left: 20, bottom: 5),
                          border: InputBorder.none,
                        ),
                        hint: const Text("Select Claim Type", style: TextStyle(color: kBlackColor)),
                        value: _selectedClaimType,
                        items: _claimTypes.map((type) {
                          return DropdownMenuItem(
                            value: type.claimName,
                            child: Text("${type.claimId} - ${type.claimName}", style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedClaimType = val),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 24.0),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Claim Details
                    const Text("Claim Details", style: TextStyle(color: kThemeColor, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: _boxDecoration(),
                      child: TextField(
                        controller: _detailsController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: "Type claim details...",
                          enabledBorder: InputBorder.none,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Death Date
                    const Text("Date of Incident / Death", style: TextStyle(fontWeight: FontWeight.w600, color: kThemeColor)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDeathDate = DateFormat("yyyy-MM-dd").format(picked);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: _boxDecoration(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedDeathDate ?? "Select Date", style: const TextStyle(fontSize: 16)),
                            const Icon(Icons.calendar_today, color: Color(0xFFBA853A), size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload Document
                    const Text('Upload Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: kThemeColor)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white60,
                          foregroundColor: kThemeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          elevation: 0,
                        ),
                        onPressed: _showImageSourceDialog,
                        child: const Text("Upload"),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Image Preview
                    if (_selectedImage != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        child: Center(
                          child: kIsWeb
                              ? (_webImageBytes != null ? Image.memory(_webImageBytes!, fit: BoxFit.contain) : const CircularProgressIndicator())
                              : Image.file(File(_selectedImage!.path), fit: BoxFit.contain),
                        ),
                      ),
                    
                    if (_selectedImage != null)
                       Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Text("File Selected: ${_selectedImage!.name}", style: const TextStyle(color: Colors.green)),
                       ),

                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kThemeColor,
                          foregroundColor: kWhiteColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: kWhiteColor)
                            : const Text("Submit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: kWhiteColor,
      borderRadius: BorderRadius.circular(4),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          blurRadius: 1,
          spreadRadius: 1,
          offset: const Offset(0, 1),
        )
      ],
    );
  }
}
