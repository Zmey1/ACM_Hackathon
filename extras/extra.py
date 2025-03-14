import os
import requests
import json
import re
from langdetect import detect
from dotenv import load_dotenv
from typing import Optional
from pydantic import BaseModel, Field

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

# Tamil & English Mapping for Soil and Crops
TAMIL_SOIL_MAP = {'சிவப்பு மண்': 'Red Soil', 'கருப்பு களிமண்': 'Black Clayey Soil', 'பழுப்பு மண்': 'Brown Soil', 'வண்டல் மண்': 'Alluvial Soil'}
TAMIL_CROP_MAP = {'நெல்': 'Rice', 'கரும்பு': 'Sugarcane', 'நிலக்கடலை': 'Groundnut', 'பருத்தி': 'Cotton', 'வாழை': 'Banana'}

# Crop Growth Stages in Days
CROP_GROWTH_STAGES = {
    "Rice": [30, 30, 60], "Sugarcane": [35, 60, 180], "Groundnut": [25, 35, 45],
    "Cotton": [30, 50, 60], "Banana": [40, 80, 120]
}

# Pydantic Model for Structured Farming Information
class FarmingInfo(BaseModel):
    soil_type: Optional[str] = None
    crop_type: Optional[str] = None
    planting_date: Optional[str] = None
    growth_stage: Optional[str] = None

# Detect Language (Tamil or English)
def detect_language(text):
    try:
        return detect(text)
    except:
        return "unknown"

# Extract JSON response safely
def extract_json(response_text):
    try:
        json_start = response_text.find('{')
        json_end = response_text.rfind('}') + 1
        return json.loads(response_text[json_start:json_end]) if json_start >= 0 else None
    except json.JSONDecodeError as e:
        print("JSON Parsing Error:", e)
        return None

# Determine Crop Growth Stage
def determine_growth_stage(days_ago, crop_type):
    stages = CROP_GROWTH_STAGES.get(crop_type, [30, 40, 60])  # Default if crop not in dictionary
    if days_ago <= stages[0]: return "initial"
    elif days_ago <= sum(stages[:2]): return "development"
    elif days_ago <= sum(stages): return "mid_season"
    else: return "late_season"

# Call OpenRouter API for normal chat responses
def call_openrouter_api(user_input):
    """
    Calls OpenRouter API and ensures chatty but farming-specific responses.
    """
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    system_message = (
        "You are a helpful farming assistant. You **only** talk about farming topics. "
        "You give advice on crops, soil, irrigation, fertilizers, pests, and related agricultural topics. "
        "You do NOT discuss politics, finance, entertainment, or unrelated topics. "
        "Keep your responses friendly, helpful, and practical for farmers."
    )

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": system_message},
            {"role": "user", "content": user_input}
        ],
        "temperature": 0.7  # Chatty but still informative
    }

    response = requests.post(URL, headers=headers, json=payload)
    response.raise_for_status()

    response_text = response.json()["choices"][0]["message"]["content"]
    return response_text

# Call OpenRouter API for **structured** JSON data extraction
def extract_farming_info(conversation_text):
    """
    Extracts soil type, crop type, planting date, and growth stage from the conversation.
    """

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    system_message = (
        "You are an AI assistant specializing in farming. "
        "Analyze the user's conversation and extract **only farming-related details** in **STRICT JSON format**. "
        "Return **ONLY JSON** without any explanation. "
        "If any value is missing, return **null** instead of text."
    )

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": system_message},
            {"role": "user", "content": conversation_text}
        ],
        "temperature": 0.1  # Low temperature for accuracy
    }

    response = requests.post(URL, headers=headers, json=payload, timeout=10)  # Reduce delay
    response.raise_for_status()

    response_text = response.json()["choices"][0]["message"]["content"]

    extracted_data = extract_json(response_text)

    if extracted_data:
        return FarmingInfo(
            soil_type=TAMIL_SOIL_MAP.get(extracted_data.get("soil_type"), extracted_data.get("soil_type")),
            crop_type=TAMIL_CROP_MAP.get(extracted_data.get("crop_type"), extracted_data.get("crop_type")),
            planting_date=extracted_data.get("planting_date"),
            growth_stage=extracted_data.get("growth_stage"),
        )

    return FarmingInfo()  # Return empty object if extraction fails

# Chat with User
def chat():
    print("🌾 Welcome to the Farmer Assistant! (Supports Tamil & English)")
    print("Type 'quit' to exit. Type 'json' to see collected data.\n")

    conversation_history = []
    farming_data = FarmingInfo()  # Initialize empty farming data

    while True:
        user_input = input("> ").strip()

        if user_input.lower() == "quit":
            print("Goodbye! 👋")
            break

        if user_input.lower() == "json":
            if farming_data.soil_type or farming_data.crop_type or farming_data.planting_date:
                print("\n🌾 Extracted Farming Data:")
                print(json.dumps(farming_data.dict(), indent=2))
            else:
                print("\n⚠️ No farming data has been detected yet in the conversation.")
            continue

        # Ensure AI still responds even when extracting JSON
        extracted_info = extract_farming_info(user_input)

        # Update farming data if new info is found
        updated = False
        if extracted_info.soil_type:
            farming_data.soil_type = extracted_info.soil_type
            updated = True
        if extracted_info.crop_type:
            farming_data.crop_type = extracted_info.crop_type
            updated = True
        if extracted_info.planting_date:
            farming_data.planting_date = extracted_info.planting_date
            updated = True
        if extracted_info.growth_stage:
            farming_data.growth_stage = extracted_info.growth_stage
            updated = True

        # Let AI generate a response even when JSON is extracted
        ai_response = call_openrouter_api(user_input)

        # If new farming data was extracted, summarize the info & continue chat
        if updated:
            print("🤖 Got it! I’ve noted down your farming details.")
            print(f"🌱 Soil: {farming_data.soil_type}, Crop: {farming_data.crop_type}, Planted: {farming_data.planting_date}\n")
        
        # Always respond chattily
        print("🤖", ai_response)

        # Save chat history
        conversation_history.append({"role": "user", "content": user_input})
        conversation_history.append({"role": "assistant", "content": ai_response})

# Run Chatbot
if __name__ == "__main__":
    chat()
