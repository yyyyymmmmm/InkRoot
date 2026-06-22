# InkRoot Website

The public website source lives in `docs/site`.

## Pages

- `docs/site/index.html`: product homepage.
- `docs/site/pages/download/index.html`: release download page.
- `docs/site/pages/guide.html`: user guide.
- `docs/site/pages/faq.html`: FAQ.
- `docs/site/pages/changelog.html`: website changelog summary.
- `docs/site/privacy.html`: privacy policy.
- `docs/site/agreement.html`: user agreement.
- `docs/site/account-deletion.html`: account and data deletion page.

## Update Checklist

1. Update the app version and file names in `pages/download/index.html`.
2. Update the latest release summary in `index.html`.
3. Add the user-facing release notes in `pages/changelog.html`.
4. Keep legal pages aligned with the current app data flow.
5. Keep the real site identity information:
   - ICP filing: `陕ICP备20002445号-6`
   - Public security filing: `陕公网安备 61011302002176号`
   - Contact email: `inkroot2025@gmail.com`
   - Baidu verification file: `baidu_verify_codeva-AVWaMz7Wrp.html`
6. Keep compatibility redirect pages for old public URLs:
   - `/guide.html`, `/faq.html`, `/changelog.html`
   - `/features-v107.html`, `/features-v108.html`
   - `/pages/privacy.html`, `/pages/agreement.html`
7. Run a local static preview:

```bash
python3 -m http.server 8097 --directory docs/site
```

6. Check key URLs:

```bash
for p in / /pages/download/ /pages/guide.html /pages/faq.html /pages/changelog.html /privacy.html /agreement.html /account-deletion.html /guide.html /faq.html /changelog.html /baidu_verify_codeva-AVWaMz7Wrp.html; do
  curl -I "http://127.0.0.1:8097$p"
done
```

The website should use restrained product language. Avoid vague claims such as
"industry-leading", "big-company standard", "AI-powered everything", or release
process details that users do not need.
