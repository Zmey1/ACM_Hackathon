import 'dart:convert';
import 'package:agricare/pages/dashboardpage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Resultpage extends StatefulWidget {
  const Resultpage({super.key});

  @override
  State<Resultpage> createState() => _ResultpageState();
}

class _ResultpageState extends State<Resultpage> {
  String crop_type = "Loading...";
  String water_predicted_acre = "Loading...";
  String water_frequency = "Loading...";
  String next_water_date = "Loading...";
  String simple_instruction = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchCropData();
  }

  Future<void> fetchCropData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://52e6-103-4-220-252.ngrok-free.app/api/crop/get-water-prediction'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          crop_type = data['crop_type'] ?? "Unknown";
          water_predicted_acre = "${data['water_predicted_acre']} ltr";
          water_frequency = data['water_frequency'].toString();
          simple_instruction = data['simple_instruction'].toString();
          next_water_date = data['next_water_date'] ?? "Unknown";
        });
      } else {
        print("Error: Unexpected status code ${response.statusCode}");
        setState(() {
          crop_type = "Error";
          water_predicted_acre = "Error";
          water_frequency = "Error";
          next_water_date = "Error";
          simple_instruction = "Error";
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        crop_type = "Error";
        water_predicted_acre = "Error";
        water_frequency = "Error";
        next_water_date = "Error";
        simple_instruction = "Error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "images/bg.png",
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                SizedBox(height: screenHeight * 0.3),
                CropDetailsCard(
                  crop_type: crop_type,
                  water_predicted_acre: water_predicted_acre,
                ),
                SizedBox(height: screenHeight * 0.05),
                IrrigationDetailsCard(
                  simple_instruction: simple_instruction,
                  water_frequency: water_frequency,
                  next_water_date: next_water_date,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CropDetailsCard extends StatelessWidget {
  final String crop_type;
  final String water_predicted_acre;

  const CropDetailsCard({
    required this.crop_type,
    required this.water_predicted_acre,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      margin:
          EdgeInsets.fromLTRB(screenWidth * 0.05, 0, screenWidth * 0.05, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('images/crop.png'),
                    SizedBox(width: 8),
                    Text(
                      "Crop",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  crop_type,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop, size: 24, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "Water Predicted",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  water_predicted_acre,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IrrigationDetailsCard extends StatelessWidget {
  final String simple_instruction;
  final String water_frequency;
  final String next_water_date;

  const IrrigationDetailsCard({
    required this.simple_instruction,
    required this.water_frequency,
    required this.next_water_date,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Card(
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, size: 24, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      "Instructions",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width * 0.9, // Adjust width
                  ),
                  child: Text(
                    simple_instruction,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    softWrap: true,
                    maxLines: 3, // Ensures it doesn't overflow
                    overflow:
                        TextOverflow.ellipsis, // Adds "..." if it overflows
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Icon(Icons.hourglass_empty,
                        size: 24, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      "Irrigation Events: $water_frequency",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 24, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      "Irrigation Dates: $next_water_date",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 35),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Dashboardpage(),
              ),
            );
          },
          child: Icon(Icons.home, size: 60, color: Colors.black87),
        ),
      ],
    );
  }
}
