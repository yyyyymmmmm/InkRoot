# InkRoot Marketing Assets

This folder keeps store screenshots and promotional images.

Rules:

- Store screenshots must come from real app rendering captured in the iOS simulator.
- Do not draw fake device frames, fake status bars, fake notches, fake signals, or fake app pages.
- Deliverable assets live under `marketing/real`.
- Drafts, local databases, simulator captures, and rejected generated assets should stay outside the repository.

Current pipeline:

1. Capture real simulator screenshots into `marketing/real/raw`.
2. Run `python3 marketing/generate_marketing_assets.py`.
3. Review the generated contact sheets in `marketing/real`.

Output folders:

- `marketing/real/app-store`: App Store screenshots, 1320x2868, RGB PNG.
- `marketing/real/google-play`: Google Play screenshots, 1080x1920, RGB PNG.
- `marketing/real/promo`: promotional images made from real app screenshots.
