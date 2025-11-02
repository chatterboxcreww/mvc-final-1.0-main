import firebase_admin
from firebase_admin import credentials, db
import google.generativeai as genai
import time
import json
import re


# Configuration
FIREBASE_DATABASE_URL = "https://trkd-12728-default-rtdb.asia-southeast1.firebasedatabase.app"
SERVICE_ACCOUNT_KEY = "serviceAccountKey.json"
GEMINI_API_KEY = "AIzaSyBs39z1L2l4qfX7ofYzkWUn4ZCwTcKcGsI"


# Your system prompt
SYSTEM_PROMPT = """You are a nutrition expert creating curated content for a health app. Generate meal/food items in this EXACT JSON format:

{
  "item001": {
    "title": "Food Item Name",
    "description": "Detailed description of the food item, ingredients, and preparation. Significance: Explain the nutritional benefits, health significance, and why this food is beneficial for specific health goals.",
    "keywords": ["keyword1", "keyword2", "keyword3"]
  },
  "item002": {
    "title": "Another Food Item Name", 
    "description": "Detailed description with significance explained.",
    "keywords": ["keyword1", "keyword2"]
  }
}

Use these keyword categories: veg, vegan, non_veg, gluten_free, high_protein, low_carb, high_fiber, diabetes_friendly, skinny_fat_friendly, breakfast, lunch, dinner, snack, salad, soup, smoothie, weight_loss, muscle_building, heart_healthy, brain_food.

Always include 'Significance:' in the description explaining health benefits. consider egg as non vegetarian food. give indian based food items."""


# Initialize Firebase Admin SDK
cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
firebase_admin.initialize_app(cred, {
    'databaseURL': FIREBASE_DATABASE_URL
})


# Initialize Google AI Studio (Gemini)
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-2.0-flash-exp')


def clean_response(text):
    """Clean AI response by removing markdown code blocks and parsing JSON if possible"""
    # Remove markdown code blocks (triple backticks)
    text = re.sub(r'\n```$', '', text, flags=re.MULTILINE)
    text = text.strip()
    
    # Try to parse as JSON
    try:
        parsed = json.loads(text)
        return parsed, True
    except json.JSONDecodeError:
        return text, False


def generate_content(prompt):
    """Generate content using Google AI Studio API"""
    try:
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"Error generating content: {e}")
        return None


def add_to_firebase(path, data):
    """Add data to Firebase Realtime Database"""
    try:
        ref = db.reference(path)
        new_ref = ref.push(data)
        print(f"✓ Data added with key: {new_ref.key}")
        return new_ref.key
    except Exception as e:
        print(f"Error adding to Firebase: {e}")
        return None


def main():
    print("=== Firebase + AI Studio Content Generator ===\n")
    
    user_input = input("Enter your prompt: ")
    full_prompt = f"{SYSTEM_PROMPT}\n\nUser request: {user_input}"
    
    print("\n🔄 Generating content...")
    generated_content = generate_content(full_prompt)
    
    if generated_content:
        # Clean the response
        cleaned_content, is_json = clean_response(generated_content)
        
        print(f"\n📝 Generated Content (cleaned):")
        if is_json:
            print(json.dumps(cleaned_content, indent=2))
        else:
            print(cleaned_content)
        
        # Prepare data structure
        data = {
            "prompt": user_input,
            "timestamp": int(time.time() * 1000),
            "created_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        }
        
        # Add content based on type
        if is_json:
            data["content"] = cleaned_content
            data["content_type"] = "json"
        else:
            data["content"] = cleaned_content
            data["content_type"] = "text"
        
        # Save to Firebase
        firebase_path = "/generated_content"
        key = add_to_firebase(firebase_path, data)
        
        if key:
            print(f"\n✓ Successfully saved to Firebase!")
            print(f"  View at: https://console.firebase.google.com/u/4/project/trkd-12728/database/trkd-12728-default-rtdb/data/~2Fgenerated_content~2F{key}")
    else:
        print("❌ Failed to generate content")


if __name__ == "__main__":
    main()
