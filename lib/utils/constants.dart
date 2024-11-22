import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF00ADEF);
  static const Color accentColor = Color(0xFFFFC107);
  static const Color backgroundColor = Color(0xFFF7F7F7);
  static const Color textColor = Color(0xFF333333);


  static const Color Tile_color = Color.fromRGBO(250, 248, 246, 1);
  static const Color button_color = Color.fromRGBO(11, 82, 38, 1);
  static const Color button_in_color = Color.fromRGBO(193, 212, 192, 1);
  static const Color user_tile_color = Color.fromRGBO(211, 211, 211, 1);


  // Padding
  static const double defaultPadding = 16.0;

  // API Keys (example)
  static const String stripePublishableKey = "your_stripe_publishable_key";

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 14.0,
    color: textColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
