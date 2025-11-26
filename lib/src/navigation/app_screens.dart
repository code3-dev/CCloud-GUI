import 'package:flutter/material.dart';

enum AppScreen { movies, series, search, countries, favorites, settings }

extension AppScreenExtension on AppScreen {
  String get route {
    switch (this) {
      case AppScreen.movies:
        return '/movies';
      case AppScreen.series:
        return '/series';
      case AppScreen.search:
        return '/search';
      case AppScreen.favorites:
        return '/favorites';
      case AppScreen.settings:
        return '/settings';
      case AppScreen.countries:
        return '/countries';
    }
  }

  String get title {
    switch (this) {
      case AppScreen.movies:
        return 'فیلم‌ها';
      case AppScreen.series:
        return 'سریال‌ها';
      case AppScreen.search:
        return 'جستجو';
      case AppScreen.favorites:
        return 'علاقه‌مندی‌ها';
      case AppScreen.countries:
        return 'کشورها';
      case AppScreen.settings:
        return 'تنظیمات';
    }
  }

  IconData get icon {
    switch (this) {
      case AppScreen.movies:
        return Icons.movie;
      case AppScreen.series:
        return Icons.tv;
      case AppScreen.search:
        return Icons.search;
      case AppScreen.favorites:
        return Icons.favorite;
      case AppScreen.countries:
        return Icons.flag;
      case AppScreen.settings:
        return Icons.settings;
    }
  }

  bool get showInSidebar {
    return true;
  }
}
