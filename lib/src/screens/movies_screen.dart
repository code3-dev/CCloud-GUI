import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/media_card.dart';
import '../widgets/genre_selector.dart';
import '../screens/single_movie_screen.dart';
import '../providers/movie_provider.dart';
import '../providers/genre_provider.dart';
import '../models/media_item.dart';
import '../utils/storage_utils.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      if (movieProvider.movies.isEmpty) {
        movieProvider.loadMovies();
      }
    });

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      if (!movieProvider.isLoading && movieProvider.hasMore) {
        movieProvider.loadMovies();
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
            Text(
              'فیلم‌ها',
              style: GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Filter and sort options
            Row(
              children: [
                // Genre filter button
                Consumer<GenreProvider>(
                  builder: (context, genreProvider, child) {
                    return ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => const GenreSelector(),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            genreProvider.selectedGenre?.title ?? 'ژانرها',
                            style: GoogleFonts.vazirmatn(),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),
                // Sort filter dropdown
                Consumer<MovieProvider>(
                  builder: (context, movieProvider, child) {
                    return DropdownButton<FilterType>(
                      value: movieProvider.selectedFilter,
                      items: const [
                        DropdownMenuItem(
                          value: FilterType.defaultFilter,
                          child: Text('پیشفرض'),
                        ),
                        DropdownMenuItem(
                          value: FilterType.byYear,
                          child: Text('بر اساس سال'),
                        ),
                        DropdownMenuItem(
                          value: FilterType.byImdb,
                          child: Text('بر اساس IMDB'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          movieProvider.selectFilter(value);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 20),
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    final movieProvider = Provider.of<MovieProvider>(
                      context,
                      listen: false,
                    );
                    movieProvider.refreshMovies();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Movie grid
            Expanded(
              child: Consumer<MovieProvider>(
                builder: (context, movieProvider, child) {
                  if (movieProvider.isLoading && movieProvider.movies.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (movieProvider.errorMessage.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${movieProvider.errorMessage}'),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: movieProvider.refreshMovies,
                            child: const Text('تلاش مجدد'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (movieProvider.movies.isEmpty) {
                    return const Center(child: Text('فیلمی یافت نشد'));
                  }

                  return LayoutBuilder(
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
                        controller: _scrollController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: count, // Use dynamic count instead of fixed 5
                          childAspectRatio: 0.68, // Adjusted for the new card dimensions
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount:
                            movieProvider.movies.length +
                            (movieProvider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == movieProvider.movies.length) {
                            // Loading indicator for pagination
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final movie = movieProvider.movies[index];
                          return MediaCard(
                            mediaItem: MediaItem(
                              id: movie.id,
                              type: movie.type,
                              title: movie.title,
                              description: movie.description,
                              year: movie.year,
                              imdb: movie.imdb,
                              rating: movie.rating,
                              duration: movie.duration,
                              image: movie.image,
                              cover: movie.cover,
                              genres: movie.genres
                                  .map((g) => Genre(id: g.id, title: g.title))
                                  .toList(),
                              sources: movie.sources
                                  .map(
                                    (s) => Source(
                                      id: s.id,
                                      quality: s.quality,
                                      type: s.type,
                                      url: s.url,
                                    ),
                                  )
                                  .toList(),
                              countries: movie.countries
                                  .map(
                                    (c) => Country(
                                      id: c.id,
                                      title: c.title,
                                      image: c.image,
                                    ),
                                  )
                                  .toList(),
                            ),
                            onTap: () async {
                              // Save movie to storage and navigate to single movie screen
                              await StorageUtils.saveMovie(movie);
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SingleMovieScreen(movie: movie),
                                  ),
                                );
                              }
                            },
                          );
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
