import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/genre_provider.dart';
import '../providers/movie_provider.dart';

class GenreSelector extends StatefulWidget {
  const GenreSelector({super.key});

  @override
  State<GenreSelector> createState() => _GenreSelectorState();
}

class _GenreSelectorState extends State<GenreSelector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final genreProvider = Provider.of<GenreProvider>(context, listen: false);
      if (genreProvider.genres.isEmpty) {
        genreProvider.loadGenres();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GenreProvider>(
      builder: (context, genreProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ژانرها',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // All Genres option
              GestureDetector(
                onTap: () {
                  genreProvider.selectGenre(0);
                  final movieProvider = Provider.of<MovieProvider>(
                    context,
                    listen: false,
                  );
                  movieProvider.selectGenre(0);
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: genreProvider.selectedGenreId == 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: genreProvider.selectedGenreId == 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        genreProvider.selectedGenreId == 0
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: genreProvider.selectedGenreId == 0
                            ? Colors.white
                            : Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'همه ژانرها',
                        style: GoogleFonts.vazirmatn(
                          color: genreProvider.selectedGenreId == 0
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: genreProvider.selectedGenreId == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Loading or error state
              if (genreProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (genreProvider.errorMessage.isNotEmpty)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Error: ${genreProvider.errorMessage}',
                        style: GoogleFonts.vazirmatn(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: genreProvider.loadGenres,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                )
              else
                // Genres grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3,
                        ),
                    itemCount: genreProvider.genres.length,
                    itemBuilder: (context, index) {
                      final genre = genreProvider.genres[index];
                      final isSelected =
                          genre.id == genreProvider.selectedGenreId;

                      return GestureDetector(
                        onTap: () {
                          genreProvider.selectGenre(genre.id);
                          final movieProvider = Provider.of<MovieProvider>(
                            context,
                            listen: false,
                          );
                          movieProvider.selectGenre(genre.id);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              genre.title,
                              style: GoogleFonts.vazirmatn(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
