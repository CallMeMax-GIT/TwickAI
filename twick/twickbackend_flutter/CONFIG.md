# App configuration (do not commit secrets)

## Server URL

Set in **assets/config.json**:

```json
{ "apiUrl": "https://YOUR_SERVER_URL/" }
```

Or pass at build/run time:

```bash
flutter run --dart-define=SERVER_URL=https://your-server.com/
```

## Gemini API key

Pass at build/run time (not stored in repo):

```bash
flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key
```

For release:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_key
flutter build ios --dart-define=GEMINI_API_KEY=your_key
```

## Google Sign-In (Android)

In **android/app/src/main/res/values/strings.xml**, set `default_web_client_id` to your Android OAuth 2.0 Client ID from Google Cloud Console.
