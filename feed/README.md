# Health App Feed Generator

Flask-based API for generating personalized Indian food feeds with comprehensive health filtering.

## Features

- **AI-Powered Generation**: Uses Google Gemini AI to generate diverse Indian food items
- **Comprehensive Filtering**: 
  - Allergen filtering (excludes foods with user's allergens)
  - Diet preferences (vegetarian, vegan, non-vegetarian)
  - Disease management (excludes foods bad for user's conditions)
  - Health goals (prioritizes foods good for specific conditions)
  - Nutritional needs (protein, carbs, fiber, etc.)

- **Meal Types**: Breakfast, Lunch, Dinner
- **Recipe Details**: Each dish includes:
  - Ingredients list
  - Cooking instructions
  - Nutritional information table
  - Health benefits
  - Allergen warnings
  - Disease considerations

## Setup

### Local Development

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Copy service account key:
```bash
cp ../serviceAccountKey.json ./serviceAccountKey.json
```

3. Create `.env` file:
```bash
cp .env.example .env
```

4. Run the app:
```bash
python app.py
```

5. Open browser: `http://localhost:5000`

### Deploy to Vercel

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Deploy:
```bash
vercel
```

3. Set environment variables in Vercel dashboard:
   - `FIREBASE_DATABASE_URL`
   - `GEMINI_API_KEY`
   - Upload `serviceAccountKey.json` as secret

## API Endpoints

### Health Check
```
GET /api/health
```

### Generate Feed
```
POST /api/generate-feed
Body: {
  "meal_type": "breakfast|lunch|dinner",
  "count": 20
}
```

### Generate All Feeds
```
POST /api/generate-all-feeds
```

### Upload Static Feed
```
POST /api/upload-static-feed
```

### Get Feed
```
GET /api/get-feed/<meal_type>
```

## Keyword Categories

- **Diet**: veg, vegan, non_veg
- **Allergen-free**: gluten_free, dairy_free, nut_free
- **Nutrition**: high_protein, low_carb, high_fiber, low_fat
- **Health**: diabetes_friendly, heart_healthy, weight_loss, muscle_building
- **Meal Type**: breakfast, lunch, dinner, snack
- **Dish Type**: salad, soup, smoothie, curry, rice, bread
- **Special**: skinny_fat_friendly, brain_food, immunity_boost

## Filtering Logic

The app implements comprehensive filtering in the Flutter app's `CuratedContentProvider`:

1. **Allergen Filtering**: Automatically excludes foods containing user's allergens
2. **Diet Filtering**: Filters based on vegetarian/vegan/non-veg preferences
3. **Disease Filtering**: Excludes foods marked as bad for user's health conditions
4. **Health Prioritization**: Prioritizes foods good for user's specific conditions

## Recipe Detail Screen

Each dish in the feed has a "More Details" button that opens a detailed screen showing:

- Recipe image
- Full description
- Tags/keywords
- Complete ingredients list
- Step-by-step cooking instructions
- Nutritional facts table (calories, protein, carbs, fat, fiber, etc.)
- Health benefits explanation
- Allergen warnings
- Health considerations (good for / avoid if you have)

## System Prompt

The AI uses a comprehensive system prompt that ensures:
- Indian-based food items
- Eggs considered as non-vegetarian
- 3-5 options for each keyword combination
- Complete health information (allergens, diseases, benefits)
- Detailed descriptions with significance

## File Structure

```
feed/
├── app.py                              # Flask application
├── requirements.txt                    # Python dependencies
├── vercel.json                         # Vercel configuration
├── comprehensive_indian_food_feed.json # Pre-generated feed data
├── templates/
│   └── index.html                      # Dashboard UI
└── README.md                           # This file
```

## Integration with Flutter App

The Flutter app (`lib/features/home/widgets/feed_section.dart`) automatically:
1. Fetches feeds from Firebase based on time of day
2. Applies user-specific filtering
3. Shows "More Details" button for each dish
4. Opens `RecipeDetailScreen` with complete recipe information

## Notes

- Eggs are considered non-vegetarian as per Indian dietary preferences
- All feeds focus on Indian cuisine
- Filtering ensures user safety (allergens, diseases)
- Comprehensive nutritional information for informed choices
