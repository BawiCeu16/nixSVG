import 'package:flutter/material.dart';
import 'package:nixsvg/models/vector_shape.dart';

enum DeviceBrand {
  apple('Apple'),
  google('Google'),
  nothing('Nothing');

  final String label;
  const DeviceBrand(this.label);
}

enum CutoutType {
  notch,
  compactNotch,
  dynamicIsland,
  microIsland,
  centerPunchHole,
  cornerPunchHole,
}

class DevicePreset {
  final String id;
  final String name;
  final DeviceBrand brand;
  final Size size;
  final double cornerRadius;
  final String displaySpec;
  final String screenDiagonal;
  final CutoutType cutoutType;
  final double topSafeArea;
  final double bottomSafeArea;

  const DevicePreset({
    required this.id,
    required this.name,
    required this.brand,
    required this.size,
    required this.cornerRadius,
    required this.displaySpec,
    required this.screenDiagonal,
    required this.cutoutType,
    this.topSafeArea = 47.0,
    this.bottomSafeArea = 34.0,
  });

  double get width => size.width;
  double get height => size.height;

  String get series {
    if (brand == DeviceBrand.apple) {
      if (id.startsWith('iphone-18')) return 'iPhone 18';
      if (id.startsWith('iphone-17')) return 'iPhone 17';
      if (id.startsWith('iphone-16')) return 'iPhone 16';
      if (id.startsWith('iphone-15')) return 'iPhone 15';
      if (id.startsWith('iphone-14')) return 'iPhone 14';
      if (id.startsWith('iphone-13')) return 'iPhone 13';
      if (id.startsWith('iphone-12')) return 'iPhone 12';
      if (id.startsWith('iphone-se')) return 'iPhone SE';
      return 'iPhone';
    } else if (brand == DeviceBrand.google) {
      if (id.startsWith('pixel-11')) return 'Pixel 11';
      if (id.startsWith('pixel-10')) return 'Pixel 10';
      if (id.startsWith('pixel-9')) return 'Pixel 9';
      if (id.startsWith('pixel-8')) return 'Pixel 8';
      if (id.startsWith('pixel-7')) return 'Pixel 7';
      return 'Pixel';
    } else if (brand == DeviceBrand.nothing) {
      if (id.startsWith('nothing-phone-3')) return 'Phone (3)';
      if (id.startsWith('nothing-phone-2a')) return 'Phone (2a)';
      if (id.startsWith('nothing-phone-2')) return 'Phone (2)';
      if (id.startsWith('nothing-phone-1')) return 'Phone (1)';
      if (id.startsWith('cmf')) return 'CMF';
      return 'Nothing';
    }
    return '';
  }

  double get frameThickness {
    if (id.contains('18-pro') || id.contains('17-pro') || id.contains('16-pro')) {
      return 2.2;
    }
    if (id.contains('15-pro') || id.contains('11-pro') || id.contains('10-pro') || id.contains('9-pro')) {
      return 2.6;
    }
    if (id.contains('mini') || id.contains('se')) {
      return 3.5;
    }
    return 3.0;
  }

  static List<String> getSeriesForBrand(DeviceBrand? brand) {
    if (brand == null) return [];
    final presets = switch (brand) {
      DeviceBrand.apple => applePresets,
      DeviceBrand.google => googlePresets,
      DeviceBrand.nothing => nothingPresets,
    };
    final seen = <String>{};
    final result = <String>[];
    for (final p in presets) {
      if (seen.add(p.series)) {
        result.add(p.series);
      }
    }
    return result;
  }

