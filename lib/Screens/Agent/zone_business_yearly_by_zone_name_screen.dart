import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petro_app/Screens/Agent/business_summary_screen.dart';

// --- Constants (re-used for consistency) ---
const Color kPrimaryDarkBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kTextColorLight = Color(0xFFF9FAFB);
const Color kScaffoldBackground = Color(0xFFF3F4F6);
const Color kTextColorDark = Color(0xFF1F2937);

// Base URL for API calls (from premium_calculator_screen.dart)
const String BASE_URL = 'https://nliapi.nextgenitltd.com/api';

// Placeholder for UserData.token (assuming it's fetched from SharedPreferences)
class AuthService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }
}

class ZoneBusinessScreen extends StatefulWidget {
  const ZoneBusinessScreen({Key? key}) : super(key: key);

  @override
  _ZoneBusinessScreenState createState() => _ZoneBusinessScreenState();
}

class _ZoneBusinessScreenState extends State<ZoneBusinessScreen> {
  List<dynamic> data = [];
  List<dynamic> dataId = [];
  List<dynamic> updateData = [];
  List<dynamic> dataName = [];
  List<dynamic> firstYR = [];
  List<dynamic> renYR = [];
  List<dynamic> cfirstYR = [];
  List<dynamic> crenYR = [];
  double totalFirstYR = 0.0;
  double totalRenYR = 0.0;
  double totalCFirstYR = 0.0;
  double totalCRenYR = 0.0;
  bool isLoading = false;
  String dropdownvalue = "AKOK OFFICE";
  List<String> Office = ["AKOK OFFICE", "JANA OFFICE"];
  TextEditingController searchValue = TextEditingController();

