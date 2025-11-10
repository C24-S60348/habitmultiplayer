import 'package:http/http.dart' as http;
import 'dart:convert';

// API base for new server
const String apiBase = 'https://afwanhaziq.vps.webdock.cloud/api/habit';

// Simple connectivity check (works on all platforms)
Future<bool> hasInternetConnection() async {
  try {
    final response = await http
        .get(Uri.parse('https://www.google.com/generate_204'))
        .timeout(const Duration(seconds: 5));
    return response.statusCode == 204 || response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

// Helper function for safe HTTP GET requests with timeout and error handling
Future<http.Response?> safeHttpGet(Uri url, {Duration timeout = const Duration(seconds: 10)}) async {
  try {
    // Yield control to UI thread before making request
    await Future.delayed(Duration.zero);
    return await http.get(url).timeout(timeout);
  } catch (e) {
    print('Network error: $e');
    return null;
  }
}

// Helper function for safe JSON decoding that yields control
dynamic safeJsonDecode(String source) {
  try {
    return jsonDecode(source);
  } catch (e) {
    print('JSON decode error: $e');
    return null;
  }
}

