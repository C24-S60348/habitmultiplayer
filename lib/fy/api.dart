import 'dart:convert';
import 'package:http/http.dart' as http;

class FireflyApi {
  static const String _baseUrl = 'https://appapidev.fireflyz.com.my/api/v5';

  /// Calls GET /Loading endpoint and returns the decoded JSON response.
  static Future<dynamic> getLoading() async {
    final url = Uri.parse('$_baseUrl/Loading');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}
