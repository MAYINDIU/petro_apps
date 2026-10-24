import 'dart:typed_data';

import 'package:petro_app/api_config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:intl/intl.dart';
import 'package:petro_app/widgets/fuel_animations.dart';
import 'package:petro_app/widgets/page_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kTextColorDark = Color(0xFF1F2937);

class ScanResultScreen extends StatefulWidget {
  final Map<String, dynamic> scanData;

  const ScanResultScreen({super.key, required this.scanData});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _literController = TextEditingController();
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Photo bytes work on both mobile and web (dart:io File does not on web).
  Uint8List? _imageBytes;
  String _imageName = 'meter_reading.jpg';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _literController.dispose();
    _meterController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ক্যামেরা থেকে ছবি তোলার ফাংশন
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        if (pickedFile.name.isNotEmpty) _imageName = pickedFile.name;
      });
    }
  }

  // ডেটা সাবমিট করার ফাংশন (Multipart/form-data)
  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate() || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সবগুলো ফিল্ড পূরণ করুন এবং মিটারের ছবি তুলুন'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      // Safely access driver_id to prevent null exception
      final driver = widget.scanData['driver'] as Map<String, dynamic>?;
      final driverId = driver?['id'];

      if (driverId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Driver ID not found.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      dio_pkg.Dio dio = dio_pkg.Dio();

      // এপিআই রিকোয়েস্ট ডেটা (Multipart)
      dio_pkg.FormData formData = dio_pkg.FormData.fromMap({
        "driver_id": driverId,
        "amount": _amountController.text,
        "liters": _literController.text,
        "meter_reading": _meterController.text,
        "note": _noteController.text,
        "meter_photo": dio_pkg.MultipartFile.fromBytes(
          _imageBytes!,
          filename: _imageName,
        ),
      });

      final response = await dio.post(
        ApiConfig.stationFuelPurchase,
        data: formData,
        options: dio_pkg.Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
      );

      if (!mounted) return;
      // Also check for the 'success' flag from the API response
      if (response.statusCode == 200 && response.data['success'] == true) {
        _showSuccessDialog();
      } else {
        final errorMessage =
            response.data?['message'] ?? 'Submission failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } on dio_pkg.DioException catch (e) {
      if (!mounted) return;
      // Handle Dio-specific network errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network Error: ${e.message ?? "Check connection"}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Handle other unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, v, child) =>
              Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF34D399), Color(0xFF059669)],
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
        title: const Text(
          'সফল হয়েছে',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'তেল বিক্রির তথ্য সফলভাবে সংরক্ষণ করা হয়েছে।',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryDarkBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.scanData['driver'] as Map<String, dynamic>? ?? {};
    final assignment = widget.scanData['assignment'] as Map<String, dynamic>?;
    final vehicle = assignment?['vehicle'] as Map<String, dynamic>? ?? {};
    final wallet = widget.scanData['wallet'] as Map<String, dynamic>?;
    final balanceText =
        widget.scanData['balance']?.toString() ??
        wallet?['balance']?.toString() ??
        '0';
    final balance = double.tryParse(balanceText) ?? 0;
    final driverName = driver['name']?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: kPageBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            FuelPageHeader(
              title: 'Fuel Purchase',
              subtitle: 'Driver verified — enter sale details',
              child: _buildDriverCard(
                driverName,
                vehicle['plate_number']?.toString() ?? 'N/A',
                balance,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FuelSectionCard(
                      title: 'Sale details',
                      icon: Icons.local_gas_station_rounded,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: FuelTextField(
                                  controller: _amountController,
                                  label: 'AMOUNT (BDT)',
                                  hint: '0.00',
                                  icon: Icons.payments_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: _required,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FuelTextField(
                                  controller: _literController,
                                  label: 'LITERS',
                                  hint: '0.0',
                                  icon: Icons.water_drop_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: _required,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          FuelTextField(
                            controller: _meterController,
                            label: 'METER READING',
                            hint: 'e.g., 125430',
                            icon: Icons.speed_rounded,
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          FuelTextField(
                            controller: _noteController,
                            label: 'NOTE (OPTIONAL)',
                            hint: 'Anything to remember',
                            icon: Icons.sticky_note_2_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FuelSectionCard(
                      title: 'Meter photo',
                      icon: Icons.photo_camera_rounded,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildPhotoPicker(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FuelGradientButton(
                      text: 'SUBMIT PURCHASE',
                      icon: Icons.check_circle_rounded,
                      onPressed: _submitPurchase,
                      isLoading: _isSubmitting,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.isEmpty) ? 'এটি প্রয়োজন' : null;

  Widget _buildDriverCard(String name, String plate, double balance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          FuelAvatar(name: name, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_bus_rounded,
                      size: 14,
                      color: kFuelAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
              Text(
                '৳ ${NumberFormat('#,##0.00').format(balance)}',
                style: const TextStyle(
                  color: kFuelAmber,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    if (_imageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              _imageBytes!,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retake'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kPrimaryDarkBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Photo added',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: SizedBox(
          height: 170,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [kFuelAmber, kFuelOrange]),
                ),
                child: const Icon(
                  Icons.add_a_photo_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap to take meter photo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kTextColorDark,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'The pump meter must be clearly visible',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFF8FAFC));
    final paint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => false;
}
