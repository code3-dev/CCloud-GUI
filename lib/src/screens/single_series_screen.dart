import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/media_item.dart';
import '../utils/storage_utils.dart';
import '../providers/seasons_provider.dart';
import '../platform/vlc_launcher.dart';

class SingleSeriesScreen extends StatefulWidget {
  final MediaItem series;

  const SingleSeriesScreen({super.key, required this.series});

  @override
  State<SingleSeriesScreen> createState() => _SingleSeriesScreenState();
}

class _SingleSeriesScreenState extends State<SingleSeriesScreen> {
  late MediaItem _series;
  bool _isFavorite = false;
  Episode? _selectedEpisode;

  @override
  void initState() {
    super.initState();
    _series = widget.series;
    if (_series.id <= 0) {
      print('WARNING: Series ID is invalid (${_series.id})');
    }

    _saveSeriesToStorage();

    // Load seasons data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seasonsProvider = Provider.of<SeasonsProvider>(
        context,
        listen: false,
      );
      if (_series.id > 0) {
        seasonsProvider.loadSeasons(_series.id);
      } else {
        print('ERROR: Cannot load seasons - invalid series ID (${_series.id})');
        // Show error to user
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطا در بارگذاری اطلاعات سریال'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      }
    });
  }

  Future<void> _saveSeriesToStorage() async {
    await StorageUtils.saveSeries(_series);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<SeasonsProvider>(
        builder: (context, seasonsProvider, child) {
          return CustomScrollView(
            slivers: [
              // Series header with parallax effect
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                stretch: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                      // Show snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isFavorite
                                ? 'Added to favorites'
                                : 'Removed from favorites',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background cover image with parallax effect
                      Image.network(_series.cover, fit: BoxFit.cover),
                      // Gradient overlay for better text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // Series poster and details overlay
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Series poster with enhanced styling
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDarkMode
                                        ? Colors.black.withOpacity(0.5)
                                        : Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _series.image,
                                  width: 150,
                                  height: 220,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Series details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Series title with better styling
                                  Text(
                                    _series.title,
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(1, 1),
                                          blurRadius: 3,
                                          color: Colors.black.withOpacity(0.8),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Country and year with enhanced styling
                                  Text(
                                    _series.countries.isNotEmpty
                                        ? '${_series.countries.map((c) => c.title).join(', ')} • ${_series.year}'
                                        : '${_series.year}',
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(1, 1),
                                          blurRadius: 2,
                                          color: Colors.black.withOpacity(0.8),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Rating with enhanced styling
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _series.imdb.toStringAsFixed(1),
                                          style: GoogleFonts.vazirmatn(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content below the header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genres with enhanced styling
                      if (_series.genres.isNotEmpty) ...[
                        Text(
                          'ژانرها',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Genres chips with better styling
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _series.genres.map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDarkMode
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                genre.title,
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Description with enhanced styling
                      Text(
                        'توضیحات',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _series.description,
                        style: GoogleFonts.vazirmatn(
                          fontSize: 16,
                          height: 1.8,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Seasons and Episodes with enhanced styling
                      if (seasonsProvider.isLoading) ...[
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 24),
                      ] else if (seasonsProvider.errorMessage.isNotEmpty) ...[
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Error loading seasons: ${seasonsProvider.errorMessage}',
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (_series.id > 0) {
                                    seasonsProvider.loadSeasons(_series.id);
                                  }
                                },
                                child: Text('تلاش مجدد'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else if (seasonsProvider.seasons.isNotEmpty) ...[
                        // Seasons selector with enhanced styling and horizontal scrolling
                        Text(
                          'فصل‌ها',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Help text for desktop users with specific keyboard instructions
                        Text(
                          'برای پیمایش افقی از ماوس یا کلیدهای جهت‌دار ← → صفحه کلید استفاده کنید',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14,
                            color: isDarkMode
                                ? Theme.of(context).textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7)
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Enhanced seasons chips with better scrolling and styling for desktop
                        SizedBox(
                          height: 60,
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              scrollbars:
                                  false, // Hide default scrollbar for cleaner look
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: seasonsProvider.seasons.length,
                              itemBuilder: (context, index) {
                                final season = seasonsProvider.seasons[index];
                                final isSelected =
                                    seasonsProvider.selectedSeasonIndex ==
                                    index;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 0 : 8,
                                    right:
                                        index ==
                                            seasonsProvider.seasons.length - 1
                                        ? 0
                                        : 8,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : isDarkMode
                                          ? Theme.of(context)
                                                .colorScheme
                                                .surfaceVariant
                                                .withOpacity(0.7)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        if (!isSelected)
                                          BoxShadow(
                                            color: isDarkMode
                                                ? Colors.black.withOpacity(0.2)
                                                : Colors.grey.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: ChoiceChip(
                                      label: Text(
                                        season.title,
                                        style: GoogleFonts.vazirmatn(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.purple
                                              : isDarkMode
                                              ? Colors.white70
                                              : Colors.black,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          seasonsProvider.selectSeason(index);
                                        }
                                      },
                                      selectedColor: Colors.transparent,
                                      backgroundColor: Colors.transparent,
                                      labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Episodes list for selected season with enhanced styling
                        if (seasonsProvider.selectedSeason != null) ...[
                          Text(
                            seasonsProvider.selectedSeason!.title,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Grid layout with 2 items per row and enhanced styling
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final itemWidth = (constraints.maxWidth - 20) / 2;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 15,
                                      mainAxisSpacing: 15,
                                      childAspectRatio: 2.5,
                                    ),
                                itemCount: seasonsProvider
                                    .selectedSeason!
                                    .episodes
                                    .length,
                                itemBuilder: (context, index) {
                                  final episode = seasonsProvider
                                      .selectedSeason!
                                      .episodes[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.surfaceVariant
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDarkMode
                                              ? Colors.black.withOpacity(0.3)
                                              : Colors.grey.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        setState(() {
                                          _selectedEpisode = episode;
                                        });
                                        _showSourceOptionsDialog(episode);
                                      },
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                        title: Text(
                                          episode.title,
                                          style: GoogleFonts.vazirmatn(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge?.color
                                                : Colors.black,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (episode.sources.isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ] else if (_series.id > 0) ...[
                        // No seasons message - but only show if we have a valid series ID
                        Center(
                          child: Text(
                            'هیچ فصلی یافت نشد',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Error message for invalid series ID
                        Center(
                          child: Text(
                            'اطلاعات سریال ناقص است',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSourceOptionsDialog(Episode episode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      episode.title,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  'کیفیت‌های موجود',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),

                // Quality options with enhanced styling
                Column(
                  children: episode.sources.asMap().entries.map((entry) {
                    final index = entry.key;
                    final source = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          title: Text(
                            // Fallback to "کیفیت پیشفرض" if quality is null or empty
                            source.quality.isEmpty
                                ? 'کیفیت پیشفرض'
                                : source.quality,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Text(
                            source.type.toUpperCase(),
                            style: GoogleFonts.vazirmatn(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showDownloadOptionsDialog(source);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Cancel button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    'لغو',
                    style: GoogleFonts.vazirmatn(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDownloadOptionsDialog(Source source) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      source.quality.isEmpty ? 'کیفیت پیشفرض' : source.quality,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Source type display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hd,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.quality.isEmpty
                                ? 'کیفیت پیشفرض'
                                : source.quality,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            source.type.toUpperCase(),
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Action buttons in Farsi
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final success = await VLCLauncher.launchInVLC(
                            source.url,
                          );
                          if (!success) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'نمی‌توان لینک را در VLC باز کرد',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'پخش با VLC',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Clipboard.setData(ClipboardData(text: source.url));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('لینک کپی شد')),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'کپی لینک',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final Uri url = Uri.parse(source.url);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('نمی‌توان لینک را دانلود کرد'),
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'دانلود',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Share.share(
                            'قسمت: ${_selectedEpisode?.title ?? 'نامشخص'}\nکیفیت ${source.quality.isEmpty ? 'پیشفرض' : source.quality}: ${source.url}',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'اشتراک‌گذاری لینک',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
