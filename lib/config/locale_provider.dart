import 'package:flutter/material.dart';
import 'app_strings.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'th'; // default Thai

  String get locale => _locale;
  bool get isThai => _locale == 'th';
  bool get isEnglish => _locale == 'en';

  void toggleLocale() {
    _locale = _locale == 'th' ? 'en' : 'th';
    notifyListeners();
  }

  void setLocale(String locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }
}

class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_LocalizationsInherited>();
    return provider?.localizations ?? AppLocalizations('th');
  }

  String tr(String key) {
    final map = AppStrings.strings[key];
    if (map == null) return key;
    return map[locale] ?? map['en'] ?? key;
  }
}

class LocalizationsWrapper extends StatelessWidget {
  final String locale;
  final Widget child;

  const LocalizationsWrapper({
    super.key,
    required this.locale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _LocalizationsInherited(
      localizations: AppLocalizations(locale),
      child: child,
    );
  }
}

class _LocalizationsInherited extends InheritedWidget {
  final AppLocalizations localizations;

  const _LocalizationsInherited({
    required this.localizations,
    required super.child,
  });

  @override
  bool updateShouldNotify(_LocalizationsInherited oldWidget) {
    return localizations.locale != oldWidget.localizations.locale;
  }
}
