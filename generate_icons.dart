import 'dart:io';
import 'package:ccloud_gui/src/utils/icon_generator.dart' as icon_generator;

void main() async {
  print('Flutter Desktop Icon Generator');
  print('==============================');

  final logoFile = File('assets/logo.png');
  if (!await logoFile.exists()) {
    print('Error: assets/logo.png not found!');
    print(
      'Please place your logo file at assets/logo.png and run this script again.',
    );
    exit(1);
  }

  print('Found logo.png, generating icons for all platforms...');
  print('');

  try {
    await icon_generator.IconGenerator.generateAllIcons();
    print('');
    print('✅ Icon generation completed successfully!');
    print('');
    print('Next steps:');
    print(
      '1. For macOS: Icons are in macos/Runner/Assets.xcassets/AppIcon.appiconset/',
    );
    print('2. For Windows: Icons are in windows/runner/resources/');
    print('3. For Linux: Icons are in linux/assets/');
    print('');
    print('You can now build your app for any platform with the new icons.');
  } catch (e) {
    print('❌ Error generating icons: $e');
    exit(1);
  }
}
