# Adding a New Language to LaChispa Mobile
This guide explains how to add a new language to the LaChispa Mobile Flutter application. The app uses Flutter's internationalization (i18n) system with ARB (Application Resource Bundle) files for translations.

## 📋 Overview
The LaChispa Mobile app currently supports:

- **Spanish (es)** - Primary language 🇪🇸
- **English (en)** - Secondary language 🇺🇸  
- **Portuguese (pt)** - Secondary language 🇵🇹

The localization system automatically detects the user's device language and displays the appropriate translations. As of the latest update, the app includes comprehensive localization for:

- **Authentication Flow** - Login, registration, password management
- **Wallet Management** - Balance display, transaction history, wallet creation
- **Lightning Network** - Invoice generation, payment processing, address management
- **Settings & Configuration** - Language selection, server settings, account preferences
- **Payment Interface** - Send/receive screens, amount entry, QR code scanning
- **Navigation** - Drawer menus, screen titles, button labels, dialog boxes

## 🛠 Prerequisites
Before adding a new language, ensure you have:

- Flutter SDK installed and configured
- Access to the LaChispa project repository
- Native speakers or reliable translation tools for accuracy
- Understanding of Bitcoin/Lightning Network terminology

## 📂 File Structure
The localization files are organized as follows:

```
lib/
├── l10n/                      # Translation source files (ARB)
│   ├── app_es.arb            # Spanish translations (primary)
│   ├── app_en.arb            # English translations
│   ├── app_pt.arb            # Portuguese translations
│   └── app_[NEW].arb         # Your new language file
├── l10n/generated/           # Auto-generated files (do not edit)
│   ├── app_localizations.dart         # Main localization class
│   ├── app_localizations_es.dart      # Spanish implementation
│   ├── app_localizations_en.dart      # English implementation
│   ├── app_localizations_pt.dart      # Portuguese implementation
│   └── app_localizations_[NEW].dart   # Auto-generated for new language
├── providers/
│   └── language_provider.dart # Language management logic
└── main.dart                  # App configuration with supported locales
```

## 🚀 Step-by-Step Guide

### Step 1: Create the ARB Translation File
Navigate to the l10n directory:
```bash
cd lib/l10n/
```

Create a new ARB file for your language using the ISO 639-1 language code:
```bash
# Example for French
touch app_fr.arb

# Example for German  
touch app_de.arb

# Example for Italian
touch app_it.arb
```

Copy the structure from English as your starting template:
```bash
# Copy English file as template
cp app_en.arb app_fr.arb  # Replace 'fr' with your language code
```

### Step 2: Translate the Content
Open your new ARB file and update the locale identifier:

```json
{
  "@@locale": "fr",  // Change this to your language code
  // ... rest of translations
}
```

Translate all string values while keeping the keys unchanged:

```json
{
  "@@locale": "fr",
  "welcome_title": "Bienvenue à La Chispa!",        // Was: "Welcome to La Chispa!"
  "login_title": "Se connecter",                     // Was: "Login"
  "wallet_title": "Portefeuille",                   // Was: "Wallet"
  "balance_label": "Solde",                         // Was: "Balance"
  "send_button": "Envoyer",                         // Was: "Send"
  "receive_button": "Recevoir",                     // Was: "Receive"
  "lightning_address_title": "Adresse Lightning",  // Was: "Lightning Address"
  // ... continue for all 200+ keys
}
```

Handle parameterized strings carefully:
```json
{
  "payment_sent_status_prefix": "Paiement envoyé - Statut: ",
  "invoice_generation_error_prefix": "Erreur lors de la génération de facture: "
}
```

### Step 3: Update Language Provider
Edit `lib/providers/language_provider.dart` to add support for your new language:

```dart
static const List<Locale> supportedLocales = [
  Locale('es', ''),
  Locale('en', ''),
  Locale('pt', ''),
  Locale('fr', ''),  // Add your new language
];
```

Add language name:
```dart
String getCurrentLanguageName() {
  switch (_currentLocale.languageCode) {
    case 'es':
      return 'Español';
    case 'en':
      return 'English';
    case 'pt':
      return 'Português';
    case 'fr':         // Add your language
      return 'Français';
    default:
      return 'Español';
  }
}
```

Add flag emoji:
```dart
String getCurrentLanguageFlag() {
  switch (_currentLocale.languageCode) {
    case 'es':
      return '🇪🇸';
    case 'en':
      return '🇺🇸';
    case 'pt':
      return '🇵🇹';
    case 'fr':         // Add your flag
      return '🇫🇷';
    default:
      return '🇪🇸';
  }
}
```

