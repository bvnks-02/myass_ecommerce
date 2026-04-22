import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isSmallPhone(BuildContext context) {
    return screenWidth(context) < 360;
  }

  static bool isMediumPhone(BuildContext context) {
    return screenWidth(context) >= 360 && screenWidth(context) < 400;
  }

  static bool isLargePhone(BuildContext context) {
    return screenWidth(context) >= 400;
  }

  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  // Scale factor based on screen width (baseline: 375px - iPhone X)
  static double scaleFactor(BuildContext context) {
    return screenWidth(context) / 375;
  }

  // Scaled width
  static double sw(BuildContext context, double width) {
    return width * scaleFactor(context);
  }

  // Scaled height
  static double sh(BuildContext context, double height) {
    return height * scaleFactor(context);
  }

  // Scaled font size
  static double sf(BuildContext context, double fontSize) {
    return fontSize * scaleFactor(context);
  }

  // Responsive padding
  static double padding(BuildContext context) {
    if (isSmallPhone(context)) return 12;
    if (isMediumPhone(context)) return 16;
    return 20;
  }

  // Responsive grid columns
  static int gridColumns(BuildContext context) {
    if (isTablet(context)) return 4;
    if (isLargePhone(context)) return 3;
    return 2;
  }

  // Responsive child aspect ratio for grid
  static double gridAspectRatio(BuildContext context) {
    if (isTablet(context)) return 0.7;
    if (isLargePhone(context)) return 0.68;
    return 0.65;
  }
}
