import 'package:petro_app/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petro_app/widgets/fuel_animations.dart';

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
  static const String _registerUrl = ApiConfig.register;

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

// --- Main Registration Screen (RegisterPage) ---
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RoleOption {
  final String role;
  final String title;
  final String subtitle;
  final IconData icon;
  const _RoleOption(this.role, this.title, this.subtitle, this.icon);
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  static const _roles = [
    _RoleOption(
      'bus_owner',
      'Bus Owner',
      'Pay fuel for your fleet',
      Icons.directions_bus_rounded,
    ),
    _RoleOption(
      'station',
      'Station',
      'Accept cashless payments',
      Icons.local_gas_station_rounded,
    ),
  ];

  String _selectedRole = 'bus_owner';

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _entranceController,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slideAnimation =
      Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
      );

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFuelDeepNavy,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: Colors.white.withOpacity(0.15),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: _navigateToLogin,
            ),
          ),
        ),
      ),
      body: FuelAnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildCard(),
                      ),
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

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          const FuelTankLogo(size: 96),
          const SizedBox(height: 10),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              children: [
                TextSpan(
                  text: "Join ",
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: "WMS CWallet",
                  style: TextStyle(color: kFuelAmber),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Create your account and go cashless at the pump",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "I am a...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kTextColorDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < _roles.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _buildRoleTile(_roles[i])),
              ],
            ],
          ),
          const SizedBox(height: 22),
          _GenericRegistrationForm(
            role: _selectedRole,
            roleTitle: _roles.firstWhere((r) => r.role == _selectedRole).title,
            onSuccess: _navigateToLogin,
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  "Already have an account?",
                  style: TextStyle(color: kTextColorDark, fontSize: 13),
                ),
                TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text(
                    "Login",
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
    );
  }

  Widget _buildRoleTile(_RoleOption option) {
    final selected = option.role == _selectedRole;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = option.role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kFuelBlue, kFuelCyan],
                )
              : null,
          color: selected ? null : const Color(0xFFF8FAFC),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: kFuelBlue.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white.withOpacity(0.2)
                      : kAccentBlue.withOpacity(0.1),
                ),
                child: Icon(
                  option.icon,
                  size: 28,
                  color: selected ? kFuelAmber : kPrimaryDarkBlue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : kTextColorDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              option.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white.withOpacity(0.85) : kHintColor,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Registration Form Widget (Bus Owner/Station) ---
class _GenericRegistrationForm extends StatefulWidget {
  final String role;
  final String roleTitle;
  final VoidCallback onSuccess;
  const _GenericRegistrationForm({
    required this.role,
    required this.roleTitle,
    required this.onSuccess,
  });

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

  // 0..4 based on length, digits, upper-case letters and symbols.
  int get _passwordScore {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    var score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 10) score++;
    if (RegExp(r'\d').hasMatch(p) && RegExp(r'[A-Za-z]').hasMatch(p)) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) || RegExp(r'[^A-Za-z0-9]').hasMatch(p)) {
      score++;
    }
    return score;
  }

  Widget _buildPasswordStrength() {
    final score = _passwordScore;
    const labels = ['Too short', 'Weak', 'Fair', 'Good', 'Strong'];
    const colors = [
      Colors.red,
      Colors.redAccent,
      kFuelOrange,
      kFuelAmber,
      Colors.green,
    ];
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: _passwordController.text.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i < score
                              ? colors[score]
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    labels[score],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors[score],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FuelTextField(
            controller: _nameController,
            label: widget.role == 'station'
                ? 'STATION / OWNER NAME'
                : 'FULL NAME',
            hint: widget.role == 'station'
                ? 'e.g., City Fuel Station'
                : 'e.g., John Doe',
            icon: widget.role == 'station'
                ? Icons.storefront_rounded
                : Icons.person_outline_rounded,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          FuelTextField(
            controller: _emailController,
            label: 'EMAIL ADDRESS',
            hint: 'e.g., user@example.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => (value == null || !value.contains('@'))
                ? 'Enter a valid email'
                : null,
          ),
          const SizedBox(height: 14),
          FuelTextField(
            controller: _phoneController,
            label: 'PHONE NUMBER',
            hint: 'e.g., 01712345678',
            icon: Icons.phone_iphone_rounded,
            keyboardType: TextInputType.phone,
            validator: (value) => (value == null || value.length < 11)
                ? 'Enter a valid 11-digit phone number'
                : null,
          ),
          const SizedBox(height: 14),
          FuelTextField(
            controller: _passwordController,
            label: 'PASSWORD',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: kHintColor,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) => (value == null || value.length < 6)
                ? 'Password must be at least 6 chars'
                : null,
          ),
          _buildPasswordStrength(),
          const SizedBox(height: 14),
          FuelTextField(
            controller: _confirmPasswordController,
            label: 'CONFIRM PASSWORD',
            hint: '••••••••',
            icon: Icons.lock_reset_rounded,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
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
          const SizedBox(height: 26),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: FuelGradientButton(
              key: ValueKey(widget.role),
              text: 'REGISTER AS ${widget.roleTitle.toUpperCase()}',
              icon: Icons.how_to_reg_rounded,
              onPressed: _handleRegister,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
