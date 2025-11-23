import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform, exit;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/theme_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedSection = 0; // 0 for theme, 1 for about, 2 for support

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(screenWidth > 1200 ? 40.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title
            Text(
              'تنظیمات',
              style: GoogleFonts.vazirmatn(
                fontSize: screenWidth > 1200 ? 32 : 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 30),
            
            // Main content area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use responsive layout for desktop
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left panel - Navigation/Sections
                        Container(
                          width: 250,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Theme.of(context).colorScheme.surfaceVariant
                                : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildNavigationItem(
                                  context,
                                  title: 'ظاهر',
                                  icon: Icons.color_lens,
                                  isSelected: _selectedSection == 0,
                                  onTap: () => setState(() => _selectedSection = 0),
                                ),
                                _buildNavigationItem(
                                  context,
                                  title: 'درباره',
                                  icon: Icons.info,
                                  isSelected: _selectedSection == 1,
                                  onTap: () => setState(() => _selectedSection = 1),
                                ),
                                _buildNavigationItem(
                                  context,
                                  title: 'پشتیبانی',
                                  icon: Icons.support,
                                  isSelected: _selectedSection == 2,
                                  onTap: () => setState(() => _selectedSection = 2),
                                ),
                                _buildNavigationItem(
                                  context,
                                  title: 'بستن برنامه',
                                  icon: Icons.exit_to_app,
                                  isSelected: _selectedSection == 3,
                                  onTap: () => _confirmExit(context),
                                  isExitItem: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 30),
                        
                        // Right panel - Content
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Theme.of(context).colorScheme.surfaceVariant
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: _selectedSection == 0
                                    ? _buildThemeContent(context, themeManager)
                                    : _selectedSection == 1
                                        ? _buildAboutContent(context)
                                        : _selectedSection == 2
                                            ? _buildSupportContent(context)
                                            : Container(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Mobile layout
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Theme Settings Section
                          Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Theme.of(context).colorScheme.surfaceVariant
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.color_lens,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'تم برنامه',
                                      style: GoogleFonts.vazirmatn(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 25),
                                _buildThemeOption(
                                  context,
                                  title: 'پیشفرض سیستم',
                                  icon: Icons.auto_mode,
                                  isSelected: themeManager.currentTheme == AppTheme.system,
                                  onTap: () => themeManager.setTheme(AppTheme.system),
                                ),
                                const SizedBox(height: 15),
                                _buildThemeOption(
                                  context,
                                  title: 'روشن',
                                  icon: Icons.light_mode,
                                  isSelected: themeManager.currentTheme == AppTheme.light,
                                  onTap: () => themeManager.setTheme(AppTheme.light),
                                ),
                                const SizedBox(height: 15),
                                _buildThemeOption(
                                  context,
                                  title: 'تاریک',
                                  icon: Icons.dark_mode,
                                  isSelected: themeManager.currentTheme == AppTheme.dark,
                                  onTap: () => themeManager.setTheme(AppTheme.dark),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // About section
                          Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Theme.of(context).colorScheme.surfaceVariant
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'درباره',
                                      style: GoogleFonts.vazirmatn(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 25),
                                Container(
                                  padding: const EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(25),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 25),
                                      Text(
                                        'CCloud',
                                        style: GoogleFonts.vazirmatn(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        'توسط حسین پیرا',
                                        style: GoogleFonts.vazirmatn(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.9),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'برنامه‌ای برای تماشای فیلم و سریال',
                                        style: GoogleFonts.vazirmatn(
                                          fontSize: 18,
                                          height: 1.6,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 25),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 25,
                                          vertical: 15,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Text(
                                          'نسخه 1.0.0',
                                          style: GoogleFonts.vazirmatn(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
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
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeContent(BuildContext context, ThemeManager themeManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.color_lens,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Text(
              'ظاهر',
              style: GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        
        // Theme options with desktop-friendly layout
        Text(
          'تم برنامه',
          style: GoogleFonts.vazirmatn(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 25),
        
        // Theme options in a grid layout for desktop
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              crossAxisCount: constraints.maxWidth > 1000 ? 3 : 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildThemeCard(
                  context,
                  title: 'پیشفرض سیستم',
                  icon: Icons.auto_mode,
                  isSelected: themeManager.currentTheme == AppTheme.system,
                  onTap: () => themeManager.setTheme(AppTheme.system),
                ),
                _buildThemeCard(
                  context,
                  title: 'روشن',
                  icon: Icons.light_mode,
                  isSelected: themeManager.currentTheme == AppTheme.light,
                  onTap: () => themeManager.setTheme(AppTheme.light),
                ),
                _buildThemeCard(
                  context,
                  title: 'تاریک',
                  icon: Icons.dark_mode,
                  isSelected: themeManager.currentTheme == AppTheme.dark,
                  onTap: () => themeManager.setTheme(AppTheme.dark),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAboutContent(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.info,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Text(
              'درباره',
              style: GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        
        // Modern desktop about content
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App icon
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_circle_fill,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              
              // App name and version
              Text(
                'CCloud',
                style: GoogleFonts.vazirmatn(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'نسخه 1.0.0',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Developer info
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'توسعه‌دهنده',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'حسین پیرا',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'این برنامه برای تماشای فیلم‌ها و سریال‌ها طراحی شده است.',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 16,
                        height: 1.6,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Features section
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ویژگی‌ها',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      context,
                      icon: Icons.movie,
                      title: 'فیلم‌ها',
                      description: 'دسترسی به هزاران فیلم با کیفیت‌های مختلف',
                    ),
                    const SizedBox(height: 15),
                    _buildFeatureItem(
                      context,
                      icon: Icons.live_tv,
                      title: 'سریال‌ها',
                      description: 'تماشای سریال‌های محبوب با زیرنویس فارسی',
                    ),
                    const SizedBox(height: 15),
                    _buildFeatureItem(
                      context,
                      icon: Icons.search,
                      title: 'جستجوی پیشرفته',
                      description: 'پیدا کردن محتوا با فیلترهای مختلف',
                    ),
                    const SizedBox(height: 15),
                    _buildFeatureItem(
                      context,
                      icon: Icons.favorite,
                      title: 'علاقه‌مندی‌ها',
                      description: 'ذخیره کردن محتواهای مورد علاقه',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Support section with buttons
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'پشتیبانی',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      children: [
                        _buildSupportButton(
                          context,
                          icon: Icons.telegram,
                          label: 'تلگرام',
                          url: 'https://t.me/h3dev',
                        ),
                        _buildSupportButton(
                          context,
                          icon: Icons.email,
                          label: 'ایمیل',
                          url: 'mailto:h3dev.pira@gmail.com',
                        ),
                        _buildSupportButton(
                          context,
                          icon: Icons.code,
                          label: 'گیت‌هاب',
                          url: 'https://github.com/code3-dev',
                        ),
                        _buildSupportButton(
                          context,
                          icon: Icons.camera_alt,
                          label: 'اینستاگرام',
                          url: 'https://www.instagram.com/h3dev.pira',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportContent(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.support,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Text(
              'پشتیبانی',
              style: GoogleFonts.vazirmatn(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        
        // Support content
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'راه‌های ارتباطی',
                style: GoogleFonts.vazirmatn(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 30),
              
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildSupportButton(
                    context,
                    icon: Icons.telegram,
                    label: 'تلگرام',
                    url: 'https://t.me/h3dev',
                  ),
                  _buildSupportButton(
                    context,
                    icon: Icons.email,
                    label: 'ایمیل',
                    url: 'mailto:h3dev.pira@gmail.com',
                  ),
                  _buildSupportButton(
                    context,
                    icon: Icons.code,
                    label: 'گیت‌هاب',
                    url: 'https://github.com/code3-dev',
                  ),
                  _buildSupportButton(
                    context,
                    icon: Icons.camera_alt,
                    label: 'اینستاگرام',
                    url: 'https://www.instagram.com/h3dev.pira',
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'راهنمایی',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'در صورت وجود هرگونه مشکل یا سوال، می‌توانید از طریق یکی از راه‌های فوق با ما در ارتباط باشید.',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 16,
                        height: 1.6,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.vazirmatn(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: GoogleFonts.vazirmatn(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    VoidCallback? onTap,
    bool isExitItem = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isExitItem
              ? Colors.red.withOpacity(0.2)
              : isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isExitItem
                ? Colors.red
                : isSelected
                    ? Colors.white
                    : isDarkMode
                        ? Colors.white70
                        : Colors.black54,
          ),
          title: Text(
            title,
            style: GoogleFonts.vazirmatn(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isExitItem
                  ? Colors.red
                  : isSelected
                      ? Colors.white
                      : isDarkMode
                          ? Colors.white70
                          : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : isDarkMode
                  ? Theme.of(context).colorScheme.surface
                  : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : isDarkMode
                    ? Colors.white10
                    : Colors.black12,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: GoogleFonts.vazirmatn(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 10),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : isDarkMode
                  ? Theme.of(context).colorScheme.surface
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color,
              size: 28,
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.vazirmatn(
                fontSize: 20,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String url,
  }) {
    return ElevatedButton.icon(
      onPressed: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('نمی‌توان لینک را باز کرد: $url'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      icon: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
      label: Text(
        label,
        style: GoogleFonts.vazirmatn(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'بستن برنامه',
            style: GoogleFonts.vazirmatn(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'آیا از بستن برنامه اطمینان دارید؟',
            style: GoogleFonts.vazirmatn(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'لغو',
                style: GoogleFonts.vazirmatn(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Close the application
                _exitApp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'بستن',
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _exitApp() {
    // Exit the application
    if (!kIsWeb) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        exit(0);
      }
    }
    // For web or mobile, we'll just show a message
    // In a real mobile app, you might want to minimize instead
  }

}