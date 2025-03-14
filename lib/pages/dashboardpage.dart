import 'package:agricare/pages/chat_app.dart';
import 'package:agricare/pages/resultpage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Dashboardpage extends StatefulWidget {
  const Dashboardpage({super.key});

  @override
  State<Dashboardpage> createState() => _DashboardpageState();
}

class _DashboardpageState extends State<Dashboardpage> {
  String temperature = "Loading...";
  String weatherCondition = "";
  String weatherIcon = "images/sunny.png";
  bool isSoilExpanded = false;
  bool isCropExpanded = false;
  String selectedSoil = "";
  String selectedCrop = "";
  DateTime? selectedDate;

  final List<Map<String, String>> soils = [
    {"name": "Red Soil", "image": "images/red_soil.png"},
    {"name": "Black clayey soil", "image": "images/Brown_soil.png"},
    {"name": "Brown soil", "image": "images/Black_clayey_soil.png"},
    {"name": "Alluvial soil", "image": "images/alluvial_soil.png"},
  ];
  final List<Map<String, String>> crops = [
    {"name": "Rice", "image": "images/rice.png"},
    {"name": "Sugarcane", "image": "images/sugarcane.png"},
    {"name": "Groundnut", "image": "images/groundnut.png"},
    {"name": "Cotton", "image": "images/cotton.png"},
    {"name": "Banana", "image": "images/banana.png"},
  ];

  Future<void> sendSelectionToBackend() async {
    if (selectedSoil.isNotEmpty &&
        selectedCrop.isNotEmpty &&
        selectedDate != null) {
      final url = Uri.parse(
          "https://ba7f-103-238-230-194.ngrok-free.app/api/crop/get-crop");

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "soil_type": selectedSoil,
            "crop_type": selectedCrop,
            "plantation_date": selectedDate!.toIso8601String(),
          }),
        );

        if (response.statusCode == 200) {
          print("Selection sent successfully!");
          navigateToNextPage();
        } else {
          print("Failed to send selection: ${response.body}");
        }
      } catch (e) {
        print("Error sending data: $e");
      }
    }
  }

  void navigateToNextPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Resultpage()),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse('https://ba7f-103-238-230-194.ngrok-free.app/get-weather'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('minTemp') &&
            data.containsKey('maxTemp') &&
            data.containsKey('mainWeather')) {
          setState(() {
            temperature = "${data['minTemp']}°C - ${data['maxTemp']}°C";
            weatherCondition = data['mainWeather'] ?? "Unknown";
            weatherIcon = getWeatherIcon(data['mainWeather']);
          });
        } else {
          setState(() {
            temperature = "Error: Invalid API response";
            weatherIcon = "images/sunny.png";
          });
        }
      } else {
        setState(() {
          temperature = "Error fetching data";
          weatherIcon = "images/sunny.png";
        });
      }
    } catch (e) {
      setState(() {
        temperature = "Error fetching data";
        weatherIcon = "images/sunny.png";
      });
    }
  }

  String getWeatherIcon(String? condition) {
    if (condition == null) return "images/sunny.png";

    switch (condition.toLowerCase()) {
      case 'clear':
        return 'images/sunny.png';
      case 'clouds':
        return 'images/cloudy.png';
      case 'rain':
        return 'images/rainy.png';
      case 'drizzle':
        return 'images/light_rain.png';
      case 'thunderstorm':
        return 'images/thunderstorm.png';
      case 'haze':
        return 'images/hazy.png';
      default:
        return 'images/sunny.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 30),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFE1EFCE),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                  color: Colors.black87)),
                          SizedBox(height: 4),
                          Text("$temperature $weatherCondition",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                  color: Colors.black54)),
                        ],
                      ),
                      SizedBox(width: 10),
                      Image.asset(weatherIcon, width: 45, height: 45),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 50),
              buildDropdown("Select Soil Type", soils, isSoilExpanded, () {
                setState(() {
                  isSoilExpanded = !isSoilExpanded;
                  isCropExpanded = false;
                });
              }, true),
              buildDropdown("Select Crop Type", crops, isCropExpanded, () {
                setState(() {
                  isCropExpanded = !isCropExpanded;
                  isSoilExpanded = false;
                });
              }, false),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text(selectedDate == null
                      ? "Select Date"
                      : "Date: ${selectedDate!.toLocal()}".split(' ')[0])),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: sendSelectionToBackend,
                child: Text("Next"),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
                child: Transform.translate(
                  offset: Offset(screenWidth * 0.34, screenHeight * 0.11),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Center(
                      child: Image.asset(
                        'images/ai_chatbot.png',
                        height: screenHeight * 0.4,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdown(String title, List<Map<String, String>> items,
      bool isExpanded, VoidCallback onTap, bool isSoil) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing:
                Icon(isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            onTap: onTap,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items.map((item) {
                  bool isSelected = isSoil
                      ? selectedSoil == item["name"]
                      : selectedCrop == item["name"];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSoil) {
                          selectedSoil = item["name"]!;
                        } else {
                          selectedCrop = item["name"]!;
                        }
                      });
                      sendSelectionToBackend();
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: Colors.green, width: 3)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Image.asset(item["image"]!,
                              height: 50, width: 80, fit: BoxFit.cover),
                          SizedBox(height: 5),
                          Text(item["name"]!,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
