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
  String weatherIcon = "";
  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(
          'https://ba7f-103-238-230-194.ngrok-free.app/store-weather'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = "${data['temp_min']}°C - ${data['temp_max']}°C";
          weatherCondition = data['condition'];
          weatherIcon = getWeatherIcon(data['condition']);
        });
      } else {
        setState(() {
          temperature = "Error fetching data";
        });
      }
    } catch (e) {
      setState(() {
        temperature = "Error fetching data";
      });
    }
  }

  String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return 'images/sunny.png';
      case 'cloudy':
        return 'images/cloudy.png';
      case 'rainy':
        return 'images/rainy.png';
      default:
        return 'images/sunny.png';
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
            ),
          ],
        ),
      ),
    );
  }
}