  Future<void> getResponseFormApi({
    required String office_type,
    required String searchValue,
  }) async {
    setState(() {
      isLoading = true;
      dataId = [];
      data = [];
      updateData = [];
      dataName = [];
      firstYR = [];
      renYR = [];
      cfirstYR = [];
      crenYR = [];
      totalFirstYR = 0.0;
      totalRenYR = 0.0;
      totalCFirstYR = 0.0;
      totalCRenYR = 0.0;
    });

    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Authentication token not found. Please log in again.',
            ),
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
      return;
    }

    var response = await http.get(
      Uri.parse("$BASE_URL/zone-business/?office_type=${office_type}"),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      var getResponse = jsonDecode(response.body)["branch"];
      setState(() {
        if (searchValue == "") {
          data = getResponse;
          updateData = data;
        } else {
          data = getResponse;
          updateData = data
              .where(
                (element) => element["zone_name"].toString().contains(
                  searchValue.toUpperCase(),
                ),
              )
              .toList();
        }

        updateData.forEach((e) {
          if (dataId.contains(e["zone_code"]) == false) {
            dataId.add(e["zone_code"]);
          }
        });

        dataId.forEach((e) {
          updateData.forEach((data) {
            if (data["zone_code"] == e) {
              if (dataName.contains(data["zone_name"]) == false) {
                dataName.add(data["zone_name"]);
              }
            }
          });
        });

        dataName.forEach((e) {
          updateData.forEach((data) {
            if (data["zone_name"] == e) {
              if (data["year_category"] == "PREVIOUS_YEAR" &&
                  data["type"] == "FR") {
                firstYR.add(data["premium_paid"]);
                totalFirstYR =
                    totalFirstYR + double.parse(data["premium_paid"]);
              }
              if (data["year_category"] == "PREVIOUS_YEAR" &&
                  data["type"] == "RR") {
                renYR.add(data["premium_paid"]);
                totalRenYR = totalRenYR + double.parse(data["premium_paid"]);
              }
              if (data["year_category"] == "CURRENT_YEAR" &&
                  data["type"] == "FR") {
                cfirstYR.add(data["premium_paid"]);
                totalCFirstYR =
                    totalCFirstYR + double.parse(data["premium_paid"]);
              }
              if (data["year_category"] == "CURRENT_YEAR" &&
                  data["type"] == "RR") {
                crenYR.add(data["premium_paid"]);
                totalCRenYR = totalCRenYR + double.parse(data["premium_paid"]);
              }
            }
          });
        });
      });
      setState(() {
        isLoading = false;
      });
    } else {
      print("${response.statusCode.toString()}");
      setState(() {
        isLoading = false;
      });
    }
  }

  bool isCurrentYear = true;

  @override
  void initState() {
    super.initState();
    getResponseFormApi(office_type: "AKOK OFFICE", searchValue: "");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BusinessSummaryScreen()),
        );
        return true;
      },
      child: Scaffold(
        backgroundColor: kScaffoldBackground,
        appBar: AppBar(
          backgroundColor: kPrimaryDarkBlue,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            color: kTextColorLight,
            iconSize: 20,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BusinessSummaryScreen(),
                ),
              );
            },
          ),
          title: Text(
            "Zone Business Yearly (By Zone Name)",
            style: TextStyle(color: kTextColorLight, fontSize: 14),
          ),
        ),
        body: isLoading == true
            ? Container(
                height: MediaQuery.of(context).size.height / 1,
                width: MediaQuery.of(context).size.width / 1,
                child: Center(
                  child: CircularProgressIndicator(color: kPrimaryDarkBlue),
                ),
              )
            : CustomScrollView(
                slivers: [
                  //Header
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: kScaffoldBackground,
                    primary: false,
                    pinned: false,
                    floating: true,
                    collapsedHeight: 250,
                    expandedHeight: 250,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Office Type',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                value: dropdownvalue,
                                items: Office.map((String items) {
                                  return DropdownMenuItem(
                                    value: items,
                                    child: Text(items),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) async {
                                  if (newValue != null) {
                                    setState(() {
                                      dropdownvalue = newValue;
                                    });
                                    await getResponseFormApi(
                                      office_type: newValue,
                                      searchValue: searchValue.text,
                                    );
                                  }
                                },
                              ),
                              TextFormField(
                                controller: searchValue,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  hintText: "Search by zone name",
                                  labelText: 'Search',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      Icons.search,
                                      color: kPrimaryDarkBlue,
                                    ),
                                    onPressed: () async {
                                      await getResponseFormApi(
                                        office_type: dropdownvalue,
                                        searchValue: searchValue.text,
                                      );
                                    },
                                  ),
                                ),
                                onFieldSubmitted: (value) async {
                                  await getResponseFormApi(
                                    office_type: dropdownvalue,
                                    searchValue: value,
                                  );
                                },
                              ),
                              ToggleButtons(
                                isSelected: [isCurrentYear, !isCurrentYear],
                                onPressed: (int index) {
                                  setState(() {
                                    isCurrentYear = index == 0;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                selectedColor: kTextColorLight,
                                color: kPrimaryDarkBlue,
                                fillColor: kPrimaryDarkBlue,
                                selectedBorderColor: kPrimaryDarkBlue,
                                borderColor: kPrimaryDarkBlue,
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Text('CURRENT YEAR'),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Text('PREVIOUS YEAR'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  //Table headre
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    primary: true,
                    backgroundColor: kScaffoldBackground,
                    automaticallyImplyLeading: false,
                    expandedHeight: MediaQuery.of(context).size.height / 15,
                    flexibleSpace: Column(
                      children: [
                        SizedBox(height: 15),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                height: MediaQuery.of(context).size.height / 15,
                                width: MediaQuery.of(context).size.width / 6.6,
                                decoration: BoxDecoration(
                                  color: kPrimaryDarkBlue,
                                  border: Border.all(
                                    width: 1,
                                    color: kTextColorLight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "Code",
                                    style: TextStyle(color: kTextColorLight),
                                  ),
                                ),
                              ),
                              Container(
                                height: MediaQuery.of(context).size.height / 15,
                                width: MediaQuery.of(context).size.width / 2.25,
                                decoration: BoxDecoration(
                                  color: kPrimaryDarkBlue,
                                  border: Border.all(
                                    width: 1,
                                    color: kTextColorLight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "Name",
                                    style: TextStyle(color: kTextColorLight),
                                  ),
                                ),
                              ),
                              Container(
                                height: MediaQuery.of(context).size.height / 15,
                                width: MediaQuery.of(context).size.width / 5,
                                decoration: BoxDecoration(
                                  color: kPrimaryDarkBlue,
                                  border: Border.all(
                                    width: 1,
                                    color: kTextColorLight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "FIRST YR",
                                    style: TextStyle(color: kTextColorLight),
                                  ),
                                ),
                              ),
                              Container(
                                height: MediaQuery.of(context).size.height / 15,
                                width: MediaQuery.of(context).size.width / 5,
                                decoration: BoxDecoration(
                                  color: kPrimaryDarkBlue,
                                  border: Border.all(
                                    width: 1,
                                    color: kTextColorLight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "REN YR",
                                    style: TextStyle(color: kTextColorLight),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  //list
                  SliverList(
                    delegate: SliverChildBuilderDelegate((
                      BuildContext context,
                      int index,
                    ) {
                      return Row(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height / 15,
                            width: MediaQuery.of(context).size.width / 6.5,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                width: 1,
                                color: kTextColorDark,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "${dataId[index]}",
                                style: TextStyle(color: kTextColorDark),
                              ),
                            ),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height / 15,
                            width: MediaQuery.of(context).size.width / 2.25,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                width: 1,
                                color: kTextColorDark,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "${dataName[index]}",
                                style: TextStyle(color: kTextColorDark),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          firstYR.length <= index
                              ? Container(
                                  height:
                                      MediaQuery.of(context).size.height / 15,
                                  width: MediaQuery.of(context).size.width / 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      width: 1,
                                      color: kTextColorDark,
                                    ),
                                  ),
                                )
                              : cfirstYR.length <= index
                              ? Container(
                                  height:
                                      MediaQuery.of(context).size.height / 15,
                                  width: MediaQuery.of(context).size.width / 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      width: 1,
                                      color: kTextColorDark,
                                    ),
                                  ),
                                )
                              : Container(
                                  height:
                                      MediaQuery.of(context).size.height / 15,
                                  width: MediaQuery.of(context).size.width / 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      width: 1,
                                      color: kTextColorDark,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isCurrentYear == true
                                          ? "${double.parse(cfirstYR[index]).toStringAsFixed(2)}"
                                          : "${double.parse(firstYR[index]).toStringAsFixed(2)}",
                                      style: TextStyle(color: kTextColorDark),
                                    ),
                                  ),
                                ),
                          crenYR.length <= index
                              ? Container(
                                  height:
                                      MediaQuery.of(context).size.height / 15,
                                  width: MediaQuery.of(context).size.width / 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      width: 1,
                                      color: kTextColorDark,
                                    ),
                                  ),
                                )
                              : renYR.length <= index
                              ? Container(
                                  height:
                                      MediaQuery.of(context).size.height / 15,
                                  width: MediaQuery.of(context).size.width / 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      width: 1,
                                      color: kTextColorDark,
                                    ),
                                  ),
                                )
                              : Container(
                                  height:
                                      MediaQuery.of(context).size.height / 15,
                                  width: MediaQuery.of(context).size.width / 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      width: 1,
                                      color: kTextColorDark,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isCurrentYear == true
                                          ? "${double.parse(crenYR[index]).toStringAsFixed(2)}"
                                          : "${double.parse(renYR[index]).toStringAsFixed(2)}",
                                      style: TextStyle(color: kTextColorDark),
                                    ),
                                  ),
                                ),
                        ],
                      );
                    }, childCount: dataId.length),
                  ),
                  //Total
                  SliverToBoxAdapter(
                    child: Container(
                      height: MediaQuery.of(context).size.height / 15,
                      width: MediaQuery.of(context).size.width / 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height / 15,
                                  width:
                                      MediaQuery.of(context).size.width / 6.5,
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(24, 200, 45, .8),
                                    border: Border.all(
                                      width: 1,
                                      color: kTextColorLight,
                                    ),
                                  ),
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height / 15,
                                  width:
                                      MediaQuery.of(context).size.width / 2.25,
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(24, 200, 45, .8),
                                    border: Border.all(
                                      width: 1,
                                      color: kTextColorLight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Total = ",
                                      style: TextStyle(
                                        color: kTextColorLight,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height / 15,
                                  width: MediaQuery.of(context).size.width / 5,
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(24, 200, 45, .8),
                                    border: Border.all(
                                      width: 1,
                                      color: kTextColorLight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isCurrentYear == true
                                          ? "${totalCFirstYR.toStringAsFixed(2)}"
                                          : "${totalFirstYR.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: kTextColorLight,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height / 15,
                                  width: MediaQuery.of(context).size.width / 5,
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(24, 200, 45, .8),
                                    border: Border.all(
                                      width: 1,
                                      color: kTextColorLight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isCurrentYear == true
                                          ? "${totalCRenYR.toStringAsFixed(2)}"
                                          : "${totalRenYR.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: kTextColorLight,
                                        fontSize: 16,
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
                  ),
                ],
              ),
      ),
    );
  }
}
