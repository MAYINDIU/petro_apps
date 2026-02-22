import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // For picking images/files
import 'dart:convert';
import 'dart:math'; // For min/max in age calculation
import 'package:path/path.dart' as p; // For getting file name from path
import 'package:shared_preferences/shared_preferences.dart'; // For accessing stored token
import 'package:http/http.dart' as http;
 
// --- 1. Constants and Theme Colors ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kCardBackground = Color(0xFFFFFFFF);
const Color kTextColorDark = Color(0xFF1F2937);
const Color kHintColor = Color(0xFF9CA3AF);

// --- Constants ---
const String USERAPP_URL = 'https://nliuserapi.nextgenitltd.com/api';

// --- Placeholder/Mock Implementations (from policy_search_screen.dart) ---
class LogDebugger {
  static final LogDebugger instance = LogDebugger._internal();
  LogDebugger._internal();
  void i(dynamic message) => debugPrint('[INFO]: $message');
  void e(dynamic message) => debugPrint('[ERROR]: $message');
}

enum ResponseCode { SUCCESSFUL, FAILED }

class ResponseObject {
  final dynamic object;
  final ResponseCode id;
  final String? errorMessage;
  final bool success;

  ResponseObject({required this.object, required this.id, this.errorMessage, this.success = false});
}

// Placeholder model for the file upload response
class PolicyApplicantFileUploadModel {
  final String? fileName;
  PolicyApplicantFileUploadModel({this.fileName});

  factory PolicyApplicantFileUploadModel.fromJson(Map<String, dynamic> json) {
    String? extractedName;
    if (json['fileName'] is String) {
      extractedName = json['fileName'];
    } else if (json['data'] is String) {
      extractedName = json['data'];
    } else if (json['data'] is Map) {
      extractedName = json['data']['fileName']?.toString();
    }
    return PolicyApplicantFileUploadModel(
      fileName: extractedName,
    );
  }
}

// --- API Service for Application Submission ---
class FileUploadAPIServices {
  Future<ResponseObject> applicantFileUpload(XFile image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(USERAPP_URL + "/applicantfileupload"));
      request.headers['Accept'] = 'application/json';
      request.headers['Content-Type'] = 'application/json';
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        await image.readAsBytes(),
        filename: image.name,
      ));
      http.StreamedResponse _response = await request.send();

      LogDebugger.instance.i("File upload");
      final _responseData = await _response.stream.transform(utf8.decoder).join();
      final decodedJson = json.decode(_responseData);
      LogDebugger.instance.i(decodedJson);

      if (_response.statusCode == 200 || _response.statusCode == 201) {
        LogDebugger.instance.i("Success");
        return ResponseObject(
            object: PolicyApplicantFileUploadModel.fromJson(decodedJson),
            id: ResponseCode.SUCCESSFUL, success: true);
      } else {
        LogDebugger.instance.i("Failed");
        return ResponseObject(object: decodedJson['message'] ?? "File upload failed.", id: ResponseCode.FAILED, success: false);
      }
    } catch (e) {
      LogDebugger.instance.i("Error");
      LogDebugger.instance.e(e);
      return ResponseObject(object: e.toString(), id: ResponseCode.FAILED, success: false);
    }
  }

  Future<Map<String, dynamic>> submitApplication(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse(USERAPP_URL + "/applicant/submit"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.body.isEmpty) {
        return {"success": false, "message": "Received empty response from server."};
      }
      final Map<String, dynamic> responseBody = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      } else {
        return {
          "success": false, 
          "message": responseBody['message'] ?? "Application submission failed.",
          "errors": responseBody['errors']
        };
      }
    } catch (e) {
      return {"success": false, "message": "A network error occurred: ${e.toString()}"};
    }
  }
}

// --- 2. Data Models (based on your JSON structure) ---

class Applicant {
  String applicantNameEng = '';
  String applicantNameBang = ''; // Assuming this is needed
  XFile? applicantPhotoFile; // Temporary storage for picked file
  String? applicantPhotoName; // File name after upload, for API submission
  String applicantFatherName = '';
  String applicantMotherName = '';
  String applicantSpouseName = '';
  String profession = '';
  String mobileNo = ''; // This seems redundant with ParmanentContact
  String email = 'N/A'; // Default from JSON
  String parmanentContact = ''; // From JSON
  String parmanentDistrict = ''; // From JSON
  String parmanentPoliceStation = ''; // From JSON
  String parmanentPostOffice = ''; // From JSON
  String parmanentPostCode = ''; // From JSON
  String permanentVilTown = ''; // From JSON
  String presentContact = ''; // From JSON
  String presentDistrict = ''; // From JSON
  String presentPoliceStation = ''; // From JSON
  String presentPostOffice = ''; // From JSON
  String presentPostCode = ''; // From JSON
  String presentVilTown = ''; // From JSON
  DateTime? dob;
  String gender = 'Female'; // Default from JSON
  String documentType = 'Voter ID';
  String documentID = '';
  XFile? applicantDocumentFile; // Temporary storage for picked file
  String? applicantDocumentName; // File name after upload, for API submission
  String birthPlace = ''; // From JSON
  String nationality = 'Bangladesh';
  String maritalStatus = 'Married';
  String eduQualification = ''; // From JSON

