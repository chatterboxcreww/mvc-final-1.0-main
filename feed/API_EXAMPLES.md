# API Examples - Health App Feed Generator

## Base URL
- **Local**: `http://localhost:5000`
- **Production**: `https://your-project.vercel.app/feed`

## Authentication
No authentication required for current version. Add API keys in production if needed.

---

## 1. Health Check

Check if the API is running and services are connected.

### Request
```bash
curl http://localhost:5000/api/health
```

### Response
```json
{
  "status": "healthy",
  "timestamp": "2025-11-02T10:30:00.000Z",
  "firebase": "connected",
  "ai": "configured"
}
```

---

## 2. Upload Static Feed

Upload the pre-generated comprehensive feed to Firebase.

### Request
```bash
curl -X POST http://localhost:5000/api/upload-static-feed
```

### Response
```json
{
  "success": true,
  "message": "Static feed uploaded successfully",
  "timestamp": "2025-11-02T10:30:00.000Z"
}
```

---

## 3. Generate Feed (Single Meal Type)

Generate feed for a specific meal type using AI.

### Request - Breakfast
```bash
curl -X POST http://localhost:5000/api/generate-feed \
  -H "Content-Type: application/json" \
  -d '{
    "meal_type": "breakfast",
    "count": 25
  }'
```

### Request - Lunch
```bash
curl -X POST http://localhost:5000/api/generate-feed \
  -H "Content-Type: application/json" \
  -d '{
    "meal_type": "lunch",
    "count": 25
  }'
```

### Request - Dinner
```bash
curl -X POST http://localhost:5000/api/generate-feed \
  -H "Content-Type: application/json" \
  -d '{
    "meal_type": "dinner",
    "count": 25
  }'
```

### Response
```json
{
  "success": true,
  "meal_type": "breakfast",
  "items_generated": 25,
  "timestamp": "2025-11-02T10:30:00.000Z"
}
```

---

## 4. Generate All Feeds

Generate feeds for all meal types (breakfast, lunch, dinner) in one call.

### Request
```bash
curl -X POST http://localhost:5000/api/generate-all-feeds
```

### Response
```json
{
  "success": true,
  "results": {
    "breakfast": 25,
    "lunch": 25,
    "dinner": 25
  },
  "timestamp": "2025-11-02T10:30:00.000Z"
}
```

---

## 5. Get Feed

Retrieve current feed for a specific meal type from Firebase.

### Request - Breakfast
```bash
curl http://localhost:5000/api/get-feed/breakfast
```

### Request - Lunch
```bash
curl http://localhost:5000/api/get-feed/lunch
```

### Request - Dinner
```bash
curl http://localhost:5000/api/get-feed/dinner
```

### Response
```json
{
  "success": true,
  "meal_type": "breakfast",
  "count": 20,
  "items": {
    "item001": {
      "title": "Masala Oats Upma",
      "description": "Savory oats cooked with vegetables...",
      "keywords": ["veg", "high_fiber", "breakfast"],
      "allergens": ["gluten"],
      "goodForDiseases": ["diabetes", "heart_disease"],
      "badForDiseases": ["celiac_disease"],
      "healthBenefit": "Rich in beta-glucan fiber...",
      "category": "breakfast",
      "ingredients": ["2 cups oats", "1 onion"],
      "instructions": ["Heat oil", "Add vegetables"],
      "nutrition": {
        "calories": "280 kcal",
        "protein": "12g",
        "carbs": "45g",
        "fat": "6g",
        "fiber": "8g"
      }
    },
    "item002": {
      // ... more items
    }
  }
}
```

---

## Python Examples

### Using requests library

```python
import requests
import json

BASE_URL = "http://localhost:5000"

# Health check
response = requests.get(f"{BASE_URL}/api/health")
print(response.json())

# Upload static feed
response = requests.post(f"{BASE_URL}/api/upload-static-feed")
print(response.json())

# Generate breakfast feed
response = requests.post(
    f"{BASE_URL}/api/generate-feed",
    json={"meal_type": "breakfast", "count": 25}
)
print(response.json())

# Get breakfast feed
response = requests.get(f"{BASE_URL}/api/get-feed/breakfast")
data = response.json()
print(f"Retrieved {data['count']} breakfast items")
```

---

## JavaScript Examples

### Using fetch API

```javascript
const BASE_URL = 'http://localhost:5000';

// Health check
fetch(`${BASE_URL}/api/health`)
  .then(res => res.json())
  .then(data => console.log(data));

// Upload static feed
fetch(`${BASE_URL}/api/upload-static-feed`, {
  method: 'POST'
})
  .then(res => res.json())
  .then(data => console.log(data));

// Generate breakfast feed
fetch(`${BASE_URL}/api/generate-feed`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    meal_type: 'breakfast',
    count: 25
  })
})
  .then(res => res.json())
  .then(data => console.log(data));

// Get breakfast feed
fetch(`${BASE_URL}/api/get-feed/breakfast`)
  .then(res => res.json())
  .then(data => {
    console.log(`Retrieved ${data.count} breakfast items`);
    console.log(data.items);
  });
```

---

## Postman Collection

### Import this JSON into Postman

