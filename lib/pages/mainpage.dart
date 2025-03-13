import 'package:agricare/pages/signinpage.dart';
import 'package:flutter/material.dart';

class Mainpage extends StatefulWidget {
  const Mainpage({super.key});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                Stack(
                  children: [
                    Transform.translate(
                      offset:
                          Offset(-screenWidth * 0.04, -screenHeight * 0.001),
                      child: Center(
                        child: Image(
                          image: AssetImage('images/farmer_icon.png'),
                          height: screenHeight * 0.4,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(screenWidth * 0.025, screenHeight * 0.195),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Agri',
                                    style: TextStyle(
                                      fontFamily: 'CopperplateGothic',
                                      fontSize: screenWidth * 0.07,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Care',
                                    style: TextStyle(
                                      fontFamily: 'CopperplateGothic',
                                      fontSize: screenWidth * 0.07,
                                      color: Color(
                                          0xFFA8E07B), // Same green as in image
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: screenHeight * 0.003,
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Smarter Irrigation,',
                                    style: TextStyle(
                                      fontFamily: 'CopperplateGothic',
                                      fontSize: screenWidth * 0.02,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Greener Tomorrow',
                                    style: TextStyle(
                                      fontFamily: 'CopperplateGothic',
                                      fontSize: screenWidth * 0.02,
                                      color: Color(0xFF53C38A),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignInPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF75B94A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    minimumSize: Size(150, 60),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 30,
                      ),
                    ],
                  ),
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
