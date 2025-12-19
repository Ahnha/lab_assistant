# lab_assistant

A new Flutter project.

## Running Locally

### Web

To run the web app locally:

```bash
flutter run -d chrome
```

## Deployment

### GitHub Pages

The web app is automatically deployed to GitHub Pages on every push to the `main` branch via GitHub Actions.

- The workflow builds the Flutter web app with the correct base-href for GitHub Pages
- The built app is deployed to the `gh-pages` branch
- **Note:** In your GitHub repository settings, ensure that GitHub Pages is configured to deploy from the `gh-pages` branch (root directory)

The app will be available at: `https://<user>.github.io/<repo>/`
