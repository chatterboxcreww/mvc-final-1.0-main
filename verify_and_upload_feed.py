"""
Verify feed.json structure and upload to Firebase
"""
import firebase_admin
from firebase_admin import credentials, db
import json
import sys

def verify_feed_structure(feed_data):
    """Verify the feed has correct structure"""
    print("\n🔍 Verifying feed structure...")
    
    errors = []
    warnings = []
    
    # Check root keys
    required_keys = ['breakfast', 'lunch', 'dinner']
    root_keys = list(feed_data.keys())
    
    if set(root_keys) != set(required_keys):
        errors.append(f"Root keys mismatch. Expected {required_keys}, got {root_keys}")
    else:
        print(f"✅ Root keys correct: {root_keys}")
    
    # Check each meal type
    for meal_type in required_keys:
        if meal_type not in feed_data:
            errors.append(f"Missing meal type: {meal_type}")
            continue
        
        meal_data = feed_data[meal_type]
        
        # Check for 'items' key
        if 'items' not in meal_data:
            errors.append(f"{meal_type} missing 'items' key")
            continue
        
        items = meal_data['items']
        item_count = len(items)
        
        print(f"✅ {meal_type.capitalize()}: {item_count} items")
        
        # Check first item structure
        if items:
            first_item_id = list(items.keys())[0]
            first_item = items[first_item_id]
            
            required_fields = [
                'title', 'description', 'keywords', 'allergens',
                'goodForDiseases', 'badForDiseases', 'healthBenefit',
                'category', 'imagePlaceholder', 'ingredients',
                'instructions', 'nutrition'
            ]
            
            missing_fields = [f for f in required_fields if f not in first_item]
            if missing_fields:
                warnings.append(f"{meal_type}/{first_item_id} missing fields: {missing_fields}")
            
            # Check category matches meal type
            if first_item.get('category') != meal_type:
                warnings.append(f"{meal_type}/{first_item_id} category mismatch: '{first_item.get('category')}' should be '{meal_type}'")
            
            # Check nutrition structure
            if 'nutrition' in first_item:
                nutrition = first_item['nutrition']
                required_nutrition = ['calories', 'protein', 'carbs', 'fat', 'fiber', 'sugar', 'sodium']
                missing_nutrition = [n for n in required_nutrition if n not in nutrition]
                if missing_nutrition:
                    warnings.append(f"{meal_type}/{first_item_id} missing nutrition fields: {missing_nutrition}")
    
    return errors, warnings

def upload_to_firebase(feed_data):
    """Upload feed to Firebase"""
    print("\n📤 Uploading to Firebase...")
    
    try:
        # Initialize Firebase
        if not firebase_admin._apps:
            cred = credentials.Certificate('feed/serviceAccountKey.json')
            firebase_admin.initialize_app(cred, {
                'databaseURL': 'https://trkd-12728-default-rtdb.asia-southeast1.firebasedatabase.app'
            })
        
        # Upload to curatedContent path
        ref = db.reference('curatedContent')
        ref.set(feed_data)
        
        print("✅ Upload successful!")
        
        # Verify upload
        print("\n🔍 Verifying upload...")
        uploaded_data = ref.get()
        
        if uploaded_data:
            print("✅ Data verified in Firebase!")
            print(f"   Breakfast items: {len(uploaded_data.get('breakfast', {}).get('items', {}))}")
            print(f"   Lunch items: {len(uploaded_data.get('lunch', {}).get('items', {}))}")
            print(f"   Dinner items: {len(uploaded_data.get('dinner', {}).get('items', {}))}")
            
            # Show sample item
            breakfast_items = uploaded_data.get('breakfast', {}).get('items', {})
            if breakfast_items:
                first_item_id = list(breakfast_items.keys())[0]
                first_item = breakfast_items[first_item_id]
                print(f"\n📋 Sample item (breakfast/{first_item_id}):")
                print(f"   Title: {first_item.get('title')}")
                print(f"   Category: {first_item.get('category')}")
                print(f"   Keywords: {first_item.get('keywords', [])[:3]}...")
                print(f"   Ingredients: {len(first_item.get('ingredients', []))} items")
                print(f"   Instructions: {len(first_item.get('instructions', []))} steps")
                print(f"   Nutrition keys: {list(first_item.get('nutrition', {}).keys())}")
            
            return True
        else:
            print("❌ No data found in Firebase after upload!")
            return False
            
    except Exception as e:
        print(f"❌ Upload failed: {e}")
        return False

def main():
    print("=" * 60)
    print("Feed Verification and Upload Tool")
    print("=" * 60)
    
    # Load feed.json
    try:
        with open('feed.json', 'r', encoding='utf-8') as f:
            feed_data = json.load(f)
        print("✅ feed.json loaded successfully")
    except FileNotFoundError:
        print("❌ feed.json not found!")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in feed.json: {e}")
        sys.exit(1)
    
    # Verify structure
    errors, warnings = verify_feed_structure(feed_data)
    
    if errors:
        print("\n❌ ERRORS FOUND:")
        for error in errors:
            print(f"   - {error}")
        print("\n⚠️  Fix errors before uploading!")
        sys.exit(1)
    
    if warnings:
        print("\n⚠️  WARNINGS:")
        for warning in warnings:
            print(f"   - {warning}")
    
    print("\n✅ Feed structure is valid!")
    
    # Ask for confirmation
    response = input("\n📤 Upload to Firebase? (yes/no): ").strip().lower()
    
    if response in ['yes', 'y']:
        success = upload_to_firebase(feed_data)
        if success:
            print("\n" + "=" * 60)
            print("✅ ALL DONE!")
            print("=" * 60)
            print("\n📱 Next steps:")
            print("   1. Open your Flutter app")
            print("   2. Pull down to refresh the feed")
            print("   3. Check the time - feed shows based on time of day:")
            print("      • 4 AM - 9 AM: Breakfast")
            print("      • 9 AM - 4 PM: Lunch")
            print("      • 4 PM onwards: Dinner")
            print("   4. Check app logs for: 'Fetched feed content: X breakfast...'")
        else:
            print("\n❌ Upload failed. Check errors above.")
            sys.exit(1)
    else:
        print("\n⏸️  Upload cancelled.")

if __name__ == '__main__':
    main()