  // ================= PRESETS LIST =================
  static List<DevicePreset> get presets => allPresets;
  static const List<DevicePreset> allPresets = [
    // ----------------------------------------------------
    // APPLE IPHONE (12 to 18)
    // ----------------------------------------------------
    DevicePreset(
      id: 'iphone-18-pro-max',
      name: 'iPhone 18 Pro Max',
      brand: DeviceBrand.apple,
      size: Size(440, 956),
      cornerRadius: 56.0,
      screenDiagonal: '6.9"',
      displaySpec: 'Super Retina XDR OLED • 120Hz ProMotion',
      cutoutType: CutoutType.microIsland,
      topSafeArea: 56.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-18-pro',
      name: 'iPhone 18 Pro',
      brand: DeviceBrand.apple,
      size: Size(402, 874),
      cornerRadius: 56.0,
      screenDiagonal: '6.3"',
      displaySpec: 'Super Retina XDR OLED • 120Hz ProMotion',
      cutoutType: CutoutType.microIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-18',
      name: 'iPhone 18',
      brand: DeviceBrand.apple,
      size: Size(402, 874),
      cornerRadius: 55.0,
      screenDiagonal: '6.3"',
      displaySpec: 'Super Retina XDR OLED • 120Hz',
      cutoutType: CutoutType.microIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-17-pro-max',
      name: 'iPhone 17 Pro Max',
      brand: DeviceBrand.apple,
      size: Size(440, 956),
      cornerRadius: 55.0,
      screenDiagonal: '6.9"',
      displaySpec: 'Super Retina XDR OLED • ProMotion',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 56.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-17-pro',
      name: 'iPhone 17 Pro',
      brand: DeviceBrand.apple,
      size: Size(402, 874),
      cornerRadius: 55.0,
      screenDiagonal: '6.3"',
      displaySpec: 'Super Retina XDR OLED • ProMotion',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-17-air',
      name: 'iPhone 17 Air / Slim',
      brand: DeviceBrand.apple,
      size: Size(414, 896),
      cornerRadius: 55.0,
      screenDiagonal: '6.6"',
      displaySpec: 'Ultra-Thin Titanium Frame • ProMotion',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-17',
      name: 'iPhone 17',
      brand: DeviceBrand.apple,
      size: Size(393, 852),
      cornerRadius: 54.0,
      screenDiagonal: '6.3"',
      displaySpec: 'Super Retina XDR OLED • 120Hz ProMotion',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-16-pro-max',
      name: 'iPhone 16 Pro Max',
      brand: DeviceBrand.apple,
      size: Size(440, 956),
      cornerRadius: 55.0,
      screenDiagonal: '6.9"',
      displaySpec: '1320 × 2868 px • Camera Control',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 56.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-16-pro',
      name: 'iPhone 16 Pro',
      brand: DeviceBrand.apple,
      size: Size(402, 874),
      cornerRadius: 55.0,
      screenDiagonal: '6.3"',
      displaySpec: '1206 × 2622 px • Camera Control',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-16-plus',
      name: 'iPhone 16 Plus',
      brand: DeviceBrand.apple,
      size: Size(430, 932),
      cornerRadius: 53.0,
      screenDiagonal: '6.7"',
      displaySpec: '1290 × 2796 px • Dynamic Island',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-16',
      name: 'iPhone 16',
      brand: DeviceBrand.apple,
      size: Size(393, 852),
      cornerRadius: 53.0,
      screenDiagonal: '6.1"',
      displaySpec: '1179 × 2556 px • Dynamic Island',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-15-pro-max',
      name: 'iPhone 15 Pro Max',
      brand: DeviceBrand.apple,
      size: Size(430, 932),
      cornerRadius: 53.0,
      screenDiagonal: '6.7"',
      displaySpec: '1290 × 2796 px • Titanium Body',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-15-pro',
      name: 'iPhone 15 Pro',
      brand: DeviceBrand.apple,
      size: Size(393, 852),
      cornerRadius: 53.0,
      screenDiagonal: '6.1"',
      displaySpec: '1179 × 2556 px • Action Button',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-15-plus',
      name: 'iPhone 15 Plus',
      brand: DeviceBrand.apple,
      size: Size(430, 932),
      cornerRadius: 53.0,
      screenDiagonal: '6.7"',
      displaySpec: '1290 × 2796 px • Dynamic Island',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-15',
      name: 'iPhone 15',
      brand: DeviceBrand.apple,
      size: Size(393, 852),
      cornerRadius: 50.0,
      screenDiagonal: '6.1"',
      displaySpec: '1179 × 2556 px • Dynamic Island',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-14-pro-max',
      name: 'iPhone 14 Pro Max',
      brand: DeviceBrand.apple,
      size: Size(430, 932),
      cornerRadius: 53.0,
      screenDiagonal: '6.7"',
      displaySpec: '1290 × 2796 px • Dynamic Island',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-14-pro',
      name: 'iPhone 14 Pro',
      brand: DeviceBrand.apple,
      size: Size(393, 852),
      cornerRadius: 53.0,
      screenDiagonal: '6.1"',
      displaySpec: '1179 × 2556 px • Dynamic Island',
      cutoutType: CutoutType.dynamicIsland,
      topSafeArea: 54.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-14-plus',
      name: 'iPhone 14 Plus',
      brand: DeviceBrand.apple,
      size: Size(428, 926),
      cornerRadius: 50.0,
      screenDiagonal: '6.7"',
      displaySpec: '1284 × 2778 px • Compact Notch',
      cutoutType: CutoutType.compactNotch,
      topSafeArea: 47.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-14',
      name: 'iPhone 14',
      brand: DeviceBrand.apple,
      size: Size(390, 844),
      cornerRadius: 47.0,
      screenDiagonal: '6.1"',
      displaySpec: '1170 × 2532 px • Compact Notch',
      cutoutType: CutoutType.compactNotch,
      topSafeArea: 47.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-13-pro-max',
      name: 'iPhone 13 Pro Max',
      brand: DeviceBrand.apple,
      size: Size(428, 926),
      cornerRadius: 50.0,
      screenDiagonal: '6.7"',
      displaySpec: '1284 × 2778 px • ProMotion 120Hz',
      cutoutType: CutoutType.compactNotch,
      topSafeArea: 47.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-13-pro',
      name: 'iPhone 13 Pro',
      brand: DeviceBrand.apple,
      size: Size(390, 844),
      cornerRadius: 47.0,
      screenDiagonal: '6.1"',
      displaySpec: '1170 × 2532 px • ProMotion 120Hz',
      cutoutType: CutoutType.compactNotch,
      topSafeArea: 47.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-13',
      name: 'iPhone 13',
      brand: DeviceBrand.apple,
      size: Size(390, 844),
      cornerRadius: 47.0,
      screenDiagonal: '6.1"',
      displaySpec: '1170 × 2532 px • Super Retina XDR',
      cutoutType: CutoutType.compactNotch,
      topSafeArea: 47.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-13-mini',
      name: 'iPhone 13 mini',
      brand: DeviceBrand.apple,
      size: Size(375, 812),
      cornerRadius: 44.0,
      screenDiagonal: '5.4"',
      displaySpec: '1080 × 2340 px • Compact Frame',
      cutoutType: CutoutType.compactNotch,
      topSafeArea: 47.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-12-pro-max',
      name: 'iPhone 12 Pro Max',
      brand: DeviceBrand.apple,
      size: Size(428, 926),
      cornerRadius: 50.0,
      screenDiagonal: '6.7"',
      displaySpec: '1284 × 2778 px • Stainless Steel',
      cutoutType: CutoutType.notch,
      topSafeArea: 47.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-12-pro',
      name: 'iPhone 12 Pro',
      brand: DeviceBrand.apple,
      size: Size(390, 844),
      cornerRadius: 47.0,
      screenDiagonal: '6.1"',
      displaySpec: '1170 × 2532 px • Ceramic Shield',
      cutoutType: CutoutType.notch,
      topSafeArea: 47.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-12',
      name: 'iPhone 12',
      brand: DeviceBrand.apple,
      size: Size(390, 844),
      cornerRadius: 47.0,
      screenDiagonal: '6.1"',
      displaySpec: '1170 × 2532 px • Flat Edge Design',
      cutoutType: CutoutType.notch,
      topSafeArea: 47.0,
      bottomSafeArea: 34.0,
    ),
    DevicePreset(
      id: 'iphone-12-mini',
      name: 'iPhone 12 mini',
      brand: DeviceBrand.apple,
      size: Size(375, 812),
      cornerRadius: 44.0,
      screenDiagonal: '5.4"',
      displaySpec: '1080 × 2340 px • Mini Form Factor',
      cutoutType: CutoutType.notch,
      topSafeArea: 47.0,
      bottomSafeArea: 34.0,
    ),

    // ----------------------------------------------------
    // GOOGLE PIXEL (7 to 11)
    // ----------------------------------------------------
    DevicePreset(
      id: 'pixel-11-pro-xl',
      name: 'Pixel 11 Pro XL',
      brand: DeviceBrand.google,
      size: Size(412, 892),
      cornerRadius: 50.0,
      screenDiagonal: '6.8"',
      displaySpec: 'Next-Gen Super Actua LTPO • Micro Punch',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 48.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-11-pro',
      name: 'Pixel 11 Pro',
      brand: DeviceBrand.google,
      size: Size(412, 915),
      cornerRadius: 48.0,
      screenDiagonal: '6.3"',
      displaySpec: 'Super Actua OLED 1-120Hz • Micro Bezel',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 48.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-11',
      name: 'Pixel 11',
      brand: DeviceBrand.google,
      size: Size(412, 915),
      cornerRadius: 48.0,
      screenDiagonal: '6.3"',
      displaySpec: 'Actua OLED • Symmetrical Slim Bezel',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 48.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-10-pro-xl',
      name: 'Pixel 10 Pro XL',
      brand: DeviceBrand.google,
      size: Size(412, 892),
      cornerRadius: 48.0,
      screenDiagonal: '6.8"',
      displaySpec: '1344 × 2992 px • Tensor G5 Display',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 48.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-10-pro',
      name: 'Pixel 10 Pro',
      brand: DeviceBrand.google,
      size: Size(412, 915),
      cornerRadius: 46.0,
      screenDiagonal: '6.3"',
      displaySpec: '1280 × 2856 px • Super Actua',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 48.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-10',
      name: 'Pixel 10',
      brand: DeviceBrand.google,
      size: Size(412, 915),
      cornerRadius: 46.0,
      screenDiagonal: '6.3"',
      displaySpec: '1080 × 2424 px • Actua Display',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 48.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-9-pro-xl',
      name: 'Pixel 9 Pro XL',
      brand: DeviceBrand.google,
      size: Size(412, 892),
      cornerRadius: 46.0,
      screenDiagonal: '6.8"',
      displaySpec: '1344 × 2992 px • 3000 nits Peak',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 48.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-9-pro',
      name: 'Pixel 9 Pro',
      brand: DeviceBrand.google,
      size: Size(412, 915),
      cornerRadius: 46.0,
      screenDiagonal: '6.3"',
      displaySpec: '1280 × 2856 px • Super Actua LTPO',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 48.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-9-pro-fold',
      name: 'Pixel 9 Pro Fold (Inner)',
      brand: DeviceBrand.google,
      size: Size(820, 892),
      cornerRadius: 38.0,
      screenDiagonal: '8.0"',
      displaySpec: '2076 × 2152 px • Foldable LTPO OLED',
      cutoutType: CutoutType.cornerPunchHole,
      topSafeArea: 42.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-9',
      name: 'Pixel 9',
      brand: DeviceBrand.google,
      size: Size(412, 915),
      cornerRadius: 44.0,
      screenDiagonal: '6.3"',
      displaySpec: '1080 × 2424 px • Actua OLED 120Hz',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 48.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-8-pro',
      name: 'Pixel 8 Pro',
      brand: DeviceBrand.google,
      size: Size(412, 892),
      cornerRadius: 44.0,
      screenDiagonal: '6.7"',
      displaySpec: '1344 × 2992 px • Super Actua 120Hz',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 46.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-8',
      name: 'Pixel 8',
      brand: DeviceBrand.google,
      size: Size(412, 915),
      cornerRadius: 42.0,
      screenDiagonal: '6.2"',
      displaySpec: '1080 × 2400 px • Actua Display',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 46.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-8a',
      name: 'Pixel 8a',
      brand: DeviceBrand.google,
      size: Size(412, 915),
      cornerRadius: 44.0,
      screenDiagonal: '6.1"',
      displaySpec: '1080 × 2400 px • Smooth 120Hz',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 46.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-7-pro',
      name: 'Pixel 7 Pro',
      brand: DeviceBrand.google,
      size: Size(412, 892),
      cornerRadius: 40.0,
      screenDiagonal: '6.7"',
      displaySpec: '1440 × 3120 px • Curved LTPO OLED',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 44.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-7',
      name: 'Pixel 7',
      brand: DeviceBrand.google,
      size: Size(412, 915),
      cornerRadius: 36.0,
      screenDiagonal: '6.3"',
      displaySpec: '1080 × 2400 px • 90Hz Smooth Display',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 44.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'pixel-7a',
      name: 'Pixel 7a',
      brand: DeviceBrand.google,
      size: Size(412, 915),
      cornerRadius: 36.0,
      screenDiagonal: '6.1"',
      displaySpec: '1080 × 2400 px • FHD+ OLED 90Hz',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 44.0,
      bottomSafeArea: 24.0,
    ),

    // ----------------------------------------------------
    // NOTHING PHONES (All)
    // ----------------------------------------------------
    DevicePreset(
      id: 'nothing-phone-3',
      name: 'Nothing Phone (3)',
      brand: DeviceBrand.nothing,
      size: Size(412, 920),
      cornerRadius: 44.0,
      screenDiagonal: '6.77"',
      displaySpec: '1080 × 2412 px • Next-Gen Glyph Interface',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 46.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'nothing-phone-2',
      name: 'Nothing Phone (2)',
      brand: DeviceBrand.nothing,
      size: Size(412, 919),
      cornerRadius: 42.0,
      screenDiagonal: '6.7"',
      displaySpec: '1080 × 2412 px • LTPO Flexible OLED 120Hz',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 46.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'nothing-phone-2a-plus',
      name: 'Nothing Phone (2a) Plus',
      brand: DeviceBrand.nothing,
      size: Size(412, 919),
      cornerRadius: 42.0,
      screenDiagonal: '6.7"',
      displaySpec: '1080 × 2412 px • Metallic Finish & Glyph Eyes',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 46.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'nothing-phone-2a',
      name: 'Nothing Phone (2a)',
      brand: DeviceBrand.nothing,
      size: Size(412, 919),
      cornerRadius: 42.0,
      screenDiagonal: '6.7"',
      displaySpec: '1080 × 2412 px • 1.3B Colors AMOLED 120Hz',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 46.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'nothing-cmf-phone-1',
      name: 'CMF Phone 1 by Nothing',
      brand: DeviceBrand.nothing,
      size: Size(412, 919),
      cornerRadius: 40.0,
      screenDiagonal: '6.67"',
      displaySpec: '1080 × 2400 px • Modular Accessory Dial',
      cutoutType: CutoutType.centerPunchHole,
      topSafeArea: 44.0,
      bottomSafeArea: 24.0,
    ),
    DevicePreset(
      id: 'nothing-phone-1',
      name: 'Nothing Phone (1)',
      brand: DeviceBrand.nothing,
      size: Size(412, 915),
      cornerRadius: 38.0,
      screenDiagonal: '6.55"',
      displaySpec: '1080 × 2400 px • Original Glyph Design',
      cutoutType: CutoutType.cornerPunchHole,
      topSafeArea: 44.0,
      bottomSafeArea: 24.0,
    ),
  ];

