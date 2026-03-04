import 'package:flutter/material.dart';
import 'package:petro_app/Screens/login.dart'; // Reusing styles and ApiService

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State Management
  int _currentStep = 0; // 0: Enter Phone, 1: Enter OTP, 2: Enter New Password
  bool _isLoading = false;
  String? _resetToken; // To store the token from OTP verification
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  Future<void> _handleNextStep() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_currentStep == 0) {
        // Request OTP
        final response = await _apiService.requestPasswordResetOtp(
          _phoneController.text,
        );
        if (response['success'] == true) {
          _showSnackbar(
            response['message'] ?? 'OTP sent successfully.',
            isError: false,
          );
          setState(() => _currentStep = 1);
        } else {
          _showSnackbar(response['message'] ?? 'Failed to request OTP.');
        }
      } else if (_currentStep == 1) {
        // Verify OTP
        final response = await _apiService.verifyPasswordResetOtp(
          _phoneController.text,
          _otpController.text,
        );
        final data = response['data'] as Map<String, dynamic>?;
        final accessToken = data?['accessToken'] as String?;
        if (response['success'] == true && accessToken != null) {
          _showSnackbar(response['message'] ?? 'OTP verified.', isError: false);
          setState(() {
            _resetToken = accessToken; // Store the received accessToken
            _currentStep = 2;
          });
        } else {
          _showSnackbar(
            response['message'] ?? 'Invalid OTP or verification failed.',
          );
        }
      } else if (_currentStep == 2) {
        // Update Password
        if (_resetToken == null) {
          _showSnackbar('Reset token is missing. Please start over.');
          setState(() => _currentStep = 0);
          return;
        }
        final response = await _apiService.updatePassword(
          _resetToken!,
          _passwordController.text,
        );
        if (response['success'] == true) {
          _showSnackbar(
            'Password has been reset successfully!',
            isError: false,
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.of(context).pop(); // Go back to login page
        } else {
          _showSnackbar(response['message'] ?? 'Failed to update password.');
        }
      }
    } catch (e) {
      _showSnackbar("An unexpected error occurred: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1: // OTP Step
        return Column(
          children: [
            Text(
              'An OTP has been sent to ${_phoneController.text}. Please enter it below.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildCustomTextField(
              controller: _otpController,
              label: "OTP",
              hint: "Enter 4-digit OTP",
              icon: Icons.sms_outlined,
              keyboardType: TextInputType.number,
              validator: (val) => val == null || val.length != 4
                  ? "Enter a valid 4-digit OTP"
                  : null,
            ),
          ],
        );
      case 2: // New Password Step
        return Column(
          children: [
            _buildCustomTextField(
              controller: _passwordController,
              label: "NEW PASSWORD",
              hint: "********",
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
              validator: (val) => val == null || val.length < 6
                  ? "Password must be 6+ characters"
                  : null,
            ),
            const SizedBox(height: 15),
            _buildCustomTextField(
              controller: _confirmPasswordController,
              label: "CONFIRM NEW PASSWORD",
              hint: "********",
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
              validator: (val) => val != _passwordController.text
                  ? "Passwords do not match"
                  : null,
            ),
          ],
        );
      case 0: // Phone Number Step
      default:
        return _buildCustomTextField(
          controller: _phoneController,
          label: "PHONE NUMBER",
          hint: "e.g., 01774881746",
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          validator: (val) => val == null || val.length < 11
              ? "Enter a valid phone number"
              : null,
        );
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 1:
        return 'VERIFY OTP';
      case 2:
        return 'UPDATE PASSWORD';
      default:
        return 'REQUEST OTP';
    }
  }

  String _getHeaderText() {
    switch (_currentStep) {
      case 1:
        return 'Verify Your Phone';
      case 2:
        return 'Set New Password';
      default:
        return 'Reset Your Password';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: kTextColorLight,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kCardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryDarkBlue.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_reset,
                    size: 60,
                    color: kPrimaryDarkBlue.withOpacity(0.8),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _getHeaderText(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextColorDark,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildStepContent(),
                  const SizedBox(height: 25),
                  _buildActionButton(
                    text: _getButtonText(),
                    onPressed: _handleNextStep,
                    isLoading: _isLoading,
                  ),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _currentStep = 0),
                      child: const Text(
                        "Start Over",
                        style: TextStyle(
                          color: kAccentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusing the helper widgets from login.dart for consistent UI
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kPrimaryDarkBlue),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimaryDarkBlue, width: 2.0),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryDarkBlue,
          foregroundColor: kTextColorLight,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
