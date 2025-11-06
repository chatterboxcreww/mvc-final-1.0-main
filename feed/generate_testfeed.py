import json

testfeed = {
    "breakfast": {},
    "lunch": {},
    "dinner": {}
}

# BREAKFAST ITEMS (10 items)
testfeed["breakfast"] = {
    "item001": {
        "title": "Moong Dal Cheela (Protein Pancake)",
        "description": "Savory protein-rich pancakes made from ground moong dal with vegetables and spices. A traditional North Indian breakfast that's light yet filling. Significance: Provides complete plant-based protein with all essential amino acids, supports muscle building and weight management. The low glycemic index helps stabilize blood sugar levels, making it ideal for diabetes management.",
        "keywords": ["veg", "high_protein", "gluten_free", "breakfast", "weight_loss", "diabetes_friendly", "muscle_building"],
        "allergens": ["none"],
        "goodForDiseases": ["diabetes", "obesity", "heart_disease", "protein_deficiency", "PCOS"],
        "badForDiseases": [],
        "healthBenefit": "Contains 24g protein per 100g serving. Rich in folate (180mcg), iron (3.5mg), and B-vitamins. Low glycemic index (GI 38) prevents blood sugar spikes. High fiber content (8g) promotes satiety and digestive health.",
        "category": "breakfast",
        "imagePlaceholder": "assets/food/moong_cheela.jpg",
        "ingredients": [
            "1 cup moong dal (split green gram), soaked 4 hours",
            "1/4 cup water for grinding",
            "1 small onion, finely chopped (50g)",
            "1 medium tomato, finely chopped (80g)",
            "2 green chilies, finely chopped",
            "1/2 teaspoon cumin seeds",
            "1/4 teaspoon turmeric powder",
            "1/4 teaspoon red chili powder",
            "Salt to taste (1/2 teaspoon)",
            "2 tablespoons fresh coriander leaves, chopped",
            "1 tablespoon oil for cooking (preferably olive or mustard oil)"
        ],
        "instructions": [
            "Drain the soaked moong dal completely and rinse once with fresh water",
            "Grind the dal with 1/4 cup water to make a smooth, thick batter (consistency of pancake batter)",
            "Transfer batter to a mixing bowl and add salt, turmeric, red chili powder, and cumin seeds",
            "Mix in the chopped onions, tomatoes, green chilies, and coriander leaves until well combined",
            "Heat a non-stick pan or tawa over medium heat for 2 minutes",
            "Lightly grease the pan with 1/2 teaspoon oil using a brush or paper towel",
            "Pour one ladleful (about 1/4 cup) of batter onto the center of the pan",
            "Spread the batter in a circular motion to form a 6-inch diameter pancake",
            "Drizzle 1/2 teaspoon oil around the edges and cook for 2-3 minutes until bottom turns golden brown",
            "Flip the cheela carefully using a spatula and cook the other side for 2 minutes",
            "Remove from pan when both sides are golden and crispy",
            "Serve hot with mint-coriander chutney or plain yogurt"
        ],
        "nutrition": {
            "calories": "180 kcal",
            "protein": "12g",
            "carbs": "22g",
            "fat": "5g",
            "fiber": "8g",
            "sugar": "2g",
            "sodium": "150mg",
            "iron": "3.5mg",
            "calcium": "45mg"
        }
    }
}

# Save to file
with open('testfeed.json', 'w', encoding='utf-8') as f:
    json.dump(testfeed, f, indent=2, ensure_ascii=False)

print("✓ testfeed.json created successfully!")
