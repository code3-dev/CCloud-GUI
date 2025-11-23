import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class VLCLauncher {
  static Future<bool> launchInVLC(String url) async {
    try {
      if (kIsWeb) {
        final Uri uri = Uri.parse(url);
        return await launchUrl(uri);
      } else if (Platform.isWindows) {
        return await _launchOnWindows(url);
      } else if (Platform.isLinux) {
        return await _launchOnLinux(url);
      } else if (Platform.isMacOS) {
        return await _launchOnMacOS(url);
      } else {
        final Uri uri = Uri.parse(url);
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching VLC: $e');
      return false;
    }
  }

  static Future<bool> _launchOnWindows(String url) async {
    try {
      final List<String> vlcPaths = [
        'C:\\Program Files\\VideoLAN\\VLC\\vlc.exe',
        'C:\\Program Files (x86)\\VideoLAN\\VLC\\vlc.exe',
        'vlc.exe',
      ];

      for (final path in vlcPaths) {
        final File vlcExecutable = File(path);
        if (await vlcExecutable.exists()) {
          final result = await Process.run(path, [url]);
          return result.exitCode == 0;
        }
      }

      final Uri uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching VLC on Windows: $e');
      return false;
    }
  }

  static Future<bool> _launchOnLinux(String url) async {
    try {
      final whichResult = await Process.run('which', ['vlc']);
      if (whichResult.exitCode == 0 &&
          (whichResult.stdout as String).isNotEmpty) {
        final result = await Process.run('vlc', [url]);
        return result.exitCode == 0;
      }

      const vlcPath = '/usr/bin/vlc';
      final File vlcExecutable = File(vlcPath);
      if (await vlcExecutable.exists()) {
        final result = await Process.run(vlcPath, [url]);
        return result.exitCode == 0;
      }

      final Uri uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching VLC on Linux: $e');
      return false;
    }
  }

  static Future<bool> _launchOnMacOS(String url) async {
    try {
      final result = await Process.run('open', ['-a', 'VLC', url]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error launching VLC on macOS: $e');
      return false;
    }
  }
}
