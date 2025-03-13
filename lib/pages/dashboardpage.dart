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
    final response =
        await http.get(Uri.parse('https://your-backend-url.com/weather'));

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
  }

  String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return 'assets/sunny.png';
      case 'cloudy':
        return 'assets/cloudy.png';
      case 'rainy':
        return 'assets/rainy.png';
      default:
        return 'assets/default.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
    );
  }
}
