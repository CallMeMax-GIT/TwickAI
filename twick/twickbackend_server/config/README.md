# Server configuration

Do not commit real secrets.

**If `google_client_secret.json` was ever committed:** run  
`git rm --cached config/google_client_secret.json`  
then add real config locally from the example and never commit it. These files are gitignored:

- `config/google_client_secret.json` – Copy from `google_client_secret.example.json` and fill in your Google OAuth credentials.
- `config/AuthKey_*.p8` – Apple Sign-In private key from Apple Developer Console.
- `config/passwords.yaml` – Database and service passwords.

## Environment variables (production / Serverpod Cloud)

- **GOOGLE_CLIENT_SECRET_JSON** – Full JSON content of your Google OAuth client secret (web client).
- **APPLE_REDIRECT_URI** – Apple Sign-In redirect URI (e.g. `https://your-domain.com/auth/apple/callback`).
- **APPLE_TEAM_ID** – Apple Developer Team ID.
- **APPLE_KEY_ID** – Apple Sign-In Key ID.
- **APPLE_PRIVATE_KEY** – Contents of your `.p8` Apple private key file.