```json
{
  "info": {
    "name": "Health App Feed Generator",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/health",
          "host": ["{{base_url}}"],
          "path": ["api", "health"]
        }
      }
    },
    {
      "name": "Upload Static Feed",
      "request": {
        "method": "POST",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/upload-static-feed",
          "host": ["{{base_url}}"],
          "path": ["api", "upload-static-feed"]
        }
      }
    },
    {
      "name": "Generate Breakfast Feed",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"meal_type\": \"breakfast\",\n  \"count\": 25\n}"
        },
        "url": {
          "raw": "{{base_url}}/api/generate-feed",
          "host": ["{{base_url}}"],
          "path": ["api", "generate-feed"]
        }
      }
    },
    {
      "name": "Generate All Feeds",
      "request": {
        "method": "POST",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/generate-all-feeds",
          "host": ["{{base_url}}"],
          "path": ["api", "generate-all-feeds"]
        }
      }
    },
    {
      "name": "Get Breakfast Feed",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/api/get-feed/breakfast",
          "host": ["{{base_url}}"],
          "path": ["api", "get-feed", "breakfast"]
        }
      }
    }
  ],
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:5000"
    }
  ]
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "error": "Invalid meal_type. Must be breakfast, lunch, or dinner"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Failed to generate content: API quota exceeded"
}
```

---

## Rate Limiting

Currently no rate limiting. For production, consider:
- 100 requests per hour per IP
- 10 AI generation requests per day
- Implement using Flask-Limiter

---

## Best Practices

### 1. Use Static Feed First
```bash
# Upload static feed once
curl -X POST http://localhost:5000/api/upload-static-feed

# Then use get-feed for retrieval
curl http://localhost:5000/api/get-feed/breakfast
```

### 2. Generate Feeds During Off-Peak Hours
```bash
# Schedule daily generation at 2 AM
# Use cron job or Vercel cron
```

### 3. Cache Responses
```python
import requests
from functools import lru_cache

@lru_cache(maxsize=128)
def get_feed(meal_type):
    response = requests.get(f"{BASE_URL}/api/get-feed/{meal_type}")
    return response.json()
```

### 4. Handle Errors Gracefully
```python
try:
    response = requests.post(f"{BASE_URL}/api/generate-feed", 
                            json={"meal_type": "breakfast", "count": 25},
                            timeout=60)
    response.raise_for_status()
    data = response.json()
    if data['success']:
        print(f"Generated {data['items_generated']} items")
    else:
        print(f"Error: {data['error']}")
except requests.exceptions.Timeout:
    print("Request timed out")
except requests.exceptions.RequestException as e:
    print(f"Request failed: {e}")
```

---

## Testing Workflow

### 1. Initial Setup
```bash
# 1. Health check
curl http://localhost:5000/api/health

# 2. Upload static feed
curl -X POST http://localhost:5000/api/upload-static-feed

# 3. Verify data
curl http://localhost:5000/api/get-feed/breakfast
curl http://localhost:5000/api/get-feed/lunch
curl http://localhost:5000/api/get-feed/dinner
```

### 2. AI Generation Test
```bash
# Generate small batch first
curl -X POST http://localhost:5000/api/generate-feed \
  -H "Content-Type: application/json" \
  -d '{"meal_type": "breakfast", "count": 5}'

# Verify generated content
curl http://localhost:5000/api/get-feed/breakfast
```

### 3. Full Generation
```bash
# Generate all feeds
curl -X POST http://localhost:5000/api/generate-all-feeds

# Wait for completion (may take 1-2 minutes)
# Then verify
curl http://localhost:5000/api/get-feed/breakfast
curl http://localhost:5000/api/get-feed/lunch
curl http://localhost:5000/api/get-feed/dinner
```

---

## Integration with Flutter App

The Flutter app automatically fetches feeds from Firebase. No direct API calls needed from the app.

### Data Flow
1. API generates/uploads feeds to Firebase
2. Firebase Realtime Database stores data
3. Flutter app listens to Firebase changes
4. App automatically updates when data changes

### Manual Trigger from App (Optional)
```dart
// In Flutter app
final provider = context.read<CuratedContentProvider>();
await provider.refreshFeed();
```

---

## Monitoring

### Check Feed Status
```bash
# Quick status check
curl http://localhost:5000/api/health && \
curl http://localhost:5000/api/get-feed/breakfast | jq '.count' && \
curl http://localhost:5000/api/get-feed/lunch | jq '.count' && \
curl http://localhost:5000/api/get-feed/dinner | jq '.count'
```

### Expected Output
```
{"status":"healthy",...}
20
20
20
```

---

## Troubleshooting

### Issue: Connection Refused
```bash
# Check if server is running
curl http://localhost:5000/api/health

# If fails, start server
python app.py
```

### Issue: Empty Feed
```bash
# Upload static feed
curl -X POST http://localhost:5000/api/upload-static-feed

# Verify in Firebase Console
# Check curatedContent/breakfast/items
```

### Issue: AI Generation Fails
```bash
# Check API key
echo $GEMINI_API_KEY

# Check quota
# Visit Google Cloud Console
# Check Gemini API usage
```

---

## Production Deployment

### Update Base URL
```bash
# Replace localhost with your Vercel URL
BASE_URL="https://your-project.vercel.app/feed"

# Test production
curl $BASE_URL/api/health
```

### Environment Variables
Set in Vercel dashboard:
- `FIREBASE_DATABASE_URL`
- `GEMINI_API_KEY`
- `SERVICE_ACCOUNT_KEY`

---

## Support

For issues with API:
1. Check server logs: `python app.py`
2. Verify Firebase connection
3. Check API key validity
4. Review error messages
5. Test with curl commands above

For Flutter integration issues:
1. Check Firebase configuration
2. Verify data structure in Firebase Console
3. Test filtering logic
4. Check provider implementation
