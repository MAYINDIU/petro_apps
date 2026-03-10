import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:petro_app/Screens/Station/StationDashboard.dart';
import 'package:petro_app/Screens/forgot_password.dart';
import 'package:http/http.dart' as http;
import 'package:petro_app/Screens/Driver/DriverDashboard.dart';
import 'package:petro_app/Screens/register.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- MAIN APPLICATION SETUP ---

void main() {
  // Ensure the widget binding is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Auth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryDarkBlue,
        scaffoldBackgroundColor: kScaffoldBackground,
        appBarTheme: const AppBarTheme(
          color: kPrimaryDarkBlue,
          titleTextStyle: TextStyle(
            color: kTextColorLight,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: kTextColorLight),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: kAccentBlue),
      ),
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        // Calculate scale factor based on screen width (Standard mobile width: 375px)
        final double scale = mediaQueryData.size.width / 375.0;
        // Clamp the scale to prevent text from becoming too small or too large
        final double clampedScale = scale.clamp(0.85, 1.15);

        return MediaQuery(
          data: mediaQueryData.copyWith(textScaleFactor: clampedScale),
          child: child!,
        );
      },
      home: const LoginPage(),
    );
  }
}

// --- Custom Colors based on the New Dark Blue Theme & Gray Background ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kCardBackground = Color(0xFFFFFFFF);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kTextColorDark = Color(0xFF1F2937);
const Color kHintColor = Color(0xFF9CA3AF);

// --- Simple API Service to handle the POST request ---
class ApiService {
  static const String _loginUrl =
      "https://alhamarahomesbd.com/cashless-fuel-api/public/api/v1/auth/login";

  Future<Map<String, dynamic>> login(String email, String password) async {
    final Map<String, dynamic> payload = {"email": email, "password": password};

    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successful API response
        return responseBody;
      } else {
        // Handle non-200/201 status codes (e.g., 401, 500)
        // If the API returns a failure message in the body, use it.
        return {
          "success": false,
          "message":
              responseBody['message'] ??
              "Server error: Status code ${response.statusCode}",
          "data": null,
        };
      }
    } catch (e) {
      // Handle network or parsing errors
      return {
        "success": false,
        "message": "Network error or data processing failed: ${e.toString()}",
        "data": null,
      };
    }
  }

  Future<Map<String, dynamic>> getDriverProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      return {
        "success": false,
        "message": "Authentication error: Token not found.",
      };
    }

    const String profileUrl =
        "https://alhamarahomesbd.com/cashless-fuel-api/public/api/v1/driver/me";

    try {
      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        return {
          "success": false,
          "message":
              responseBody['message'] ?? "Failed to load driver profile.",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> getDriverQrCode() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      return {
        "success": false,
        "message": "Authentication error: Token not found.",
      };
    }

    const String qrCodeUrl =
        "https://alhamarahomesbd.com/cashless-fuel-api/public/api/v1/driver/qr";

    try {
      final response = await http.get(
        Uri.parse(qrCodeUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        return {
          "success": false,
          "message": responseBody['message'] ?? "Failed to load QR code.",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> changeAgentPassword(
    String oldPassword,
    String newPassword,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      return {
        "success": false,
        "message": "Authentication error: Token not found.",
      };
    }

    const String changePasswordUrl =
        "https://nliapi.nextgenitltd.com/api/auth/change-password";

    final Map<String, dynamic> payload = {
      "oldpassword": oldPassword,
      "newpassword": newPassword,
    };

    try {
      final response = await http.post(
        Uri.parse(changePasswordUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);

      // The success field might be boolean or string "true", handle both.
      responseBody['success'] = responseBody['success'].toString() == 'true';

      return responseBody;
    } catch (e) {
      return {"success": false, "message": "Network error: ${e.toString()}"};
    }
  }

  // --- Password Reset Flow ---
  static const String _resetBaseUrl =
      "https://nliuserapi.nextgenitltd.com/api/auth/password/reset";

  Future<Map<String, dynamic>> requestPasswordResetOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_resetBaseUrl/request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"phone": phone}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Network error: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetOtp(
    String phone,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_resetBaseUrl/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"phone": phone, "otp": otp}),
      );
      // The response body from a successful verification is expected to contain the reset token
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Network error: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> updatePassword(
    String resetToken,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_resetBaseUrl/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $resetToken',
        },
        body: json.encode({"password": password}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Network error: ${e.toString()}"};
    }
  }
}

// --- Simple Auth Service for SharedPreferences (Local Storage) ---
class AuthService {
  static Future<void> saveLoginData(
    Map<String, dynamic> data,
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Handle nested 'user' object from new API response
    final user = data['user'] as Map<String, dynamic>?;
    final token =
        data['token'] as String? ?? data['accessToken'] as String? ?? '';

    final name =
        user?['name'] ??
        data['name'] ??
        (role == 'driver' ? 'Driver' : 'Station');
    final email = user?['email'] ?? data['email'] ?? '';
    final phone = user?['phone'] ?? data['phone'] ?? '';

    // Store critical data
    await prefs.setString('accessToken', token);
    await prefs.setString('username', name);
    await prefs.setString('email', email);
    await prefs.setString('mobile', phone); // Dashboard uses 'mobile' key

    // Map to existing dashboard logic
    // driver -> USER, station -> AGENT
    final apiRole = user?['role'] ?? role;
    final userType = (apiRole == 'station') ? 'AGENT' : 'USER';
    await prefs.setString('userType', userType);

    debugPrint("Login data saved successfully for role: $role");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    // Clear other stored session data if necessary
    debugPrint("User logged out and token cleared.");
  }
}

