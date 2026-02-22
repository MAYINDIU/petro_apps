import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// UI Constants
const Color kPrimaryBlue = Color(0xFF2563EB);
const Color kBgGray = Color(0xFFF8FAFC);
const Color kTextDark = Color(0xFF0F172A);
const Color kTextMuted = Color(0xFF64748B);

class ChangePasswordApiService {
  Future<Map<String, dynamic>> changePassword({
    required String mobile,
    required String oldPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    
    if (token == null) {
      return {'success': false, 'message': 'User not authenticated.'};
    }

    final url = Uri.parse('https://nliuserapi.nextgenitltd.com/api/auth/change-password-new');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'mobile': mobile,          // User-provided mobile
          'oldpassword': oldPassword, // User-provided old password
          'newpassword': newPassword, // User-provided new password
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Password Updated'};
      } else {
        return {'success': false, 'message': decoded['message'] ?? 'Update Failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ChangePasswordApiService();

  // Controllers
  final _mobileController = TextEditingController(); // Added Mobile Controller
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;

  @override
  void dispose() {
    _mobileController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _showMsg(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await _apiService.changePassword(
      mobile: _mobileController.text.trim(),
      oldPassword: _oldPassController.text.trim(),
      newPassword: _newPassController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (result['success']) {
      _showMsg(result['message'], isError: false);
      Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
    } else {
      _showMsg(result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGray,
      appBar: AppBar(
        title: const Text("Security Settings"),
        backgroundColor: kBgGray,
        elevation: 0,
        foregroundColor: kTextDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.security_rounded, size: 80, color: kPrimaryBlue),
              const SizedBox(height: 16),
              const Text("Change Password", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
              const Text("Verify your identity and set a new password", 
                style: TextStyle(color: kTextMuted)),
              const SizedBox(height: 32),
              
              // Mobile Field
              _buildSimpleField(
                controller: _mobileController, 
                label: "Mobile Number", 
                hint: "019********", 
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Old Password Field
              _buildPasswordField(_oldPassController, "Current Password", "e.g. *******"),
              const SizedBox(height: 16),

              // New Password Field
              _buildPasswordField(_newPassController, "New Password", "e.g. ******"),
              const SizedBox(height: 16),

              // Confirm Password Field
              _buildPasswordField(_confirmPassController, "Confirm Password", "Repeat new password", isConfirm: true),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Update Password", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile Input Field Builder
  Widget _buildSimpleField({
    required TextEditingController controller, 
    required String label, 
    required String hint, 
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kPrimaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Mobile is required" : null,
    );
  }

  // Password Input Field Builder
  Widget _buildPasswordField(TextEditingController controller, String label, String hint, {bool isConfirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: _isObscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: kPrimaryBlue),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _isObscure = !_isObscure),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return "Field required";
        if (isConfirm && val != _newPassController.text) return "Passwords mismatch";
        if (!isConfirm && val.length < 6) return "Min 6 characters";
        return null;
      },
    );
  }
}