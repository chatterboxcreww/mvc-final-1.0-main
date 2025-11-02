// api/generate-daily-feed.js
const admin = require('firebase-admin');

// Initialize Firebase Admin (only once)
if (!admin.apps.length) {
  const serviceAccount = {
    type: "service_account",
    project_id: process.env.FIREBASE_PROJECT_ID,
    private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
    private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    client_email: process.env.FIREBASE_CLIENT_EMAIL,
    client_id: process.env.FIREBASE_CLIENT_ID,
    auth_uri: "https://accounts.google.com/o/oauth2/auth",
    token_uri: "https://oauth2.googleapis.com/token",
    auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
    client_x509_cert_url: process.env.FIREBASE_CLIENT_CERT_URL
  };

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DATABASE_URL
  });
}

const db = admin.database();

// AI-powered feed generation using Google AI Studio
async function generateDailyFeedWithAI() {
  const { GoogleGenerativeAI } = require('@google/generative-ai');
  
  const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY);
  const model = genAI.getGenerativeModel({ model: "gemini-pro" });

  const systemPrompt = `You are a nutrition expert creating curated content for a health app. Generate meal/food items in this EXACT JSON format:

{"item001": {"title": "Food Item Name","description": "Detailed description of the food item, ingredients, and preparation. Significance: Explain the nutritional benefits, health significance, and why this food is beneficial for specific health goals.","keywords": ["keyword1", "keyword2", "keyword3"],"allergens": ["allergen1", "allergen2"],"ingredients": ["ingredient1", "ingredient2"],"nutrition": {"calories": "280 kcal","protein": "12g","carbs": "45g","fat": "6g","fiber": "8g","sugar": "8g"},"preparation_time": "15 minutes","cooking_method": "Step-by-step cooking instructions"}}

CRITICAL REQUIREMENTS:
1. Generate 5 DIFFERENT recipes for each meal type (breakfast, lunch, dinner)
2. Use these keyword categories: veg, vegan, non_veg, gluten_free, high_protein, low_carb, high_fiber, diabetes_friendly, skinny_fat_friendly, breakfast, lunch, dinner, snack, weight_loss, muscle_building, heart_healthy, brain_food
3. Consider egg as non-vegetarian food
4. Include realistic Indian cuisine recipes
5. Ensure complete coverage of dietary preferences and health conditions
6. Today's date: ${new Date().toDateString()} - make recipes seasonal and fresh

Generate ONLY the JSON object, no additional text.`;

  try {
    const result = await model.generateContent(systemPrompt);
    const response = await result.response;
    const text = response.text();
    
    // Parse the AI response
    const feedData = JSON.parse(text);
    return feedData;
  } catch (error) {
    console.error('AI generation failed:', error);
    // Fallback to predefined recipes
    return generateFallbackFeed();
  }
}

// Fallback feed generation
function generateFallbackFeed() {
  const today = new Date();
  const dayOfWeek = today.getDay(); // 0 = Sunday, 1 = Monday, etc.
  
  // Rotate recipes based on day of week
  const breakfastRotation = [
    {
      title: "Monday Masala Oats",
      description: "Spiced oats with vegetables for a healthy start. Significance: High fiber content helps regulate blood sugar and provides sustained energy throughout the morning.",
      keywords: ["veg", "high_fiber", "diabetes_friendly", "breakfast", "heart_healthy"],
      allergens: ["gluten"],
      ingredients: ["rolled oats", "mixed vegetables", "Indian spices"],
      nutrition: { calories: "280 kcal", protein: "12g", carbs: "45g", fat: "6g", fiber: "8g", sugar: "8g" },
      preparation_time: "15 minutes",
      cooking_method: "Sauté vegetables with spices, add oats and water, cook until creamy"
    },
    // Add more recipes for each day...
  ];
  
  return {
    breakfast: { items: { "breakfast_001": breakfastRotation[dayOfWeek % breakfastRotation.length] } },
    lunch: { items: {} },
    dinner: { items: {} },
    snacks: { items: {} }
  };
}

export default async function handler(req, res) {
  // Verify this is a cron job request (security)
  const authHeader = req.headers.authorization;
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    console.log('🕛 Starting daily feed generation at:', new Date().toISOString());
    
    // Generate new feed data
    const feedData = await generateDailyFeedWithAI();
    
    // Add timestamp and metadata
    const enrichedFeedData = {
      ...feedData,
      metadata: {
        generated_at: new Date().toISOString(),
        generated_by: 'daily_cron_job',
        version: '2.0'
      }
    };
    
    // Deploy to Firebase
    await db.ref('curatedContent').set(enrichedFeedData);
    
    console.log('✅ Daily feed generated and deployed successfully');
    
    res.status(200).json({ 
      success: true, 
      message: 'Daily feed generated successfully',
      timestamp: new Date().toISOString(),
      itemCount: Object.keys(feedData).length
    });
    
  } catch (error) {
    console.error('❌ Error generating daily feed:', error);
    res.status(500).json({ 
      error: 'Failed to generate daily feed', 
      details: error.message 
    });
  }
}