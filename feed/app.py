"""
Flask API for Health App Feed Generation
Generates breakfast, lunch, and dinner feeds with comprehensive filtering
"""
import os
import json
import time
from datetime import datetime
from flask import Flask, jsonify, request, render_template
import firebase_admin
from firebase_admin import credentials, db
import google.generativeai as genai

app = Flask(__name__)

# Configuration
FIREBASE_DATABASE_URL = os.getenv('FIREBASE_DATABASE_URL', 'https://trkd-12728-default-rtdb.asia-southeast1.firebasedatabase.app')
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', 'AIzaSyBs39z1L2l4qfX7ofYzkWUn4ZCwTcKcGsI')
SERVICE_ACCOUNT_KEY = os.getenv('SERVICE_ACCOUNT_KEY', 'serviceAccountKey.json')

# Initialize Firebase
try:
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
        firebase_admin.initialize_app(cred, {
            'databaseURL': FIREBASE_DATABASE_URL
        })
    print("✓ Firebase initialized successfully")
except Exception as e:
    print(f"⚠ Firebase initialization error: {e}")

# Initialize Gemini AI
try:
    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel('gemini-2.0-flash-exp')
    print("✓ Gemini AI initialized successfully")
except Exception as e:
    print(f"⚠ Gemini AI initialization error: {e}")

# System Prompt for AI Generation
SYSTEM_PROMPT = """You are a nutrition expert creating curated Indian food content for a health app. 

Generate meal/food items in this EXACT JSON format:
{
  "item001": {
    "title": "Food Item Name",
    "description": "Detailed description of the food item, ingredients, and preparation. Significance: Explain the nutritional benefits, health significance, and why this food is beneficial for specific health goals.",
    "keywords": ["keyword1", "keyword2", "keyword3"],
    "allergens": ["allergen1", "allergen2"],
    "goodForDiseases": ["disease1", "disease2"],
    "badForDiseases": ["disease1", "disease2"],
    "healthBenefit": "Specific health benefits explanation",
    "category": "breakfast/lunch/dinner",
    "imagePlaceholder": "assets/food/placeholder.jpg"
  }
}

IMPORTANT RULES:
1. Consider eggs as NON-VEGETARIAN food
2. Focus on INDIAN-BASED food items
3. Always include 'Significance:' in the description explaining health benefits
4. Provide at least 3-5 options for EACH keyword combination
5. Ensure comprehensive coverage of all keyword combinations

KEYWORD CATEGORIES:
- Diet: veg, vegan, non_veg
- Allergen-free: gluten_free, dairy_free, nut_free
- Nutrition: high_protein, low_carb, high_fiber, low_fat
- Health: diabetes_friendly, heart_healthy, weight_loss, muscle_building
- Meal Type: breakfast, lunch, dinner, snack
- Dish Type: salad, soup, smoothie, curry, rice, bread
- Special: skinny_fat_friendly, brain_food, immunity_boost

ALLERGEN INFORMATION:
- List ALL potential allergens: gluten, dairy, nuts, soy, eggs, fish, shellfish, etc.
- Use "none" if no common allergens
DISEASE INFORMATION:
- goodForDiseases: List conditions this food helps (diabetes, heart_disease, obesity, etc.)
- badForDiseases: List conditions that should avoid this food

Generate diverse, nutritious Indian meals with complete health information."""

@app.route('/')
def index():
    """Dashboard homepage"""
    return render_template('index.html')

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'firebase': 'connected' if firebase_admin._apps else 'disconnected',
        'ai': 'configured'
    })

@app.route('/api/generate-feed', methods=['POST'])
def generate_feed():
    """Generate feed for specific meal type"""
    try:
        data = request.get_json() or {}
        meal_type = data.get('meal_type', 'breakfast')  # breakfast, lunch, dinner
        count = data.get('count', 20)
        
        prompt = f"{SYSTEM_PROMPT}\n\nGenerate {count} diverse {meal_type} items covering all keyword combinations."
        
        response = model.generate_content(prompt)
        generated_text = response.text
        
        # Clean and parse JSON
        cleaned_json = clean_json_response(generated_text)
        
        if cleaned_json:
            # Save to Firebase
            ref = db.reference(f'curatedContent/{meal_type}/items')
            ref.set(cleaned_json)
            
            return jsonify({
                'success': True,
                'meal_type': meal_type,
                'items_generated': len(cleaned_json),
                'timestamp': datetime.now().isoformat()
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to parse AI response'
            }), 500
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/generate-all-feeds', methods=['POST'])
def generate_all_feeds():
    """Generate all meal feeds (breakfast, lunch, dinner)"""
    try:
        results = {}
        
        for meal_type in ['breakfast', 'lunch', 'dinner']:
            prompt = f"{SYSTEM_PROMPT}\n\nGenerate 25 diverse {meal_type} items covering all keyword combinations."
            
            response = model.generate_content(prompt)
            generated_text = response.text
            
            cleaned_json = clean_json_response(generated_text)
            
            if cleaned_json:
                ref = db.reference(f'curatedContent/{meal_type}/items')
                ref.set(cleaned_json)
                results[meal_type] = len(cleaned_json)
                time.sleep(2)  # Rate limiting
            else:
                results[meal_type] = 0
        
        return jsonify({
            'success': True,
            'results': results,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/get-feed/<meal_type>')
def get_feed(meal_type):
    """Get current feed from Firebase"""
    try:
        ref = db.reference(f'curatedContent/{meal_type}/items')
        data = ref.get()
        
        return jsonify({
            'success': True,
            'meal_type': meal_type,
            'items': data or {},
            'count': len(data) if data else 0
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/upload-static-feed', methods=['POST'])
def upload_static_feed():
    """Upload pre-generated comprehensive feed"""
    try:
        # Load comprehensive feed
        with open('comprehensive_indian_food_feed.json', 'r', encoding='utf-8') as f:
            feed_data = json.load(f)
        
        # Upload to Firebase
        for meal_type in ['breakfast', 'lunch', 'dinner']:
            if meal_type in feed_data:
                ref = db.reference(f'curatedContent/{meal_type}/items')
                ref.set(feed_data[meal_type])
        
        return jsonify({
            'success': True,
            'message': 'Static feed uploaded successfully',
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

def clean_json_response(text):
    """Clean AI response and extract JSON"""
    import re
    
    # Remove markdown code blocks
    text = re.sub(r'```json\s*', '', text)
    text = re.sub(r'```\s*', '', text)
    text = text.strip()
    
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # Try to find JSON object in text
        match = re.search(r'\{.*\}', text, re.DOTALL)
        if match:
            try:
                return json.loads(match.group())
            except:
                pass
    return None

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
