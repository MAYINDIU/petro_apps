import 'package:petro_app/api_config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:petro_app/Screens/login.dart'; // ApiService এবং কন্সট্যান্টের জন্য
import 'package:petro_app/widgets/fuel_animations.dart';
import 'package:petro_app/widgets/page_widgets.dart';

class DriverTransactionHistoryScreen extends StatefulWidget {
  const DriverTransactionHistoryScreen({super.key});

  @override
  State<DriverTransactionHistoryScreen> createState() =>
      _DriverTransactionHistoryScreenState();
}

class _DriverTransactionHistoryScreenState
    extends State<DriverTransactionHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ডিফল্টভাবে গত ৩০ দিনের ডাটা দেখাবে
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  final NumberFormat _money = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final from = DateFormat('yyyy-MM-dd').format(_fromDate);
      final to = DateFormat('yyyy-MM-dd').format(_toDate);

      final response = await _apiService.getDriverTransactions(
        fromDate: from,
        toDate: to,
      );

      if (mounted) {
        setState(() {
          if (response['success'] == true && response['data'] != null) {
            _transactions = response['data']['transactions'] ?? [];
          } else {
            _errorMessage =
                response['message'] ?? 'Failed to load transactions.';
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

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: isFromDate ? DateTime(2020) : _fromDate,
      lastDate: isFromDate ? _toDate : DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimaryDarkBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _fetchTransactions();
    }
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    // Safe parsing for meta field which might be a JSON string or a Map
    Map<String, dynamic> meta = {};
    if (tx['meta'] != null) {
      if (tx['meta'] is String) {
        try {
          meta = jsonDecode(tx['meta']);
        } catch (e) {
          debugPrint("Error decoding meta JSON: $e");
        }
      } else if (tx['meta'] is Map) {
        meta = Map<String, dynamic>.from(tx['meta']);
      }
    }

    final createdAt = DateTime.parse(tx['created_at']);
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final isDebit = tx['type'] == 'fuel_purchase';
    final accent = isDebit ? kFuelOrange : const Color(0xFF10B981);

    // Base URL for images stored on the server
    const String imageBaseUrl = ApiConfig.storageUrl;
    String? photoPath = meta['meter_photo_path']?.toString();

    // Sanitize photo path (remove leading slash if present to avoid double slashes)
    if (photoPath != null && photoPath.startsWith('/')) {
      photoPath = photoPath.substring(1);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kPageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Amount hero
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [accent.withOpacity(0.8), accent],
                            ),
                          ),
                          child: Icon(
                            isDebit
                                ? Icons.local_gas_station_rounded
                                : Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${isDebit ? '-' : '+'} ৳ ${_money.format(amount)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDebit ? kTextColorDark : accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tx['type']
                              .toString()
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: kHintColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FuelStatusBadge(tx['status'].toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FuelSectionCard(
                    title: 'Details',
                    icon: Icons.receipt_long_rounded,
                    child: Column(
                      children: [
                        FuelInfoRow(
                          icon: Icons.event_rounded,
                          label: 'Date',
                          value: DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(createdAt),
                        ),
                        FuelInfoRow(
                          icon: Icons.water_drop_outlined,
                          label: 'Liters',
                          value: '${meta['liters'] ?? 'N/A'} L',
                        ),
                        FuelInfoRow(
                          icon: Icons.speed_rounded,
                          label: 'Meter Reading',
                          value: '${meta['meter_reading'] ?? 'N/A'}',
                        ),
                        FuelInfoRow(
                          icon: Icons.sticky_note_2_outlined,
                          label: 'Note',
                          value: '${meta['note'] ?? 'No note provided'}',
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  if (photoPath != null && photoPath.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    FuelSectionCard(
                      title: 'Meter Photo',
                      icon: Icons.photo_camera_rounded,
                      padding: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            imageBaseUrl + photoPath,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _photoPlaceholder(),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: kFuelBlue,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, size: 40, color: kHintColor),
          SizedBox(height: 6),
          Text(
            'Photo not available',
            style: TextStyle(color: kHintColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBackground,
      body: RefreshIndicator(
        onRefresh: _fetchTransactions,
        color: kPrimaryDarkBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FuelPageHeader(
                title: 'Transaction History',
                subtitle: 'Your cashless fuel payments',
                watermark: Icons.receipt_long_rounded,
                child: Column(
                  children: [
                    _buildDateFilter(),
                    if (!_isLoading &&
                        _errorMessage == null &&
                        _transactions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildSummary(),
                    ],
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: FuelLoadingView(message: 'Loading transactions...'),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FuelStateView.error(
                  message: _errorMessage,
                  onRetry: _fetchTransactions,
                ),
              )
            else if (_transactions.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: FuelStateView(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'No transactions yet',
                  message: 'No transactions found for this period',
                  color: kFuelBlue,
                ),
              )
            else
              _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Row(
      children: [
        Expanded(child: _buildDateColumn("From", _fromDate, true)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white.withOpacity(0.7),
            size: 18,
          ),
        ),
        Expanded(child: _buildDateColumn("To", _toDate, false)),
      ],
    );
  }

  Widget _buildDateColumn(String label, DateTime date, bool isFrom) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _selectDate(context, isFrom),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: kFuelAmber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM, yyyy').format(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Count and total fuel spend for the loaded period.
  Widget _buildSummary() {
    final spent = _transactions
        .where((tx) => tx['type'] == 'fuel_purchase')
        .fold<double>(
          0,
          (sum, tx) => sum + (double.tryParse(tx['amount'].toString()) ?? 0),
        );
    Widget item(IconData icon, String label, String value) => Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: kFuelAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          item(
            Icons.receipt_rounded,
            'Transactions',
            '${_transactions.length}',
          ),
          item(
            Icons.local_gas_station_rounded,
            'Fuel spent',
            '৳ ${_money.format(spent)}',
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, dd MMM yyyy').format(date);
  }

  Widget _buildTransactionList() {
    // Flatten into day headers + transactions, preserving API order.
    final rows = <Object>[];
    String? lastDay;
    for (final tx in _transactions) {
      final label = _dayLabel(DateTime.parse(tx['created_at']));
      if (label != lastDay) {
        rows.add(label);
        lastDay = label;
      }
      rows.add(tx);
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is String) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(
                row,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kHintColor,
                ),
              ),
            );
          }
          return _buildTransactionCard(row as Map<String, dynamic>, index);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, int index) {
    final createdAt = DateTime.parse(tx['created_at']);
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final type = tx['type'].toString().replaceAll('_', ' ').toUpperCase();
    final isDebit = tx['type'] == 'fuel_purchase';
    final accent = isDebit ? kFuelOrange : const Color(0xFF10B981);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index.clamp(0, 10) * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 20),
        child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showTransactionDetails(tx),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isDebit
                          ? Icons.local_gas_station_rounded
                          : Icons.account_balance_wallet_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: kTextColorDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: kHintColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('hh:mm a').format(createdAt),
                              style: const TextStyle(
                                color: kHintColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isDebit ? '-' : '+'} ৳${_money.format(amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isDebit ? kTextColorDark : accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FuelStatusBadge(tx['status'].toString()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
