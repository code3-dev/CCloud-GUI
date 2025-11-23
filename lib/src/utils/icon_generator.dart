import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Icon Generator for Flutter Desktop Apps
/// Generates and copies icon files for macOS, Windows, and Linux from a source PNG
class IconGenerator {
  static const String sourceLogoPath = 'assets/logo.png';

  // Required icon sizes for each platform
  static const List<int> macIconSizes = [16, 32, 64, 128, 256, 512, 1024];
  static const List<int> windowsIconSizes = [16, 24, 32, 48, 64, 96, 128, 256];
  static const List<int> linuxIconSizes = [
    16,
    22,
    24,
    32,
    48,
    64,
    128,
    256,
    512,
  ];

  /// Main function to generate all icons for all platforms
  static Future<void> generateAllIcons() async {
    print('Starting icon generation...');

    // Check if source logo exists
    final logoFile = File(sourceLogoPath);
    if (!await logoFile.exists()) {
      print('Error: Source logo not found at $sourceLogoPath');
      return;
    }

    print('Source logo found. Generating icons...');

    try {
      // Generate icons for each platform
      await _generateMacIcons();
      await _generateWindowsIcons();
      await _generateLinuxIcons();

      print('All icons generated successfully!');
    } catch (e) {
      print('Error generating icons: $e');
    }
  }

  /// Generate icons for macOS
  static Future<void> _generateMacIcons() async {
    print('Generating macOS icons...');

    // Create AppIcon.appiconset directory if it doesn't exist
    final appIconDir = Directory(
      'macos/Runner/Assets.xcassets/AppIcon.appiconset',
    );

    // Remove old icons
    if (await appIconDir.exists()) {
      await appIconDir.delete(recursive: true);
    }

    // Create fresh directory
    await appIconDir.create(recursive: true);

    // Load the source image
    final imageBytes = await File(sourceLogoPath).readAsBytes();
    final sourceImage = img.decodePng(imageBytes);

    if (sourceImage == null) {
      print('Error: Could not decode source PNG image');
      return;
    }

    // Generate individual PNG icons
    final List<Map<String, dynamic>> iconContents = [];

    for (final size in macIconSizes) {
      final resizedImage = img.copyResize(
        sourceImage,
        width: size,
        height: size,
      );
      final pngBytes = img.encodePng(resizedImage);

      final filename = '${size}x$size.png';
      final filePath = '${appIconDir.path}/$filename';
      await File(filePath).writeAsBytes(pngBytes);

      iconContents.add({
        'size': '${size}x$size',
        'idiom': 'mac',
        'filename': filename,
        'scale': '1x',
      });

      print('Generated: $filename');
    }

    // Create Contents.json for macOS
    final contentsJson =
        '''
{
  "images": [${iconContents.map((icon) => '''
    {
      "size": "${icon['size']}",
      "idiom": "${icon['idiom']}",
      "filename": "${icon['filename']}",
      "scale": "${icon['scale']}"
    }''').join(',')}],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''';

    await File('${appIconDir.path}/Contents.json').writeAsString(contentsJson);
    print('macOS icons generated successfully!');
  }

  /// Generate icons for Windows
  static Future<void> _generateWindowsIcons() async {
    print('Generating Windows icons...');

    // Create resources directory if it doesn't exist
    final windowsResourcesDir = Directory('windows/runner/resources');

    // Remove old icons
    if (await windowsResourcesDir.exists()) {
      await windowsResourcesDir.delete(recursive: true);
    }

    // Create fresh directory
    await windowsResourcesDir.create(recursive: true);

    // Load the source image
    final imageBytes = await File(sourceLogoPath).readAsBytes();
    final sourceImage = img.decodePng(imageBytes);

    if (sourceImage == null) {
      print('Error: Could not decode source PNG image');
      return;
    }

    // Generate ICO file (contains multiple sizes)
    final icoFilePath = '${windowsResourcesDir.path}/app_icon.ico';
    await _createICOFile(sourceImage, icoFilePath, windowsIconSizes);
    print('Generated Windows ICO file: app_icon.ico');

    print('Windows icons generated successfully!');
  }

  /// Generate icons for Linux
  static Future<void> _generateLinuxIcons() async {
    print('Generating Linux icons...');

    // Create icons directory if it doesn't exist
    final linuxIconsDir = Directory('linux/assets');

    // Remove old icons
    if (await linuxIconsDir.exists()) {
      await linuxIconsDir.delete(recursive: true);
    }

    // Create fresh directory
    await linuxIconsDir.create(recursive: true);

    // Load the source image
    final imageBytes = await File(sourceLogoPath).readAsBytes();
    final sourceImage = img.decodePng(imageBytes);

    if (sourceImage == null) {
      print('Error: Could not decode source PNG image');
      return;
    }

    // Generate PNG icons for different sizes
    for (final size in linuxIconSizes) {
      final resizedImage = img.copyResize(
        sourceImage,
        width: size,
        height: size,
      );
      final pngBytes = img.encodePng(resizedImage);

      final filename = '${size}x$size.png';
      final filePath = '${linuxIconsDir.path}/$filename';
      await File(filePath).writeAsBytes(pngBytes);

      print('Generated Linux icon: $filename');
    }

    print('Linux icons generated successfully!');
  }

  /// Create a proper ICO file with multiple embedded images
  static Future<void> _createICOFile(
    img.Image sourceImage,
    String outputPath,
    List<int> sizes,
  ) async {
    final icoBytes = <int>[];

    // ICO Header (6 bytes)
    icoBytes.addAll([0x00, 0x00]); // Reserved
    icoBytes.addAll([0x01, 0x00]); // ICO type
    icoBytes.addAll(_toLittleEndian16(sizes.length)); // Number of images

    // Directory entries (16 bytes each)
    int imageDataOffset = 6 + (16 * sizes.length);
    final List<img.Image> resizedImages = [];

    for (final size in sizes) {
      final resizedImage = img.copyResize(
        sourceImage,
        width: size,
        height: size,
      );
      resizedImages.add(resizedImage);

      final pngBytes = img.encodePng(resizedImage);

      // Directory entry
      icoBytes.addAll([size == 256 ? 0 : size]); // Width
      icoBytes.addAll([size == 256 ? 0 : size]); // Height
      icoBytes.addAll([0x00]); // Color palette
      icoBytes.addAll([0x00]); // Reserved
      icoBytes.addAll([0x01, 0x00]); // Color planes
      icoBytes.addAll([0x20, 0x00]); // Bits per pixel (32)
      icoBytes.addAll(_toLittleEndian32(pngBytes.length)); // Image data size
      icoBytes.addAll(_toLittleEndian32(imageDataOffset)); // Image data offset

      imageDataOffset += pngBytes.length;
    }

    // Image data
    for (final image in resizedImages) {
      final pngBytes = img.encodePng(image);
      icoBytes.addAll(pngBytes);
    }

    // Write ICO file
    await File(outputPath).writeAsBytes(icoBytes);
  }

  /// Convert int to little-endian 16-bit bytes
  static List<int> _toLittleEndian16(int value) {
    return [value & 0xFF, (value >> 8) & 0xFF];
  }

  /// Convert int to little-endian 32-bit bytes
  static List<int> _toLittleEndian32(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }
}
