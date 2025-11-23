import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/media_card.dart';
import '../providers/search_provider.dart';
import '../models/poster.dart';
import '../utils/storage_utils.dart';
import '../screens/single_movie_screen.dart';
import '../screens/single_series_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'جستجو',
              style: GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Search bar
            Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                return TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    searchProvider.updateSearchQuery(value);
                  },
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      searchProvider.triggerSearch();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'جستجوی فیلم و سریال...',
                    hintStyle: GoogleFonts.vazirmatn(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    prefixIcon: IconButton(
                      icon: Icon(
                        Icons.search,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          searchProvider.triggerSearch();
                        }
                      },
                    ),
                    suffixIcon: searchProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              searchProvider.clearSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Search results
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, searchProvider, child) {
                  if (searchProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (searchProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'خطا: ${searchProvider.errorMessage}',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لطفاً دوباره تلاش کنید',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: searchProvider.triggerSearch,
                            child: Text(
                              'تلاش مجدد',
                              style: GoogleFonts.vazirmatn(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (searchProvider.searchResults.isNotEmpty) {
                    return _buildSearchResultsGrid(
                      searchProvider.searchResults,
                    );
                  }
                  if (searchProvider.hasSearched &&
                      searchProvider.searchQuery.isNotEmpty &&
                      !searchProvider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'نتیجه‌ای یافت نشد',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'عبارت جستجو را تغییر دهید',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'جستجوی فیلم و سریال',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'برای شروع یک کلمه کلیدی وارد کنید',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsGrid(List<Poster> posters) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cross axis count based on available width
        final cardWidth = 200.0;
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
            crossAxisCount: count, // Use dynamic count instead of fixed 5
            childAspectRatio: 0.68, // Match the media card dimensions
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: posters.length,
          itemBuilder: (context, index) {
            final poster = posters[index];
            // Convert Poster to MediaItem and use MediaCard
            final mediaItem = poster.toMediaItem();
            return MediaCard(
              mediaItem: mediaItem,
              onTap: () async {
                if (poster.isMovie()) {
                  await StorageUtils.saveMovie(mediaItem);
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            SingleMovieScreen(movie: mediaItem),
                      ),
                    );
                  }
                } else if (poster.isSeries()) {
                  await StorageUtils.saveSeries(mediaItem);
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            SingleSeriesScreen(series: mediaItem),
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}
