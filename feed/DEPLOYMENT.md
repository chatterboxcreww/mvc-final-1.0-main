# Deployment Guide - Health App Feed Generator

## Prerequisites

1. **Vercel Account**: Sign up at https://vercel.com
2. **Firebase Project**: Already configured
3. **Google AI API Key**: Already configured
4. **Service Account Key**: `serviceAccountKey.json` in root directory

## Option 1: Deploy via Vercel CLI (Recommended)

### Step 1: Install Vercel CLI
```bash
npm install -g vercel
```

### Step 2: Login to Vercel
```bash
vercel login
```

### Step 3: Deploy from Root Directory
```bash
# From project root (where vercel.json is)
vercel
```

### Step 4: Set Environment Variables
```bash
vercel env add FIREBASE_DATABASE_URL
# Enter: https://trkd-12728-default-rtdb.asia-southeast1.firebasedatabase.app

vercel env add GEMINI_API_KEY
# Enter: AIzaSyBs39z1L2l4qfX7ofYzkWUn4ZCwTcKcGsI
```

### Step 5: Upload Service Account Key
```bash
# Copy service account key to feed folder
cp serviceAccountKey.json feed/serviceAccountKey.json
```

### Step 6: Deploy to Production
```bash
vercel --prod
```

## Option 2: Deploy via Vercel Dashboard

### Step 1: Connect Repository
1. Go to https://vercel.com/dashboard
2. Click "Add New Project"
3. Import your Git repository
4. Select the repository

### Step 2: Configure Build Settings
- **Framework Preset**: Other
- **Root Directory**: `./` (leave as root)
- **Build Command**: (leave empty)
- **Output Directory**: (leave empty)

### Step 3: Add Environment Variables
In Vercel dashboard, add:
- `FIREBASE_DATABASE_URL`: `https://trkd-12728-default-rtdb.asia-southeast1.firebasedatabase.app`
- `GEMINI_API_KEY`: `AIzaSyBs39z1L2l4qfX7ofYzkWUn4ZCwTcKcGsI`

### Step 4: Upload Service Account Key
1. Copy `serviceAccountKey.json` content
2. In Vercel dashboard, go to Settings > Environment Variables
3. Add `SERVICE_ACCOUNT_KEY` as a secret (paste JSON content)
4. Or upload the file to the repository (ensure it's in feed folder)

### Step 5: Deploy
Click "Deploy" button

## Post-Deployment

### Access Your Dashboard
```
https://your-project.vercel.app/feed/
```

### Test API Endpoints
```bash
# Health check
curl https://your-project.vercel.app/feed/api/health

# Upload static feed
curl -X POST https://your-project.vercel.app/feed/api/upload-static-feed

# Generate breakfast feed
curl -X POST https://your-project.vercel.app/feed/api/generate-feed \
  -H "Content-Type: application/json" \
  -d '{"meal_type": "breakfast", "count": 25}'
```

## Local Testing Before Deployment

### Step 1: Install Dependencies
```bash
cd feed
pip install -r requirements.txt
```

### Step 2: Copy Service Account Key
```bash
cp ../serviceAccountKey.json ./serviceAccountKey.json
```

### Step 3: Create .env File
```bash
cp .env.example .env
# Edit .env with your values
```

### Step 4: Run Locally
```bash
python app.py
```

### Step 5: Test Locally
Open browser: `http://localhost:5000`

## Troubleshooting

### Issue: Module not found
**Solution**: Ensure `requirements.txt` is in the feed folder and all dependencies are listed

### Issue: Firebase connection error
**Solution**: 
- Verify `serviceAccountKey.json` is in the feed folder
- Check Firebase database URL is correct
- Ensure Firebase Realtime Database is enabled

### Issue: Gemini API error
**Solution**:
- Verify API key is correct
- Check API quota limits
- Ensure Gemini API is enabled in Google Cloud Console

### Issue: 404 on routes
**Solution**:
- Check `vercel.json` configuration
- Ensure routes are properly configured
- Verify build completed successfully

## Monitoring

### View Logs
```bash
vercel logs
```

### View Deployment Status
```bash
vercel ls
```

### View Environment Variables
```bash
vercel env ls
```

## Updating Deployment

### Update Code
```bash
git add .
git commit -m "Update feed generator"
git push
# Vercel auto-deploys on push
```

### Manual Redeploy
```bash
vercel --prod
```

## Security Notes

1. **Never commit** `serviceAccountKey.json` to public repositories
2. **Use environment variables** for sensitive data
3. **Rotate API keys** regularly
4. **Monitor usage** to prevent abuse
5. **Set up rate limiting** if needed

## Integration with Flutter App

The Flutter app automatically connects to Firebase and fetches feeds. No additional configuration needed after deployment.

### Verify Integration
1. Deploy feed generator
2. Upload static feed or generate new feeds
3. Open Flutter app
4. Check if feeds appear in home screen
5. Test "More Details" button on each dish

## Support

For issues:
1. Check Vercel deployment logs
2. Verify Firebase console for data
3. Test API endpoints manually
4. Check Flutter app logs

## Next Steps

After successful deployment:
1. ✅ Upload comprehensive feed: Click "Upload Comprehensive Feed" in dashboard
2. ✅ Verify feeds in Firebase console
3. ✅ Test Flutter app to see feeds
4. ✅ Test filtering with different user profiles
5. ✅ Test "More Details" screen for each dish
6. ✅ Set up automated daily feed generation (optional)
