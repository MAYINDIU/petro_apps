import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import 'package:nli_apps/Screens/Public/premium_calculator_screen.dart';

const Color kPrimaryColor = Color(0xFF1E40AF);
const Color kBackgroundColor = Color(0xFFF3F4F6);
const Color kTextColor = Color(0xFF1F2937);
const Color kThemeColor = kPrimaryColor;
const Color kWhiteColor = Colors.white;

class PolicyAdvisorOne extends StatefulWidget {
  const PolicyAdvisorOne({Key? key}) : super(key: key);

  @override
  _PolicyAdvisorOneState createState() => _PolicyAdvisorOneState();
}

class _PolicyAdvisorOneState extends State<PolicyAdvisorOne> {
  bool _isLoading = true;
  List<PolicyAdvisorData> _advisorData = [];
  int _selectedValue = -1;

  @override
  void initState() {
    super.initState();
    _fetchPolicyAdvisorData('1');
  }

  Future<void> _fetchPolicyAdvisorData(String id) async {
    setState(() {
      _isLoading = true;
      _selectedValue = -1;
    });

    try {
      final response = await http.post(
        Uri.parse('https://nliuserapi.nextgenitltd.com/api/policy-advisor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          List<dynamic> data = jsonResponse['data'];
          List<PolicyAdvisorData> parsedData = data.map((e) => PolicyAdvisorData.fromJson(e)).toList();

          // Check if leaf node (product)
          if (parsedData.isNotEmpty && parsedData[0].productId != "0" && parsedData[0].productId != null && parsedData.length == 1) {
             if (mounted) {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => const PremiumCalculatorScreen(isFromPolicyAdvisor: true),
                 ),
               );
             }
             setState(() => _isLoading = false);
          } else {
            setState(() {
              _advisorData = parsedData;
              _isLoading = false;
            });
          }
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching policy advisor data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Policy Advisor", style: TextStyle(fontWeight: FontWeight.bold)).tr(),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _advisorData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text("No data available", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Styled Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
                      decoration: const BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.support_agent, size: 48, color: Colors.white),
                          const SizedBox(height: 12),
                          const Text(
                            "get-immediate",
                            style: TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ).tr(),
                          const SizedBox(height: 4.0),
                          const Text(
                            "free-consultation",
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ).tr(),
                        ],
                      ),
                    ),
                    
                    // Content List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20.0),
                        itemCount: _advisorData.length,
                        itemBuilder: (context, index) {
                          final item = _advisorData[index];
                          
                          // Display Question (First item or type Question)
                          if (index == 0 || item.titleType == 'Question') {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                              child: Text(
                                item.advisorTitleEng ?? 'N/A',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: kTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          } 
                          
                          // Display Answers as Interactive Cards
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: _selectedValue == index 
                                  ? Border.all(color: kPrimaryColor, width: 2)
                                  : Border.all(color: Colors.transparent),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  setState(() => _selectedValue = index);
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  if (!mounted) return;
                                  if (item.productId != null && item.productId != "0") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PremiumCalculatorScreen(isFromPolicyAdvisor: true),
                                      ),
                                    );
                                  } else if (item.id != null) {
                                    _fetchPolicyAdvisorData(item.id!);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _selectedValue == index ? Icons.radio_button_checked : Icons.radio_button_off,
                                        color: _selectedValue == index ? kPrimaryColor : Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          item.advisorTitleEng ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: _selectedValue == index ? kPrimaryColor : kTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class PolicyQuestionThree extends StatefulWidget {
  const PolicyQuestionThree({Key? key}) : super(key: key);

  @override
  _PolicyQuestionThreeState createState() => _PolicyQuestionThreeState();
}

class _PolicyQuestionThreeState extends State<PolicyQuestionThree> {
  List<ProfessionCategory> professionList = [
    ProfessionCategory(index: 1, label: "Business"),
    ProfessionCategory(index: 2, label: "Job Holder"),
    ProfessionCategory(index: 3, label: "Others"),
  ];
  int id = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Policy Advisor"),
        backgroundColor: kThemeColor,
        foregroundColor: kWhiteColor,
        actions: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: kWhiteColor,
              child: Text('U', style: TextStyle(color: kThemeColor)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(top: 30.0, left: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Get Immediate',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 6.0,
              ),
              const Text(
                'Free Consultation !',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Container(
                height: 315,
                width: MediaQuery.of(context).size.width - 32,
                padding: const EdgeInsets.only(
                  top: 20.0,
                ),
                decoration: BoxDecoration(
                  color: kThemeColor,
                  borderRadius: BorderRadius.circular(27.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Please specify Your Profession?',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: kWhiteColor,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),
                    ...professionList
                        .map((profession) => Container(
                              margin: const EdgeInsets.only(
                                  bottom: 10.0, left: 20.0, right: 20.0),
                              decoration: BoxDecoration(
                                  color: kWhiteColor,
                                  borderRadius: BorderRadius.circular(6.0),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.grey,
                                        blurRadius: 0.2,
                                        spreadRadius: 0.5,
                                        offset: Offset(0, .2)),
                                  ]),
                              child: RadioListTile(
                                title: Text(
                                  profession.label,
                                ),
                                value: profession.index,
                                onChanged: (val) {
                                  setState(() {
                                    id = profession.index;
                                  });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const PolicyQuestionFour()),
                                  );
                                },
                                groupValue: id,
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfessionCategory {
  String label;
  int index;
  ProfessionCategory({required this.label, required this.index});
}

class PolicyQuestionFour extends StatefulWidget {
  const PolicyQuestionFour({Key? key}) : super(key: key);

  @override
  _PolicyQuestionFourState createState() => _PolicyQuestionFourState();
}

class _PolicyQuestionFourState extends State<PolicyQuestionFour> {
  List<OptionCategory> optionList = [
    OptionCategory(index: 1, label: "Frequent Cashback"),
    OptionCategory(index: 2, label: "DPS"),
    OptionCategory(index: 3, label: "Child Protection"),
    OptionCategory(index: 4, label: "Savings & Profits"),
    OptionCategory(index: 5, label: "Micro Savings"),
    OptionCategory(index: 6, label: "Retirement Security"),
    OptionCategory(index: 7, label: "Guaranteed Bonus"),
    OptionCategory(index: 8, label: "Shariah"),
  ];
  int id = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Policy Advisor"),
        backgroundColor: kThemeColor,
        foregroundColor: kWhiteColor,
        actions: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: kWhiteColor,
              child: Text('U', style: TextStyle(color: kThemeColor)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(top: 30.0, left: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Get Immediate',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 6.0,
              ),
              const Text(
                'Free Consultation !',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Container(
                height: 670,
                width: MediaQuery.of(context).size.width - 40,
                padding: const EdgeInsets.only(
                  top: 20.0,
                ),
                decoration: BoxDecoration(
                  color: kThemeColor,
                  borderRadius: BorderRadius.circular(27.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Please specify, Why do you want to have an Insurance?',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: kWhiteColor,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),
                    ...optionList
                        .map((option) => Container(
                              margin: const EdgeInsets.only(
                                  bottom: 10.0, left: 20.0, right: 20.0),
                              decoration: BoxDecoration(
                                  color: kWhiteColor,
                                  borderRadius: BorderRadius.circular(6.0),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.grey,
                                        blurRadius: 0.2,
                                        spreadRadius: 0.5,
                                        offset: Offset(0, .2)),
                                  ]),
                              child: RadioListTile(
                                title: Text(
                                  option.label,
                                ),
                                value: option.index,
                                onChanged: (val) {
                                  setState(() {
                                    id = option.index;
                                  });
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const PremiumCalculatorScreen()));
                                },
                                groupValue: id,
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionCategory {
  String label;
  int index;
  OptionCategory({required this.label, required this.index});
}

class PolicyAdvisorData {
  final String? id;
  final String? advisorTitleBan;
  final String? advisorTitleEng;
  final String? productId;
  final String? titleType;

  PolicyAdvisorData({
    this.id,
    this.advisorTitleBan,
    this.advisorTitleEng,
    this.productId,
    this.titleType,
  });

  factory PolicyAdvisorData.fromJson(Map<String, dynamic> json) {
    // Helper to handle keys with potential trailing spaces
    dynamic getVal(String key) {
      if (json.containsKey(key)) return json[key];
      if (json.containsKey('$key ')) return json['$key '];
      return null;
    }

    return PolicyAdvisorData(
      id: getVal('id')?.toString(),
      advisorTitleBan: getVal('advisortitleban'),
      advisorTitleEng: getVal('advisortitleeng'),
      productId: getVal('productid')?.toString(),
      titleType: getVal('titletype'),
    );
  }
}