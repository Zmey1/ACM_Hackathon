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
  String weatherIcon = "images/sunny.png"; // Default image

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

      print("🔵 API Response Code: ${response.statusCode}");
      print("🔵 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debugging: Print received data
        print("🟢 Decoded JSON Data: $data");

        if (data.containsKey('minTemp') &&
            data.containsKey('maxTemp') &&
            data.containsKey('mainWeather')) {
          setState(() {
            temperature = "${data['minTemp']}°C - ${data['maxTemp']}°C";
            weatherCondition = data['mainWeather'] ?? "Unknown";
            weatherIcon = getWeatherIcon(data['mainWeather']);
          });
        } else {
          print("❌ Missing required keys in API response");
          setState(() {
            temperature = "Error: Invalid API response";
            weatherIcon = "images/sunny.png"; // Fallback
          });
        }
      } else {
        print("❌ Server Error: ${response.statusCode} - ${response.body}");
        setState(() {
          temperature = "Error fetching data";
          weatherIcon = "images/sunny.png"; // Fallback
        });
      }
    } catch (e) {
      print("❌ Exception: $e");
      setState(() {
        temperature = "Error fetching data";
        weatherIcon = "images/sunny.png"; // Fallback
      });
    }
  }

  String getWeatherIcon(String? condition) {
    if (condition == null) return "images/sunny.png"; // Prevent null errors

    switch (condition.toLowerCase()) {
      case 'sunny':
        return 'images/sunny.png';
      case 'clouds':
        return 'images/cloudy.png';
      case 'rainy':
        return 'images/rainy.png';
      default:
        return 'images/sunny.png'; // Default image
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "$temperature $weatherCondition",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Image.asset(
              weatherIcon,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('images/sunny.png', width: 40, height: 40);
              },
            ),
          ],
        ),
      ),
    );
  }
}
