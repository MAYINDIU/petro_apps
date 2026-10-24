import 'package:petro_app/api_config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:petro_app/Screens/Station/StationDashboard.dart';
import 'package:http/http.dart' as http;
import 'package:petro_app/Screens/Driver/DriverDashboard.dart';
import 'package:petro_app/Screens/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petro_app/widgets/fuel_animations.dart';

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
  static const String _loginUrl = ApiConfig.login;

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

    const String profileUrl = ApiConfig.driverMe;

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

    const String qrCodeUrl = ApiConfig.driverQr;

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

  Future<Map<String, dynamic>> getDriverTransactions({
    String? fromDate,
    String? toDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      return {
        "success": false,
        "message": "Authentication error: Token not found.",
      };
    }

    // Build the query parameters
    final Map<String, String> queryParams = {};
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['from'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams['to'] = toDate;
    }

    final uri = Uri.parse(
      ApiConfig.driverTransactions,
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);

      return responseBody;
    } catch (e) {
      return {"success": false, "message": "Network error: ${e.toString()}"};
    }
  }

  Future<Map<String, dynamic>> getDriverWalletSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      return {
        "success": false,
        "message": "Authentication error: Token not found.",
      };
    }

    const String walletUrl = ApiConfig.driverWallet;

    try {
      final response = await http.get(
        Uri.parse(walletUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseBody = json.decode(response.body);
      return responseBody;
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
}

// --- Simple Auth Service for SharedPreferences (Local Storage) ---
class AuthService {
  static Future<void> saveLoginData(
    Map<String, dynamic> data,
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // The response now contains a 'data' object with 'user' and 'token'.
    final user = data['user'] as Map<String, dynamic>?;
    final token = data['token'] as String?;

    if (user != null && token != null) {
      final name = user['name'] as String? ?? 'N/A';
      final email = user['email'] as String? ?? 'N/A';
      final phone = user['phone'] as String? ?? 'N/A';
      // The role from the API is the source of truth.
      final apiRole = user['role'] as String? ?? role;

      // Store critical data
      await prefs.setString('accessToken', token);
      await prefs.setString('username', name);
      await prefs.setString('email', email);
      await prefs.setString('mobile', phone); // Dashboard uses 'mobile' key

      // Store the role directly from API: station or driver
      await prefs.setString('userType', apiRole);

      debugPrint("Login data saved successfully for role: $apiRole");
    } else {
      debugPrint("Login data from API is incomplete. Cannot save session.");
    }
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
  bool _obscureLoginPass = true;
  bool _isLoading = false;

  // --- Entrance Animation ---
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

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
        // Extract role from response data, defaulting to 'driver' if undefined
        final user = data['user'] as Map<String, dynamic>?;
        final String role = user?['role'] ?? 'driver';

        await AuthService.saveLoginData(data, role);
        _showSnackbar("Login successful! Redirecting...");

        // 3. Go to Customer Dashboard
        if (mounted) {
          if (role == 'station') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const StationDashboard()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DriverDashboard()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFuelDeepNavy,
      body: FuelAnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    _buildHero(),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildLoginForm(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Secured cashless fuel payment",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Hero: animated fuel tank gauge + brand ---
  Widget _buildHero() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          const FuelTankLogo(size: 150),
          const SizedBox(height: 14),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              children: [
                TextSpan(
                  text: "WMS ",
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: "CWallet",
                  style: TextStyle(color: kFuelAmber),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Scan • Pay • Fuel up — 100% cashless",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureChip(Icons.qr_code_scanner_rounded, "QR Pay"),
              _buildFeatureChip(
                Icons.account_balance_wallet_outlined,
                "Wallet",
              ),
              _buildFeatureChip(Icons.receipt_long_outlined, "Live Receipts"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kFuelAmber),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Build Method for Login Form ---
  Widget _buildLoginForm(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kAccentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.login_rounded,
                    color: kPrimaryDarkBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kTextColorDark,
                        ),
                      ),
                      Text(
                        "Sign in as Driver or Station",
                        style: TextStyle(fontSize: 13, color: kHintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Email Field
            FuelTextField(
              controller: loginEmailCTRL,
              label: "EMAIL ADDRESS",
              hint: "e.g., user@example.com",
              icon: Icons.alternate_email_rounded,
              validator: (val) =>
                  val == null || val.isEmpty ? "Required field" : null,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password Field
            FuelTextField(
              controller: loginPasswordCTRL,
              label: "PASSWORD",
              hint: "••••••••",
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureLoginPass,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kHintColor,
                ),
                onPressed: () =>
                    setState(() => _obscureLoginPass = !_obscureLoginPass),
              ),
              validator: (val) => val == null || val.length < 5
                  ? "Password must be 5+ characters"
                  : null,
            ),
            const SizedBox(height: 28),

            // Login Button (Calls the API logic)
            FuelGradientButton(
              text: "LOGIN & FUEL UP",
              onPressed: _handleLogin,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),

            // Register Link
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(color: kTextColorDark, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Create one",
                      style: TextStyle(
                        color: kAccentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