  // New fields from JSON
  String? countryCodeName;
  String bankName = '';
  String bankBranch = '';
  String bankAccount = '';
  String? currentlyWell;
  String? weightLossOrGain;
  String? longHolidayForIllness;
  String? physicalDisability;
  String? chikenPox;
  String? chikenPoxVaccin;
  String? infectiousDisease;
  String? ancestralDisease;
  String? epilepticProblem;
  String? frequentCough;
  String? stomachInfection;
  String? miltDisease;
  String? urineStone;
  String? eyeDisease;
  String? goitrousDisease;
  String? otherDisease;
  String? typesOfOperation;
  int? lien;
  int? lienTerm;
  double? monthlySalary;
  int? companyId;
}

class PolicyInfo {
  int policyId = 201; // Example from JSON
  String installmentTypeId = 'Monthly';
  int termOfYear = 5;
  double totalPolicyAmount = 60000.0;
  double premiumAmount = 1000.0;
  String policyReason = 'Savings & Security';
  int age = 0; // Populated from Applicant DOB
  String yearlyIncome = '';
  String sourceOfIncome = '';

  // New fields from JSON
  String? policyPayee;
  double? supplementryAmount;
  double? basicAmount;
  double? extraPremium;
  int? surrenderId;
  double? othersPremium;
  double? totalDeposit;
  String? prBmNo;
  String? otherPolicyNo;
  String? otherPolicyCompany;
  double? otherPolicyAmount;
  String? otherPolicyName;
  String? otherPolicyDuration;
  String? otherPolicyCondition;
  String? otherPolicyAccpDate;
  String? otherDuePolicySli;
  String? otherPolicyRejectInfo;
  String? policyRiskAdditonalFactor;
  double? ysapa;
  int? pensionAge;
  String? policyRiskCategory;
}

class Nominee {
  int nomineeSerial;
  String nomineeName = '';
  String nomineeAge = '';
  String nomineeRelation = '';
  double nomineeAllocation = 100.0; // Default from JSON
  String documentType = 'Voter ID'; // Default from JSON
  XFile? uploadDocumentFile; // Temporary storage for picked file
  String? uploadDocument; // File name after upload
  XFile? nomineePPNameFile; // Temporary storage for picked file (PPName likely means passport photo)
  String? nomineePPName; // File name after upload
  String nomineeGuardianName = '';
  String guardianAddress = '';
  String legalGuardianRelation = '';
  String legalGuardianNIDNo = '';
  XFile? legalGuardianNIDPhotoFile; // Temporary storage for picked file
  String? legalGuardianNIDPhoto; // File name after upload
  XFile? legalGuardianPhotoFile; // Temporary storage for picked file
  String? legalGuardianPhoto; // File name after upload
  Nominee({required this.nomineeSerial});
}

class FamilyMember {
  String relation;
  String lifeStatus = 'Alive';
  String age = '';
  String currentPhysicalStatus = 'Good';
  String? ageDuringDeath;
  String? deathReason;
  // New fields from JSON
  String? durationOfLastIllness;
  String? yearOfDeath;

  FamilyMember({required this.relation});
}

// --- Main Stepper Screen ---

class ApplyForPolicyScreen extends StatefulWidget {
  const ApplyForPolicyScreen({super.key});

  @override
  State<ApplyForPolicyScreen> createState() => _ApplyForPolicyScreenState();
}

