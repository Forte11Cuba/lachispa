import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  static const List<Locale> supportedLocales = [
    Locale('es', ''),
    Locale('en', ''),
    Locale('pt', ''),
    Locale('de', ''),
    Locale('fr', ''),
    Locale('it', ''),
  ];
  
  Locale _currentLocale = const Locale('es', '');
  
  Locale get currentLocale => _currentLocale;
  
  LanguageProvider() {
    _loadSavedLanguage();
  }
  
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);
      
      if (savedLanguageCode != null) {
        final savedLocale = supportedLocales.firstWhere(
          (locale) => locale.languageCode == savedLanguageCode,
          orElse: () => const Locale('es', ''),
        );
        
        _currentLocale = savedLocale;
        notifyListeners();
      } else {
        await _detectSystemLanguage();
      }
    } catch (e) {
      print('[LanguageProvider] Error cargando idioma guardado: $e');
      _currentLocale = const Locale('es', '');
    }
  }
  
  Future<void> _detectSystemLanguage() async {
    try {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      
      final isSupported = supportedLocales.any(
        (locale) => locale.languageCode == systemLocale.languageCode,
      );
      
      if (isSupported) {
        _currentLocale = Locale(systemLocale.languageCode, '');
        await _saveLanguagePreference(_currentLocale.languageCode);
        notifyListeners();
      }
    } catch (e) {
      print('[LanguageProvider] Error detectando idioma del sistema: $e');
    }
  }
  
  Future<void> changeLanguage(Locale newLocale) async {
    final isSupported = supportedLocales.any((locale) => locale.languageCode == newLocale.languageCode);
    if (!isSupported) {
      print('[LanguageProvider] Idioma no soportado: ${newLocale.languageCode}');
      return;
    }
    
    if (_currentLocale.languageCode == newLocale.languageCode) {
      return;
    }
    
    _currentLocale = Locale(newLocale.languageCode, '');
    await _saveLanguagePreference(newLocale.languageCode);
    notifyListeners();
    
    print('[LanguageProvider] Idioma cambiado a: ${newLocale.languageCode}');
  }
  
  Future<void> _saveLanguagePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('[LanguageProvider] Error guardando preferencia de idioma: $e');
    }
  }
  
  String getCurrentLanguageName() {
    switch (_currentLocale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'it':
        return 'Italiano';
      default:
        return 'Español';
    }
  }
  
  String getCurrentLanguageFlag() {
    switch (_currentLocale.languageCode) {
      case 'es':
        return '🇪🇸';
      case 'en':
        return '🇺🇸';
      case 'pt':
        return '🇵🇹';
      case 'de':
        return '🇩🇪';
      case 'fr':
        return '🇫🇷';
      case 'it':
        return '🇮🇹';
      default:
        return '🇪🇸';
    }
  }
  
  String getCurrentLanguageDisplay() {
    return '${getCurrentLanguageFlag()} ${getCurrentLanguageName()}';
  }
  
  List<Map<String, String>> getAvailableLanguages() {
    final languages = supportedLocales.map((locale) {
      switch (locale.languageCode) {
        case 'es':
          return {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'};
        case 'en':
          return {'code': 'en', 'name': 'English', 'flag': '🇺🇸'};
        case 'pt':
          return {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'};
        case 'de':
          return {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'};
        case 'fr':
          return {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'};
        case 'it':
          return {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'};
        default:
          return {'code': locale.languageCode, 'name': locale.languageCode, 'flag': '🌐'};
      }
    }).toList();
    
    // Sort alphabetically by language name
    languages.sort((a, b) => a['name']!.compareTo(b['name']!));
    return languages;
  }
  
  Future<void> resetToDefault() async {
    await changeLanguage(const Locale('es', ''));
  }
}