Add to available languages list:
```dart
List<Map<String, String>> getAvailableLanguages() {
  return supportedLocales.map((locale) {
    switch (locale.languageCode) {
      case 'es':
        return {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'};
      case 'en':
        return {'code': 'en', 'name': 'English', 'flag': '🇺🇸'};
      case 'pt':
        return {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'};
      case 'fr':         // Add your language
        return {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'};
      default:
        return {'code': locale.languageCode, 'name': locale.languageCode, 'flag': '🌐'};
    }
  }).toList();
}
```

### Step 4: Update Main App Configuration
Edit `lib/main.dart` to add the new locale to supported locales:

```dart
supportedLocales: const [
  Locale('es', ''),
  Locale('en', ''),
  Locale('pt', ''),
  Locale('fr', ''),  // Add your new language
],
```

### Step 5: Update About Dialog (if needed)
If you want custom About dialog text, update the hardcoded parts in:

**lib/screens/6home_screen.dart:**
```dart
switch (currentLanguage) {
  case 'en':
    subtitle = 'Lightning Wallet';
    description = 'A mobile application to manage Bitcoin through Lightning Network using LNBits as backend.';
    break;
  case 'pt':
    subtitle = 'Carteira Lightning';
    description = 'Uma aplicação móvel para gerir Bitcoin através da Lightning Network usando LNBits como backend.';
    break;
  case 'fr':  // Add your language
    subtitle = 'Portefeuille Lightning';
    description = 'Une application mobile pour gérer Bitcoin via le Lightning Network en utilisant LNBits comme backend.';
    break;
  default: // es
    subtitle = 'Billetera Lightning';
    description = 'Una aplicación móvil para gestionar Bitcoin a través de Lightning Network usando LNBits como backend.';
    break;
}
```

**lib/screens/8settings_screen.dart:** (Similar switch statement)

### Step 6: Generate Localization Files
Run the following command to generate the Dart localization files:

```bash
# Generate localization files
flutter gen-l10n
```

Expected output:
- `lib/l10n/generated/app_localizations_[your_language].dart` will be created
- `lib/l10n/generated/app_localizations.dart` will be updated with new language support

### Step 7: Test the Implementation
Build the app to ensure everything compiles:
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

Test locale switching:
1. Launch the app
2. Go to Settings → Language (or hamburger menu → Language)
3. Select your new language
4. Verify all text appears correctly
5. Test About dialog functionality
6. Test payment flows and wallet operations

## 🧪 Testing Checklist
- [ ] All strings are translated (no Spanish/English text appears)
- [ ] App launches without errors
- [ ] Language selector shows new language with correct flag
- [ ] Navigation and core functionality work
- [ ] Text fits properly in UI elements (no overflow)
- [ ] About dialog displays in new language
- [ ] Payment flows work correctly
- [ ] Lightning address functionality works
- [ ] Settings screens display properly

## 📝 Translation Guidelines

### Best Practices
- **Keep context in mind**: Understand where each string appears in the app
- **Maintain consistency**: Use the same terms throughout the app
- **Respect character limits**: Some UI elements have space constraints
- **Use native expressions**: Translate meaning, not just words
- **Test with real users**: Native speakers can catch nuances

### Key Terminology
When translating, maintain consistency for these core concepts:

