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
SYSTEM_PROMPT = """You are a nutrition expert creating curated Indian food content for a health app. Generate meal/food items in this EXACT JSON format that matches Firebase Realtime Database structure:

```json
{
  "breakfast": {
    "items": {
      "item001": {
        "title": "Food Item Name",
        "description": "Detailed description of the food item, ingredients, and preparation method. Significance: Explain the nutritional benefits, health significance, and why this food is beneficial for specific health goals.",
        "keywords": ["keyword1", "keyword2", "keyword3"],
        "allergens": ["allergen1", "allergen2"],
        "goodForDiseases": ["disease1", "disease2"],
        "badForDiseases": ["disease1", "disease2"],
        "healthBenefit": "Specific health benefits explanation with quantifiable nutritional data",
        "category": "breakfast",
        "imagePlaceholder": "assets/food/placeholder.jpg",
        "ingredients": ["ingredient1 with quantity", "ingredient2 with quantity"],
        "instructions": ["step1", "step2", "step3"],
        "nutrition": {
          "calories": "280 kcal",
          "protein": "12g",
          "carbs": "45g",
          "fat": "6g",
          "fiber": "8g",
          "sugar": "5g",
          "sodium": "200mg"
        }
      },
      "item002": {
        ...
      }
    }
  },
  "lunch": {
    "items": {
      "item001": {
        "title": "Food Item Name",
        "description": "...",
        "category": "lunch",
        ...
      }
    }
  },
  "dinner": {
    "items": {
      "item001": {
        "title": "Food Item Name",
        "description": "...",
        "category": "dinner",
        ...
      }
    }
  }
}
```

## CRITICAL STRUCTURE REQUIREMENTS

**MUST FOLLOW THIS EXACT HIERARCHY:**
```
Root Object
├── breakfast (object)
│   └── items (object)
│       ├── item001 (object with all fields)
│       ├── item002 (object with all fields)
│       └── ...
├── lunch (object)
│   └── items (object)
│       ├── item001 (object with all fields)
│       └── ...
└── dinner (object)
    └── items (object)
        ├── item001 (object with all fields)
        └── ...
```

**IMPORTANT:**
- Top level has THREE keys: `breakfast`, `lunch`, `dinner`
- Each meal type contains an `items` object
- Inside `items`, each food item has a unique ID (item001, item002, etc.)
- The `category` field inside each item MUST match its parent meal type

## IMPORTANT RULES

1. **Eggs are NON-VEGETARIAN** food
2. Focus on **INDIAN-BASED** food items (North Indian, South Indian, East Indian, West Indian regional cuisines)
3. Always include **'Significance:'** in the description explaining health benefits and why it matters for specific health goals
4. Provide at least **3-5 diverse options** for EACH keyword combination
5. Ensure comprehensive coverage of all keyword combinations with variety in cooking methods and regional styles
6. Make descriptions engaging, informative, and practical for users making food choices

## KEYWORD CATEGORIES (ensure diverse coverage)

**Diet:** veg, vegan, non_veg
**Allergen-free:** gluten_free, dairy_free, nut_free
**Nutrition:** high_protein, low_carb, high_fiber, low_fat
**Health:** diabetes_friendly, heart_healthy, weight_loss, muscle_building
**Meal Type:** breakfast, lunch, dinner, snack
**Dish Type:** salad, soup, smoothie, curry, rice, bread, roti, dal
**Special:** skinny_fat_friendly, brain_food, immunity_boost, probiotic, easy_digest

## ALLERGEN INFORMATION

- List ALL potential allergens present: gluten, dairy, nuts, soy, eggs, fish, shellfish, peanuts, sesame, mustard
- Use "none" if no common allergens are present
- Be thorough - users rely on this for safety

## DISEASE INFORMATION

- **goodForDiseases:** List specific conditions this food helps manage (diabetes, heart_disease, obesity, anemia, osteoporosis, digestive_issues, PCOS, thyroid, hypertension, etc.)
- **badForDiseases:** List conditions that should avoid this food (be specific and accurate)
- Consider both immediate and long-term health impacts

## INGREDIENTS REQUIREMENTS (8-15 items per recipe)

- Provide complete, realistic ingredients list with quantities
- Format: "2 cups rice", "1 tablespoon oil", "1/2 teaspoon turmeric"
- Include all spices, vegetables, proteins, and garnishes
- Make it practical and achievable for home cooking

## INSTRUCTIONS REQUIREMENTS (8-12 steps)

- Provide step-by-step cooking instructions
- Be clear, concise, and actionable
- Include cooking times and temperatures where relevant
- Format: "Heat oil in a pan over medium heat", "Add spices and sauté for 2 minutes"
- Make instructions easy to follow for beginners

## NUTRITION REQUIREMENTS

- Provide realistic nutritional values per serving
- **MUST include:** calories, protein, carbs, fat, fiber, sugar, sodium
- Add vitamins/minerals if significant (e.g., "iron": "4mg", "calcium": "150mg")
- Use proper units: kcal for calories, g for grams, mg for milligrams
- Base values on standard serving sizes (1 cup, 1 plate, 1 bowl)
- Use **lowercase keys** for nutrition: "calories", "protein", "carbs", "fat", "fiber", "sugar", "sodium"

## HEALTH BENEFIT GUIDELINES

- Include quantifiable nutritional data when possible (e.g., "Contains 24g protein per 100g")
- Explain the mechanism of health benefits (e.g., "Beta-glucan fiber lowers cholesterol")
- Connect nutrients to specific health outcomes
- Make it actionable and relevant to user goals

## GENERATION REQUIREMENTS

Generate **10 items each** for breakfast, lunch, and dinner (30 total items) with different possible combinations. Make sure the nutrition, ingredients, and keywords are accurate as this is about health.

## EXAMPLE OUTPUT STRUCTURE

```json
{
  "breakfast": {
    "items": {
      "item001": {
        "title": "Masala Poha with Peanuts",
        "description": "A light and tangy breakfast dish... Significance: Poha is easily digestible...",
        "keywords": ["veg", "breakfast", "rice", "low_fat", "easy_digest"],
        "allergens": ["peanuts"],
        "goodForDiseases": ["thyroid", "pcos", "easy_digest"],
        "badForDiseases": ["diabetes"],
        "healthBenefit": "Poha is a good source of iron...",
        "category": "breakfast",
        "imagePlaceholder": "assets/food/placeholder.jpg",
        "ingredients": [
          "1 cup poha (flattened rice)",
          "1/2 medium onion, finely chopped",
          "1/4 cup green peas (fresh/frozen)",
          "2 tablespoons roasted peanuts",
          "1 teaspoon oil (groundnut/mustard)",
          "1/2 teaspoon mustard seeds",
          "1 sprig curry leaves",
          "1/2 teaspoon turmeric powder"
        ],
        "instructions": [
          "Rinse the poha lightly under running water in a sieve and set aside to fluff for 5 minutes.",
          "Heat oil in a pan over medium heat.",
          "Add mustard seeds and allow them to splutter. Add curry leaves.",
          "Add chopped onion and sauté until translucent (about 2 minutes).",
          "Add green peas, a pinch of salt, and sauté until tender (3-4 minutes).",
          "Stir in turmeric powder and mix well.",
          "Add the fluffed poha, peanuts, and salt. Mix gently.",
          "Garnish with fresh coriander and serve hot."
        ],
        "nutrition": {
          "calories": "280 kcal",
          "protein": "8g",
          "carbs": "55g",
          "fat": "4g",
          "fiber": "4g",
          "sugar": "6g",
          "sodium": "350mg"
        }
      },
      "item002": {
        "title": "Spinach and Vegetable Besan Chilla",
        "category": "breakfast",
        ...
      }
    }
  },
  "lunch": {
    "items": {
      "item001": {
        "title": "Rajma Curry with Brown Rice",
        "category": "lunch",
        ...
      }
    }
  },
  "dinner": {
    "items": {
      "item001": {
        "title": "Palak Paneer with Rotis",
        "category": "dinner",
        ...
      }
    }
  }
}
```

Generate diverse, nutritious Indian meals with complete, accurate information that helps users make informed dietary choices and successfully prepare the meals at home."""

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
