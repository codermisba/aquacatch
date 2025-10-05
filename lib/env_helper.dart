import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;

class Env {
  static final Map<String, String> _env = {};

  // Load .env from web assets (if needed)
  static Future<void> loadWebEnv() async {
    try {
      final envString = await rootBundle.loadString('assets/.env');
      for (var line in envString.split('\n')) {
        if (line.contains('=')) {
          final parts = line.split('=');
          _env[parts[0].trim()] = parts.sublist(1).join('=').trim();
        }
      }
    } catch (e) {
      print('No web .env found: $e');
    }
  }

  static String? get(String key) => _env[key];
}

String? getHfToken() {
  String? token;
  if (kIsWeb) {
    token = Env.get('HF_TOKEN'); // from runtime .env
  } else {
    token = dotenv.env['HF_TOKEN']; // mobile/desktop
  }

  // fallback: if token is null/empty, load from dotenv anyway
  if (token == null || token.isEmpty) {
    token = dotenv.env['HF_TOKEN'];
  }

  return token;
}
