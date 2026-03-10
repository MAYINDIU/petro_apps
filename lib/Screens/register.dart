import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// NOTE: These colors are copied from your main.dart file for consistent styling
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kCardBackground = Color(0xFFFFFFFF);
const Color kTextColorDark = Color(0xFF1F2937);
const Color kHintColor = Color(0xFF9CA3AF);
const Color kTextColorLight = Color(0xFFF9FAFB);

// --- API Service for OTP Registration Flow ---
class ApiService {
  static const String _registerUrl =
      "https://alhamarahomesbd.com/cashless-fuel-api/public/api/v1/auth/register";

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    final payload = {
      "name": name,
      "email": email,
      "phone": phone,
      "password": password,
      "password_confirmation": passwordConfirmation,
      "role": role,
    };
    try {
      final response = await http.post(
        Uri.parse(_registerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": responseBody['message'] ?? "Registration successful.",
        };
      } else {
        return {
          "success": false,
          "message": responseBody['message'] ?? "Registration failed.",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: ${e.toString()}"};
    }
  }
}

// --- Main Registration Screen with Tabs (RegisterPage) ---
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  // Placeholder for navigation logic (pop back to LoginPage)
  void _navigateToLogin(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The DefaultTabController manages the state for the TabBar and TabBarView
    return DefaultTabController(
      length: 2, // Customer and Agent tabs
      child: Scaffold(
        backgroundColor: kScaffoldBackground,
        appBar: AppBar(
          title: const Text(
            'Create Account',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          // Dark Blue AppBar
          backgroundColor: kPrimaryDarkBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 4,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Header Text
                      const Text(
                        "Registration With Us",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryDarkBlue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Register as a new Bus Owner or Station Driver",
                        style: TextStyle(fontSize: 16, color: kHintColor),
                      ),
                      const SizedBox(height: 20),

                      // --- Tab Bar (Role Selector) ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: kHintColor.withOpacity(0.3),
                          ),
                        ),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            // Dark Blue Tab Indicator
                            color: kPrimaryDarkBlue,
                          ),
                          labelColor: kTextColorLight,
                          unselectedLabelColor: kTextColorDark.withOpacity(0.7),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          tabs: const [
                            Tab(text: 'Bus Owner'),
                            Tab(text: 'Station'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- Tab Content (Registration Forms) ---
                      // Adjusted height to comfortably fit all form elements
                      SizedBox(
                        height: 600,
                        child: TabBarView(
                          children: [
                            _GenericRegistrationForm(
                              role: 'bus_owner',
                              onSuccess: () => _navigateToLogin(context),
                            ),
                            _GenericRegistrationForm(
                              role: 'station',
                              onSuccess: () => _navigateToLogin(context),
                            ),
                          ],
                        ),
                      ),

                      // --- Back to Login Link ---
                      TextButton(
                        onPressed: () => _navigateToLogin(context),
                        child: const Text(
                          "Already have an account? Login here",
                          // Accent Blue Text Button
                          style: TextStyle(
                            color: kAccentBlue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Common Custom Text Field Style ---
Widget _buildCustomTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  bool obscureText = false,
  Widget? suffixIcon,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
        child: Text(
          label,
          style: TextStyle(
            color: kHintColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: kTextColorDark),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[50],
          hintText: hint,
          hintStyle: TextStyle(color: kHintColor),
          // Dark Blue prefix icon
          prefixIcon: Icon(icon, color: kPrimaryDarkBlue),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            // Dark Blue focused border
            borderSide: const BorderSide(color: kPrimaryDarkBlue, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14.0,
            horizontal: 10.0,
          ),
        ),
        validator: validator,
      ),
    ],
  );
}

// --- Common Action Button Style ---
Widget _buildActionButton({
  required String text,
  required VoidCallback onPressed,
  bool isLoading = false,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: kPrimaryDarkBlue.withOpacity(0.3),
          blurRadius: 7,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        // Dark Blue button background
        backgroundColor: kPrimaryDarkBlue,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
}

// --- Generic Registration Form Widget (Driver/Station) ---
class _GenericRegistrationForm extends StatefulWidget {
  final String role;
  final VoidCallback onSuccess;
  const _GenericRegistrationForm({required this.role, required this.onSuccess});

  @override
  _GenericRegistrationFormState createState() =>
      _GenericRegistrationFormState();
}

class _GenericRegistrationFormState extends State<_GenericRegistrationForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final ApiService _apiService = ApiService();

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackbar('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.registerUser(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        role: widget.role,
      );

      if (response['success'] == true) {
        _showSnackbar(
          response['message'] ?? 'Registration Successful!',
          isError: false,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) widget.onSuccess();
      } else {
        _showSnackbar(response['message'] ?? 'Registration failed.');
      }
    } catch (e) {
      _showSnackbar('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildCustomTextField(
              controller: _nameController,
              label: 'FULL NAME',
              hint: 'e.g., John Doe',
              icon: Icons.person_outline,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 15),
            _buildCustomTextField(
              controller: _emailController,
              label: 'EMAIL ADDRESS',
              hint: 'e.g., user@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || !value.contains('@'))
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 15),
            _buildCustomTextField(
              controller: _phoneController,
              label: 'PHONE NUMBER',
              hint: 'e.g., 01712345678',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.length < 11)
                  ? 'Enter a valid 11-digit phone number'
                  : null,
            ),
            const SizedBox(height: 15),
            _buildCustomTextField(
              controller: _passwordController,
              label: 'PASSWORD',
              hint: '********',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: kHintColor,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) => (value == null || value.length < 6)
                  ? 'Password must be at least 6 chars'
                  : null,
            ),
            const SizedBox(height: 15),
            _buildCustomTextField(
              controller: _confirmPasswordController,
              label: 'CONFIRM PASSWORD',
              hint: '********',
              icon: Icons.lock_reset,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: kHintColor,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Confirm your password'
                  : null,
            ),

            const SizedBox(height: 30),
            _buildActionButton(
              text:
                  'REGISTER AS ${widget.role.toUpperCase().replaceAll('_', ' ')}',
              onPressed: _handleRegister,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
