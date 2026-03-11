import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petro_app/Screens/login.dart'; // ApiService, kPrimaryDarkBlue, kScaffoldBackground ইত্যাদির জন্য

class WalletSummaryScreen extends StatefulWidget {
  const WalletSummaryScreen({super.key});

  @override
  State<WalletSummaryScreen> createState() => _WalletSummaryScreenState();
}

class _WalletSummaryScreenState extends State<WalletSummaryScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _walletData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWalletSummary();
  }

  Future<void> _fetchWalletSummary() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getDriverWalletSummary();
      if (mounted) {
        setState(() {
          if (response['success'] == true && response['data'] != null) {
            _walletData = response['data'];
          } else {
            _errorMessage = response['message'] ?? 'Failed to load summary.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Modern off-white background
      appBar: AppBar(
        title: const Text(
          'Wallet Summary',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWalletSummary,
        color: kPrimaryDarkBlue,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryDarkBlue),
              )
            : _errorMessage != null
            ? _buildErrorView()
            : _buildEnhancedContent(),
      ),
    );
  }

  Widget _buildEnhancedContent() {
    if (_walletData == null) return _buildErrorView(message: "No data found");

    // JSON থেকে ডাটা পার্স করা হচ্ছে (৳400, ৳100, ৳100)
    final double balance =
        double.tryParse(_walletData!['balance'].toString()) ?? 0.0;
    final double spendToday =
        double.tryParse(_walletData!['spend_today'].toString()) ?? 0.0;
    final double spendWeek =
        double.tryParse(_walletData!['spend_week'].toString()) ?? 0.0;

    final currencyFormat = NumberFormat.currency(
      locale: 'en_BD',
      symbol: '৳ ',
      decimalDigits: 2,
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // প্রিমিয়াম ব্যালেন্স কার্ড
          _buildBalanceCard(currencyFormat.format(balance)),

          const SizedBox(height: 30),
          const Text(
            "Spending Insights",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),

          // আজকের খরচ এবং সাপ্তাহিক খরচ পাশাপাশি
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Today",
                  currencyFormat.format(spendToday),
                  Icons.today_rounded,
                  Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  "This Week",
                  currencyFormat.format(spendWeek),
                  Icons.analytics_outlined,
                  Colors.blue.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // কুইক অ্যাকশন বাটন
          _buildActionItem(
            Icons.history_rounded,
            "Transaction History",
            "Check all your past records",
            onTap: () {
              // Navigator.push...
            },
          ),
          _buildActionItem(
            Icons.info_outline_rounded,
            "Wallet Information",
            "How your balance is calculated",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [kPrimaryDarkBlue, Color(0xFF2A3A8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryDarkBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            balance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Active Status",
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Verified",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: kPrimaryDarkBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildErrorView({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
          const SizedBox(height: 10),
          Text(message ?? _errorMessage ?? "An error occurred"),
          TextButton(
            onPressed: _fetchWalletSummary,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
