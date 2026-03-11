import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petro_app/Screens/login.dart'; // ApiService এবং কন্সট্যান্টের জন্য

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

  // ডিফল্টভাবে গত ৭ দিনের ডাটা দেখাবে
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

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
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: kPrimaryDarkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA), // kScaffoldBackground
      body: Column(
        children: [
          _buildDateFilter(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchTransactions,
              color: kPrimaryDarkBlue,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimaryDarkBlue),
                    )
                  : _errorMessage != null
                  ? _buildErrorView()
                  : _transactions.isEmpty
                  ? _buildEmptyView()
                  : _buildTransactionList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDateColumn("From", _fromDate, true),
          const Icon(Icons.swap_horiz, color: Colors.grey),
          _buildDateColumn("To", _toDate, false),
        ],
      ),
    );
  }

  Widget _buildDateColumn(String label, DateTime date, bool isFrom) {
    return InkWell(
      onTap: () => _selectDate(context, isFrom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                size: 16,
                color: kPrimaryDarkBlue,
              ),
              const SizedBox(width: 5),
              Text(
                DateFormat('dd MMM, yyyy').format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final createdAt = DateTime.parse(tx['created_at']);
        final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
        final type = tx['type'].toString().replaceAll('_', ' ').toUpperCase();
        final isDebit = tx['type'] == 'fuel_purchase';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isDebit ? Colors.red[50] : Colors.green[50],
                child: Icon(
                  isDebit
                      ? Icons.local_gas_station
                      : Icons.account_balance_wallet,
                  color: isDebit ? Colors.red : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yy hh:mm a').format(createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? '-' : '+'} ৳${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDebit ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(tx['status']),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isSuccess = status.toLowerCase() == 'success';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSuccess ? Colors.green[800] : Colors.orange[800],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 10),
          const Text(
            "No transactions found for this period",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 10),
          Text(_errorMessage ?? "An error occurred"),
          TextButton(onPressed: _fetchTransactions, child: const Text("Retry")),
        ],
      ),
    );
  }
}
