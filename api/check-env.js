// api/check-env.js - Environment Variables Checker
export default function handler(req, res) {
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    const requiredEnvVars = [
        'GOOGLE_AI_API_KEY',
        'FIREBASE_PROJECT_ID',
        'FIREBASE_PRIVATE_KEY_ID',
        'FIREBASE_PRIVATE_KEY',
        'FIREBASE_CLIENT_EMAIL',
        'FIREBASE_CLIENT_ID',
        'FIREBASE_DATABASE_URL',
        'FIREBASE_CLIENT_CERT_URL',
        'CRON_SECRET'
    ];

    const envStatus = {};
    let allSet = true;

    requiredEnvVars.forEach(varName => {
        const value = process.env[varName];
        if (value) {
            if (varName === 'FIREBASE_PRIVATE_KEY') {
                envStatus[varName] = {
                    status: 'SET',
                    length: value.length,
                    hasBeginEnd: value.includes('-----BEGIN PRIVATE KEY-----') && value.includes('-----END PRIVATE KEY-----')
                };
            } else {
                envStatus[varName] = {
                    status: 'SET',
                    length: value.length,
                    preview: varName.includes('SECRET') || varName.includes('KEY') ? 
                        value.substring(0, 10) + '...' : value
                };
            }
        } else {
            envStatus[varName] = {
                status: 'NOT SET',
                length: 0
            };
            allSet = false;
        }
    });

    const response = {
        success: allSet,
        message: allSet ? 'All environment variables are properly set!' : 'Some environment variables are missing',
        totalRequired: requiredEnvVars.length,
        totalSet: Object.values(envStatus).filter(v => v.status === 'SET').length,
        envStatus: envStatus,
        timestamp: new Date().toISOString()
    };

    return res.status(allSet ? 200 : 400).json(response);
}