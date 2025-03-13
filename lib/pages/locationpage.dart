import 'package:agricare/pages/dashboardpage.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  Location location = new Location();
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;
  void _requestLocationPermisson() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    _locationData = await location.getLocation();
    setState(() {});
    if (_locationData != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Dashboardpage(),
        ),
      );
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
              offset: Offset(-screenWidth * 0.01,
                  -screenHeight * 0.02), // Adjust this value as needed
              child: Center(
                child: Image(
                  image: AssetImage('images/location_img.png'),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _requestLocationPermisson();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF75B94A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

class UpwardCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height);

    // Make curve height responsive
    final curveHeight = size.height * 0.3; // 20% of container height
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
