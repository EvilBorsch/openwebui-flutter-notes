# Open WebUI Notes App

Mobile-first, desktop-ready Flutter notes app using Open WebUI Knowledge as backend.

Features:
- Cards view of notes (Google Keep style), sorted by last edit
- Quick add with Markdown editor and preview
- Edit, delete notes (Markdown storage)
- Local search and RAG search (collection-based)
- Settings: base URL, token, model, collection, theme

Run:
```
flutter pub get
flutter run
```

Configure Settings in-app: set Base URL (e.g. http://localhost:3000), Bearer Token, and optionally Model and Collection ID (`notes`).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
