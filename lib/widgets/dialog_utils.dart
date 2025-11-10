import 'package:flutter/material.dart';

// Dialog utilities for URL validation
class DialogUtils {
  static bool isValidUrl(String url) {
    if (url.isEmpty) return true; // Allow empty URLs
    try {
      final uri = Uri.parse(url);
      // Check for valid scheme (http or https)
      if (uri.scheme != 'http' && uri.scheme != 'https') return false;
      
      // Check for valid domain (must have at least one dot and valid TLD)
      if (!uri.host.contains('.')) return false;
      
      // Check for valid path (optional)
      // Check for valid authority (domain)
      if (uri.authority.isEmpty) return false;
      
      // Additional check for common invalid patterns
      if (uri.host.endsWith('.') || uri.host.startsWith('.')) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> showLinkValidationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Link'),
          content: Text('Please enter a valid URL with proper domain (e.g., https://example.com)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Continue Anyway'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}

