import 'package:flutter/material.dart';

class SkinConfig {
  const SkinConfig({
    required this.id,
    required this.name,
    required this.price,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String id;
  final String name;
  final int price; // en LUX coins
  final Color primaryColor;
  final Color secondaryColor;

  bool get isFree => price <= 0;
}

class SkinCatalog {
  static const SkinConfig standard = SkinConfig(
    id: 'standard',
    name: 'Standard',
    price: 0,
    primaryColor: Color(0xFF00FFFF),
    secondaryColor: Color(0xFF7800FF),
  );

  static const SkinConfig neonAmber = SkinConfig(
    id: 'neon_ambre',
    name: 'Néon Ambre',
    price: 1000,
    primaryColor: Color(0xFFFFD700),
    secondaryColor: Color(0xFFFF6A00),
  );

  static const SkinConfig emeraldRoyal = SkinConfig(
    id: 'emeraude_royale',
    name: 'Émeraude Royale',
    price: 2500,
    primaryColor: Color(0xFF39FF14),
    secondaryColor: Color(0xFF00E5FF),
  );

  static const List<SkinConfig> all = <SkinConfig>[
    standard,
    neonAmber,
    emeraldRoyal,
  ];

  static SkinConfig byId(String id) {
    for (final SkinConfig s in all) {
      if (s.id == id) return s;
    }
    return standard;
  }
}

