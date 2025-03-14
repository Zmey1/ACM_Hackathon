import 'dart:convert';

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
      final response = await http.post(
        Uri.parse(
            'https://ba7f-103-238-230-194.ngrok-free.app/api/crop/store-prediction'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          crop_type = data['cropName'] ?? "Unknown";
          water_predicted_acre = "${data['waterNeeded']} mm";
          water_frequency = data['irrigationEvents'].toString();
          simple_instruction = data['instructions'].toString();
          next_water_date = data['firstIrrigationDate'] ?? "Unknown";
        });
      } else {
        setState(() {
          crop_type = "Error";
          water_predicted_acre = "Error";
          water_frequency = "Error";
          next_water_date = "Error";
          simple_instruction = "Error";
        });
      }
    } catch (e) {
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
                SizedBox(
                  height: screenHeight * 0.3, // Responsive height
                ),
                CropDetailsCard(
                  crop_type: crop_type,
                  water_predicted_acre: water_predicted_acre,
                ),
                SizedBox(height: screenHeight * 0.05), // Responsive space
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
      margin: EdgeInsets.fromLTRB(
          screenWidth * 0.05, 0, screenWidth * 0.05, 20), // Responsive margin
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

    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05), // Responsive margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.info, size: 24, color: Colors.black87),
                        SizedBox(width: 8),
                        Text(
                          "Instructions",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      simple_instruction,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.hourglass_empty,
                            size: 24, color: Colors.black87),
                        SizedBox(width: 8),
                        Text(
                          "Irrigation Events",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      water_frequency,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 24, color: Colors.black87),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "First Irrigation Date",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      next_water_date,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
