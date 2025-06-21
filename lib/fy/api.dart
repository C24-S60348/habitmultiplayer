import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class FireflyApi {
  static String get _baseUrl {
    final proxyUrl = "http://afwanhaziq.my:5000/proxy?url=";
    final apiUrl = "https://appapidev.fireflyz.com.my/api/v5";
    if (kIsWeb) {
      // bypass CORS
      // return 'http://afwanhaziq.vps.webdock.cloud:5000/api/fy';
      return proxyUrl + apiUrl;
    } else {
      return apiUrl;
    }
  }

  static Future<dynamic> getLoading() async {
    print('$_baseUrl/Loading');
    final url = Uri.parse('$_baseUrl/Loading');
    final response = await http.get(url);

    print(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}