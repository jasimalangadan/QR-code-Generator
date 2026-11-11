import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant Harmonious Brand Palette
  static const Color primaryPurple = Color(0xFF6C5CE7);
  static const Color darkPurple = Color(0xFF5A4AD1);
  static const Color lightPurpleBg = Color(0xFFF1EFFF);
  static const Color backgroundGrey = Color(0xFFF8F9FD);

  static const Color textDark = Color(0xFF1E202C);
  static const Color textGrey = Color(0xFF7A7E96);
  static const Color borderGrey = Color(0xFFE4E6F1);

  // Specific Badge Colors
  static const Color badgeRedBg = Color(0xFFFFF0F1);
  static const Color badgeRedText = Color(0xFFFF5252);
  static const Color progressTrack = Color(0xFFE6E5FF);

  // Gradient definitions for brand icons
  static const Gradient instagramGradient = RadialGradient(
    colors: [
      Color(0xFFFEE140),
      Color(0xFFFA709A),
      Color(0xFFC428AC),
      Color(0xFF8134AF),
      Color(0xFF515BD4),
    ],
    center: Alignment.bottomLeft,
    radius: 1.5,
  );

  static const List<ThemePreset> brandPresets = [
    // Stunning Premium Local Asset Themes
    ThemePreset(
      id: 'apple_theme',
      name: 'Apple Tech',
      value: 'assets/images/themeImages/appleTheme.jpg',
      colors: [Color(0xFFE22D43), Color(0xFFC70039)],
      imageUrl: 'assets/images/themeImages/appleTheme.jpg',
    ),
    ThemePreset(
      id: 'bag_theme',
      name: 'Fashion Bags',
      value: 'assets/images/themeImages/bagTheme.jpg',
      colors: [Color(0xFF8B5A2B), Color(0xFFCD853F)],
      imageUrl: 'assets/images/themeImages/bagTheme.jpg',
    ),
    ThemePreset(
      id: 'cosmetics_theme',
      name: 'Cosmetics',
      value: 'assets/images/themeImages/cosmeticsTheme.jpg',
      colors: [Color(0xFFFF82AB), Color(0xFFFFC0CB)],
      imageUrl: 'assets/images/themeImages/cosmeticsTheme.jpg',
    ),
    ThemePreset(
      id: 'fancy_theme',
      name: 'Fancy Boutique',
      value: 'assets/images/themeImages/fancyTheme.jpg',
      colors: [Color(0xFFEC008C), Color(0xFFFC6767)],
      imageUrl: 'assets/images/themeImages/fancyTheme.jpg',
    ),
    ThemePreset(
      id: 'furniture_theme',
      name: 'Furniture Store',
      value: 'assets/images/themeImages/furnitureTheme.jpg',
      colors: [Color(0xFF8B4513), Color(0xFFCD853F)],
      imageUrl: 'assets/images/themeImages/furnitureTheme.jpg',
    ),
    ThemePreset(
      id: 'gents_clothing_theme',
      name: 'Gents Clothing',
      value: 'assets/images/themeImages/gentscloathingTheme.jpg',
      colors: [Color(0xFF2C3E50), Color(0xFF1B263B)],
      imageUrl: 'assets/images/themeImages/gentscloathingTheme.jpg',
    ),
    ThemePreset(
      id: 'homedecor_theme',
      name: 'Home Decor',
      value: 'assets/images/themeImages/homedecorTheme.jpg',
      colors: [Color(0xFF6B8E23), Color(0xFF8FBC8F)],
      imageUrl: 'assets/images/themeImages/homedecorTheme.jpg',
    ),
    ThemePreset(
      id: 'jwellery_theme',
      name: 'Jewelry Luxury',
      value: 'assets/images/themeImages/jwelleryTheme.jpg',
      colors: [Color(0xFFDAA520), Color(0xFFCFB53B)],
      imageUrl: 'assets/images/themeImages/jwelleryTheme.jpg',
    ),
    ThemePreset(
      id: 'kidswear_theme',
      name: 'Kids Wear',
      value: 'assets/images/themeImages/kidswearTheme.jpg',
      colors: [Color(0xFFFF758C), Color(0xFF70A1FF)],
      imageUrl: 'assets/images/themeImages/kidswearTheme.jpg',
    ),
    ThemePreset(
      id: 'mens_beauty_theme',
      name: 'Mens Grooming',
      value: 'assets/images/themeImages/mensbeautyTheme.jpg',
      colors: [Color(0xFF1A1C29), Color(0xFF4A4E69)],
      imageUrl: 'assets/images/themeImages/mensbeautyTheme.jpg',
    ),
    ThemePreset(
      id: 'nuts_theme',
      name: 'Organic Nuts',
      value: 'assets/images/themeImages/nutsTheme.jpg',
      colors: [Color(0xFFD2691E), Color(0xFFCD853F)],
      imageUrl: 'assets/images/themeImages/nutsTheme.jpg',
    ),
    ThemePreset(
      id: 'partha_theme',
      name: 'Partha Sarees',
      value: 'assets/images/themeImages/parthaTheme.jpg',
      colors: [Color(0xFF800080), Color(0xFFFF00FF)],
      imageUrl: 'assets/images/themeImages/parthaTheme.jpg',
    ),
    ThemePreset(
      id: 'perfume_theme',
      name: 'Luxury Perfume',
      value: 'assets/images/themeImages/perfumeTheme.jpg',
      colors: [Color(0xFFE6C280), Color(0xFFB8860B)],
      imageUrl: 'assets/images/themeImages/perfumeTheme.jpg',
    ),
    ThemePreset(
      id: 'restaurant_theme',
      name: 'Restaurant',
      value: 'assets/images/themeImages/restuarentTheme.jpg',
      colors: [Color(0xFFD35400), Color(0xFFE67E22)],
      imageUrl: 'assets/images/themeImages/restuarentTheme.jpg',
    ),
    ThemePreset(
      id: 'shoes_theme',
      name: 'Shoe Shop',
      value: 'assets/images/themeImages/shoeshopTheme.jpg',
      colors: [Color(0xFF2980B9), Color(0xFF3498DB)],
      imageUrl: 'assets/images/themeImages/shoeshopTheme.jpg',
    ),
    ThemePreset(
      id: 'toy_theme',
      name: 'Toy World',
      value: 'assets/images/themeImages/toyTheme.jpg',
      colors: [Color(0xFFF1C40F), Color(0xFFE67E22)],
      imageUrl: 'assets/images/themeImages/toyTheme.jpg',
    ),
    ThemePreset(
      id: 'women_beauty_theme',
      name: 'Women Beauty',
      value: 'assets/images/themeImages/womenbeautyTheme.jpg',
      colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
      imageUrl: 'assets/images/themeImages/womenbeautyTheme.jpg',
    ),
    ThemePreset(
      id: 'women_clothing_theme',
      name: 'Women Clothing',
      value: 'assets/images/themeImages/womencloathingTheme.jpg',
      colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
      imageUrl: 'assets/images/themeImages/womencloathingTheme.jpg',
    ),

    // Tailored Industry Themes
    ThemePreset(
      id: 'kids_wear',
      name: 'Kids Wear',
      value: '#FF758C,#70A1FF',
      colors: [Color(0xFFFF758C), Color(0xFF70A1FF)],
      isGradient: true,
    ),
    ThemePreset(
      id: 'gents_wear',
      name: 'Gents Wear',
      value: '#1F2430,#D4AF37',
      colors: [Color(0xFF1F2430), Color(0xFFD4AF37)],
      isGradient: true,
    ),
    ThemePreset(
      id: 'fancy_shop',
      name: 'Fancy Shop',
      value: '#EC008C,#FC6767',
      colors: [Color(0xFFEC008C), Color(0xFFFC6767)],
      isGradient: true,
    ),

    // Stunning Premium Gradients
    ThemePreset(
      id: 'sunset',
      name: 'Sunset Glow',
      colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
      value: '#FA709A,#FEE140',
      isGradient: true,
    ),
    ThemePreset(
      id: 'royal',
      name: 'Royal Purple',
      value: '#7F00FF,#E100FF',
      colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
      isGradient: true,
    ),
    ThemePreset(
      id: 'ocean',
      name: 'Ocean Breeze',
      value: '#00C6FF,#0072FF',
      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
      isGradient: true,
    ),
    ThemePreset(
      id: 'neon',
      name: 'Neon Emerald',
      value: '#11998E,#38EF7D',
      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      isGradient: true,
    ),
    ThemePreset(
      id: 'cosmos',
      name: 'Deep Cosmos',
      value: '#1F1C2C,#928DAB',
      colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
      isGradient: true,
    ),
    // Premium Single Solid Colors
    ThemePreset(
      id: 'pure_black',
      name: 'Pure Black',
      value: '#000000',
      colors: [Color(0xFF000000)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'navy_blue',
      name: 'Navy Blue',
      value: '#001F3F',
      colors: [Color(0xFF001F3F)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'royal_blue',
      name: 'Royal Blue',
      value: '#0052CC',
      colors: [Color(0xFF0052CC)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'sky_blue',
      name: 'Sky Blue',
      value: '#00A8FF',
      colors: [Color(0xFF00A8FF)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'crimson_red',
      name: 'Crimson Red',
      value: '#D32F2F',
      colors: [Color(0xFFD32F2F)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'emerald_green',
      name: 'Emerald Green',
      value: '#2E7D32',
      colors: [Color(0xFF2E7D32)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'forest_green',
      name: 'Forest Green',
      value: '#1B4D3E',
      colors: [Color(0xFF1B4D3E)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'vibrant_orange',
      name: 'Vibrant Orange',
      value: '#FF6F00',
      colors: [Color(0xFFFF6F00)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'coral_orange',
      name: 'Coral Orange',
      value: '#E17055',
      colors: [Color(0xFFE17055)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'deep_violet',
      name: 'Deep Violet',
      value: '#6A1B9A',
      colors: [Color(0xFF6A1B9A)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'purple',
      name: 'Vibrant Purple',
      value: '#6C5CE7',
      colors: [Color(0xFF6C5CE7)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'hot_pink',
      name: 'Hot Pink',
      value: '#E91E63',
      colors: [Color(0xFFE91E63)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'amber_yellow',
      name: 'Amber Yellow',
      value: '#FFB300',
      colors: [Color(0xFFFFB300)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'chocolate_brown',
      name: 'Chocolate Brown',
      value: '#5D4037',
      colors: [Color(0xFF5D4037)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'charcoal',
      name: 'Charcoal Black',
      value: '#12141D',
      colors: [Color(0xFF12141D)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'mint',
      name: 'Teal Mint',
      value: '#00B894',
      colors: [Color(0xFF00B894)],
      isGradient: false,
    ),
    ThemePreset(
      id: 'pure_white',
      name: 'Pure White',
      value: '#FFFFFF',
      colors: [Color(0xFFFFFFFF)],
      isGradient: false,
    ),
  ];

  static List<Color> parseThemeColors(String themeColorStr) {
    if (themeColorStr.isEmpty) {
      return [primaryPurple];
    }
    try {
      final matchedPreset = brandPresets.firstWhere(
        (p) =>
            p.value.toLowerCase() == themeColorStr.toLowerCase() ||
            p.id.toLowerCase() == themeColorStr.toLowerCase(),
      );
      return matchedPreset.colors;
    } catch (_) {
      // Proceed with raw parsing
    }
    final lower = themeColorStr.trim().toLowerCase();
    if (lower == 'white' || lower == 'pure_white' || lower == '#fff' || lower == '#ffffff') {
      return [const Color(0xFFFFFFFF)];
    }
    if (lower == 'black' || lower == 'pure_black' || lower == '#000' || lower == '#000000') {
      return [const Color(0xFF000000)];
    }
    try {
      final cleanStr = themeColorStr
          .replaceAll(' ', '')
          .replaceAll('"', '')
          .replaceAll("'", '');
      if (cleanStr.contains(',')) {
        return cleanStr.split(',').map((c) => _parseHexColor(c)).toList();
      } else {
        return [_parseHexColor(cleanStr)];
      }
    } catch (_) {
      return [primaryPurple];
    }
  }

  static Color _parseHexColor(String hexStr) {
    String clean = hexStr.replaceAll('#', '').trim();
    if (clean.length == 3) {
      clean = clean.split('').map((c) => '$c$c').join();
    }
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    return Color(int.parse(clean, radix: 16));
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundGrey,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        primary: primaryPurple,
        surface: backgroundGrey,
      ),
      fontFamily: 'Inter', // Default fallback is system font, styled precisely
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.2,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textGrey,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderGrey, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textGrey, fontSize: 14),
        hintStyle: const TextStyle(
          color: textGrey,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}

class ThemePreset {
  final String id;
  final String name;
  final String value; // Hex string e.g. '#6C5CE7', gradients, or image URL
  final List<Color> colors;
  final bool isGradient;
  final String? imageUrl;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.value,
    required this.colors,
    this.isGradient = false,
    this.imageUrl,
  });
}
