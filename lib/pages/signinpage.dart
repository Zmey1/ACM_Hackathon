import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:agricare/pages/locationpage.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool isLogin = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String errorMessage = ""; // To store validation errors

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
                                errorMessage = "";
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
                                errorMessage = "";
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
      ),
    );
  }

  Widget loginForm(double screenWidth) {
    return Column(
      children: [
        textField("EMAIL", screenWidth, controller: emailController),
        SizedBox(height: screenWidth * 0.08),
        textField("PASSWORD", screenWidth,
            controller: passwordController, obscureText: true),
        SizedBox(height: screenWidth * 0.05),
        logInButton("LOGIN"),
      ],
    );
  }

  Widget signUpForm(double screenWidth) {
    return Column(
      children: [
        textField("EMAIL", screenWidth, controller: emailController),
        SizedBox(height: screenWidth * 0.08),
        textField("PASSWORD", screenWidth,
            controller: passwordController, obscureText: true),
        SizedBox(height: screenWidth * 0.08),
        textField("CONFIRM PASSWORD", screenWidth,
            controller: confirmPasswordController, obscureText: true),
        SizedBox(height: screenWidth * 0.02),
        if (errorMessage.isNotEmpty)
          Text(
            errorMessage,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        SizedBox(height: screenWidth * 0.05),
        signUpButton("SIGN UP"),
      ],
    );
  }

  Widget textField(String hint, double screenWidth,
      {bool obscureText = false, TextEditingController? controller}) {
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
        controller: controller,
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
      onPressed: () async {
        if (passwordController.text != confirmPasswordController.text) {
          setState(() {
            errorMessage = "Passwords do not match!";
          });
          return;
        }

        try {
          final response = await http.post(
            Uri.parse(
                "https://ba7f-103-238-230-194.ngrok-free.app/api/auth/register"),
            body: jsonEncode({
              "email": emailController.text,
              "password": passwordController.text,
              "confirmPassword": confirmPasswordController.text,
            }),
            headers: {"Content-Type": "application/json"},
          );

          print("Response Status: ${response.statusCode}");
          print("Response Body: ${response.body}");

          // Check if the response body is empty
          if (response.body.isEmpty) {
            setState(() {
              errorMessage = "No response from server. Please try again later.";
            });
            return;
          }

          final responseData = jsonDecode(response.body);

          if (response.statusCode == 201 && responseData["success"] == true) {
            await saveLoginStatus();
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LocationPage()));
          } else {
            setState(() {
              errorMessage = responseData["message"] ??
                  "Signup failed! User may already exist.";
            });
          }
        } catch (e) {
          print("Signup Error: $e");
          setState(() {
            errorMessage = "An unexpected error occurred. Please try again.";
          });
        }
      },
      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF75B94A)),
      child: Text(text, style: TextStyle(color: Colors.white)),
    );
  }

  Widget logInButton(String text) {
    return ElevatedButton(
      onPressed: () async {
        final response = await http.post(
          Uri.parse(
              "https://ba7f-103-238-230-194.ngrok-free.app/api/auth/login"),
          body: jsonEncode({
            "email": emailController.text,
            "password": passwordController.text,
          }),
          headers: {"Content-Type": "application/json"},
        );

        final responseData = jsonDecode(response.body);
        print("Response Status: ${response.statusCode}");
        print("Response Body: ${response.body}");

        if (response.statusCode == 200 && responseData["success"] == true) {
          await saveLoginStatus();
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LocationPage()));
        } else {
          setState(() {
            errorMessage =
                responseData["message"] ?? "Invalid email or password!";
          });
        }
      },
      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF75B94A)),
      child: Text(text, style: TextStyle(color: Colors.white)),
    );
  }
}

// Save login status locally
Future<void> saveLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
}