  static List<DevicePreset> get applePresets =>
      allPresets.where((p) => p.brand == DeviceBrand.apple).toList();

  static List<DevicePreset> get googlePresets =>
      allPresets.where((p) => p.brand == DeviceBrand.google).toList();

  static List<DevicePreset> get nothingPresets =>
      allPresets.where((p) => p.brand == DeviceBrand.nothing).toList();

  // ================= TEMPLATE VECTOR SHAPES GENERATOR =================
  /// Generates clean, standards-compliant vector shapes constructing a realistic
  /// device mock frame, status bar, dynamic island/camera cutout, and starter screen layout.
  List<VectorShape> generateTemplateShapes({
    Offset origin = Offset.zero,
    bool darkMode = true,
    bool isTemplate = true,
  }) {
    final shapes = <VectorShape>[];
    final groupId = 'device_${id}_${DateTime.now().millisecondsSinceEpoch}';

    final bgColor = darkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = darkMode ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = darkMode ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        darkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accentColor = switch (brand) {
      DeviceBrand.apple => const Color(0xFF007AFF),
      DeviceBrand.google => const Color(0xFF4285F4),
      DeviceBrand.nothing => const Color(0xFFEA2027),
    };

    // 1. Device Bezel Outer Border / Canvas Card
    final bezelStrokeColor =
        darkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    shapes.add(
      VectorShape(
        id: '$groupId-bezel',
        name: '$name Frame Bezel',
        groupId: groupId,
        type: ShapeType.roundedRectangle,
        rect: Rect.fromLTWH(origin.dx, origin.dy, width, height),
        fillColor: bgColor,
        isStroked: true,
        strokeColor: bezelStrokeColor,
        strokeWidth: frameThickness,
        cornerRadius: cornerRadius,
      ),
    );

    // 2. Hardware Cutout (Dynamic Island / Micro Island / Notch / Center Punch Hole / Corner Punch Hole)
    if (cutoutType == CutoutType.dynamicIsland) {
      const islandW = 125.0;
      const islandH = 35.0;
      final islandX = origin.dx + (width - islandW) / 2;
      final islandY = origin.dy + 11.0;
      shapes.add(
        VectorShape(
          id: '$groupId-cutout',
          name: 'Dynamic Island',
          groupId: groupId,
          type: ShapeType.roundedRectangle,
          rect: Rect.fromLTWH(islandX, islandY, islandW, islandH),
          fillColor: Colors.black,
          cornerRadius: islandH / 2,
        ),
      );
      // Camera lens hardware reflection
      shapes.add(
        VectorShape(
          id: '$groupId-cutout-lens',
          name: 'Camera Lens',
          groupId: groupId,
          type: ShapeType.ellipse,
          rect: Rect.fromLTWH(
            islandX + islandW - 22.0,
            islandY + (islandH - 10.0) / 2,
            10.0,
            10.0,
          ),
          fillColor: const Color(0xFF1E293B),
        ),
      );
    } else if (cutoutType == CutoutType.microIsland) {
      const islandW = 85.0;
      const islandH = 26.0;
      final islandX = origin.dx + (width - islandW) / 2;
      final islandY = origin.dy + 10.0;
      shapes.add(
        VectorShape(
          id: '$groupId-cutout',
          name: 'Micro Dynamic Island',
          groupId: groupId,
          type: ShapeType.roundedRectangle,
          rect: Rect.fromLTWH(islandX, islandY, islandW, islandH),
          fillColor: Colors.black,
          cornerRadius: islandH / 2,
        ),
      );
    } else if (cutoutType == CutoutType.notch ||
        cutoutType == CutoutType.compactNotch) {
      final notchW = cutoutType == CutoutType.notch ? 160.0 : 125.0;
      const notchH = 30.0;
      final notchX = origin.dx + (width - notchW) / 2;
      shapes.add(
        VectorShape(
          id: '$groupId-cutout',
          name: 'Camera Notch',
          groupId: groupId,
          type: ShapeType.roundedRectangle,
          rect: Rect.fromLTWH(notchX, origin.dy, notchW, notchH),
          fillColor: Colors.black,
          cornerRadius: 16.0,
        ),
      );
      // Earpiece speaker slit
      const slitW = 44.0;
      const slitH = 3.0;
      shapes.add(
        VectorShape(
          id: '$groupId-speaker',
          name: 'Earpiece Speaker',
          groupId: groupId,
          type: ShapeType.roundedRectangle,
          rect: Rect.fromLTWH(
            origin.dx + (width - slitW) / 2,
            origin.dy + 4.0,
            slitW,
            slitH,
          ),
          fillColor: const Color(0xFF1E293B),
          cornerRadius: 1.5,
        ),
      );
    } else if (cutoutType == CutoutType.centerPunchHole) {
      const holeSize = 13.0;
      final holeX = origin.dx + (width - holeSize) / 2;
      final holeY = origin.dy + 12.0;
      shapes.add(
        VectorShape(
          id: '$groupId-cutout',
          name: 'Camera Punch Hole',
          groupId: groupId,
          type: ShapeType.ellipse,
          rect: Rect.fromLTWH(holeX, holeY, holeSize, holeSize),
          fillColor: Colors.black,
        ),
      );
      shapes.add(
        VectorShape(
          id: '$groupId-cutout-lens',
          name: 'Camera Lens',
          groupId: groupId,
          type: ShapeType.ellipse,
          rect: Rect.fromLTWH(holeX + 3.0, holeY + 3.0, 7.0, 7.0),
          fillColor: const Color(0xFF1E293B),
        ),
      );
    } else if (cutoutType == CutoutType.cornerPunchHole) {
      const holeSize = 13.0;
      final holeX = origin.dx + 24.0;
      final holeY = origin.dy + 14.0;
      shapes.add(
        VectorShape(
          id: '$groupId-cutout',
          name: 'Corner Punch Hole',
          groupId: groupId,
          type: ShapeType.ellipse,
          rect: Rect.fromLTWH(holeX, holeY, holeSize, holeSize),
          fillColor: Colors.black,
        ),
      );
      shapes.add(
        VectorShape(
          id: '$groupId-cutout-lens',
          name: 'Camera Lens',
          groupId: groupId,
          type: ShapeType.ellipse,
          rect: Rect.fromLTWH(holeX + 3.0, holeY + 3.0, 7.0, 7.0),
          fillColor: const Color(0xFF1E293B),
        ),
      );
    }

    // 3. Status Bar Clock Text
    final timeString = brand == DeviceBrand.apple ? '9:41' : '10:00';
    final clockLeft =
        cutoutType == CutoutType.cornerPunchHole ? origin.dx + 48.0 : origin.dx + 28.0;
    shapes.add(
      VectorShape(
        id: '$groupId-status-time',
        name: 'Status Time',
        groupId: groupId,
        type: ShapeType.text,
        rect: Rect.fromLTWH(clockLeft, origin.dy + 15.0, 50, 20),
        textContent: timeString,
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
        fillColor: primaryTextColor,
      ),
    );

    // 4. Status Bar Cellular Signal & Battery Icon
    final batteryRight = origin.dx + width - 36.0;

    // Signal Bars
    shapes.add(
      VectorShape(
        id: '$groupId-status-signal-1',
        name: 'Signal Bar 1',
        groupId: groupId,
        type: ShapeType.roundedRectangle,
        rect: Rect.fromLTWH(batteryRight - 20.0, origin.dy + 23.0, 3.0, 6.0),
        fillColor: primaryTextColor,
        cornerRadius: 0.8,
      ),
    );
    shapes.add(
      VectorShape(
        id: '$groupId-status-signal-2',
        name: 'Signal Bar 2',
        groupId: groupId,
        type: ShapeType.roundedRectangle,
        rect: Rect.fromLTWH(batteryRight - 15.0, origin.dy + 20.0, 3.0, 9.0),
        fillColor: primaryTextColor,
        cornerRadius: 0.8,
      ),
    );
    shapes.add(
      VectorShape(
        id: '$groupId-status-signal-3',
        name: 'Signal Bar 3',
        groupId: groupId,
        type: ShapeType.roundedRectangle,
        rect: Rect.fromLTWH(batteryRight - 10.0, origin.dy + 17.0, 3.0, 12.0),
        fillColor: primaryTextColor,
        cornerRadius: 0.8,
      ),
    );

    // Battery Shell Outline
    shapes.add(
      VectorShape(
        id: '$groupId-status-battery',
        name: 'Battery Indicator',
        groupId: groupId,
        type: ShapeType.roundedRectangle,
        rect: Rect.fromLTWH(batteryRight, origin.dy + 18.0, 22, 11),
        fillColor: Colors.transparent,
        isStroked: true,
        strokeColor: primaryTextColor,
        strokeWidth: 1.2,
        cornerRadius: 3.5,
      ),
    );
    // Battery Terminal Cap
    shapes.add(
      VectorShape(
        id: '$groupId-status-battery-cap',
        name: 'Battery Cap',
        groupId: groupId,
        type: ShapeType.roundedRectangle,
        rect: Rect.fromLTWH(batteryRight + 22.5, origin.dy + 21.0, 1.5, 5),
        fillColor: primaryTextColor.withValues(alpha: 0.7),
        cornerRadius: 0.8,
      ),
    );
    // Battery Fill Level
    shapes.add(
      VectorShape(
        id: '$groupId-status-battery-fill',
        name: 'Battery Fill',
        groupId: groupId,
        type: ShapeType.roundedRectangle,
        rect: Rect.fromLTWH(batteryRight + 2.5, origin.dy + 20.5, 12.0, 6.0),
        fillColor: primaryTextColor,
        cornerRadius: 1.5,
      ),
    );

    // 5. Navigation Bar / Home Indicator (Bottom)
    final barW = brand == DeviceBrand.apple ? 140.0 : 80.0;
    final barH = brand == DeviceBrand.apple ? 5.0 : 4.0;
    final barX = origin.dx + (width - barW) / 2;
    final barY = origin.dy + height - (bottomSafeArea > 20 ? bottomSafeArea - 12.0 : 14.0);
    shapes.add(
      VectorShape(
        id: '$groupId-home-bar',
        name: 'Home Indicator Pill',
        groupId: groupId,
        type: ShapeType.roundedRectangle,
        rect: Rect.fromLTWH(barX, barY, barW, barH),
        fillColor: primaryTextColor.withValues(alpha: 0.5),
        cornerRadius: barH / 2,
      ),
    );

    // BLANK FRAME: If not generating template mock content, return pristine blank frame immediately!
    if (!isTemplate) {
      return shapes;
    }

    // 6. App Screen Header Title & Subtitle (Mock Template only)
    final headerY = origin.dy + topSafeArea + 16.0;
    shapes.add(
      VectorShape(
        id: '$groupId-header-title',
        name: 'Screen Header Title',
        groupId: groupId,
        type: ShapeType.text,
        rect: Rect.fromLTWH(origin.dx + 24.0, headerY, width - 48.0, 36.0),
        textContent: name,
        fontSize: 24.0,
        fontWeight: FontWeight.w800,
        fillColor: primaryTextColor,
      ),
    );

    shapes.add(
      VectorShape(
        id: '$groupId-header-sub',
        name: 'Screen Header Subtitle',
        groupId: groupId,
        type: ShapeType.text,
        rect: Rect.fromLTWH(origin.dx + 24.0, headerY + 34.0, width - 48.0, 22.0),
        textContent: '$screenDiagonal • ${width.toInt()} × ${height.toInt()} pt',
        fontSize: 13.0,
        fontWeight: FontWeight.w500,
        fillColor: secondaryTextColor,
      ),
    );

    // 7. Showcase Card Container (Mock Template only)
    final cardY = headerY + 70.0;
    final cardW = width - 48.0;
    const cardH = 160.0;
    shapes.add(
      VectorShape(
        id: '$groupId-hero-card',
        name: 'Hero Card Container',
        groupId: groupId,
        type: ShapeType.roundedRectangle,
        rect: Rect.fromLTWH(origin.dx + 24.0, cardY, cardW, cardH),
        fillColor: cardColor,
        isStroked: true,
        strokeColor:
            darkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        strokeWidth: 1.0,
        cornerRadius: 20.0,
      ),
    );

    // Accent Graphic / Badge inside card
    shapes.add(
      VectorShape(
        id: '$groupId-card-accent',
        name: 'Brand Accent Dot',
        groupId: groupId,
        type: ShapeType.ellipse,
        rect: Rect.fromLTWH(origin.dx + 44.0, cardY + 22.0, 14.0, 14.0),
        fillColor: accentColor,
      ),
    );

    shapes.add(
      VectorShape(
        id: '$groupId-card-brand',
        name: 'Brand Label',
        groupId: groupId,
        type: ShapeType.text,
        rect: Rect.fromLTWH(origin.dx + 66.0, cardY + 20.0, 180.0, 20.0),
        textContent: brand.label.toUpperCase(),
        fontSize: 11.0,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        fillColor: accentColor,
      ),
    );

    shapes.add(
      VectorShape(
        id: '$groupId-card-title',
        name: 'Card Title',
        groupId: groupId,
        type: ShapeType.text,
        rect: Rect.fromLTWH(origin.dx + 44.0, cardY + 48.0, cardW - 40.0, 28.0),
        textContent: 'Vector Frame Template',
        fontSize: 17.0,
        fontWeight: FontWeight.w700,
        fillColor: primaryTextColor,
      ),
    );

    shapes.add(
      VectorShape(
        id: '$groupId-card-desc',
        name: 'Card Description',
        groupId: groupId,
        type: ShapeType.text,
        rect: Rect.fromLTWH(origin.dx + 44.0, cardY + 80.0, cardW - 40.0, 48.0),
        textContent: displaySpec,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        fillColor: secondaryTextColor,
      ),
    );

    return shapes;
  }
}
