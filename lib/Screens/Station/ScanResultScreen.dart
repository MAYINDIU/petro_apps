import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kTextColorDark = Color(0xFF1F2937);

class ScanResultScreen extends StatefulWidget {
  final Map<String, dynamic> scanData;

  const ScanResultScreen({Key? key, required this.scanData}) : super(key: key);

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _literController = TextEditingController();
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  File? _image;
  bool _isSubmitting = false;

  // ক্যামেরা থেকে ছবি তোলার ফাংশন
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  // ডেটা সাবমিট করার ফাংশন (Multipart/form-data)
  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate() || _image == null) {
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

      // এপিআই রিকোয়েস্ট ডেটা (Multipart)
      dio_pkg.FormData formData = dio_pkg.FormData.fromMap({
        "driver_id": driverId,
        "amount": _amountController.text,
        "liters": _literController.text,
        "meter_reading": _meterController.text,
        "note": _noteController.text,
        "meter_photo": await dio_pkg.MultipartFile.fromFile(
          _image!.path,
          filename: "meter_reading.jpg",
        ),
      });

      final response = await dio.post(
        "https://alhamarahomesbd.com/cashless-fuel-api/public/api/v1/station/fuel-purchase",
        data: formData,
        options: dio_pkg.Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
      );

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
      // Handle Dio-specific network errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network Error: ${e.message ?? "Check connection"}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
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
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('সফল হয়েছে'),
        content: const Text('তেল বিক্রির তথ্য সফলভাবে সংরক্ষণ করা হয়েছে।'),
        actions: [
          ElevatedButton(
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
    final balance =
        widget.scanData['balance']?.toString() ??
        wallet?['balance']?.toString() ??
        '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Purchase Form'),
        backgroundColor: kPrimaryDarkBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ড্রাইভার এবং গাড়ির তথ্য কার্ড
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person, "Driver", driver['name']),
                    _buildInfoRow(
                      Icons.directions_bus,
                      "Vehicle",
                      vehicle['plate_number'],
                    ),
                    _buildInfoRow(
                      Icons.account_balance_wallet,
                      "Balance",
                      "BDT $balance",
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ইনপুট ফর্ম
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    _amountController,
                    "Amount (BDT)",
                    Icons.money,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    _literController,
                    "Liters",
                    Icons.local_gas_station,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    _meterController,
                    "Meter Reading",
                    Icons.speed,
                    TextInputType.text,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    _noteController,
                    "Note (Optional)",
                    Icons.note,
                    TextInputType.text,
                  ),
                  const SizedBox(height: 20),

                  // মিটার ফটো সেকশন
                  const Text(
                    "Take Meter Photo",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade100,
                      ),
                      child: _image == null
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // সাবমিট বাটন
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryDarkBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit Purchase",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String? value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimaryDarkBlue),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value ?? 'N/A',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType type,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryDarkBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'এটি প্রয়োজন' : null,
    );
  }
}
