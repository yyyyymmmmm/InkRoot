# Security Policy

## 🔒 Reporting a Vulnerability

The InkRoot team takes security seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**Please DO NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by emailing:

📧 **[inkroot2025@gmail.com](mailto:inkroot2025@gmail.com)**

Include the following information in your report:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### What to Expect

- **Initial Response**: You should receive a response within 48 hours
- **Status Updates**: We will keep you informed about the progress
- **Fix Timeline**: We aim to fix critical vulnerabilities within 7 days
- **Credit**: We will publicly credit you for responsibly disclosing the issue (unless you prefer to remain anonymous)

---

## 🛡️ Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | ✅ Yes             |
| < 1.0   | ❌ No              |

---

## 🔐 Security Considerations

### Data Storage

#### Local Mode
- All data is stored locally on your device
- No data is sent to any server
- Data is stored in SQLite database
- Sensitive tokens are stored in secure storage (iOS Keychain / Android Keystore)

#### Server Sync Mode
- Data is synced to the official server or the Memos server you configure
- Connections use HTTPS encryption (recommended)
- Authentication tokens are stored securely
- Data in self-hosted Memos, WebDAV, AI, or other third-party services is processed by the service you choose

### Privacy

#### What We Collect
- Official server account profile and user content only when you choose to sign in to the official server
- Feedback content and diagnostic context only when you submit feedback or enable related diagnostics
- Android analytics or crash diagnostics only when enabled by the build and app settings

#### What We DON'T Collect
- ❌ We do not sell personal information
- ❌ We do not read private notes for advertising profiles
- ❌ We do not access self-hosted Memos, WebDAV, or AI service data unless you configure and use those features in the app

For more details, see our [Privacy Policy](https://inkroot.cn/privacy.html)

### Third-Party Services

InkRoot uses the following third-party services:

1. **Umeng Analytics** (Android only when enabled)
   - Purpose: Usage statistics and crash reporting
   - Privacy Policy: [https://www.umeng.com/policy](https://www.umeng.com/policy)

2. **Sentry** (Android only)
   - Purpose: Error monitoring
   - Privacy Policy: [https://sentry.io/privacy/](https://sentry.io/privacy/)

3. **DeepSeek AI** (Optional)
   - Purpose: AI-powered note enhancement
   - Only used when explicitly enabled by user
   - Only sends note content when user requests AI features
   - Privacy Policy: [https://www.deepseek.com/privacy](https://www.deepseek.com/privacy)

### Permissions

#### iOS Permissions
- **Microphone** (`NSMicrophoneUsageDescription`) - For voice-to-text feature
- **Photos** (`NSPhotoLibraryUsageDescription`) - For image uploads and saving
- **Camera** (`NSCameraUsageDescription`) - For taking photos to attach to notes
- **Notifications** - For reminder notifications

#### Android Permissions
- **INTERNET** - For server sync (only used in sync mode)
- **RECORD_AUDIO** - For voice-to-text feature
- **READ_EXTERNAL_STORAGE** / **WRITE_EXTERNAL_STORAGE** - For image management
- **CAMERA** - For taking photos
- **POST_NOTIFICATIONS** - For reminder notifications
- **SCHEDULE_EXACT_ALARM** - For reminder scheduling

### Best Practices for Users

1. **Use HTTPS** - Always use HTTPS for server connections, never HTTP in production
2. **Strong Passwords** - Use strong, unique passwords for your Memos account
3. **Keep Updated** - Always use the latest version of InkRoot
4. **Secure Your Device** - Use device lock (PIN/password/biometrics)
5. **Review Permissions** - Only grant permissions you need
6. **Backup Data** - Regularly export your notes for backup

### Secure Development Practices

We follow these practices to ensure InkRoot's security:

- ✅ Regular dependency updates
- ✅ Code review for all changes
- ✅ Static code analysis (`dart tool/inkroot.dart verify`)
- ✅ GitHub Actions secret scanning
- ✅ Secure storage for sensitive data
- ✅ Input validation and sanitization
- ✅ HTTPS for all network communications
- ✅ No hardcoded secrets or credentials
- ✅ Minimal permission requests

### Credential Handling

Never commit or paste production credentials into issues, pull requests, chat,
or documentation examples. This includes:

- GitHub personal access tokens
- Android keystores and `android/key.properties`
- Apple certificates, provisioning profiles, and export options with secrets
- API keys, service account JSON files, and private keys

If a token or signing credential is exposed, revoke it immediately, rotate the
credential, and update GitHub Secrets or local signing files with the new value.

Android release signing is configured locally through ignored files:

```text
android/key.properties
android/inkroot-new-release.keystore
```

CI release signing uses GitHub Secrets as documented in
[`docs/MAINTENANCE.md`](docs/MAINTENANCE.md).

---

## 📝 Known Security Considerations

### Current Limitations

1. **Local Database Encryption**
   - The local SQLite database is NOT encrypted by default
   - If device encryption is enabled, the database is protected by OS-level encryption
   - We're considering adding app-level encryption in future versions

2. **Markdown Rendering**
   - User-generated Markdown is rendered without sandboxing
   - Avoid copying untrusted Markdown content

3. **Image Handling**
   - Images are stored unencrypted
   - Large images may consume significant storage

### Planned Improvements

- 🔄 Optional database encryption
- 🔄 Biometric authentication for app access
- 🔄 Note-level encryption
- 🔄 Enhanced security audit logging

---

## 🔗 Resources

- [Security Best Practices for Flutter Apps](https://flutter.dev/docs/deployment/security)
- [OWASP Mobile Security Project](https://owasp.org/www-project-mobile-security/)
- [Android Security Best Practices](https://developer.android.com/topic/security/best-practices)
- [iOS Security Guide](https://support.apple.com/guide/security/welcome/web)

---

## 🙏 Thank You

We appreciate the security research community and thank all researchers who responsibly disclose vulnerabilities to us.

### Hall of Fame

_(We will list security researchers who have helped improve InkRoot's security here)_

---

## 📧 Contact

For security-related inquiries:
- **Email**: [inkroot2025@gmail.com](mailto:inkroot2025@gmail.com)
- **Subject**: `[SECURITY] Your concern here`

For general inquiries:
- **GitHub Issues**: [https://github.com/yyyyymmmmm/InkRoot/issues](https://github.com/yyyyymmmmm/InkRoot/issues)
- **Website**: [https://inkroot.cn](https://inkroot.cn)

---

Last updated: 2025-10-25
