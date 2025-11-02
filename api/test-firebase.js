// api/test-firebase.js

export default async function handler(req, res) {
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    try {
        console.log('🧪 Testing Firebase configuration...');
        
        // Check environment variables
        const envVars = {
            FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID || 'NOT SET',
            FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL || 'NOT SET',
            FIREBASE_DATABASE_URL: process.env.FIREBASE_DATABASE_URL || 'NOT SET',
            FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY ? 'SET (length: ' + process.env.FIREBASE_PRIVATE_KEY.length + ')' : 'NOT SET'
        };

        console.log('Environment variables:', envVars);

        // Simple test without Firebase for now
        return res.status(200).json({
            success: true,
            message: 'Environment variables check completed',
            envVars: envVars,
            timestamp: new Date().toISOString(),
            note: 'This is a basic test. Firebase connection will be tested after env vars are properly set.'
        });

    } catch (error) {
        console.error('❌ Firebase test failed:', error);
        
        return res.status(500).json({
            success: false,
            error: 'Firebase test failed',
            message: error.message,
            code: error.code,
            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
            timestamp: new Date().toISOString()
        });
    }
}