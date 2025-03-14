import 'package:agricare/pages/dashboardpage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'llm_service.dart'; // Import the LLM service

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final LLMService _llmService = LLMService();

  // Farming data
  String? soilType;
  String? cropType;
  String? plantingDate;
  bool dataCollectionComplete = false;
  bool isLoading = false;
  bool apiCallInProgress = false;
  Map<String, dynamic>? apiResponse;

  @override
  void initState() {
    super.initState();
    _addBotMessage(
        "🌾 Welcome to the Farmer Assistant! I'll help you with farming advice. First, I need to collect some information.");
    _addBotMessage("What is your soil type? (e.g., Red Soil, Black Soil)");
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add({"sender": "bot", "text": message});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    String message = _controller.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({"sender": "user", "text": message});
        _controller.clear();
        isLoading = true;
      });

      _scrollToBottom();

      if (!dataCollectionComplete) {
        _processFarmingData(message);
      } else {
        _sendChatMessage(message);
      }
    }
  }

  Future<void> _processFarmingData(String userInput) async {
    try {
      if (soilType == null) {
        final extractedInfo = await _llmService.extractFarmingInfo(userInput);
        if (extractedInfo != null && extractedInfo['soil_type'] != null) {
          soilType = extractedInfo['soil_type'];
          _addBotMessage("Got it! Your soil type is: $soilType");
          _addBotMessage("What crop are you growing?");
        } else {
          _addBotMessage(
              "I couldn't understand the soil type. Please specify a soil type.");
        }
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (cropType == null) {
        final extractedInfo = await _llmService.extractFarmingInfo(userInput);
        if (extractedInfo != null && extractedInfo['crop_type'] != null) {
          cropType = extractedInfo['crop_type'];
          _addBotMessage("Great! You're growing: $cropType");
          _addBotMessage("Enter the planting date in YYYY-MM-DD format:");
        } else {
          _addBotMessage(
              "I couldn't understand the crop type. Please specify a valid crop.");
        }
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (plantingDate == null) {
        if (_llmService.validateDate(userInput)) {
          plantingDate = userInput;
          _addBotMessage("Please wait while I analyze your farming data...");

          setState(() {
            apiCallInProgress = true;
          });

          final response = await _llmService.sendFarmingData(
              soilType: soilType!,
              cropType: cropType!,
              plantingDate: plantingDate!);

          setState(() {
            isLoading = false;
            apiCallInProgress = false;
          });

          if (response['success']) {
            apiResponse = response['data'];
            dataCollectionComplete = true;
            _displayApiResponse(response['data']);
            _addBotMessage(
                "✅ All information collected! Now you can ask farming-related questions.");
          } else {
            _addBotMessage("❌ Server error: ${response['error']}");
            dataCollectionComplete = true;
          }
        } else {
          _addBotMessage(
              "⚠ Invalid date format! Please enter in YYYY-MM-DD format.");
        }
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        apiCallInProgress = false;
      });
      _addBotMessage("There was an error processing your information.");
      print('Error processing farming data: $e');
    }
  }

  void _displayApiResponse(Map<String, dynamic> data) {
    String responseMessage = "📊 Based on your information:\n";
    data.forEach((key, value) {
      if (value != null && key != 'success') {
        responseMessage += "• $key: $value\n";
      }
    });
    _addBotMessage(responseMessage);
  }

  Future<void> _sendChatMessage(String message) async {
    try {
      final context = {
        'soil_type': soilType,
        'crop_type': cropType,
        'planting_date': plantingDate,
        'api_response': apiResponse
      };

      final response = await _llmService.getFarmingAdvice(message, context);

      setState(() {
        isLoading = false;
      });

      _addBotMessage(response);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _addBotMessage("I'm experiencing an issue. Please try again.");
      print('Error sending chat message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("AgriBot"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg["sender"] == "user";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    enabled: !isLoading && !apiCallInProgress,
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed:
                      (isLoading || apiCallInProgress) ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
