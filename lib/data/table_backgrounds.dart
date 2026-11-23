import 'package:flutter/material.dart';

/// How a table texture is drawn.
enum TexturePattern { wood, crosshatch, weave }

/// One table surface the player can choose (the "Tablecraft" idea).
class TableBackground {
  final String id;
  final String name;
  final Color base; // main color
  final Color grain; // color of the texture lines
  final TexturePattern pattern;
  final bool isDark; // tells us to use light text on top of it

  const TableBackground({
    required this.id,
    required this.name,
    required this.base,
    required this.grain,
    required this.pattern,
    required this.isDark,
  });
}

const tableBackgrounds = <TableBackground>[
  TableBackground(id: 'oak', name: 'Light oak', base: Color(0xFFE7C99C), grain: Color(0x1F7A4E24), pattern: TexturePattern.wood, isDark: false),
  TableBackground(id: 'walnut', name: 'Walnut', base: Color(0xFF6E4529), grain: Color(0x2E000000), pattern: TexturePattern.wood, isDark: true),
  TableBackground(id: 'linen', name: 'Linen', base: Color(0xFFE9E2D3), grain: Color(0x12000000), pattern: TexturePattern.weave, isDark: false),
  TableBackground(id: 'felt', name: 'Green felt', base: Color(0xFF2F5D46), grain: Color(0x14FFFFFF), pattern: TexturePattern.crosshatch, isDark: true),
  TableBackground(id: 'slate', name: 'Slate', base: Color(0xFF3A4048), grain: Color(0x12FFFFFF), pattern: TexturePattern.crosshatch, isDark: true),
  TableBackground(id: 'denim', name: 'Denim', base: Color(0xFF4F7099), grain: Color(0x1FFFFFFF), pattern: TexturePattern.crosshatch, isDark: true),
];

TableBackground backgroundById(String id) =>
    tableBackgrounds.firstWhere((b) => b.id == id, orElse: () => tableBackgrounds.first);
