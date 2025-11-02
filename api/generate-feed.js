// api/generate-feed.js
export default async function handler(req, res) {
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
        console.log('🚀 Starting feed generation...');
        
        // Generate feed data directly in JavaScript (Vercel doesn't support Python execution)
        const feedData = generateComprehensiveFeed();
        
        const totalItems = Object.values(feedData)
            .filter(meal => meal && meal.items)
            .reduce((sum, meal) => sum + Object.keys(meal.items).length, 0);

        console.log('✅ Feed generation completed successfully');
        console.log(`📊 Total items generated: ${totalItems}`);

        return res.status(200).json({
            success: true,
            message: 'Feed generated successfully',
            totalItems,
            timestamp: new Date().toISOString(),
            feedData: feedData
        });

    } catch (error) {
        console.error('❌ Feed generation failed:', error);
        
        return res.status(500).json({
            success: false,
            error: 'Feed generation failed',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
}

function generateComprehensiveFeed() {
    const today = new Date();
    const dayOfWeek = today.getDay();
    const timestamp = today.toISOString();
    
    // Generate more comprehensive feed with 10+ items per category
    const breakfastItems = generateBreakfastItems(timestamp);
    const lunchItems = generateLunchItems(timestamp);
    const dinnerItems = generateDinnerItems(timestamp);
    const snackItems = generateSnackItems(timestamp);
    
    return {
        breakfast: { items: breakfastItems },
        lunch: { items: lunchItems },
        dinner: { items: dinnerItems },
        snacks: { items: snackItems },
        metadata: {
            generated_at: timestamp,
            generated_by: 'vercel_comprehensive_generator',
            version: '2.0',
            total_items: Object.keys(breakfastItems).length + Object.keys(lunchItems).length + Object.keys(dinnerItems).length + Object.keys(snackItems).length
        }
    };
}

function generateBreakfastItems(timestamp) {
    return {
        "breakfast_001": {
            title: "Masala Oats with Vegetables",
            description: "Nutritious oats cooked with Indian spices, mixed vegetables, and herbs. Significance: High in beta-glucan fiber which helps lower cholesterol, provides sustained energy, and supports digestive health.",
            keywords: ["veg", "high_fiber", "diabetes_friendly", "breakfast", "weight_loss", "heart_healthy"],
            allergens: ["gluten"],
            ingredients: ["rolled oats", "onions", "tomatoes", "green peas", "carrots", "turmeric", "cumin seeds"],
            nutrition: { calories: "280 kcal", protein: "12g", carbs: "45g", fat: "6g", fiber: "8g", sugar: "8g" },
            preparation_time: "15 minutes",
            cooking_method: "Sauté vegetables with spices, add oats and water, cook until creamy"
        },
        "breakfast_002": {
            title: "Moong Dal Chilla with Spinach",
            description: "Protein-rich pancakes made from yellow lentils with iron-rich spinach. Significance: High in plant protein and folate, supports muscle building and prevents anemia.",
            keywords: ["veg", "high_protein", "gluten_free", "breakfast", "muscle_building", "diabetes_friendly"],
            allergens: [],
            ingredients: ["moong dal", "spinach", "onions", "tomatoes", "ginger", "green chilies"],
            nutrition: { calories: "320 kcal", protein: "18g", carbs: "35g", fat: "8g", fiber: "12g", sugar: "4g" },
            preparation_time: "20 minutes",
            cooking_method: "Soak dal overnight, grind to batter, add spices, cook like pancakes"
        },
        "breakfast_003": {
            title: "Quinoa Upma with Vegetables",
            description: "South Indian style upma made with protein-rich quinoa. Significance: Complete protein source with all essential amino acids, gluten-free alternative.",
            keywords: ["veg", "high_protein", "gluten_free", "breakfast", "muscle_building", "weight_loss"],
            allergens: [],
            ingredients: ["quinoa", "mustard seeds", "curry leaves", "onions", "carrots", "green peas"],
            nutrition: { calories: "340 kcal", protein: "14g", carbs: "52g", fat: "10g", fiber: "6g", sugar: "6g" },
            preparation_time: "25 minutes",
            cooking_method: "Roast quinoa, sauté spices and vegetables, add quinoa and water, cook until fluffy"
        },
        "breakfast_004": {
            title: "Ragi Dosa with Coconut Chutney",
            description: "Fermented crepe made from finger millet flour. Significance: Rich in calcium and amino acids, supports bone health and helps regulate blood sugar.",
            keywords: ["veg", "gluten_free", "high_fiber", "breakfast", "diabetes_friendly", "heart_healthy"],
            allergens: [],
            ingredients: ["ragi flour", "rice flour", "urad dal", "coconut", "green chilies", "ginger"],
            nutrition: { calories: "290 kcal", protein: "10g", carbs: "50g", fat: "6g", fiber: "10g", sugar: "3g" },
            preparation_time: "8 hours + 20 minutes",
            cooking_method: "Ferment batter overnight, spread thin on griddle, cook until crispy"
        },
        "breakfast_005": {
            title: "Egg Bhurji with Multigrain Toast",
            description: "Scrambled eggs with Indian spices and multigrain bread. Significance: Complete protein supports muscle building, B-vitamins support brain function.",
            keywords: ["non_veg", "high_protein", "breakfast", "muscle_building", "brain_food"],
            allergens: ["eggs", "wheat"],
            ingredients: ["eggs", "onions", "tomatoes", "green chilies", "turmeric", "multigrain bread"],
            nutrition: { calories: "350 kcal", protein: "20g", carbs: "25g", fat: "18g", fiber: "4g", sugar: "6g" },
            preparation_time: "15 minutes",
            cooking_method: "Sauté vegetables, add beaten eggs, scramble until cooked"
        },
        "breakfast_006": {
            title: "Chia Seed Pudding with Berries",
            description: "Omega-3 rich chia seeds soaked in plant milk with berries. Significance: High in omega-3 fatty acids for brain health, fiber promotes satiety.",
            keywords: ["vegan", "high_protein", "low_carb", "breakfast", "weight_loss", "brain_food"],
            allergens: [],
            ingredients: ["chia seeds", "almond milk", "mixed berries", "vanilla extract", "maple syrup"],
            nutrition: { calories: "250 kcal", protein: "12g", carbs: "18g", fat: "16g", fiber: "14g", sugar: "12g" },
            preparation_time: "8 hours + 5 minutes",
            cooking_method: "Mix chia seeds with plant milk, refrigerate overnight, top with berries"
        },
        "breakfast_007": {
            title: "Spinach and Paneer Paratha",
            description: "Whole wheat flatbread stuffed with spinach and cottage cheese. Significance: High in iron and calcium, supports bone health and prevents anemia.",
            keywords: ["veg", "high_protein", "breakfast", "muscle_building", "heart_healthy"],
            allergens: ["wheat", "milk"],
            ingredients: ["whole wheat flour", "spinach", "paneer", "onions", "ginger", "green chilies"],
            nutrition: { calories: "380 kcal", protein: "16g", carbs: "48g", fat: "14g", fiber: "8g", sugar: "4g" },
            preparation_time: "30 minutes",
            cooking_method: "Make dough, prepare filling, stuff and roll parathas, cook on griddle"
        },
        "breakfast_008": {
            title: "Avocado Toast with Sprouts",
            description: "Mashed avocado on whole grain bread with protein-rich sprouts. Significance: Healthy monounsaturated fats support heart health, sprouts provide enzymes.",
            keywords: ["vegan", "high_fiber", "breakfast", "weight_loss", "heart_healthy"],
            allergens: ["wheat"],
            ingredients: ["avocado", "whole grain bread", "mixed sprouts", "lemon juice", "black pepper"],
            nutrition: { calories: "310 kcal", protein: "12g", carbs: "35g", fat: "16g", fiber: "12g", sugar: "4g" },
            preparation_time: "10 minutes",
            cooking_method: "Toast bread, mash avocado with seasonings, spread on toast, top with sprouts"
        },
        "breakfast_009": {
            title: "Protein Smoothie Bowl",
            description: "Thick protein smoothie with fruits and nuts. Significance: High protein supports muscle recovery, antioxidants from fruits boost immunity.",
            keywords: ["veg", "high_protein", "breakfast", "muscle_building", "smoothie"],
            allergens: ["milk", "tree_nuts"],
            ingredients: ["protein powder", "Greek yogurt", "berries", "spinach", "almond butter"],
            nutrition: { calories: "380 kcal", protein: "25g", carbs: "32g", fat: "18g", fiber: "8g", sugar: "20g" },
            preparation_time: "10 minutes",
            cooking_method: "Blend ingredients until thick, pour in bowl, add toppings"
        },
        "breakfast_010": {
            title: "Millet Porridge with Dates",
            description: "Creamy millet porridge naturally sweetened with dates. Significance: Millet is gluten-free and rich in magnesium, dates provide natural sweetness and fiber.",
            keywords: ["vegan", "gluten_free", "high_fiber", "breakfast", "diabetes_friendly", "heart_healthy"],
            allergens: [],
            ingredients: ["pearl millet", "dates", "almond milk", "cardamom", "nuts", "cinnamon"],
            nutrition: { calories: "300 kcal", protein: "8g", carbs: "55g", fat: "8g", fiber: "8g", sugar: "18g" },
            preparation_time: "25 minutes",
            cooking_method: "Cook millet until soft, blend with dates, add spices and nuts"
        }
    };
}

function generateLunchItems(timestamp) {
    return {
        "lunch_001": {
            title: "Dal Tadka with Brown Rice",
            description: "Yellow lentils tempered with cumin and curry leaves, served with fiber-rich brown rice. Significance: Complete protein when combined with rice, high in folate and iron.",
            keywords: ["veg", "high_protein", "gluten_free", "lunch", "diabetes_friendly", "heart_healthy"],
            allergens: [],
            ingredients: ["toor dal", "brown rice", "turmeric", "cumin seeds", "mustard seeds", "curry leaves"],
            nutrition: { calories: "420 kcal", protein: "18g", carbs: "68g", fat: "8g", fiber: "12g", sugar: "4g" },
            preparation_time: "45 minutes",
            cooking_method: "Pressure cook dal and rice separately, prepare tempering, mix and serve"
        },
        "lunch_002": {
            title: "Chicken Curry with Quinoa",
            description: "Lean chicken in aromatic Indian spices with quinoa. Significance: High-quality complete protein supports muscle building.",
            keywords: ["non_veg", "high_protein", "gluten_free", "lunch", "muscle_building", "low_carb"],
            allergens: [],
            ingredients: ["chicken breast", "quinoa", "onions", "tomatoes", "ginger-garlic paste", "spices"],
            nutrition: { calories: "480 kcal", protein: "35g", carbs: "45g", fat: "15g", fiber: "6g", sugar: "8g" },
            preparation_time: "40 minutes",
            cooking_method: "Marinate chicken, cook quinoa, prepare curry base, simmer until tender"
        },
        "lunch_003": {
            title: "Rajma Masala with Jeera Rice",
            description: "Kidney beans in rich tomato gravy with cumin rice. Significance: Excellent source of plant protein and fiber, helps regulate blood sugar.",
            keywords: ["veg", "high_protein", "high_fiber", "lunch", "diabetes_friendly", "heart_healthy"],
            allergens: [],
            ingredients: ["rajma beans", "basmati rice", "onions", "tomatoes", "ginger-garlic", "cumin seeds"],
            nutrition: { calories: "450 kcal", protein: "16g", carbs: "72g", fat: "10g", fiber: "15g", sugar: "6g" },
            preparation_time: "1 hour",
            cooking_method: "Soak beans overnight, pressure cook, prepare masala base, simmer together"
        },
        "lunch_004": {
            title: "Fish Curry with Coconut Rice",
            description: "Fresh fish in coconut milk with South Indian spices. Significance: Rich in omega-3 fatty acids for brain and heart health.",
            keywords: ["non_veg", "high_protein", "gluten_free", "lunch", "brain_food", "heart_healthy"],
            allergens: ["fish"],
            ingredients: ["fish fillets", "coconut milk", "basmati rice", "curry leaves", "mustard seeds", "turmeric"],
            nutrition: { calories: "520 kcal", protein: "28g", carbs: "55g", fat: "20g", fiber: "4g", sugar: "6g" },
            preparation_time: "35 minutes",
            cooking_method: "Marinate fish, prepare coconut rice, cook curry with coconut milk and spices"
        },
        "lunch_005": {
            title: "Palak Paneer with Millet Roti",
            description: "Cottage cheese in creamy spinach gravy with millet flatbread. Significance: High in iron, calcium, and protein, supports bone health.",
            keywords: ["veg", "high_protein", "gluten_free", "lunch", "muscle_building", "heart_healthy"],
            allergens: ["milk"],
            ingredients: ["paneer", "spinach", "millet flour", "onions", "tomatoes", "ginger-garlic paste"],
            nutrition: { calories: "460 kcal", protein: "22g", carbs: "42g", fat: "22g", fiber: "8g", sugar: "8g" },
            preparation_time: "40 minutes",
            cooking_method: "Blanch spinach, prepare paneer, make millet dough, cook curry and rotis"
        },
        "lunch_006": {
            title: "Mixed Vegetable Sambar",
            description: "South Indian lentil curry with mixed vegetables and tamarind. Significance: Complete nutrition with protein from lentils and vitamins from vegetables.",
            keywords: ["veg", "high_fiber", "gluten_free", "lunch", "diabetes_friendly", "heart_healthy"],
            allergens: [],
            ingredients: ["toor dal", "drumsticks", "okra", "eggplant", "tomatoes", "tamarind", "sambar powder"],
            nutrition: { calories: "400 kcal", protein: "15g", carbs: "65g", fat: "8g", fiber: "14g", sugar: "10g" },
            preparation_time: "50 minutes",
            cooking_method: "Cook dal, prepare vegetables, make tamarind extract, combine and simmer"
        },
        "lunch_007": {
            title: "Chickpea Flour Pancakes",
            description: "Savory pancakes made from chickpea flour with vegetables. Significance: High in plant protein and fiber, gluten-free option.",
            keywords: ["vegan", "gluten_free", "high_protein", "lunch", "diabetes_friendly", "weight_loss"],
            allergens: [],
            ingredients: ["chickpea flour", "onions", "tomatoes", "spinach", "turmeric", "cumin", "coriander"],
            nutrition: { calories: "320 kcal", protein: "16g", carbs: "42g", fat: "10g", fiber: "12g", sugar: "6g" },
            preparation_time: "20 minutes",
            cooking_method: "Make batter with chickpea flour, add vegetables and spices, cook like pancakes"
        },
        "lunch_008": {
            title: "Paneer Stir-fry with Vegetables",
            description: "High-protein paneer stir-fried with colorful vegetables. Significance: Complete protein supports muscle building, low carbs help reduce body fat.",
            keywords: ["veg", "high_protein", "low_carb", "lunch", "muscle_building", "skinny_fat_friendly"],
            allergens: ["milk"],
            ingredients: ["paneer", "bell peppers", "broccoli", "snap peas", "ginger-garlic", "soy sauce"],
            nutrition: { calories: "380 kcal", protein: "24g", carbs: "18g", fat: "24g", fiber: "6g", sugar: "10g" },
            preparation_time: "20 minutes",
            cooking_method: "Stir-fry paneer until golden, add vegetables, toss with sauces and spices"
        }
    };
}

function generateDinnerItems(timestamp) {
    return {
        "dinner_001": {
            title: "Grilled Fish with Steamed Vegetables",
            description: "Omega-3 rich fish grilled with herbs and colorful steamed vegetables. Significance: High-quality protein with omega-3s for brain health.",
            keywords: ["non_veg", "high_protein", "low_carb", "dinner", "weight_loss", "brain_food"],
            allergens: ["fish"],
            ingredients: ["fish fillets", "broccoli", "carrots", "bell peppers", "herbs", "lemon", "olive oil"],
            nutrition: { calories: "320 kcal", protein: "35g", carbs: "15g", fat: "14g", fiber: "6g", sugar: "8g" },
            preparation_time: "25 minutes",
            cooking_method: "Marinate fish with herbs, grill until cooked, steam vegetables separately"
        },
        "dinner_002": {
            title: "Lentil Dal with Cauliflower Rice",
            description: "Protein-rich lentil curry with low-carb cauliflower rice. Significance: Plant protein supports muscle maintenance, low carbs help with weight management.",
            keywords: ["vegan", "high_protein", "low_carb", "dinner", "diabetes_friendly", "weight_loss"],
            allergens: [],
            ingredients: ["mixed lentils", "cauliflower", "turmeric", "cumin", "coriander", "tomatoes"],
            nutrition: { calories: "280 kcal", protein: "16g", carbs: "35g", fat: "8g", fiber: "14g", sugar: "6g" },
            preparation_time: "35 minutes",
            cooking_method: "Cook lentils with spices, rice cauliflower, sauté until tender"
        },
        "dinner_003": {
            title: "Paneer Tikka with Salad",
            description: "Grilled cottage cheese marinated in yogurt and spices with fresh salad. Significance: High protein content supports muscle building.",
            keywords: ["veg", "high_protein", "low_carb", "dinner", "muscle_building", "skinny_fat_friendly"],
            allergens: ["milk"],
            ingredients: ["paneer", "yogurt", "spices", "mixed greens", "cucumber", "tomatoes", "mint chutney"],
            nutrition: { calories: "350 kcal", protein: "22g", carbs: "18g", fat: "22g", fiber: "4g", sugar: "12g" },
            preparation_time: "1 hour + 20 minutes",
            cooking_method: "Marinate paneer, grill until golden, serve with fresh salad"
        },
        "dinner_004": {
            title: "Chicken Soup with Vegetables",
            description: "Clear chicken soup with vegetables and herbs, perfect for light dinner. Significance: Lean protein supports muscle maintenance, low calories aid weight loss.",
            keywords: ["non_veg", "high_protein", "dinner", "weight_loss", "heart_healthy", "soup"],
            allergens: [],
            ingredients: ["chicken breast", "mixed vegetables", "chicken broth", "herbs", "ginger", "garlic"],
            nutrition: { calories: "250 kcal", protein: "28g", carbs: "18g", fat: "8g", fiber: "4g", sugar: "10g" },
            preparation_time: "30 minutes",
            cooking_method: "Simmer chicken with vegetables in broth, season with herbs"
        },
        "dinner_005": {
            title: "Stuffed Zucchini Boats",
            description: "Zucchini boats filled with spiced quinoa and vegetables. Significance: Low in calories but high in nutrients, fiber helps with satiety.",
            keywords: ["veg", "high_fiber", "dinner", "diabetes_friendly", "heart_healthy", "weight_loss"],
            allergens: ["milk"],
            ingredients: ["zucchini", "quinoa", "bell peppers", "onions", "tomatoes", "cheese", "herbs"],
            nutrition: { calories: "290 kcal", protein: "14g", carbs: "38g", fat: "10g", fiber: "8g", sugar: "12g" },
            preparation_time: "45 minutes",
            cooking_method: "Hollow zucchini, prepare quinoa filling, stuff and bake until tender"
        },
        "dinner_006": {
            title: "Tofu Stir-fry with Brown Rice",
            description: "Crispy tofu stir-fried with vegetables and fiber-rich brown rice. Significance: Complete protein from tofu, isoflavones support heart health.",
            keywords: ["vegan", "high_protein", "dinner", "muscle_building", "heart_healthy"],
            allergens: ["soy"],
            ingredients: ["tofu", "brown rice", "mixed vegetables", "soy sauce", "ginger", "garlic", "sesame oil"],
            nutrition: { calories: "380 kcal", protein: "18g", carbs: "48g", fat: "14g", fiber: "6g", sugar: "8g" },
            preparation_time: "30 minutes",
            cooking_method: "Cook brown rice, stir-fry tofu until crispy, add vegetables and sauces"
        },
        "dinner_007": {
            title: "Egg Curry with Millet Roti",
            description: "Boiled eggs in spiced tomato gravy with gluten-free millet flatbread. Significance: Complete protein from eggs, choline supports brain function.",
            keywords: ["non_veg", "high_protein", "gluten_free", "dinner", "muscle_building", "brain_food"],
            allergens: ["eggs"],
            ingredients: ["eggs", "millet flour", "tomatoes", "onions", "spices", "coconut milk", "curry leaves"],
            nutrition: { calories: "420 kcal", protein: "24g", carbs: "42g", fat: "18g", fiber: "6g", sugar: "8g" },
            preparation_time: "40 minutes",
            cooking_method: "Boil eggs, prepare curry base, make millet rotis, combine and serve"
        },
        "dinner_008": {
            title: "Vegetable Khichdi Bowl",
            description: "Comfort bowl with rice, lentils, and vegetables, topped with ghee. Significance: Easy to digest, balanced nutrition, ghee provides healthy fats.",
            keywords: ["veg", "gluten_free", "dinner", "diabetes_friendly", "heart_healthy", "high_fiber"],
            allergens: ["milk"],
            ingredients: ["basmati rice", "moong dal", "mixed vegetables", "turmeric", "cumin", "ghee"],
            nutrition: { calories: "340 kcal", protein: "12g", carbs: "55g", fat: "10g", fiber: "8g", sugar: "6g" },
            preparation_time: "30 minutes",
            cooking_method: "Pressure cook rice and dal with vegetables, temper with spices and ghee"
        }
    };
}

function generateSnackItems(timestamp) {
    return {
        "snack_001": {
            title: "Roasted Chickpea Chaat",
            description: "Crunchy roasted chickpeas with tangy spices and fresh vegetables. Significance: High in plant protein and fiber, supports digestive health.",
            keywords: ["vegan", "high_protein", "high_fiber", "snack", "gluten_free", "weight_loss"],
            allergens: [],
            ingredients: ["chickpeas", "onions", "tomatoes", "chaat masala", "lemon juice", "mint", "coriander"],
            nutrition: { calories: "180 kcal", protein: "8g", carbs: "28g", fat: "4g", fiber: "8g", sugar: "6g" },
            preparation_time: "15 minutes",
            cooking_method: "Roast chickpeas until crispy, mix with chopped vegetables and spices"
        },
        "snack_002": {
            title: "Protein Energy Balls",
            description: "No-bake energy balls made with nuts, dates, and protein powder. Significance: Quick energy from natural sugars, protein supports muscle recovery.",
            keywords: ["veg", "high_protein", "snack", "muscle_building", "brain_food"],
            allergens: ["tree_nuts"],
            ingredients: ["dates", "almonds", "protein powder", "coconut", "chia seeds", "vanilla extract"],
            nutrition: { calories: "220 kcal", protein: "12g", carbs: "18g", fat: "12g", fiber: "6g", sugar: "14g" },
            preparation_time: "15 minutes",
            cooking_method: "Blend ingredients, roll into balls, refrigerate until firm"
        },
        "snack_003": {
            title: "Green Vegetable Smoothie",
            description: "Green smoothie with vegetables, fruits, and plant protein. Significance: Low in calories but high in nutrients, supports detoxification.",
            keywords: ["vegan", "low_carb", "snack", "weight_loss", "heart_healthy", "smoothie"],
            allergens: [],
            ingredients: ["spinach", "cucumber", "apple", "lemon", "ginger", "coconut water", "mint"],
            nutrition: { calories: "120 kcal", protein: "4g", carbs: "25g", fat: "2g", fiber: "6g", sugar: "18g" },
            preparation_time: "5 minutes",
            cooking_method: "Blend all ingredients until smooth, serve immediately"
        },
        "snack_004": {
            title: "Spiced Nuts Mix",
            description: "Mixed nuts roasted with Indian spices for a healthy snack. Significance: Healthy fats support brain function, protein provides satiety.",
            keywords: ["vegan", "high_protein", "low_carb", "snack", "brain_food", "heart_healthy"],
            allergens: ["tree_nuts"],
            ingredients: ["mixed nuts", "turmeric", "chili powder", "cumin powder", "salt", "curry leaves"],
            nutrition: { calories: "280 kcal", protein: "10g", carbs: "8g", fat: "24g", fiber: "4g", sugar: "2g" },
            preparation_time: "10 minutes",
            cooking_method: "Roast nuts with spices until fragrant and crispy"
        },
        "snack_005": {
            title: "Fruit and Yogurt Parfait",
            description: "Layered parfait with Greek yogurt, fruits, and nuts. Significance: Probiotics support gut health, protein aids muscle recovery.",
            keywords: ["veg", "high_protein", "snack", "diabetes_friendly", "muscle_building"],
            allergens: ["milk"],
            ingredients: ["Greek yogurt", "berries", "granola", "honey", "nuts", "chia seeds"],
            nutrition: { calories: "250 kcal", protein: "15g", carbs: "30g", fat: "8g", fiber: "6g", sugar: "22g" },
            preparation_time: "5 minutes",
            cooking_method: "Layer yogurt with fruits and toppings in a glass"
        }
    };
}