"""
Script to generate comprehensive Indian food feed with all keyword combinations
Run this locally to generate a complete feed database
"""
import json
import time
import google.generativeai as genai

# Initialize Gemini AI
GEMINI_API_KEY = "AIzaSyBs39z1L2l4qfX7ofYzkWUn4ZCwTcKcGsI"
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-2.0-flash-exp')

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
    "imagePlaceholder": "assets/food/placeholder.jpg",
    "ingredients": ["ingredient1", "ingredient2"],
    "instructions": ["step1", "step2"],
    "nutrition": {
      "calories": "280 kcal",
      "protein": "12g",
      "carbs": "45g",
      "fat": "6g",
      "fiber": "8g"
    }
  }
}

IMPORTANT RULES:
1. Consider eggs as NON-VEGETARIAN food
2. Focus on INDIAN-BASED food items (North Indian, South Indian, regional cuisines)
3. Always include 'Significance:' in the description explaining health benefits
4. Provide DIVERSE options covering ALL keyword combinations
5. Include complete ingredients list and cooking instructions
6. Provide accurate nutritional information

KEYWORD CATEGORIES (ensure coverage):
- Diet: veg, vegan, non_veg
- Allergen-free: gluten_free, dairy_free, nut_free
- Nutrition: high_protein, low_carb, high_fiber, low_fat
- Health: diabetes_friendly, heart_healthy, weight_loss, muscle_building
- Meal Type: breakfast, lunch, dinner, snack
- Dish Type: salad, soup, smoothie, curry, rice, bread, roti
- Special: skinny_fat_friendly, brain_food, immunity_boost, probiotic, easy_digest

ALLERGEN INFORMATION:
- List ALL potential allergens: gluten, dairy, nuts, soy, eggs, fish, shellfish, peanuts
- Use "none" if no common allergens

DISEASE INFORMATION:
- goodForDiseases: diabetes, heart_disease, obesity, anemia, osteoporosis, digestive_issues, etc.
- badForDiseases: List conditions that should avoid this food

INGREDIENTS & INSTRUCTIONS:
- Provide complete, realistic ingredients list
- Include step-by-step cooking instructions (8-10 steps)
- Make it practical and achievable

NUTRITION:
- Provide realistic nutritional values per serving
- Include: calories, protein, carbs, fat, fiber, sugar, sodium
- Add vitamins/minerals if significant

Generate diverse, nutritious Indian meals with complete information."""

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

def generate_meal_feed(meal_type, count=30):
    """Generate feed for specific meal type"""
    print(f"\n🔄 Generating {count} {meal_type} items...")
    
    prompt = f"""{SYSTEM_PROMPT}

Generate {count} diverse {meal_type} items covering these combinations:
- Vegetarian high-protein options (5 items)
- Vegan high-protein options (5 items)
- Non-vegetarian high-protein options (5 items)
- Diabetes-friendly options (5 items)
- Weight loss options (5 items)
- Gluten-free options (3 items)
- Heart-healthy options (2 items)

Ensure variety in:
- Cooking methods (grilled, steamed, baked, raw, fermented)
- Dish types (curry, salad, soup, rice, bread, smoothie)
- Regional cuisines (North, South, East, West Indian)
- Nutritional profiles (high-protein, low-carb, high-fiber)

Make each item unique and practical."""

    try:
        response = model.generate_content(prompt)
        generated_text = response.text
        
        cleaned_json = clean_json_response(generated_text)
        
        if cleaned_json:
            print(f"✓ Generated {len(cleaned_json)} {meal_type} items")
            return cleaned_json
        else:
            print(f"✗ Failed to parse {meal_type} response")
            return {}
            
    except Exception as e:
        print(f"✗ Error generating {meal_type}: {e}")
        return {}

def main():
    """Generate comprehensive feed for all meal types"""
    print("=== Comprehensive Indian Food Feed Generator ===")
    
    comprehensive_feed = {}
    
    for meal_type in ['breakfast', 'lunch', 'dinner']:
        feed_data = generate_meal_feed(meal_type, count=30)
        comprehensive_feed[meal_type] = feed_data
        
        # Rate limiting
        if meal_type != 'dinner':
            print("⏳ Waiting 5 seconds...")
            time.sleep(5)
    
    # Save to file
    output_file = 'comprehensive_indian_food_feed_generated.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(comprehensive_feed, f, indent=2, ensure_ascii=False)
    
    print(f"\n✓ Comprehensive feed saved to {output_file}")
    print(f"  Breakfast: {len(comprehensive_feed.get('breakfast', {}))} items")
    print(f"  Lunch: {len(comprehensive_feed.get('lunch', {}))} items")
    print(f"  Dinner: {len(comprehensive_feed.get('dinner', {}))} items")
    print(f"  Total: {sum(len(v) for v in comprehensive_feed.values())} items")

if __name__ == "__main__":
    main()
