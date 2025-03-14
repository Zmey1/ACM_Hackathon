// llm_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LLMService {
  // Singleton pattern
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  // API settings
  final String openRouterApiUrl =
      "https://openrouter.ai/api/v1/chat/completions";
  final String backendApiUrl =
      "https://ba7f-103-238-230-194.ngrok-free.app/api/crop/get-crop";
  final String modelName = "google/gemma-2-9b-it:free";

  // Secure storage for API key
  final _storage = FlutterSecureStorage();

  // Tamil & English Mapping for Soil and Crops
  final Map<String, String> tamilSoilMap = {
    'சிவப்பு மண்': 'Red Soil',
    'கருப்பு களிமண்': 'Black Clayey Soil',
    'பழுப்பு மண்': 'Brown Soil',
    'வண்டல் மண்': 'Alluvial Soil'
  };

  final Map<String, String> tamilCropMap = {
    'நெல்': 'Rice',
    'கரும்பு': 'Sugarcane',
    'நிலக்கடலை': 'Groundnut',
    'பருத்தி': 'Cotton',
    'வாழை': 'Banana'
  };

  // Set API key securely
  Future<void> setApiKey(String apiKey) async {
    await _storage.write(key: 'openrouter_api_key', value: apiKey);
  }

  // Get API key securely
  Future<String?> getApiKey() async {
    return await _storage.read(key: 'openrouter_api_key');
  }

  // Extract JSON from LLM response
  Map<String, dynamic>? _extractJson(String responseText) {
    try {
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = responseText.substring(jsonStart, jsonEnd);
        return json.decode(jsonStr);
      }
      return null;
    } catch (e) {
      print("JSON Parsing Error: $e");
      return null;
    }
  }

  // Extract farming information using OpenRouter API
  Future<Map<String, dynamic>> extractFarmingInfo(String text) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      // Fallback to local extraction if no API key
      return _localExtractFarmingInfo(text);
    }

    try {
      final headers = {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json"
      };

      final systemMessage =
          "You are an AI assistant that extracts farming information in JSON format. "
          "You MUST return ONLY JSON with two fields: soil_type and crop_type. "
          "The user will enter the planting date manually in YYYY-MM-DD format. "
          "Ensure the JSON output follows this exact format:\n"
          "{\n"
          '  "soil_type": "Red Soil",\n'
          '  "crop_type": "Rice"\n'
          "}"
          "If any value is missing, return null. Do NOT return explanations, only JSON.";

      final payload = {
        "model": modelName,
        "messages": [
          {"role": "system", "content": systemMessage},
          {"role": "user", "content": text}
        ],
        "temperature": 0.1 // Low temperature for accuracy
      };

      final response = await http
          .post(
            Uri.parse(openRouterApiUrl),
            headers: headers,
            body: json.encode(payload),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final content = responseData["choices"][0]["message"]["content"];

        final extractedData = _extractJson(content);
        if (extractedData != null) {
          // Convert Tamil mappings if needed
          String? soil = extractedData['soil_type'];
          String? crop = extractedData['crop_type'];

          if (soil != null) {
            soil = tamilSoilMap[soil] ?? soil;
          }

          if (crop != null) {
            crop = tamilCropMap[crop] ?? crop;
          }

          return {
            'soil_type': soil,
            'crop_type': crop,
          };
        }
      }

      // If API call fails, fall back to local extraction
      return _localExtractFarmingInfo(text);
    } catch (e) {
      print("Error calling OpenRouter API: $e");
      return _localExtractFarmingInfo(text);
    }
  }

  // Local extraction as a fallback
  Map<String, dynamic> _localExtractFarmingInfo(String text) {
    final textLower = text.toLowerCase();
    String? soil;
    String? crop;

    // Check for soil types
    if (textLower.contains('red') || textLower.contains('சிவப்பு')) {
      soil = 'Red Soil';
    } else if (textLower.contains('black') || textLower.contains('கருப்பு')) {
      soil = 'Black Clayey Soil';
    } else if (textLower.contains('brown') || textLower.contains('பழுப்பு')) {
      soil = 'Brown Soil';
    } else if (textLower.contains('alluvial') || textLower.contains('வண்டல்')) {
      soil = 'Alluvial Soil';
    }

    // Check for crop types
    if (textLower.contains('rice') || textLower.contains('நெல்')) {
      crop = 'Rice';
    } else if (textLower.contains('sugarcane') ||
        textLower.contains('கரும்பு')) {
      crop = 'Sugarcane';
    } else if (textLower.contains('groundnut') ||
        textLower.contains('நிலக்கடலை')) {
      crop = 'Groundnut';
    } else if (textLower.contains('cotton') || textLower.contains('பருத்தி')) {
      crop = 'Cotton';
    } else if (textLower.contains('banana') || textLower.contains('வாழை')) {
      crop = 'Banana';
    }

    return {
      'soil_type': soil,
      'crop_type': crop,
    };
  }

  // Validate date format
  bool validateDate(String dateStr) {
    final RegExp dateRegex = RegExp(r"^\d{4}-\d{2}-\d{2}$");
    return dateRegex.hasMatch(dateStr);
  }

  // Call backend API when all three variables are filled
  Future<Map<String, dynamic>> sendFarmingData({
    required String soilType,
    required String cropType,
    required String plantingDate,
  }) async {
    try {
      print(
          "Sending data to backend: soil=$soilType, crop=$cropType, date=$plantingDate");

      final response = await http
          .post(
            Uri.parse(backendApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'soil_type': soilType,
              'crop_type': cropType,
              'plantation_date': plantingDate
            }),
          )
          .timeout(Duration(seconds: 10));

      print("Backend API response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        print("Backend API error: ${response.body}");
        return {
          'success': false,
          'error': 'Server returned status code ${response.statusCode}'
        };
      }
    } catch (e) {
      print("Exception calling backend API: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get farming advice using OpenRouter API
  Future<String> getFarmingAdvice(
      String query, Map<String, dynamic> farmingContext) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return _getLocalFarmingAdvice(query, farmingContext);
    }

    try {
      final headers = {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json"
      };

      final contextJson = json.encode(farmingContext);
      final systemMessage =
          "You are a knowledgeable farming assistant providing advice to farmers in both English and Tamil. "
          "Use the following context about their farm:\n$contextJson\n\n"
          "Provide specific, practical advice relevant to their query and farming context. "
          "Keep responses concise but informative. If you're unsure, suggest seeking advice from local agricultural extension services.";

      final payload = {
        "model": modelName,
        "messages": [
          {"role": "system", "content": systemMessage},
          {"role": "user", "content": query}
        ],
        "temperature": 0.7
      };

      final response = await http
          .post(
            Uri.parse(openRouterApiUrl),
            headers: headers,
            body: json.encode(payload),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData["choices"][0]["message"]["content"];
      }

      // Fall back to local advice if API fails
      return _getLocalFarmingAdvice(query, farmingContext);
    } catch (e) {
      print("Error getting farming advice: $e");
      return _getLocalFarmingAdvice(query, farmingContext);
    }
  }

  // Local advice generation as a fallback
  String _getLocalFarmingAdvice(String query, Map<String, dynamic> context) {
    final String soil = context['soil_type'] ?? 'unknown soil type';
    final String crop = context['crop_type'] ?? 'unknown crop';
    final String plantingDate = context['planting_date'] ?? 'unknown date';

    final queryLower = query.toLowerCase();

    // Simple rule-based responses
    if (queryLower.contains('water') || queryLower.contains('irrigation')) {
      if (crop == 'Rice') {
        return "Rice typically requires standing water in the field. Ensure 5-7 cm of water depth during the growing season.";
      } else if (crop == 'Sugarcane') {
        return "Sugarcane needs regular irrigation. With your $soil, I recommend irrigation every 7-10 days.";
      } else {
        return "Your $crop crop should be watered regularly based on soil moisture conditions.";
      }
    } else if (queryLower.contains('fertilizer') ||
        queryLower.contains('nutrient')) {
      if (soil == 'Red Soil') {
        return "Red soils often need additional nitrogen. For your $crop, apply a balanced NPK fertilizer with extra nitrogen.";
      } else if (soil == 'Black Clayey Soil') {
        return "Black clayey soils are rich in nutrients but may need extra phosphorus for $crop.";
      } else {
        return "Apply balanced fertilizer suitable for $crop based on a soil test.";
      }
    } else if (queryLower.contains('pest') || queryLower.contains('disease')) {
      if (crop == 'Rice') {
        return "Monitor for rice blast, bacterial leaf blight, and stem borers. Early detection is key to management.";
      } else if (crop == 'Cotton') {
        return "Watch for bollworms and aphids. Consider integrated pest management practices.";
      } else {
        return "Regular inspection of your $crop plants can help detect pests early. Look for discolored leaves and unusual growth patterns.";
      }
    } else if (queryLower.contains('harvest')) {
      return "Based on your planting date of $plantingDate, you should be ready to harvest in about [timeframe] under optimal conditions.";
    } else {
      return "I understand you're growing $crop in $soil soil, planted on $plantingDate. How else can I assist with your farming needs?";
    }
  }
}
