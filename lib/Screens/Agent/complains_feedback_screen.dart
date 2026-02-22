import 'dart:convert';
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

// --- Constants ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kTextColorLight = Color(0xFFFFFFFF);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorDark = Color(0xFF1F2937);
const String BASE_URL = 'https://nliapi.nextgenitltd.com/api';

// --- Core Abstractions ---
enum ResponseCode { SUCCESSFUL, FAILED, UNAUTHORIZED, NETWORK_ERROR }

class ResponseObject {
  final dynamic object; 
  final ResponseCode id;
  ResponseObject({required this.object, required this.id});
}

class BaseAPIResponse {
  final bool success;
  final String? errorMessage;
  final dynamic returnValue; 
  BaseAPIResponse({this.success = false, this.errorMessage, this.returnValue});
}

// --- 🎯 Base API Caller (Optimized and Debugged) ---
class BaseAPICaller {
  static Future<BaseAPIResponse> postRequest(
    String url,
    Map<String, dynamic> body, {
    required String token, // Token MUST be provided by the service layer
  }) async {
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      // --- DEBUG LOGGING ---
     
      
      if (response.statusCode == 401 || response.statusCode == 403) {
        return BaseAPIResponse(
          success: false,
          errorMessage: 'Session expired. Please log in again.',
        );
      }
      
      if (response.body.isEmpty) {
        final statusError = 'Server returned empty response (Code: ${response.statusCode}).';
        return BaseAPIResponse(
          success: false,
          errorMessage: statusError,
        );
      }
      
      // Safely attempt JSON decoding (crucial .trim() fix included)
      final jsonResponse;
      try {
        jsonResponse = json.decode(response.body.trim()); 
      } on FormatException {
        return BaseAPIResponse(
          success: false,
          errorMessage: 'Failed to decode server response. Response not valid JSON (Code: ${response.statusCode}).',
        );
      }

      // Evaluate API Success Flag
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (jsonResponse['success'] == true || jsonResponse['success'] == 'true') {
           return BaseAPIResponse(
            success: true,
            returnValue: jsonResponse, 
          );
        } else {
          final errorMsg = jsonResponse['message'] ?? 'Submission failed: Invalid data.';
          return BaseAPIResponse(
            success: false,
            errorMessage: errorMsg,
          );
        }
      } else {
        final errorMsg = jsonResponse['message'] ?? 'Server Error: Code ${response.statusCode}.';
        return BaseAPIResponse(
          success: false,
          errorMessage: errorMsg,
        );
      }
    } on TimeoutException {
       return BaseAPIResponse(
        success: false,
        errorMessage: 'Network Timeout. Please check your connection.',
      );
    } on Exception catch (e) {
      return BaseAPIResponse(
        success: false,
        errorMessage: 'A network error occurred: ${e.toString()}',
      );
    }
  }
}

// --- Data Model for API Response Message ---
class DataMsgModel {
  final String? message;
  DataMsgModel({this.message});
  factory DataMsgModel.fromJson(Map<String, dynamic> json) {
    return DataMsgModel(message: json['message'] as String?);
  }
}

// --- 💾 Conceptual Local Database Service ---
class DatabaseService {
  Future<void> saveComplainLocally(String message) async {
    // Placeholder: Add your local storage implementation here (e.g., Hive, Moor/Drift)
    debugPrint('DatabaseService: Successfully recorded complaint locally: $message');
  }
}

// --- API Service (Business Logic & Token Management) ---
class ComplainService {
  final DatabaseService _databaseService = DatabaseService();

  Future<ResponseObject> sendComplain(String message) async {
    final prefs = await SharedPreferences.getInstance();
    // 1. Get Token (Centralized retrieval from SharedPreferences)
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      return ResponseObject(
        object: 'Authentication token not found. Please log in again.', 
        id: ResponseCode.UNAUTHORIZED
      );
    }

    // 2. Call API
    final _response = await BaseAPICaller.postRequest(
      '$BASE_URL/complain',
      {"complain": message},
      token: token, 
    );

    if (_response.success) {
      // 3. Database Interaction: Save locally on successful API response
      await _databaseService.saveComplainLocally(message); 
      
      return ResponseObject(
        object: DataMsgModel.fromJson(_response.returnValue).message ?? 'Your feedback has been submitted successfully.',
        id: ResponseCode.SUCCESSFUL,
      );
    } else {
      return ResponseObject(object: _response.errorMessage, id: ResponseCode.FAILED);
    }
  }
}

// --- Screen Implementation ---
class ComplainsFeedbackScreen extends StatefulWidget {
  const ComplainsFeedbackScreen({super.key});

  @override
  State<ComplainsFeedbackScreen> createState() => _ComplainsFeedbackScreenState();
}

class _ComplainsFeedbackScreenState extends State<ComplainsFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _complainService = ComplainService();
  bool _isLoading = false;

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _complainService.sendComplain(_messageController.text);
      
      await Future.delayed(Duration.zero); 

      final isSuccess = response.id == ResponseCode.SUCCESSFUL;
      final message = response.object as String;

      _showSnackbar(message, isError: !isSuccess); 
      
      if (isSuccess) {
        _messageController.clear(); 
      }

    } catch (e) {
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- SnackBar Implementation (Dark Red Error Background) ---
  void _showSnackbar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade900 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('Complains / Feedback'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              const Text(
                'We value your feedback',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextColorDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please share any issues or suggestions you have. Your input helps us improve our services.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 32),

              // --- Text Form Field ---
              TextFormField(
                controller: _messageController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Enter your message here...',
                  labelText: 'Your Message',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kPrimaryDarkBlue, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Message cannot be empty.';
                  }
                  if (value.length < 10) {
                    return 'Please provide a more detailed message (at least 10 characters).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Submit Button (with loading indicator) ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitFeedback,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.send_rounded),
                  label: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Submit Feedback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDarkBlue,
                    foregroundColor: kTextColorLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}