import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class FireflyApi {
  static String get _baseUrl {
    final proxyUrl = "https://afwanhaziq.vps.webdock.cloud/proxy?url=";
    final apiUrl = "https://appapidev.fireflyz.com.my/api/v5"; //or https://fyappapidev.me-tech.com.my/api/v5
    if (kIsWeb) {
      // bypass CORS
      // return 'https://afwanhaziq.vps.webdock.cloud:5000/api/fy';
      return proxyUrl + apiUrl;
    } else {
      return apiUrl;
    }
  }

  // Custom widget for loading images with proxy support
  static Widget buildNetworkImage({
    required String imageUrl,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    String fullUrl = kIsWeb 
        ? "https://afwanhaziq.vps.webdock.cloud/proxy?url=$imageUrl"
        : imageUrl;
    
    return Image.network(
      fullUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return loadingWidget ?? Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / 
                  loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? Image.asset(
          'assets/fy/dubai-uae-featured.jpg',
          fit: fit,
        );
      },
    );
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