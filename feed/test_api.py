"""
Test script for Feed Generator API
Run this to verify all endpoints are working
"""
import requests
import json
import time

BASE_URL = "http://localhost:5000"

def test_health_check():
    """Test health check endpoint"""
    print("\n🔍 Testing Health Check...")
    try:
        response = requests.get(f"{BASE_URL}/api/health")
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Health check passed")
            print(f"  Status: {data['status']}")
            print(f"  Firebase: {data['firebase']}")
            print(f"  AI: {data['ai']}")
            return True
        else:
            print(f"✗ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def test_upload_static_feed():
    """Test uploading static feed"""
    print("\n📤 Testing Upload Static Feed...")
    try:
        response = requests.post(f"{BASE_URL}/api/upload-static-feed")
        if response.status_code == 200:
            data = response.json()
            if data['success']:
                print(f"✓ Static feed uploaded successfully")
                return True
            else:
                print(f"✗ Upload failed: {data.get('error')}")
                return False
        else:
            print(f"✗ Upload failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def test_get_feed(meal_type):
    """Test getting feed for specific meal type"""
    print(f"\n📥 Testing Get {meal_type.capitalize()} Feed...")
    try:
        response = requests.get(f"{BASE_URL}/api/get-feed/{meal_type}")
        if response.status_code == 200:
            data = response.json()
            if data['success']:
                count = data['count']
                print(f"✓ Retrieved {count} {meal_type} items")
                if count > 0:
                    # Show first item
                    first_item = list(data['items'].values())[0]
                    print(f"  Sample: {first_item.get('title', 'N/A')}")
                return True
            else:
                print(f"✗ Get feed failed: {data.get('error')}")
                return False
        else:
            print(f"✗ Get feed failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def test_generate_feed(meal_type):
    """Test generating feed using AI"""
    print(f"\n🤖 Testing Generate {meal_type.capitalize()} Feed (AI)...")
    print("  (This may take 10-30 seconds...)")
    try:
        response = requests.post(
            f"{BASE_URL}/api/generate-feed",
            json={"meal_type": meal_type, "count": 5},
            timeout=60
        )
        if response.status_code == 200:
            data = response.json()
            if data['success']:
                count = data['items_generated']
                print(f"✓ Generated {count} {meal_type} items using AI")
                return True
            else:
                print(f"✗ Generation failed: {data.get('error')}")
                return False
        else:
            print(f"✗ Generation failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("Feed Generator API Test Suite")
    print("=" * 60)
    print("\nMake sure the Flask app is running on http://localhost:5000")
    print("Run: python app.py")
    
    input("\nPress Enter to start tests...")
    
    results = {
        'health_check': False,
        'upload_static': False,
        'get_breakfast': False,
        'get_lunch': False,
        'get_dinner': False,
        'generate_feed': False
    }
    
    # Test 1: Health Check
    results['health_check'] = test_health_check()
    
    if not results['health_check']:
        print("\n❌ Health check failed. Make sure the server is running.")
        return
    
    # Test 2: Upload Static Feed
    results['upload_static'] = test_upload_static_feed()
    time.sleep(2)
    
    # Test 3: Get Feeds
    results['get_breakfast'] = test_get_feed('breakfast')
    time.sleep(1)
    results['get_lunch'] = test_get_feed('lunch')
    time.sleep(1)
    results['get_dinner'] = test_get_feed('dinner')
    
    # Test 4: Generate Feed (Optional - takes longer)
    print("\n" + "=" * 60)
    generate_test = input("Do you want to test AI feed generation? (y/n): ")
    if generate_test.lower() == 'y':
        results['generate_feed'] = test_generate_feed('breakfast')
    else:
        print("⏭️  Skipping AI generation test")
        results['generate_feed'] = None
    
    # Summary
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    
    passed = sum(1 for v in results.values() if v is True)
    failed = sum(1 for v in results.values() if v is False)
    skipped = sum(1 for v in results.values() if v is None)
    total = len(results)
    
    for test_name, result in results.items():
        status = "✓ PASS" if result is True else ("✗ FAIL" if result is False else "⏭️  SKIP")
        print(f"{status:10} {test_name.replace('_', ' ').title()}")
    
    print("\n" + "=" * 60)
    print(f"Results: {passed} passed, {failed} failed, {skipped} skipped out of {total} tests")
    print("=" * 60)
    
    if failed == 0:
        print("\n🎉 All tests passed! Your API is working correctly.")
        print("\nNext steps:")
        print("1. Open Flutter app and check if feeds appear")
        print("2. Test 'More Details' button on dishes")
        print("3. Deploy to Vercel: vercel --prod")
    else:
        print("\n⚠️  Some tests failed. Check the errors above.")
        print("\nTroubleshooting:")
        print("1. Make sure Flask app is running: python app.py")
        print("2. Check serviceAccountKey.json is in feed folder")
        print("3. Verify Firebase database URL is correct")
        print("4. Check comprehensive_indian_food_feed.json exists")

if __name__ == "__main__":
    main()
