import 'package:agricare/pages/locationpage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool isLogin = true;
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
            SizedBox(height: screenHeight * 0.05),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLogin = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                !isLogin ? Color(0xFF75B94A) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "SIGN UP",
                            style: TextStyle(
                              color: !isLogin ? Colors.white : Colors.black,
                              fontFamily: 'Alata',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLogin = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isLogin ? Color(0xFF75B94A) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "LOGIN",
                            style: TextStyle(
                              color: isLogin ? Colors.white : Colors.black,
                              fontFamily: 'Alata',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  if (!isLogin)
                    signUpForm(screenWidth)
                  else
                    loginForm(screenWidth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget loginForm(double screenWidth) {
    return Column(
      children: [
        textField("EMAIL", screenWidth),
        SizedBox(height: screenWidth * 0.08),
        textField("PASSWORD", screenWidth, obscureText: true),
        SizedBox(height: screenWidth * 0.05),
        logInButton("LOGIN"),
      ],
    );
  }

  Widget signUpForm(double screenWidth) {
    return Column(
      children: [
        textField("EMAIL", screenWidth),
        SizedBox(height: screenWidth * 0.08),
        textField("PASSWORD", screenWidth, obscureText: true),
        SizedBox(height: screenWidth * 0.08),
        textField("CONFIRM PASSWORD", screenWidth, obscureText: true),
        SizedBox(height: screenWidth * 0.05),
        signUpButton("SIGN UP"),
      ],
    );
  }

  Widget textField(String hint, double screenWidth,
      {bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Alata',
            color: Colors.black,
          ),
          filled: true,
          fillColor: Colors.grey[300],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget signUpButton(String text) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LocationPage(),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF75B94A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: Size(double.infinity, 50),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Alata',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget logInButton(String text) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF75B94A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: Size(double.infinity, 50),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Alata',
          fontWeight: FontWeight.bold,
          color: Colors.white,
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

Future<void> saveLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true); // Save login status
}
