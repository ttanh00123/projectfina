# OAuth Setup Guide

This guide explains how to configure Google and Facebook OAuth for your Flutter app.

## Google OAuth Setup

### 1. Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Sign-In API

### 2. Create OAuth Credentials

#### For Android:
1. Go to **Credentials** → **Create Credentials** → **OAuth client ID**
2. Select **Android**
3. Get your SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. Enter package name: `com.example.taexpense` (or your actual package)
5. Enter SHA-1 fingerprint
6. Save the client ID

#### For iOS:
1. Create OAuth client ID for iOS
2. Enter bundle identifier from `ios/Runner/Info.plist`
3. Download the configuration file
4. Add reversed client ID to `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```

#### For Web:
1. Create OAuth client ID for Web application
2. Add authorized JavaScript origins:
   - `http://localhost` (for testing)
   - Your production domain
3. Update `auth_screen.dart`:
   ```dart
   static const String _googleClientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
   ```

### 3. Backend Configuration
Your backend at `/auth/google` should:
1. Verify the Google ID token
2. Extract user information (email, name, etc.)
3. Create or find user in database
4. Return JWT access token

Example Python (FastAPI) endpoint:
```python
from google.oauth2 import id_token
from google.auth.transport import requests

@router.post("/auth/google")
async def google_auth(data: dict):
    try:
        # Verify token
        idinfo = id_token.verify_oauth2_token(
            data['id_token'],
            requests.Request(),
            "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
        )
        
        email = idinfo['email']
        name = idinfo.get('name')
        
        # Create/find user and generate JWT
        user = await get_or_create_user(email, name)
        token = create_jwt_token(user)
        
        return {"access_token": token}
    except ValueError:
        raise HTTPException(400, "Invalid token")
```

## Facebook OAuth Setup

### 1. Create Facebook App
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app or select existing one
3. Add **Facebook Login** product

### 2. Configure Platform Settings

#### For Android:
1. In Facebook App Dashboard → Settings → Basic
2. Add Android platform
3. Enter package name: `com.example.taexpense`
4. Get your key hash:
   ```bash
   keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
   ```
5. Enter the key hash
6. Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.facebook.sdk.ApplicationId"
       android:value="@string/facebook_app_id"/>
   <meta-data
       android:name="com.facebook.sdk.ClientToken"
       android:value="@string/facebook_client_token"/>
   ```
7. Add to `android/app/src/main/res/values/strings.xml`:
   ```xml
   <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
   <string name="facebook_client_token">YOUR_CLIENT_TOKEN</string>
   ```

#### For iOS:
1. Add iOS platform in Facebook App Dashboard
2. Enter bundle ID
3. Update `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>fbYOUR_FACEBOOK_APP_ID</string>
       </array>
     </dict>
   </array>
   <key>FacebookAppID</key>
   <string>YOUR_FACEBOOK_APP_ID</string>
   <key>FacebookDisplayName</key>
   <string>YourAppName</string>
   <key>LSApplicationQueriesSchemes</key>
   <array>
     <string>fbapi</string>
     <string>fb-messenger-share-api</string>
   </array>
   ```

### 3. Update App ID in Code
In `auth_screen.dart`:
```dart
static const String _facebookAppId = 'YOUR_FACEBOOK_APP_ID';
```

### 4. Backend Configuration
Your backend at `/auth/facebook` should:
1. Verify the Facebook access token
2. Fetch user information from Facebook Graph API
3. Create or find user in database
4. Return JWT access token

Example Python (FastAPI) endpoint:
```python
import httpx

@router.post("/auth/facebook")
async def facebook_auth(data: dict):
    access_token = data['access_token']
    
    # Verify token and get user info
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"https://graph.facebook.com/me",
            params={
                "fields": "id,email,name",
                "access_token": access_token
            }
        )
        
        if response.status_code != 200:
            raise HTTPException(400, "Invalid token")
        
        user_info = response.json()
        email = user_info.get('email')
        name = user_info.get('name')
        
        # Create/find user and generate JWT
        user = await get_or_create_user(email, name)
        token = create_jwt_token(user)
        
        return {"access_token": token}
```

## Testing

### Test Google Sign-In:
1. Run the app on a real device or emulator
2. Click "Continue with Google"
3. Select a Google account
4. Verify token exchange and navigation to Home screen

### Test Facebook Sign-In:
1. Add test users in Facebook App Dashboard
2. Run the app
3. Click "Continue with Facebook"
4. Login with test account
5. Verify token exchange and navigation to Home screen

## Common Issues

### Google Sign-In Error "DEVELOPER_ERROR"
- Check SHA-1 fingerprint matches
- Verify package name matches
- Ensure OAuth client is enabled

### Facebook Login Error
- Verify app is in development/live mode
- Check key hash is correct
- Ensure Facebook app ID is correct in AndroidManifest.xml

### Backend Token Verification Fails
- Ensure backend has correct client IDs/secrets
- Check token hasn't expired
- Verify network connectivity

## Security Notes

1. **Never commit** client secrets or private keys to version control
2. Use environment variables for sensitive configuration
3. Verify tokens on the backend, never trust client-side validation
4. Implement rate limiting on OAuth endpoints
5. Log OAuth failures for security monitoring
