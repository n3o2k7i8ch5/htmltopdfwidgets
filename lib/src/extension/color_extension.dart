import 'package:pdf/pdf.dart';

// Define an extension for PdfColor to add additional functionality.
extension ColorExtension on PdfColor {
  /// Try to parse the `rgba(red, green, blue, alpha)` from the string.
  static PdfColor? tryFromRgbaString(String colorString) {
    final reg = RegExp(r'rgba?\((\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d+(?:\.\d+)?))?\s*\)');
    final match = reg.firstMatch(colorString);

    if (match == null) {
      return null;
    }

    final redStr = match.group(1);
    final greenStr = match.group(2);
    final blueStr = match.group(3);
    final alphaStr = match.group(4);

    final red = redStr != null ? int.tryParse(redStr) : null;
    final green = greenStr != null ? int.tryParse(greenStr) : null;
    final blue = blueStr != null ? int.tryParse(blueStr) : null;
    final alpha = alphaStr != null ? double.tryParse(alphaStr) : 1.0;

    if (red == null || green == null || blue == null || alpha == null) {
      return null;
    }

    return PdfColor.fromInt(hexOfRGBA(red, green, blue, opacity: alpha));
  }

  // Convert PdfColor to an RGBA string format.
  String toRgbaString() {
    return 'rgba($red, $green, $blue, $alpha)';
  }

  static PdfColor hexToPdfColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');

    if (hexColor.length == 3) {
      hexColor = hexColor.split('').map((char) => '$char$char').join();
    }

    if (hexColor.length != 6) {
      throw ArgumentError('Invalid hex color format');
    }

    final int red = int.parse(hexColor.substring(0, 2), radix: 16);
    final int green = int.parse(hexColor.substring(2, 4), radix: 16);
    final int blue = int.parse(hexColor.substring(4, 6), radix: 16);

    return PdfColor.fromInt(0xFF000000 | (red << 16) | (green << 8) | blue);
  }
}

int hexOfRGBA(int r, int g, int b, {double opacity = 1}) {
  r = r.clamp(0, 255);
  g = g.clamp(0, 255);
  b = b.clamp(0, 255);
  final int a = (opacity.clamp(0.0, 1.0) * 255).round();

  return (a << 24) | (r << 16) | (g << 8) | b;
}

bool isRgba(String color) {
  // Regular expression to check if the color is in 'rgba' format
  final rgbaRegex = RegExp(r"^rgba?\((\s*\d+\s*,){2,3}\s*\d+(\.\d+)?\s*\)$",
      caseSensitive: false);
  return rgbaRegex.hasMatch(color);
}

bool isHex(String color) {
  // Regular expression to check if the color is in hex format (#RRGGBB or #RGB)
  final hexRegex =
      RegExp(r"^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$", caseSensitive: false);
  return hexRegex.hasMatch(color);
}
