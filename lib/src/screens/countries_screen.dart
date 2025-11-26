import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/media_card.dart';
import '../providers/countries_provider.dart';
import '../models/country.dart';
import '../models/poster.dart';
import '../models/media_item.dart';
import '../screens/single_movie_screen.dart';
import '../screens/single_series_screen.dart';
import '../utils/storage_utils.dart';

class CountriesScreen extends StatefulWidget {
  const CountriesScreen({super.key});

  @override
  State<CountriesScreen> createState() => _CountriesScreenState();
}

class _CountriesScreenState extends State<CountriesScreen> {
  CountryModel? _selectedCountry;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CountriesProvider>(context, listen: false).loadCountries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedCountry == null
          ? _buildCountriesList()
          : _buildCountryMediaList(),
    );
  }

  Widget _buildCountriesList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'کشورها',
            style: GoogleFonts.vazirmatn(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'کشور مورد نظر خود را انتخاب کنید',
            style: GoogleFonts.vazirmatn(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),
          // Search bar for countries
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'جستجوی کشورها...',
              hintStyle: GoogleFonts.vazirmatn(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).iconTheme.color,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
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
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<CountriesProvider>(
              builder: (context, countriesProvider, child) {
                if (countriesProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (countriesProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'خطا: ${countriesProvider.errorMessage}',
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
                          onPressed: countriesProvider.loadCountries,
                          child: Text(
                            'تلاش مجدد',
                            style: GoogleFonts.vazirmatn(),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final filteredCountries = _searchQuery.isEmpty
                    ? countriesProvider.countries
                    : countriesProvider.countries
                          .where(
                            (country) =>
                                country.title.contains(_searchQuery) ||
                                country.title.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();

                if (filteredCountries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'کشوری یافت نشد'
                              : 'کشوری با این نام یافت نشد',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildCountriesGrid(filteredCountries);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountriesGrid(List<CountryModel> countries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = 150.0;
        final spacing = 20.0;
        final crossAxisCount =
            ((constraints.maxWidth + spacing) / (cardWidth + spacing))
                .floor()
                .toInt();

        final count = crossAxisCount.clamp(1, 6);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: 1.2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: countries.length,
          itemBuilder: (context, index) {
            final country = countries[index];
            return _CountryCard(
              country: country,
              onTap: () {
                setState(() {
                  _selectedCountry = country;
                });
                // Load media for the selected country
                Provider.of<CountryMediaProvider>(
                  context,
                  listen: false,
                ).loadMediaByCountry(country.id);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCountryMediaList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  setState(() {
                    _selectedCountry = null;
                  });
                },
              ),
              const SizedBox(width: 12),
              Text(
                _selectedCountry!.title,
                style: GoogleFonts.vazirmatn(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildFilterDropdown(),
              const SizedBox(width: 12),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  final mediaProvider = Provider.of<CountryMediaProvider>(
                    context,
                    listen: false,
                  );
                  mediaProvider.loadMediaByCountry(
                    _selectedCountry!.id,
                    filterType: mediaProvider.currentFilter,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<CountryMediaProvider>(
              builder: (context, mediaProvider, child) {
                if (mediaProvider.isLoading &&
                    mediaProvider.mediaItems.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (mediaProvider.errorMessage != null &&
                    mediaProvider.mediaItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'خطا: ${mediaProvider.errorMessage}',
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
                          onPressed: () => mediaProvider.loadMediaByCountry(
                            _selectedCountry!.id,
                            filterType: mediaProvider.currentFilter,
                          ),
                          child: Text(
                            'تلاش مجدد',
                            style: GoogleFonts.vazirmatn(),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (mediaProvider.mediaItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'محتوایی برای این کشور یافت نشد',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildMediaGrid(mediaProvider.mediaItems);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Consumer<CountryMediaProvider>(
      builder: (context, mediaProvider, child) {
        return DropdownButton<FilterType>(
          value: mediaProvider.currentFilter,
          items: const [
            DropdownMenuItem(
              value: FilterType.defaultFilter,
              child: Text('مرتب سازی: پیش فرض'),
            ),
            DropdownMenuItem(
              value: FilterType.byYear,
              child: Text('مرتب سازی: سال'),
            ),
            DropdownMenuItem(
              value: FilterType.byImdb,
              child: Text('مرتب سازی: IMDB'),
            ),
          ],
          onChanged: (FilterType? newValue) {
            if (newValue != null && _selectedCountry != null) {
              mediaProvider.loadMediaByCountry(
                _selectedCountry!.id,
                filterType: newValue,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildMediaGrid(List<Poster> posters) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = 200.0;
        final spacing = 20.0;
        final crossAxisCount =
            ((constraints.maxWidth + spacing) / (cardWidth + spacing))
                .floor()
                .toInt();

        final count = crossAxisCount.clamp(1, 5);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: 0.68,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: posters.length,
          itemBuilder: (context, index) {
            final poster = posters[index];
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

class _CountryCard extends StatelessWidget {
  final CountryModel country;
  final VoidCallback onTap;

  const _CountryCard({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(country.image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              country.title,
              style: GoogleFonts.vazirmatn(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