// --- Main Login Widget (Only Login View) ---
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  AuthenticationScreenState createState() => AuthenticationScreenState();
}

class AuthenticationScreenState extends State<LoginPage>
    with TickerProviderStateMixin {
  // --- Controllers and Keys (Only Login related) ---
  final TextEditingController loginEmailCTRL = TextEditingController();
  final TextEditingController loginPasswordCTRL = TextEditingController();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();

  // --- UI State Variables (Only Login related) ---
  bool _isDriverLogin = true;
  bool _obscureLoginPass = true;
  bool _isLoading = false;

  // --- Animation Controller for the Logo ---
  late AnimationController _logoAnimationController;
  late Animation<double> _logoFadeAnimation;

  // --- Entrance Animation ---
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _logoFadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    loginEmailCTRL.dispose();
    loginPasswordCTRL.dispose();
    _logoAnimationController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // --- Handlers for Login Action ---
  void _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ApiService apiService = ApiService();

      final String email = loginEmailCTRL.text;
      final String password = loginPasswordCTRL.text;

      final Map<String, dynamic> response = await apiService.login(
        email,
        password,
      );

      final bool isSuccess = response['success'] ?? false;
      final String message = response['message'] ?? "Unknown Error";
      final Map<String, dynamic>? data =
          response['data'] as Map<String, dynamic>?;

      if (isSuccess && data != null) {
        final String role = _isDriverLogin ? 'driver' : 'station';
        await AuthService.saveLoginData(data, role);
        _showSnackbar("Login successful! Redirecting...");

        // 3. Go to Customer Dashboard
        if (mounted) {
          if (_isDriverLogin) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DriverDashboard()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const StationDashboard()),
            );
          }
        }
      } else {
        // 4. FAILED: Show error message
        _showSnackbar(message);
      }
    } catch (e) {
      _showSnackbar("An unexpected error occurred: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: message.contains('successful')
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  // --- Toggle Login Role ---
  void _toggleLoginRole(bool isDriver) {
    setState(() {
      _isDriverLogin = isDriver;
      _loginFormKey.currentState?.reset();
      loginEmailCTRL.clear();
      loginPasswordCTRL.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Professional Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryDarkBlue, kAccentBlue],
              ),
            ),
          ),
          // 2. Decorative Background Elements
          Positioned(
            top: -60,
            left: -60,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          // 3. Main Content with Entrance Animation
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildLoginForm(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Build Method for Login Form ---
  Widget _buildLoginForm(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Form(
          key: _loginFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo with Animation
              FadeTransition(
                opacity: _logoFadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.shield_moon_outlined,
                          size: 80,
                          color: kPrimaryDarkBlue.withOpacity(0.8),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kTextColorDark,
                ),
              ),
              Text(
                "Sign in as a ${_isDriverLogin ? 'Driver' : 'Station'}",
                style: const TextStyle(fontSize: 14, color: kHintColor),
              ),
              const SizedBox(height: 24),

              // Driver/Station Toggle Tabs
              _buildRoleToggle(
                isDriver: _isDriverLogin,
                onToggle: _toggleLoginRole,
              ),
              const SizedBox(height: 20),

              // Email Field
              _buildCustomTextField(
                controller: loginEmailCTRL,
                label: "EMAIL ADDRESS",
                hint: "e.g., user@example.com",
                icon: Icons.email_outlined,
                validator: (val) =>
                    val == null || val.isEmpty ? "Required field" : null,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildCustomTextField(
                controller: loginPasswordCTRL,
                label: "PASSWORD",
                hint: "********",
                icon: Icons.lock_outline,
                obscureText: _obscureLoginPass,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPass ? Icons.visibility_off : Icons.visibility,
                    color: kHintColor,
                  ),
                  onPressed: () =>
                      setState(() => _obscureLoginPass = !_obscureLoginPass),
                ),
                validator: (val) => val == null || val.length < 5
                    ? "Password must be 5+ characters"
                    : null,
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navigate to the Forgot Password screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: kAccentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button (Calls the API logic)
              _buildActionButton(
                text: "LOGIN AS ${_isDriverLogin ? 'DRIVER' : 'STATION'}",
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),

              // Register Link (Now navigates to RegisterPage)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have account?",
                    style: TextStyle(color: kTextColorDark),
                  ),
                  TextButton(
                    onPressed: () {
                      // --- NEW NAVIGATION HERE ---
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Create a new account!",
                      style: TextStyle(
                        color: kAccentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget for Role Toggle ---
  Widget _buildRoleToggle({
    required bool isDriver,
    required Function(bool) onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleItem(
              text: "Driver",
              isSelected: isDriver,
              onTap: () => onToggle(true),
            ),
          ),
          Expanded(
            child: _buildToggleItem(
              text: "Station",
              isSelected: !isDriver,
              onTap: () => onToggle(false),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for individual toggle item
  Widget _buildToggleItem({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryDarkBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : kTextColorDark.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- Helper Widget for Custom Text Fields ---
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
            fillColor: Colors.grey[100],
            hintText: hint,
            hintStyle: TextStyle(color: kHintColor),
            prefixIcon: Icon(icon, color: kPrimaryDarkBlue),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimaryDarkBlue, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
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

  // --- Helper Widget for Action Buttons ---
  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
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
          backgroundColor: kPrimaryDarkBlue,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
