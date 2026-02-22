import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

const Color kThemeColor = Color(0xFF1E40AF);
const Color kWhiteColor = Colors.white;

class AccountDeletionRequest extends StatefulWidget {
  const AccountDeletionRequest({Key? key}) : super(key: key);

  @override
  State<AccountDeletionRequest> createState() => _AccountDeletionRequestState();
}

class _AccountDeletionRequestState extends State<AccountDeletionRequest> {
  TextEditingController emailOrPhoneNumber = TextEditingController();

  void showScaffoldMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: kThemeColor),
        ),
        titleTextStyle: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: kThemeColor),
        titleSpacing: 0,
        title: const Text("Account Deletion Request").tr(),
        actions: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/logo.png',
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Enter phone number for your account deletion request",
                    style: TextStyle(
                        color: kThemeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ).tr(),
                  const SizedBox(
                    height: 16,
                  ),
                  TextField(
                    maxLines: 1,
                    controller: emailOrPhoneNumber,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Enter your phone number".tr(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: kThemeColor),
                      ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kThemeColor,
                        foregroundColor: kWhiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () {
                        if (emailOrPhoneNumber.text.isEmpty) {
                          showScaffoldMessage("Please enter your email or phone number");
                        } else {
                          showScaffoldMessage('Your account deletion request send successfully!');
                        }
                      },
                      child: Text("submit".tr()),
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
}