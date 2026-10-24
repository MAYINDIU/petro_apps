import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petro_app/Screens/login.dart'; // ApiService, kPrimaryDarkBlue, kScaffoldBackground ইত্যাদির জন্য
import 'package:petro_app/Screens/Driver/DriverQrCodeScreen.dart';
import 'package:petro_app/Screens/Driver/DriverTransactionHistoryScreen.dart';
import 'package:petro_app/widgets/dashboard_widgets.dart';
import 'package:petro_app/widgets/fuel_animations.dart';
import 'package:petro_app/widgets/page_widgets.dart';

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

  final NumberFormat _money = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _fetchWalletSummary();
  }

  Future<void> _fetchWalletSummary() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      if (_walletData == null) _isLoading = true;
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

  double _value(String key) =>
      double.tryParse(_walletData?[key]?.toString() ?? '') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final hasData = !_isLoading && _errorMessage == null && _walletData != null;

    return Scaffold(
      backgroundColor: kPageBackground,
      body: RefreshIndicator(
        onRefresh: _fetchWalletSummary,
        color: kPrimaryDarkBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FuelPageHeader(
                title: 'Wallet Summary',
                subtitle: 'Your balance and fuel spending',
                watermark: Icons.account_balance_wallet_rounded,
                child: hasData ? _buildBalanceCard(_value('balance')) : null,
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: FuelLoadingView(message: 'Loading wallet...'),
              )
            else if (!hasData)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FuelStateView.error(
                  message: _errorMessage ?? 'No data found',
                  onRetry: _fetchWalletSummary,
                ),
              )
            else
              SliverToBoxAdapter(child: _buildEnhancedContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedContent() {
    final double spendToday = _value('spend_today');
    final double spendWeek = _value('spend_week');
    final double todayShare = spendWeek > 0
        ? (spendToday / spendWeek).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionTitle('Spending insights'),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Today',
                  spendToday,
                  Icons.today_rounded,
                  kFuelOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'This Week',
                  spendWeek,
                  Icons.date_range_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FuelSectionCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_gas_station_rounded,
                      size: 18,
                      color: kFuelOrange,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Today's share of this week",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kTextColorDark,
                        ),
                      ),
                    ),
                    Text(
                      '${(todayShare * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: kFuelOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: todayShare),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(height: 12, color: const Color(0xFFF1F5F9)),
                        FractionallySizedBox(
                          widthFactor: v,
                          child: Container(
                            height: 12,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kFuelAmber, kFuelOrange],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '৳ ${_money.format(spendToday)} of ৳ ${_money.format(spendWeek)} spent this week',
                  style: const TextStyle(fontSize: 12, color: kHintColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const DashboardSectionTitle('Quick actions'),
          _buildActionItem(
            Icons.receipt_long_rounded,
            'Transaction History',
            'Check all your past fuel payments',
            const Color(0xFF8B5CF6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DriverTransactionHistoryScreen(),
              ),
            ),
          ),
          _buildActionItem(
            Icons.qr_code_2_rounded,
            'Show My QR Code',
            'Pay for fuel at the station',
            kFuelOrange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverQrCodeScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return FuelPaymentCard(
      aspectRatio: 2.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'FUEL WALLET',
                style: TextStyle(
                  color: kFuelAmber,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              const CardChip(),
            ],
          ),
          const Spacer(),
          Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: balance),
            duration: const Duration(seconds: 2),
            curve: Curves.easeOutExpo,
            builder: (context, v, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '৳ ${_money.format(v)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const FuelStatusBadge('Active', onDark: true),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    double value,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: kHintColor, fontSize: 13)),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutExpo,
            builder: (context, v, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '৳ ${_money.format(v)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: kTextColorDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.85), color]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: kHintColor),
        ),
        trailing: Icon(Icons.arrow_forward_rounded, size: 18, color: color),
      ),
    );
  }
}
