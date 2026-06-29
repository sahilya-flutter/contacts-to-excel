# 📱 ContactsXL — Contacts to Excel

A Flutter app that exports your phone's mobile contacts to a clean, shareable `.xlsx` Excel file.

## ✨ Features

- **Mobile-only filtering** — Only exports phone numbers labeled as mobile (skips landlines/VOIP)
- **Auto-deduplication** — Same number saved with/without country code is exported only once
- **Sorted A–Z** — Contacts are alphabetically sorted in the output
- **Clean Excel output** — Styled header row, serial numbers, name and mobile number columns
- **One-tap sharing** — Share via WhatsApp, Gmail, Drive, or save anywhere using the native share sheet
- **Privacy-first** — Contacts never leave your device; no internet required

## 📸 Screens

| Idle | Loading | Done |
|------|---------|------|
| Floating icon, feature chips, Export Now button | 3-step pipeline progress indicator | Animated success + contact count + Share button |

## 🗂️ Project Structure

```
lib/
├── main.dart                        # App entry point, dark theme setup
├── model/
│   └── contact_entry.dart           # Lightweight name + mobile model
├── screens/
│   └── home_screen.dart             # Full UI — idle, loading, done, error states
├── service/
│   ├── contact_service.dart         # Fetches & filters device contacts
│   ├── excel_export_service.dart    # Builds and writes the .xlsx file
│   └── permission_service.dart      # Contacts permission handling
└── utils/
    └── phone_validator.dart         # Normalize, validate & dedupe phone numbers
```

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_contacts` | Read device contacts |
| `permission_handler` | Runtime contacts permission |
| `excel` | Build `.xlsx` files in memory |
| `path_provider` | Temporary file storage |
| `share_plus` | Native share sheet |
| `google_fonts` | Poppins typography |

## 🚀 Getting Started

```bash
flutter pub get
flutter run
```

### Android permissions required
The following is automatically requested at runtime:
- `READ_CONTACTS`

Make sure `AndroidManifest.xml` includes:
```xml
<uses-permission android:name="android.permission.READ_CONTACTS"/>
```

## 🛠️ Built With

- Flutter 3.x + Dart 3.x
- Material 3 dark theme
- Impeller rendering engine