class _ApplyForPolicyScreenState extends State<ApplyForPolicyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStep = 0; // This now represents the current tab index
  final int _totalSteps = 6; // Increased to 6 for the new Health tab

  // Controllers for address fields to manage copying state
  final _permDistrictController = TextEditingController();
  final _permPoliceStationController = TextEditingController();
  final _permPostOfficeController = TextEditingController();
  final _permPostCodeController = TextEditingController();
  final _permVilTownController = TextEditingController();

  final _presDistrictController = TextEditingController();
  final _presPoliceStationController = TextEditingController();
  final _presPostOfficeController = TextEditingController();
  final _presPostCodeController = TextEditingController();
  final _presVilTownController = TextEditingController();

  bool _presentAddressIsSame = false;

  final ImagePicker _picker = ImagePicker();
  // Form Keys
  final _applicantFormKey = GlobalKey<FormState>();
  final _policyFormKey = GlobalKey<FormState>();
  final _nomineeFormKey = GlobalKey<FormState>();
  final _familyHistoryFormKey = GlobalKey<FormState>();
  final _healthFormKey = GlobalKey<FormState>(); // Key for the new health form

  // Data Models
  final FileUploadAPIServices _fileUploadService = FileUploadAPIServices();
  final Applicant _applicantData = Applicant();
  final PolicyInfo _policyData = PolicyInfo();
  final List<Nominee> _nominees = [Nominee(nomineeSerial: 1)];
  final List<FamilyMember> _familyHistory = [
    FamilyMember(relation: 'Father'), // Pre-fill for common relations
    FamilyMember(relation: 'Mother'), // Pre-fill for common relations
    FamilyMember(relation: 'Brother'), // Pre-fill for common relations
    FamilyMember(relation: 'Sister'), // Pre-fill for common relations
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // --- Pre-fill with Dummy Data ---
    _applicantData
      ..applicantNameEng = "Rahima Begums"
      ..applicantNameBang = "রহিমা বেগম"
      ..applicantFatherName = "Abdul Sattar"
      ..applicantMotherName = "Samsurnahar"
      ..applicantSpouseName = "Md Abdullaha"
      ..profession = "House Wife"
      ..parmanentContact = "01812851004"
      ..mobileNo = "01812851004"
      ..email = "N/A"
      ..parmanentDistrict = "Coxs Bazar"
      ..parmanentPoliceStation = "Coxs Bazar"
      ..parmanentPostOffice = "Coxs Bazar"
      ..parmanentPostCode = "4700"
      ..permanentVilTown = "P.M Khali"
      ..presentContact = "01812851004"
      ..presentDistrict = "Coxs Bazar"
      ..presentPoliceStation = "Coxs Bazar"
      ..presentPostOffice = "Coxs Bazar"
      ..presentPostCode = "4700"
      ..presentVilTown = "P.M Khali"
      ..gender = "Female"
      ..documentType = "Voter ID"
      ..documentID = "2212471405499"
      ..birthPlace = "Coxs Bazar"
      ..nationality = "Bangladesh"
      ..eduQualification = "JSC"
      ..maritalStatus = "Married";

    _policyData
      ..policyId = 201
      ..installmentTypeId = "Monthly"
      ..termOfYear = 5
      ..policyReason = "savings & security"
      ..yearlyIncome = "180000"
      ..sourceOfIncome = "Service "
      ..policyPayee = "Self"
      ..age = 0
      ..totalPolicyAmount = 60000.0
      ..supplementryAmount = 0.0
      ..basicAmount = 1000.0
      ..extraPremium = 5550.0
      ..premiumAmount = 1000.0;

    // For simplicity, Nominee and Family History are kept as they were,
    // but you could pre-fill them in a similar fashion.

    _tabController = TabController(length: _totalSteps, vsync: this);
    _tabController.addListener(() {
      // Prevent swiping to unvisited tabs
      if (_tabController.index > _currentStep) {
        _tabController.index = _currentStep;
      }
    });
  }

  // --- Navigation Controls ---
  void _handleNext() {
    bool isStepValid = false;
    switch (_currentStep) {
      case 0:
        isStepValid = _applicantFormKey.currentState?.validate() ?? false;
        if (isStepValid) _applicantFormKey.currentState?.save();
        break;
      case 1:
        isStepValid = _policyFormKey.currentState?.validate() ?? false;
        if (isStepValid) _policyFormKey.currentState?.save();
        break;
      case 2:
        isStepValid = _nomineeFormKey.currentState?.validate() ?? false;
        if (isStepValid) _nomineeFormKey.currentState?.save();
        break;
      case 3:
        isStepValid = _familyHistoryFormKey.currentState?.validate() ?? false;
        if (isStepValid) _familyHistoryFormKey.currentState?.save();
        break;
      case 4: // New Health step
        isStepValid = _healthFormKey.currentState?.validate() ?? false;
        if (isStepValid) _healthFormKey.currentState?.save();
        break;
      case 5: // Review step
        isStepValid = true;
        break;
    }

    if (!isStepValid) {
      _showSnackbar('Please fill all required fields before continuing.');
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _tabController.animateTo(_currentStep);
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose controllers to free up resources
    _permDistrictController.dispose();
    _permPoliceStationController.dispose();
    _permPostOfficeController.dispose();
    _permPostCodeController.dispose();
    _permVilTownController.dispose();
    _presDistrictController.dispose();
    _presPoliceStationController.dispose();
    _presPostOfficeController.dispose();
    _presPostCodeController.dispose();
    _presVilTownController.dispose();
    super.dispose();
  }

  // Helper function to calculate age from DOB
  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return max(0, age); // Age cannot be negative
  }
  // --- File Upload Logic ---
  Future<void> _submitApplication() async {
    setState(() => _isSubmitting = true);

    _showSnackbar('Uploading documents...', isError: false);
    
    // --- 1. Upload all files and get their server names using the new service ---
    bool uploadSuccess = true;
    String? uploadErrorMessage;

    Future<String?> _uploadAndGetName(XFile? file) async {
      if (file == null) return null;
      final uploadResponse = await _fileUploadService.applicantFileUpload(file);
      if (uploadResponse.id == ResponseCode.SUCCESSFUL && uploadResponse.object is PolicyApplicantFileUploadModel) {
        return (uploadResponse.object as PolicyApplicantFileUploadModel).fileName;
      } else {
        uploadSuccess = false;
        uploadErrorMessage = uploadResponse.errorMessage ?? "File upload failed.";
        return null;
      }
    }

    _applicantData.applicantPhotoName = await _uploadAndGetName(_applicantData.applicantPhotoFile);
    if (!uploadSuccess) {
      _showSnackbar(uploadErrorMessage ?? 'Applicant photo upload failed.', isError: true);
      setState(() => _isSubmitting = false);
      return;
    }
    _applicantData.applicantDocumentName = await _uploadAndGetName(_applicantData.applicantDocumentFile);
    if (!uploadSuccess) {
      _showSnackbar(uploadErrorMessage ?? 'Applicant document upload failed.', isError: true);
      setState(() => _isSubmitting = false);
      return;
    }

    for (var nominee in _nominees) {
      nominee.uploadDocument = await _uploadAndGetName(nominee.uploadDocumentFile);
      if (!uploadSuccess) {
        _showSnackbar(uploadErrorMessage ?? 'Nominee document upload failed.', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }
      nominee.nomineePPName = await _uploadAndGetName(nominee.nomineePPNameFile);
      if (!uploadSuccess) {
        _showSnackbar(uploadErrorMessage ?? 'Nominee photo upload failed.', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }
      nominee.legalGuardianNIDPhoto = await _uploadAndGetName(nominee.legalGuardianNIDPhotoFile);
      if (!uploadSuccess) {
        _showSnackbar(uploadErrorMessage ?? 'Guardian NID photo upload failed.', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }
      nominee.legalGuardianPhoto = await _uploadAndGetName(nominee.legalGuardianPhotoFile);
      if (!uploadSuccess) {
        _showSnackbar(uploadErrorMessage ?? 'Guardian photo upload failed.', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }
    }

    _showSnackbar('Submitting application...', isError: false);

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final payload = {
      "proposal_no": _policyData.prBmNo ?? "",
      "applicant_name_eng": _applicantData.applicantNameEng,
      "father_name": _applicantData.applicantFatherName,
      "mother_name": _applicantData.applicantMotherName,
      "profession": _applicantData.profession,
      "mobile_no": _applicantData.mobileNo,
      "dob": _applicantData.dob != null ? DateFormat('yyyy-MM-dd').format(_applicantData.dob!) : null,
      "application_date": today,
      "gender": _applicantData.gender,
      "document_type": _applicantData.documentType,
      "plan_id": _policyData.policyId.toString().padLeft(3, '0'),
      "term_of_year": _policyData.termOfYear,
      "yearly_income": int.tryParse(_policyData.yearlyIncome.replaceAll(',', '')) ?? 0,
      "source_of_income": _policyData.sourceOfIncome,
      "age": _policyData.age,
      "sum_assured": _policyData.totalPolicyAmount.toInt(),
      "total_premium": _policyData.premiumAmount.toInt(),
      "nominees": _nominees.map((n) => {
        "serial": n.nomineeSerial,
        "name": n.nomineeName,
        "age": int.tryParse(n.nomineeAge) ?? 0,
        "relation": n.nomineeRelation,
        "allocation": n.nomineeAllocation.toInt(),
        "document_type": n.documentType,
        "upload_document": n.uploadDocument ?? "",
      }).toList(),
      "family_history": _familyHistory.map((f) => {
        "relation": f.relation,
        "life_status": f.lifeStatus,
        "age": int.tryParse(f.age) ?? 0,
        "current_physical_status": f.currentPhysicalStatus,
        "age_during_death": f.ageDuringDeath != null && f.ageDuringDeath!.isNotEmpty ? int.tryParse(f.ageDuringDeath!) : null,
        "death_reason": f.deathReason,
        "duration_of_last_illness": f.durationOfLastIllness,
        "year_of_death": f.yearOfDeath != null && f.yearOfDeath!.isNotEmpty ? int.tryParse(f.yearOfDeath!) : null,
      }).toList(),
    };

    // --- 3. Send the final payload using the existing submitApplication method ---
    final response = await _fileUploadService.submitApplication(payload);

    setState(() => _isSubmitting = false);

    if (response['success'] == true) {
      final String successMessage = response['message'] ?? 'Application submitted successfully';
      final String proposalNo = response['proposal_no']?.toString() ?? 'N/A';

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 10),
                Text("Success", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(successMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                const Text("Proposal No", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                SelectableText(
                  proposalNo,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDarkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("OK"),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      String errorMessage;
      if (response['errors'] != null && response['errors'] is Map) {
        final Map<String, dynamic> errors = response['errors'];
        // Extract messages from the errors map (values can be lists or strings)
        errorMessage = errors.values.expand((e) => e is List ? e : [e]).join('\n');
      } else {
        final dynamic message = response['message'];
        errorMessage = (message is String) 
            ? message 
            : (message?.toString() ?? 'An unknown error occurred.');
      }
      _showSnackbar(errorMessage);
    }
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastStep = _currentStep == _totalSteps - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for New Policy'),
        backgroundColor: kPrimaryDarkBlue, // Consistent AppBar color
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCustomStepIndicator(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // Disable swiping
              children: [
                SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildApplicantForm()),
                SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildPolicyForm()),
                SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildNomineeForm()),
                SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildFamilyHistoryForm()),
                SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildHealthAndOtherForm()),
                SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildReviewDetails()),
              ],
            ),
          ),
          // --- Persistent Navigation Buttons ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kCardBackground,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                if (_currentStep > 0)
                  TextButton.icon(
                    onPressed: _handleBack,
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: const Text('BACK'),
                    style: TextButton.styleFrom(foregroundColor: kTextColorDark),
                  ),
                const Spacer(),
                // Next/Submit Button
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : (isLastStep ? _submitApplication : _handleNext),
                  icon: _isSubmitting
                      ? const SizedBox.shrink()
                      : Icon(isLastStep ? Icons.check_circle_outline : Icons.arrow_forward_ios, size: 16),
                  label: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(isLastStep ? 'SUBMIT APPLICATION' : 'NEXT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDarkBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomStepIndicator() {
    final steps = ['Applicant', 'Policy', 'Nominee', 'Family', 'Health', 'Review'];
    return Container(
      color: kPrimaryDarkBlue,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length, (index) {
            bool isActive = index == _currentStep;
            bool isCompleted = index < _currentStep;
            
            return GestureDetector(
              onTap: () {
                if (index < _currentStep) {
                   setState(() => _currentStep = index);
                   _tabController.animateTo(index);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isActive ? kAccentBlue : (isCompleted ? Colors.green : Colors.white.withOpacity(0.1)),
                        shape: BoxShape.circle,
                        border: Border.all(color: isActive ? Colors.white : Colors.transparent, width: 2),
                      ),
                      child: Center(
                        child: isCompleted 
                          ? const Icon(Icons.check, size: 20, color: Colors.white)
                          : Text('${index + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(steps[index], style: TextStyle(color: isActive ? Colors.white : Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- Form Widgets for Each Step ---
  
  Widget _buildApplicantForm() {
    return Form(
      key: _applicantFormKey,
      child: Card( 
        elevation: 0, 
        margin: const EdgeInsets.symmetric(vertical: 4), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Slightly rounded corners
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              _buildImagePickerField(
                label: 'Applicant Photo',
                file: _applicantData.applicantPhotoFile,
                onFilePicked: (file) => setState(() => _applicantData.applicantPhotoFile = file),
              ),
              _buildTextField(label: 'Applicant Name (English)', onSaved: (val) => _applicantData.applicantNameEng = val!, validator: _validateRequired),
              _buildTextField(label: 'Applicant Name (Bangla)', onSaved: (val) => _applicantData.applicantNameBang = val!),
              _buildTextField(label: 'Father\'s Name', onSaved: (val) => _applicantData.applicantFatherName = val!, validator: _validateRequired),
              _buildTextField(label: 'Mother\'s Name', onSaved: (val) => _applicantData.applicantMotherName = val!, validator: _validateRequired),
              _buildTextField(label: 'Spouse Name (if applicable)', onSaved: (val) => _applicantData.applicantSpouseName = val!),
              _buildTextField(label: 'Profession', onSaved: (val) => _applicantData.profession = val!, validator: _validateRequired),
              // Date of Birth and Age display
              _buildDateField(
                  label: 'Date of Birth', 
                  selectedDate: _applicantData.dob, 
                  defaultInitialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                  onDateSelected: (date) {
                      setState(() {
                        _applicantData.dob = date;
                        _policyData.age = _calculateAge(date); // Update policy age
                      });
                    }),
              if (_applicantData.dob != null) _buildAgeDisplayField(age: _policyData.age), // Age field below DOB if selected

              _buildDropdownField(label: 'Gender', value: _applicantData.gender, items: ['Male', 'Female', 'Other'], onChanged: (val) => setState(() => _applicantData.gender = val!)),
              _buildDropdownField(label: 'Marital Status', value: _applicantData.maritalStatus, items: ['Married', 'Single', 'Divorced', 'Widowed'], onChanged: (val) => setState(() => _applicantData.maritalStatus = val!)),
              _buildTextField(label: 'Educational Qualification', onSaved: (val) => _applicantData.eduQualification = val!),
              _buildTextField(label: 'Birth Place', onSaved: (val) => _applicantData.birthPlace = val!, validator: _validateRequired),
              _buildTextField(label: 'Nationality', initialValue: _applicantData.nationality, onSaved: (val) => _applicantData.nationality = val!, validator: _validateRequired),
              _buildTextField(label: 'Mobile Number', onSaved: (val) => _applicantData.mobileNo = val!, validator: _validateMobile, keyboardType: TextInputType.phone),
              _buildTextField(label: 'Permanent Contact', onSaved: (val) => _applicantData.parmanentContact = val!, validator: _validateRequired, keyboardType: TextInputType.phone),
              _buildTextField(label: 'Present Contact', onSaved: (val) => _applicantData.presentContact = val!, keyboardType: TextInputType.phone),
              _buildTextField(label: 'Email Address', onSaved: (val) => _applicantData.email = val!, validator: _validateEmail, keyboardType: TextInputType.emailAddress),
              
              const Divider(height: 32),
              const Text("Bank Details", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
              _buildTextField(label: 'Bank Name', onSaved: (val) => _applicantData.bankName = val!),
              _buildTextField(label: 'Bank Branch', onSaved: (val) => _applicantData.bankBranch = val!),
              _buildTextField(label: 'Bank Account', onSaved: (val) => _applicantData.bankAccount = val!, keyboardType: TextInputType.number),

              const Divider(height: 32),
              const Text("Address Details", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
              
              // --- Combined Address Card ---
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Permanent Address Section
                      const Text("Permanent Address", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
                      _buildTextField(label: 'District', controller: _permDistrictController, onSaved: (val) => _applicantData.parmanentDistrict = val!, validator: _validateRequired),
                      _buildTextField(label: 'Police Station', controller: _permPoliceStationController, onSaved: (val) => _applicantData.parmanentPoliceStation = val!, validator: _validateRequired),
                      _buildTextField(label: 'Post Office', controller: _permPostOfficeController, onSaved: (val) => _applicantData.parmanentPostOffice = val!, validator: _validateRequired),
                      _buildTextField(label: 'Post Code', controller: _permPostCodeController, onSaved: (val) => _applicantData.parmanentPostCode = val!, validator: _validateRequired, keyboardType: TextInputType.number),
                      _buildTextField(label: 'Village / Town', controller: _permVilTownController, onSaved: (val) => _applicantData.permanentVilTown = val!, validator: _validateRequired),
                      
                      const Divider(height: 32),
                      
                      // Present Address Section
                      const Text("Present Address", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)),
                      CheckboxListTile(
                        title: const Text("Same as Permanent Address", style: TextStyle(fontSize: 14)),
                        value: _presentAddressIsSame,
                        onChanged: (bool? value) {
                          if (value == null) return;
                          setState(() { _presentAddressIsSame = value; });
                          if (value) {
                            _presDistrictController.text = _permDistrictController.text;
                            _presPoliceStationController.text = _permPoliceStationController.text;
                            _presPostOfficeController.text = _permPostOfficeController.text;
                            _presPostCodeController.text = _permPostCodeController.text;
                            _presVilTownController.text = _permVilTownController.text;
                          } else {
                            // Clear fields if unchecked
                            _presDistrictController.clear();
                            _presPoliceStationController.clear();
                            _presPostOfficeController.clear();
                            _presPostCodeController.clear();
                            _presVilTownController.clear();
                          }
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      _buildTextField(label: 'District', controller: _presDistrictController, onSaved: (val) => _applicantData.presentDistrict = val!, validator: _validateRequired, enabled: !_presentAddressIsSame),
                      _buildTextField(label: 'Police Station', controller: _presPoliceStationController, onSaved: (val) => _applicantData.presentPoliceStation = val!, validator: _validateRequired, enabled: !_presentAddressIsSame),
                      _buildTextField(label: 'Post Office', controller: _presPostOfficeController, onSaved: (val) => _applicantData.presentPostOffice = val!, validator: _validateRequired, enabled: !_presentAddressIsSame),
                      _buildTextField(label: 'Post Code', controller: _presPostCodeController, onSaved: (val) => _applicantData.presentPostCode = val!, validator: _validateRequired, keyboardType: TextInputType.number, enabled: !_presentAddressIsSame),
                      _buildTextField(label: 'Village / Town', controller: _presVilTownController, onSaved: (val) => _applicantData.presentVilTown = val!, validator: _validateRequired, enabled: !_presentAddressIsSame),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),
              const Text("Identification", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)), // Smaller title
              _buildDropdownField(label: 'Document Type', value: _applicantData.documentType, items: ['Voter ID', 'Birth Certificate', 'Passport'], onChanged: (val) => setState(() => _applicantData.documentType = val!)),
              _buildTextField(label: 'Document ID', onSaved: (val) => _applicantData.documentID = val!, validator: _validateRequired, keyboardType: TextInputType.number),
              _buildImagePickerField(
                label: 'Applicant Document Scan',
                file: _applicantData.applicantDocumentFile,
                onFilePicked: (file) => setState(() => _applicantData.applicantDocumentFile = file),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyForm() {
    return Form(
      key: _policyFormKey,
      child: Card( 
        elevation: 0, 
        margin: const EdgeInsets.symmetric(vertical: 6), // Reduced vertical margin
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            children: [
              _buildTextField(label: 'Policy Reason', initialValue: _policyData.policyReason, onSaved: (val) => _policyData.policyReason = val!, validator: _validateRequired),
              _buildTextField(label: 'Yearly Income', onSaved: (val) => _policyData.yearlyIncome = val!, validator: _validateRequired, keyboardType: TextInputType.number),
              _buildTextField(label: 'Source of Income', onSaved: (val) => _policyData.sourceOfIncome = val!, validator: _validateRequired),
              _buildDropdownField(
                label: 'Installment Type',
                value: _policyData.installmentTypeId,
                items: ['Monthly', 'Quarterly', 'Half-Yearly', 'Yearly'],
                onChanged: (val) => setState(() => _policyData.installmentTypeId = val!),
              ),
              _buildDropdownField(
                label: 'Policy Payee',
                value: _policyData.policyPayee ?? 'Self',
                items: ['Self', 'Other'],
                onChanged: (val) => setState(() => _policyData.policyPayee = val!),),
              _buildDropdownField(
                label: 'Term (Years)',
                value: _policyData.termOfYear.toString(),
                items: ['5', '10', '15', '20'],
                onChanged: (val) => setState(() => _policyData.termOfYear = int.parse(val!)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNomineeForm() {
    return Form(
      key: _nomineeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._nominees.map((nominee) => _buildSingleNomineeCard(nominee)).toList(),
          if (_nominees.length < 5) // Allow up to 5 nominees
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Another Nominee'),
              onPressed: () {
                setState(() {
                  _nominees.add(Nominee(nomineeSerial: _nominees.length + 1));
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSingleNomineeCard(Nominee nominee) {
    return Card(
      elevation: 3, 
      margin: const EdgeInsets.symmetric(vertical: 6), // Reduced vertical margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Slightly rounded corners
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nominee ${nominee.nomineeSerial}', style: Theme.of(context).textTheme.titleMedium),
                if (nominee.nomineeSerial > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => setState(() => _nominees.remove(nominee)),
                  )
              ], // Row for nominee title and remove button
            ),
            _buildTextField(label: 'Nominee Name', onSaved: (val) => nominee.nomineeName = val!, validator: _validateRequired),
            _buildTextField(label: 'Relation', onSaved: (val) => nominee.nomineeRelation = val!, validator: _validateRequired),
            _buildTextField(label: 'Age', onSaved: (val) => nominee.nomineeAge = val!, validator: _validateRequired, keyboardType: TextInputType.number),
            _buildTextField(label: 'Allocation (%)', initialValue: nominee.nomineeAllocation.toString(), onSaved: (val) => nominee.nomineeAllocation = double.tryParse(val!) ?? 100.0, validator: _validateRequired, keyboardType: TextInputType.number),
            _buildImagePickerField(
              label: 'Nominee Photo',
              file: nominee.nomineePPNameFile,
              onFilePicked: (file) => setState(() => nominee.nomineePPNameFile = file),
            ),
            _buildImagePickerField(
              label: 'Nominee Document (e.g., NID)',
              file: nominee.uploadDocumentFile,
              onFilePicked: (file) => setState(() => nominee.uploadDocumentFile = file),
            ),
            const Divider(height: 32),
            const Text("Guardian Info (if Nominee is a Minor)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryDarkBlue)), // Smaller title
            _buildTextField(label: 'Guardian Name', onSaved: (val) => nominee.nomineeGuardianName = val!),
            _buildTextField(label: 'Guardian Relation', onSaved: (val) => nominee.legalGuardianRelation = val!),
            _buildTextField(label: 'Guardian Address', onSaved: (val) => nominee.guardianAddress = val!),
            _buildTextField(label: 'Guardian NID No', onSaved: (val) => nominee.legalGuardianNIDNo = val!, keyboardType: TextInputType.number),
            _buildImagePickerField(
              label: 'Legal Guardian NID Photo',
              file: nominee.legalGuardianNIDPhotoFile, // This will now work
              onFilePicked: (file) => setState(() => nominee.legalGuardianNIDPhotoFile = file),
            ),
            _buildImagePickerField(
              label: 'Legal Guardian Photo',
              file: nominee.legalGuardianPhotoFile,
              onFilePicked: (file) => setState(() => nominee.legalGuardianPhotoFile = file),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyHistoryForm() {
    return Form(
      key: _familyHistoryFormKey,
      child: Column( // Column to hold multiple family member cards
        children: [
          ..._familyHistory.map((member) {
          // Card for each family member
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(member.relation, style: Theme.of(context).textTheme.titleMedium),
                  _buildDropdownField(label: 'Life Status', value: member.lifeStatus, items: ['Alive', 'Deceased'], onChanged: (val) => setState(() => member.lifeStatus = val!)),
                  if (member.lifeStatus == 'Alive') ...[
                    _buildTextField(label: 'Current Age', onSaved: (val) => member.age = val!, keyboardType: TextInputType.number),
                    _buildTextField(label: 'Current Physical Status', initialValue: member.currentPhysicalStatus, onSaved: (val) => member.currentPhysicalStatus = val!),
                  ],
                  if (member.lifeStatus == 'Deceased') ...[
                    _buildTextField(label: 'Age at Death', onSaved: (val) => member.ageDuringDeath = val!, keyboardType: TextInputType.number),
                    _buildTextField(label: 'Reason for Death', onSaved: (val) => member.deathReason = val!),
                  ],
                ],
              ),
            ),
          );
        }).toList()
        ]
      ),
    );
  }

  Widget _buildHealthAndOtherForm() {
    return Form(
      key: _healthFormKey,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              _buildTextField(label: 'Are you currently well?', onSaved: (val) => _applicantData.currentlyWell = val),
              _buildTextField(label: 'Recent weight loss or gain?', onSaved: (val) => _applicantData.weightLossOrGain = val),
              _buildTextField(label: 'Long holiday for illness?', onSaved: (val) => _applicantData.longHolidayForIllness = val),
              _buildTextField(label: 'Any physical disability?', onSaved: (val) => _applicantData.physicalDisability = val),
              _buildTextField(label: 'Had Chicken Pox?', onSaved: (val) => _applicantData.chikenPox = val),
              _buildTextField(label: 'Chicken Pox Vaccine?', onSaved: (val) => _applicantData.chikenPoxVaccin = val),
              _buildTextField(label: 'Any infectious disease?', onSaved: (val) => _applicantData.infectiousDisease = val),
              _buildTextField(label: 'Any ancestral disease?', onSaved: (val) => _applicantData.ancestralDisease = val),
              _buildTextField(label: 'Any other disease?', onSaved: (val) => _applicantData.otherDisease = val),
              _buildTextField(label: 'Any types of operation?', onSaved: (val) => _applicantData.typesOfOperation = val),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewDetails() {
    // Save form fields before displaying review
    _applicantFormKey.currentState?.save();
    _policyFormKey.currentState?.save();
    _nomineeFormKey.currentState?.save();
    _familyHistoryFormKey.currentState?.save();
    _healthFormKey.currentState?.save();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Please review all your information carefully before submitting.",
            style: TextStyle(fontSize: 16, color: kTextColorDark, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),

        // --- Applicant Details Review ---
        _buildReviewSection(
          "Applicant Details",
          {
            "Full Name": _applicantData.applicantNameEng,
            "Father's Name": _applicantData.applicantFatherName,
            "Mother's Name": _applicantData.applicantMotherName,
            "Date of Birth": _applicantData.dob != null ? DateFormat('dd MMM, yyyy').format(_applicantData.dob!) : "Not Set",
            "Age": "${_policyData.age} years",
            "Gender": _applicantData.gender,
            "Marital Status": _applicantData.maritalStatus,
            "Profession": _applicantData.profession,
            "Contact No": _applicantData.parmanentContact,
            "Email": _applicantData.email,
            "Permanent Address": "${_applicantData.permanentVilTown}, ${_applicantData.parmanentPoliceStation}, ${_applicantData.parmanentDistrict}",
            "Present Address": "${_applicantData.presentVilTown}, ${_applicantData.presentPoliceStation}, ${_applicantData.presentDistrict}",
            "Document Type": _applicantData.documentType,
            "Document ID": _applicantData.documentID,
            "Bank Name": _applicantData.bankName,
            "Bank Branch": _applicantData.bankBranch,
            "Bank Account": _applicantData.bankAccount,
          },
        ),

        // --- Policy Details Review ---
        _buildReviewSection(
          "Policy Details",
          {
            "Policy Reason": _policyData.policyReason,
            "Installment Type": _policyData.installmentTypeId,
            "Term": "${_policyData.termOfYear} Years",
            "Yearly Income": _policyData.yearlyIncome,
            "Source of Income": _policyData.sourceOfIncome,
            "Policy Payee": _policyData.policyPayee ?? "N/A",
          },
        ),

        // --- Nominee Details Review ---
        ..._nominees.map((nominee) {
          return _buildReviewSection(
            "Nominee ${nominee.nomineeSerial}",
            {
              "Name": nominee.nomineeName,
              "Relation": nominee.nomineeRelation,
              "Age": nominee.nomineeAge,
              "Allocation": "${nominee.nomineeAllocation}%",
              "Guardian Name": nominee.nomineeGuardianName.isNotEmpty ? nominee.nomineeGuardianName : "N/A",
            },
          );
        }).toList(),

        // --- Family History Review ---
        _buildReviewSection(
          "Family History",
          {
            for (var member in _familyHistory)
              member.relation: member.lifeStatus == 'Alive'
                  ? "Alive, ${member.age.isNotEmpty ? member.age : 'N/A'} years old, ${member.currentPhysicalStatus}"
                  : "Deceased (at age ${member.ageDuringDeath?.isNotEmpty == true ? member.ageDuringDeath : 'N/A'})",
          },
        ),

        // --- Health Details Review ---
        _buildReviewSection(
          "Health & Other Details",
          {
            "Currently Well?": _applicantData.currentlyWell ?? "N/A",
            "Any Other Disease?": _applicantData.otherDisease ?? "N/A",
          },
        ),
      ],
    );
  }

  Widget _buildReviewSection(String title, Map<String, String> details) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column( // Column to display review details
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: kPrimaryDarkBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 20),
            ...details.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [ // Key-value pair for review
                    Expanded(
                      flex: 2,
                      child: Text(e.key, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        e.value,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: kTextColorDark, fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
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

  // --- Common Form Field Widgets ---

  Widget _buildTextField({
    required String label,
    String? initialValue,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
    TextEditingController? controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), 
      child: TextFormField(
        initialValue: initialValue,
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: kTextColorDark.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryDarkBlue, width: 2.0),
          ),
        ),
        keyboardType: keyboardType,
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), 
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: kTextColorDark.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
    DateTime? defaultInitialDate,
  }) {
    final controller = TextEditingController(
      text: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate) : '',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), 
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: kTextColorDark.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kPrimaryDarkBlue, width: 2.0),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? defaultInitialDate ?? DateTime.now(),
            firstDate: DateTime(1920),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            onDateSelected(pickedDate);
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a date';
          }
          return null;
        },
      ),
    );
  }

  // New widget to display calculated age
  Widget _buildAgeDisplayField({required int age}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), 
      child: TextFormField(
        readOnly: true,
        initialValue: '$age years',
        decoration: InputDecoration(
          labelText: 'Calculated Age',
          labelStyle: TextStyle(color: kTextColorDark.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.blue.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blue.shade200)),
          suffixIcon: const Icon(Icons.cake, color: kAccentBlue),
        ),
        style: const TextStyle(fontWeight: FontWeight.bold, color: kTextColorDark),
      ),
    );
  }



  Widget _buildImagePickerField({
    required String label,
    required XFile? file,
    required ValueChanged<XFile?> onFilePicked,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextColorDark)), 
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: kAccentBlue.withOpacity(0.5), style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
              color: Colors.blue.shade50.withOpacity(0.3),
            ),
            child: InkWell(
              onTap: () async {
                final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  onFilePicked(pickedFile); // Callback when file is picked
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0), 
                child: Row( 
                  children: [
                    Icon(file != null ? Icons.check_circle : Icons.cloud_upload_outlined, color: file != null ? Colors.green : kAccentBlue, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        file != null ? file.name : 'Tap to upload $label',
                        style: TextStyle(color: file != null ? kTextColorDark : kAccentBlue, fontWeight: file != null ? FontWeight.bold : FontWeight.normal),
                        overflow: TextOverflow.ellipsis, // Handle long file names
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (value.length != 11) {
      return 'Mobile number must be exactly 11 digits';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}