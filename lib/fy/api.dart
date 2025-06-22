import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class FireflyApi {
  static String get _baseUrl {
    final proxyUrl = "https://afwanhaziq.vps.webdock.cloud/proxy?url=";
    final apiUrl = "https://appapidev.fireflyz.com.my/api/v5";
    if (kIsWeb) {
      // bypass CORS
      // return 'https://afwanhaziq.vps.webdock.cloud:5000/api/fy';
      return proxyUrl + apiUrl;
    } else {
      return apiUrl;
    }
  }

  static Future<dynamic> getLoading() async {
    final fullUrl = '$_baseUrl/Loading';
    print(fullUrl);
    final url = Uri.parse(fullUrl);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  static Future<dynamic> getBanner() async {
    final fullUrl = '$_baseUrl/HomeBanner';
    print(fullUrl);
    final url = Uri.parse(fullUrl);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load banner data: ${response.statusCode}');
    }
  }
}