# Git & Deployment Workflow Rule

Always follow this strict 3-stage release process when making any changes:

1. **Stage 1 - Local Development**:
   - Implement code changes locally.
   - Run tests and verify locally (`localhost`).
   - Present changes to user for local testing.

2. **Stage 2 - Dev Branch (`dev`)**:
   - Once user confirms local testing, commit and push changes to the `dev` branch on GitHub (`git push origin dev`).
   - DO NOT push to `main` yet.

3. **Stage 3 - Live Production (`main`)**:
   - ONLY merge `dev` into `main` and push to `main` when the user explicitly instructs to publish/make live.
