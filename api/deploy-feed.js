// api/deploy-feed.js
const admin = require('firebase-admin');

// Initialize Firebase Admin (only once)
if (!admin.apps.length) {
    const serviceAccount = {
        type: "service_account",
        project_id: process.env.FIREBASE_PROJECT_ID || "trkd-12728",
        private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
        private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        client_email: process.env.FIREBASE_CLIENT_EMAIL || "firebase-adminsdk-fbsvc@trkd-12728.iam.gserviceaccount.com",
        client_id: process.env.FIREBASE_CLIENT_ID,
        auth_uri: "https://accounts.google.com/o/oauth2/auth",
        token_uri: "https://oauth2.googleapis.com/token",
        auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
        client_x509_cert_url: process.env.FIREBASE_CLIENT_CERT_URL
    };

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: process.env.FIREBASE_DATABASE_URL || "https://trkd-12728-default-rtdb.asia-southeast1.firebasedatabase.app"
    });
}

const db = admin.database();

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
        console.log('🚀 Starting feed deployment to Firebase...');
        
        // Check environment variables
        const requiredEnvVars = [
            'FIREBASE_PROJECT_ID',
            'FIREBASE_PRIVATE_KEY',
            'FIREBASE_CLIENT_EMAIL',
            'FIREBASE_DATABASE_URL'
        ];
        
        const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
        if (missingVars.length > 0) {
            throw new Error(`Missing environment variables: ${missingVars.join(', ')}`);
        }
        
        const feedData = req.body;
        
        if (!feedData || typeof feedData !== 'object') {
            throw new Error('Invalid feed data provided');
        }

        // Add deployment metadata
        const enrichedFeedData = {
            ...feedData,
            metadata: {
                ...(feedData.metadata || {}),
                deployed_at: new Date().toISOString(),
                deployed_by: 'dashboard_manual_deploy',
                version: '2.0'
            }
        };

        // Deploy to Firebase Realtime Database
        await db.ref('curatedContent').set(enrichedFeedData);
        
        // Calculate statistics
        const totalItems = Object.values(feedData)
            .filter(meal => meal && meal.items)
            .reduce((sum, meal) => sum + Object.keys(meal.items).length, 0);

        const mealCounts = {};
        Object.entries(feedData).forEach(([mealType, mealData]) => {
            if (mealData && mealData.items) {
                mealCounts[mealType] = Object.keys(mealData.items).length;
            }
        });

        console.log('✅ Feed deployed to Firebase successfully');
        console.log(`📊 Total items deployed: ${totalItems}`);
        console.log('📋 Meal breakdown:', mealCounts);

        return res.status(200).json({
            success: true,
            message: 'Feed deployed to Firebase successfully',
            totalItems,
            mealCounts,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('❌ Feed deployment failed:', error);
        
        return res.status(500).json({
            success: false,
            error: 'Feed deployment failed',
            message: error.message,
            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
            timestamp: new Date().toISOString()
        });
    }
}