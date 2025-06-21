import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class FireflyApi {
  static String get _baseUrl {
    if (kIsWeb) {
      // bypass CORS
      return 'http://afwanhaziq.vps.webdock.cloud:5000/api/fy';
    } else {
      return 'https://appapidev.fireflyz.com.my/api/v5';
    }
  }

  static Future<dynamic> getLoading() async {
    final url = kIsWeb
        ? Uri.parse('$_baseUrl/Loading')
        : Uri.parse('$_baseUrl/Loading');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}