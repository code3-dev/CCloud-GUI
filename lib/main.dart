import 'package:flutter/material.dart';
import 'src/navigation/app_router.dart';
import 'src/utils/theme_manager.dart';
import 'package:provider/provider.dart';
import 'src/providers/movie_provider.dart';
import 'src/providers/genre_provider.dart';
import 'src/providers/series_provider.dart';
import 'src/providers/seasons_provider.dart';
import 'src/providers/search_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => GenreProvider()),
        ChangeNotifierProvider(create: (_) => SeriesProvider()),
        ChangeNotifierProvider(create: (_) => SeasonsProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: const CCloud(),
    ),
  );
}

class CCloud extends StatelessWidget {
  const CCloud({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CCloud',
      theme: Provider.of<ThemeManager>(context).lightTheme,
      darkTheme: Provider.of<ThemeManager>(context).darkTheme,
      themeMode: Provider.of<ThemeManager>(context).themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}
