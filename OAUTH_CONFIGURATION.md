# OAuth Configuration Guide

This guide will help you configure OAuth authentication providers (Google and Apple) for the AI Chat App.

## Overview

The app supports OAuth authentication through:
- **Google Sign-In**: For Android, iOS, and Web platforms
- **Apple Sign-In**: For iOS and macOS platforms

## Prerequisites

Before setting up OAuth, ensure you have:
- Firebase/Google Cloud Console access for Google OAuth
- Apple Developer Account for Apple Sign-In
- Supabase project configured

## Google Sign-In Configuration

### 1. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API and Google Sign-In API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client IDs"

### 2. Create OAuth Client IDs

#### For Android:
1. Select "Android" as application type
2. Get your SHA-1 certificate fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
3. Enter package name: `com.applifylab.ai_chat_app`
4. Enter SHA-1 fingerprint
5. Create and download the JSON file

#### For iOS:
1. Select "iOS" as application type
2. Enter bundle ID: `com.applifylab.ai-chat-app`
3. Create and download the plist file

#### For Web:
1. Select "Web application" as application type
2. Enter authorized origins and redirect URIs
3. Create and note the Client ID

### 3. Platform-Specific Configuration

#### Android Setup:
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`
3. The `android/app/build.gradle.kts` should already be configured

#### iOS Setup:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to `ios/Runner/GoogleService-Info.plist`
3. Update `ios/Runner/Info.plist` with the correct REVERSED_CLIENT_ID:
   ```xml
   <!-- Replace the placeholder with your actual REVERSED_CLIENT_ID -->
   <string>com.googleusercontent.apps.662154624857-nfv3lcio2o7n57r81rcngr0b0itjei8m</string>
   ```

#### Web Setup:
1. Add your Web Client ID to the Google Sign-In configuration
2. Update `web/index.html` if needed with meta tags

## Apple Sign-In Configuration

### 1. Apple Developer Console Setup

1. Go to [Apple Developer Console](https://developer.apple.com/account/)
2. Navigate to "Certificates, Identifiers & Profiles"
3. Create or configure your App ID with "Sign In with Apple" capability

### 2. Service ID Configuration

1. Create a new Service ID for web authentication
2. Configure the service ID with your domain and return URLs
3. Note the Service ID for web configuration

### 3. Platform-Specific Configuration

#### iOS Setup:
1. In Xcode, add "Sign In with Apple" capability to your target
2. Update `ios/Runner/Runner.entitlements`:
   ```xml
   <key>com.apple.developer.applesignin</key>
   <array>
       <string>Default</string>
   </array>
   ```

### 4. Update Apple OAuth Service

Replace the placeholder values in `lib/features/auth/data/services/apple_oauth_service.dart`:

```dart
webAuthenticationOptions: WebAuthenticationOptions(
  clientId: 'com.applifylab.ai-chat-app.service', // Your actual Service ID
  redirectUri: Uri.parse('https://your-domain.com/auth/callback'), // Your actual redirect URI
),
```

## Supabase Configuration

### 1. Enable OAuth Providers

1. Go to your Supabase project dashboard
2. Navigate to "Authentication" → "Settings"
3. Enable Google and Apple providers
4. Configure redirect URLs

### 2. Configure Provider Settings

#### Google:
1. Enter your Google OAuth Client ID
2. Enter your Google OAuth Client Secret
3. Set redirect URL: `https://your-project.supabase.co/auth/v1/callback`

#### Apple:
1. Upload your Apple private key (.p8 file)
2. Enter your Key ID
3. Enter your Team ID
4. Enter your Bundle ID
5. Set redirect URL: `https://your-project.supabase.co/auth/v1/callback`

## Environment Configuration

Create or update your `.env` file with the necessary configuration:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Google OAuth (if needed for custom configuration)
GOOGLE_CLIENT_ID=your-google-client-id

# Apple OAuth (if needed for custom configuration)
APPLE_SERVICE_ID=com.applifylab.ai-chat-app.service
```

## Testing OAuth Integration

### 1. Development Testing

1. Ensure all configuration files are in place
2. Run the app on the target platform
3. Test Google Sign-In flow
4. Test Apple Sign-In flow (iOS/macOS only)

### 2. Platform-Specific Testing

#### Android:
```bash
flutter run -d android
```

#### iOS:
```bash
flutter run -d ios
```

#### Web:
```bash
flutter run -d web-server --web-port 3000
```

## Troubleshooting

### Common Issues

#### Google Sign-In Issues:
- **"DEVELOPER_ERROR"**: Check if `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is properly configured
- **"SIGN_IN_REQUIRED"**: User needs to sign in to Google Play Services (Android)
- **"NETWORK_ERROR"**: Check internet connectivity

#### Apple Sign-In Issues:
- **"Not available"**: Apple Sign-In is only available on iOS 13+ and macOS 10.15+
- **"Invalid client"**: Check if Service ID is properly configured
- **"Invalid redirect URI"**: Ensure redirect URI matches the one configured in Apple Developer Console

### Debug Commands

Check if packages are properly configured:
```bash
flutter doctor
flutter pub deps
```

Check for any configuration issues:
```bash
flutter analyze
```

### Validation

The app includes validation methods to check if OAuth providers are properly configured:

```dart
// Google Sign-In validation
bool isGoogleConfigured = await googleOAuthService.validateConfiguration();

// Apple Sign-In validation
bool isAppleConfigured = await appleOAuthService.validateConfiguration();
```

## Security Considerations

1. **Never commit sensitive files**: Add `google-services.json`, `GoogleService-Info.plist` to `.gitignore`
2. **Use environment variables**: Store sensitive configuration in environment variables
3. **Validate tokens**: Always validate OAuth tokens on the server side
4. **Handle errors gracefully**: Implement proper error handling for OAuth flows
5. **Update dependencies**: Keep OAuth packages updated for security patches

## Production Deployment

### Before releasing to production:

1. **Update OAuth credentials**: Replace debug certificates with production certificates
2. **Configure production URLs**: Update redirect URLs for production environment
3. **Test on real devices**: Test OAuth flows on physical devices
4. **Enable logging**: Implement proper logging for OAuth events
5. **Monitor usage**: Set up monitoring for OAuth authentication flows

## Support

For additional help:
- [Google Sign-In Documentation](https://developers.google.com/identity/sign-in/android)
- [Apple Sign-In Documentation](https://developer.apple.com/documentation/sign_in_with_apple)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Flutter OAuth Packages](https://pub.dev/packages/google_sign_in)

## Checklist

- [ ] Google Cloud Console project configured
- [ ] Google OAuth client IDs created for all platforms
- [ ] `google-services.json` placed in Android project
- [ ] `GoogleService-Info.plist` placed in iOS project
- [ ] iOS Info.plist updated with REVERSED_CLIENT_ID
- [ ] Apple Developer Console App ID configured
- [ ] Apple Service ID created for web
- [ ] iOS entitlements configured for Apple Sign-In
- [ ] Supabase OAuth providers enabled and configured
- [ ] Environment variables configured
- [ ] OAuth flows tested on all target platforms
- [ ] Error handling implemented
- [ ] Security considerations addressed