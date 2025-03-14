import os
import requests
import json
from dotenv import load_dotenv
from typing import Optional
from pydantic import BaseModel, Field
import re

# Load API Key securely from environment variable
load_dotenv()
API_KEY = os.getenv("OPENROUTER_API_KEY")
if not API_KEY:
    raise ValueError("API Key missing! Set OPENROUTER_API_KEY in environment variables.")

# OpenRouter API settings
URL = "https://openrouter.ai/api/v1/chat/completions"
MODEL_NAME = "google/gemma-2-9b-it:free"

# Validate model selection
VALID_MODELS = ["google/gemma-2-9b-it:free"]
if MODEL_NAME not in VALID_MODELS:
    raise ValueError(f"Invalid model '{MODEL_NAME}'. Choose from {VALID_MODELS}")

# Backend API endpoint for sending data
BACKEND_API = "https://ba7f-103-238-230-194.ngrok-free.app/api/crop/get-crop"

# Tamil & English Mapping for Soil and Crops
TAMIL_SOIL_MAP = {'சிவப்பு மண்': 'Red Soil', 'கருப்பு களிமண்': 'Black Clayey Soil', 'பழுப்பு மண்': 'Brown Soil', 'வண்டல் மண்': 'Alluvial Soil'}
TAMIL_CROP_MAP = {'நெல்': 'Rice', 'கரும்பு': 'Sugarcane', 'நிலக்கடலை': 'Groundnut', 'பருத்தி': 'Cotton', 'வாழை': 'Banana'}

# Pydantic Model for Structured Farming Information
class FarmingInfo(BaseModel):
    soil_type: Optional[str] = None
    crop_type: Optional[str] = None
    planting_date: Optional[str] = None  # YYYY-MM-DD format

# Extract JSON response safely
def extract_json(response_text):
    try:
        json_start = response_text.find('{')
        json_end = response_text.rfind('}') + 1
        return json.loads(response_text[json_start:json_end]) if json_start >= 0 else None
    except json.JSONDecodeError as e:
        print("JSON Parsing Error:", e)
        return None

# Call OpenRouter API for **structured** JSON data extraction
def extract_farming_info(conversation_text):
    """
    Extracts soil type and crop type from the conversation.
    Farmers must enter the planting date in YYYY-MM-DD format.
    """

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    system_message = (
        "You are an AI assistant that extracts farming information in JSON format."
        "You MUST return ONLY JSON with two fields: soil_type and crop_type."
        "The user will enter the planting date manually in YYYY-MM-DD format."
        "Ensure the JSON output follows this exact format:\n"
        "{\n"
        '  "soil_type": "Red Soil",\n'
        '  "crop_type": "Rice"\n'
        "}"
        "If any value is missing, return null. Do NOT return explanations, only JSON."
    )

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": system_message},
            {"role": "user", "content": conversation_text}
        ],
        "temperature": 0.1  # Low temperature for accuracy
    }

    response = requests.post(URL, headers=headers, json=payload, timeout=10)
    response.raise_for_status()
    response_text = response.json()["choices"][0]["message"]["content"]

    extracted_data = extract_json(response_text)

    if extracted_data:
        # Convert Tamil mappings if needed
        soil = TAMIL_SOIL_MAP.get(extracted_data.get("soil_type"), extracted_data.get("soil_type"))
        crop = TAMIL_CROP_MAP.get(extracted_data.get("crop_type"), extracted_data.get("crop_type"))

        return FarmingInfo(
            soil_type=soil,
            crop_type=crop,
        )

    return FarmingInfo()  # Return empty object if extraction fails

# Validate YYYY-MM-DD date format
def validate_date(date_str):
    """
    Checks if the given string is in YYYY-MM-DD format.
    """
    return bool(re.match(r"^\d{4}-\d{2}-\d{2}$", date_str))

# Function to send data to backend API
def send_to_backend(farming_data):
    """
    Sends the collected farming data to the backend API.
    
    Args:
        farming_data (FarmingInfo): The farming information to send
        
    Returns:
        dict: Response from the API or error information
    """
    # Prepare the payload
    payload = {
        "crop_type": farming_data.crop_type,
        "soil_type": farming_data.soil_type,
        "plantation_date": farming_data.planting_date
    }
    
    print(f"Sending data to backend API: {json.dumps(payload, indent=2)}")
    
    try:
        # Send the data to the backend
        headers = {"Content-Type": "application/json"}
        response = requests.post(BACKEND_API, json=payload, headers=headers, timeout=10)
        
        # Check if the request was successful
        if response.status_code == 200:
            print("✅ API call successful!")
            return {"success": True, "data": response.json()}
        else:
            print(f"❌ API call failed with status code: {response.status_code}")
            print(f"Response: {response.text}")
            return {"success": False, "error": f"Backend API returned status code {response.status_code}"}
    
    except Exception as e:
        print(f"❌ API call failed with exception: {str(e)}")
        return {"success": False, "error": str(e)}

def chat():
    print("🌾 Welcome to the Farmer Assistant! (Supports Tamil & English)")
    print("I will collect your soil type, crop type, and plantation date before continuing.\n")

    farming_data = FarmingInfo()  # Initialize empty farming data

    while not (farming_data.soil_type and farming_data.crop_type and farming_data.planting_date):
        if not farming_data.soil_type:
            user_input = input("> ").strip()
            extracted_info = extract_farming_info(user_input)
            if extracted_info.soil_type:
                farming_data.soil_type = extracted_info.soil_type
            else:
                print("🤖 What is your soil type? (e.g., Red Soil, Black Soil)")
                continue

        if not farming_data.crop_type:
            user_input = input("🤖 What crop are you growing? ").strip()
            extracted_info = extract_farming_info(user_input)
            if extracted_info.crop_type:
                farming_data.crop_type = extracted_info.crop_type
            else:
                print("⚠️ Please enter a valid crop type.")
                continue

        if not farming_data.planting_date:
            while True:
                planting_date = input("🤖 Enter the planting date in YYYY-MM-DD format (e.g., 2024-03-01): ").strip()
                if validate_date(planting_date):
                    farming_data.planting_date = planting_date
                    break
                else:
                    print("⚠️ Invalid format! Please enter the date as YYYY-MM-DD (e.g., 2024-03-01).")

    # Print Final JSON
    print("\n✅ Farming Information Collected:")
    print(json.dumps(farming_data.dict(), indent=2))
    
    # Send data to the backend API
    api_response = send_to_backend(farming_data)
    
    if api_response["success"]:
        print("\n✅ Data successfully sent to the server!")
        if "data" in api_response and api_response["data"]:
            print("\n📊 Server Response:")
            print(json.dumps(api_response["data"], indent=2))
    else:
        print("\n❌ Failed to send data to the server.")
        print(f"Error: {api_response.get('error', 'Unknown error')}")

    print("\n🌾 Now you can ask me any farming-related questions!")
    print("Type 'quit' to exit.\n")
    
    # Continue with farming questions
    while True:
        user_input = input("> ").strip()
        
        if user_input.lower() in ["quit", "exit"]:
            print("Thank you for using the Farmer Assistant. Goodbye!")
            break
        
        # Here you would typically handle the farming questions
        # For now, just give a simple response
        print("I'm here to help with your farming questions based on your soil type, crop, and planting date.")

# Run Chatbot
if __name__ == "__main__":
    chat()