- **Bitcoin/BTC** - Usually kept as-is
- **Sats/Satoshis** - May be translated or kept as-is
- **Lightning** - Bitcoin Lightning Network (may be translated)
- **Wallet/Carteira/Portefeuille** - Bitcoin wallet
- **Invoice/Factura/Fatura** - Lightning invoice
- **Address/Dirección/Endereço** - Lightning address
- **Balance/Saldo/Solde** - Account balance
- **Transaction/Transacción/Transação** - Bitcoin transaction
- **LNBits** - Keep as-is (it's a proper name)

### Handling Parameterized Strings
Some strings contain placeholders - maintain the parameter names:

```json
// English
"payment_sent_status_prefix": "Payment sent - Status: "

// French - parameter will be appended
"payment_sent_status_prefix": "Paiement envoyé - Statut : "

// German
"payment_sent_status_prefix": "Zahlung gesendet - Status: "
```

## 🔧 Troubleshooting

### Common Issues

**1. Build errors after adding language:**
```bash
# Clean and regenerate
flutter clean
flutter pub get
flutter gen-l10n
```

**2. Language not appearing in app:**
- Verify ARB file syntax is valid JSON
- Check that locale code is correct (fr, de, it, etc.)
- Ensure all translation keys match the English file exactly
- Verify LanguageProvider is updated with new language

**3. Some strings still in original language:**
- Check if the string is hardcoded in Dart files
- Search for untranslated strings: `grep -r "hardcoded text" lib/`
- Ensure all Dart files use `AppLocalizations.of(context)!.keyName`

**4. About dialog not updating:**
- Check both `lib/screens/6home_screen.dart` and `lib/screens/8settings_screen.dart`
- Ensure switch statements include your new language case

**5. Language selector not working:**
- Verify LanguageProvider has all required methods updated
- Check that main.dart includes new locale in supportedLocales
- Test with hot restart instead of hot reload

### Debug Commands
```bash
# Check for analysis issues
flutter analyze

# Validate localization setup
flutter gen-l10n --verbose

# Clean and rebuild
flutter clean && flutter pub get && flutter gen-l10n

# Check generated files
ls -la lib/l10n/generated/
```

## 🌍 Language Priority Recommendations

Based on Bitcoin/Lightning adoption and user base:

### High Priority Languages:
- **German (de)** 🇩🇪 - Strong Bitcoin community
- **French (fr)** 🇫🇷 - Large French-speaking community
- **Italian (it)** 🇮🇹 - Active European Bitcoin scene
- **Japanese (ja)** 🇯🇵 - Major Bitcoin market
- **Chinese Simplified (zh)** 🇨🇳 - Large user base
- **Russian (ru)** 🇷🇺 - Significant crypto adoption

### Medium Priority Languages:
- **Dutch (nl)** 🇳🇱 - Bitcoin-friendly country
- **Korean (ko)** 🇰🇷 - Active crypto market
- **Arabic (ar)** - Large user base (RTL support needed)
- **Turkish (tr)** 🇹🇷 - Growing crypto adoption

## 🤖 AI Assistant Instructions

When helping with LaChispa localization:

### For Research Tasks:
- Use `Read` tool to examine existing ARB files (`app_es.arb`, `app_en.arb`, `app_pt.arb`)
- Use `Grep` tool to find hardcoded strings in Dart files
- Use `LS` tool to understand file structure

### For Implementation Tasks:
- **Create ARB file**: Use `Write` tool with proper JSON structure
- **Copy from English**: Use `Read` to get English content, then `Write` new file
- **Update LanguageProvider**: Use `Edit` tool to add new language support
- **Update main.dart**: Use `Edit` tool to add locale to supportedLocales
- **Generate files**: Use `Bash` tool to run `flutter gen-l10n`
- **Test compilation**: Use `Bash` tool to run `flutter analyze` and `flutter build`

### Critical Requirements:
- Always preserve ARB file structure and key names exactly
- Never edit files in `lib/l10n/generated/` directory
- Always run `flutter gen-l10n` after ARB changes
- Test compilation before marking task complete
- Update all three components: ARB file, LanguageProvider, and main.dart

### Example Workflow:
1. `Read app_en.arb` to understand structure
2. `Write app_[new].arb` with translated content
3. `Edit lib/providers/language_provider.dart` to add language support
4. `Edit lib/main.dart` to add locale to supportedLocales
5. Run: `flutter gen-l10n`
6. Test: `flutter analyze && flutter build apk --debug`

## 📚 Additional Resources
- [Flutter Internationalization Guide](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [ARB File Format Specification](https://github.com/google/app-resource-bundle)
- [ISO 639-1 Language Codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
- [Lightning Network Resources](https://lightning.network/)

## 🤝 Contributing

When submitting localization contributions:

1. **Test thoroughly** on a device with the target language
2. **Include screenshots** showing the translations in context
3. **Document any cultural adaptations** you made
4. **Get review from native speakers** when possible
5. **Update this guide** if you discover new steps or issues
6. **Check Bitcoin terminology** with local Bitcoin communities

## 📱 Example: Adding French Support

```bash
# 1. Create French ARB file
cp lib/l10n/app_en.arb lib/l10n/app_fr.arb

# 2. Edit app_fr.arb - change @@locale to "fr" and translate all strings

# 3. Update LanguageProvider in lib/providers/language_provider.dart
# Add 'fr' to supportedLocales, getCurrentLanguageName(), getCurrentLanguageFlag(), getAvailableLanguages()

# 4. Update main.dart supportedLocales

# 5. Generate localization files
flutter gen-l10n

# 6. Test the build
flutter analyze
flutter build apk --debug

# 7. Test on French device or emulator
```

This will add French support to your LaChispa app! 🇫🇷

---

## ✅ Currently Supported Languages

| Language | Code | Flag | Status | Version Added |
|----------|------|------|--------|---------------|
| Español | es | 🇪🇸 | ✅ Complete | v0.1.5 |
| English | en | 🇺🇸 | ✅ Complete | v0.1.5 |
| Português | pt | 🇵🇹 | ✅ Complete | v0.1.5 |

**LaChispa Mobile - Lightning for everyone, in every language! ⚡**