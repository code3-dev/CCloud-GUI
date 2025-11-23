import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/media_item.dart';
import '../utils/storage_utils.dart';
import '../widgets/media_card.dart';
import '../screens/single_movie_screen.dart';
import '../screens/single_series_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<MediaItemWithTimestamp> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final favorites = await StorageUtils.loadFavoritesWithTimestamp();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در بارگذاری علاقه‌مندی‌ها')),
        );
      }
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'حذف همه علاقه‌مندی‌ها',
          style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'آیا از حذف همه علاقه‌مندی‌ها اطمینان دارید؟',
          style: GoogleFonts.vazirmatn(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('لغو', style: GoogleFonts.vazirmatn()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'حذف',
              style: GoogleFonts.vazirmatn(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await StorageUtils.clearAllFavorites();
        setState(() {
          _favorites = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('همه علاقه‌مندی‌ها حذف شدند')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطا در حذف علاقه‌مندی‌ها')),
          );
        }
      }
    }
  }

  Future<void> _exportFavorites() async {
    try {
      // Get favorites data
      final favorites = await StorageUtils.loadFavoritesWithTimestamp();

      // Convert to JSON
      final jsonData = favorites.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonData);

      // Open file picker for save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'ذخیره علاقه‌مندی‌ها',
        fileName: 'favorites.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        // Write to file
        final file = File(result);
        await file.writeAsString(jsonString);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('علاقه‌مندی‌ها با موفقیت ذخیره شدند')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ذخیره علاقه‌مندی‌ها')),
        );
      }
    }
  }

  Future<void> _importFavorites() async {
    try {
      // Open file picker for selecting file
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'انتخاب فایل علاقه‌مندی‌ها',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        // Read file content
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as List<dynamic>;

        // Convert JSON to MediaItem objects
        final importedFavorites = jsonData
            .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
            .toList();

        // Clear existing favorites and save imported ones
        await StorageUtils.clearAllFavorites();
        for (final item in importedFavorites) {
          await StorageUtils.addToFavorites(item);
        }

        // Reload favorites
        await _loadFavorites();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${importedFavorites.length} علاقه‌مندی با موفقیت بارگذاری شد',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در بارگذاری علاقه‌مندی‌ها')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'علاقه‌مندی‌ها',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_favorites.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'export':
                          _exportFavorites();
                          break;
                        case 'import':
                          _importFavorites();
                          break;
                        case 'delete_all':
                          _clearAllFavorites();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            const Icon(Icons.upload_file, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'ذخیره علاقه‌مندی‌ها',
                              style: GoogleFonts.vazirmatn(),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'import',
                        child: Row(
                          children: [
                            const Icon(Icons.file_download, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'بارگذاری علاقه‌مندی‌ها',
                              style: GoogleFonts.vazirmatn(),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_forever, size: 20),
                            const SizedBox(width: 10),
                            Text('حذف همه', style: GoogleFonts.vazirmatn()),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Favorites grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'علاقه‌مندی‌ای یافت نشد',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'فیلم‌ها و سریال‌های مورد علاقه خود را اضافه کنید',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _importFavorites,
                                icon: const Icon(Icons.file_download),
                                label: Text(
                                  'بارگذاری علاقه‌مندی‌ها',
                                  style: GoogleFonts.vazirmatn(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate cross axis count based on available width
                        final cardWidth = 200.0; // Increased card width
                        final spacing = 20.0;
                        final crossAxisCount =
                            ((constraints.maxWidth + spacing) /
                                    (cardWidth + spacing))
                                .floor()
                                .toInt();

                        // Ensure at least 1 column and max 5 columns
                        final count = crossAxisCount.clamp(1, 5);

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                count, // Use dynamic count instead of fixed 5
                            childAspectRatio:
                                0.68, // Adjusted for the new card dimensions
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: _favorites.length,
                          itemBuilder: (context, index) {
                            final mediaItem = _favorites[index].mediaItem;
                            return MediaCard(
                              mediaItem: mediaItem,
                              showFavoriteButton:
                                  false, // Don't show favorite button in favorites screen
                              onTap: () async {
                                // Navigate to the appropriate screen based on media type
                                if (mediaItem.type == 'movie') {
                                  if (context.mounted) {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SingleMovieScreen(movie: mediaItem),
                                      ),
                                    );
                                    // Refresh after returning from the movie screen
                                    _loadFavorites();
                                  }
                                } else if (mediaItem.type == 'serie') {
                                  if (context.mounted) {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SingleSeriesScreen(
                                              series: mediaItem,
                                            ),
                                      ),
                                    );
                                    // Refresh after returning from the series screen
                                    _loadFavorites();
                                  }
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
