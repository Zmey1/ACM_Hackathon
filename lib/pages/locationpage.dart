import 'package:agricare/pages/dashboardpage.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;
  bool _isLoading = false; // Prevent multiple API calls

  /// Fetches valid location with retries (max 3 attempts)
  Future<LocationData?> _getValidLocation() async {
    for (int i = 0; i < 3; i++) {
      LocationData data = await location.getLocation();
      if (data.latitude != null && data.longitude != null) {
        return data;
      }
      await Future.delayed(Duration(seconds: 2)); // Wait before retrying
    }
    return null;
  }

  /// Requests location permission and sends data to the backend
  void _requestLocationPermission() async {
    if (_isLoading) return; // Prevent multiple clicks
    setState(() => _isLoading = true);

    try {
      // Check & request location service
      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          throw Exception('❌ Location services are disabled.');
        }
      }

      // Check & request permission
      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          throw Exception('❌ Location permission denied.');
        }
      }

      // Fetch location (with retries)
      _locationData = await _getValidLocation();
      if (_locationData == null) {
        throw Exception('❌ Unable to get valid location.');
      }

      print(
          "📍 Location: Lat: ${_locationData!.latitude}, Long: ${_locationData!.longitude}");

      // Prepare JSON payload
      Map<String, dynamic> locationPayload = {
        'lat': _locationData!.latitude,
        'lon': _locationData!.longitude
      };

      // Send data to backend (ONLY ONCE)
      final response = await http.post(
        Uri.parse('https://52e6-103-4-220-252.ngrok-free.app/store-weather'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(locationPayload),
      );

      print("🔵 Response Code: ${response.statusCode}");
      print("🔵 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboardpage()),
        );
      } else {
        throw Exception(
            "❌ Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false); // Re-enable button
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            ClipPath(
              clipper: UpwardCurveClipper(),
              child: Image(
                image: AssetImage('images/farmer_img.png'),
                height: screenHeight * 0.4,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Transform.translate(
              offset: Offset(-screenWidth * 0.01, -screenHeight * 0.02),
              child: Center(
                child: Image(image: AssetImage('images/location_img.png')),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator(
                    color: Color(0xFF75B94A)) // Show loading
                : ElevatedButton(
                    onPressed: _requestLocationPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF75B94A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: Size(300, 50),
                    ),
                    child: const Text(
                      'Use this location',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Custom Clipper for Curved UI
class UpwardCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);

    final curveHeight = size.height * 0.3;
    path.quadraticBezierTo(
      size.width / 2,
      size.height - curveHeight,
      size.width,
      size.height,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
