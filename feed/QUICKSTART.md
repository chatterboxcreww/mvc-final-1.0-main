# Quick Start Guide - Health App Feed Generator

## 🚀 Get Started in 5 Minutes

### Step 1: Copy Service Account Key
```bash
cp serviceAccountKey.json feed/serviceAccountKey.json
```

### Step 2: Install Dependencies
```bash
cd feed
pip install -r requirements.txt
```

### Step 3: Run Locally
```bash
python app.py
```

### Step 4: Open Dashboard
Open browser: `http://localhost:5000`

### Step 5: Upload Feed
Click "Upload Comprehensive Feed" button in dashboard

### Step 6: Verify in Firebase
1. Go to Firebase Console
2. Navigate to Realtime Database
3. Check `curatedContent/breakfast/items`
4. Check `curatedContent/lunch/items`
5. Check `curatedContent/dinner/items`

### Step 7: Test Flutter App
1. Run Flutter app
2. Go to Home screen
3. Scroll to "Today's Feed" section
4. Click "More Details" on any dish
5. Verify ingredients, instructions, and nutrition display

## 🌐 Deploy to Vercel

### Quick Deploy
```bash
# From project root
vercel --prod
```

### Access Deployed Dashboard
```
https://your-project.vercel.app/feed/
```

## ✅ Verification Checklist

- [ ] Dashboard loads at `http://localhost:5000`
- [ ] "Upload Comprehensive Feed" button works
- [ ] Firebase shows data in `curatedContent` node
- [ ] Flutter app displays feeds
- [ ] "More Details" button works
- [ ] Ingredients list displays
- [ ] Cooking instructions display
- [ ] Nutritional table displays
- [ ] Filtering works (test with different user profiles)

## 🔧 Troubleshooting

### Issue: Module not found
```bash
pip install -r requirements.txt
```

### Issue: Firebase connection error
- Verify `serviceAccountKey.json` is in feed folder
- Check Firebase database URL in `.env`

### Issue: Feeds not appearing in app
- Check Firebase console for data
- Verify app is connected to correct Firebase project
- Check filtering logic in app

## 📚 Next Steps

1. ✅ Generate more feeds using AI: Click "Generate All Feeds"
2. ✅ Customize feeds: Edit `comprehensive_indian_food_feed.json`
3. ✅ Deploy to production: Follow `DEPLOYMENT.md`
4. ✅ Test filtering: Create users with different profiles
5. ✅ Monitor usage: Check Vercel logs

## 🎯 Key Features

- **60+ Indian Food Items**: Breakfast, lunch, dinner
- **Complete Recipe Details**: Ingredients, instructions, nutrition
- **Smart Filtering**: Allergens, diet, diseases
- **AI-Powered**: Generate new feeds on demand
- **Easy Deployment**: One-click Vercel deployment

## 📞 Support

For issues, check:
1. `README.md` - Complete documentation
2. `DEPLOYMENT.md` - Deployment guide
3. `IMPLEMENTATION_SUMMARY.md` - Technical details
4. Firebase Console - Data verification
5. Vercel Logs - Deployment issues

## 🎉 Success!

If you can see feeds in your Flutter app with complete recipe details, you're all set! The system is working correctly.

Enjoy your personalized health app feed! 🍽️
