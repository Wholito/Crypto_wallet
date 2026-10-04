import 'package:flutter/material.dart';

class AssetIcon extends StatelessWidget {
  const AssetIcon({required this.symbol, this.size = 44, super.key});

  final String symbol;
  final double size;

  static Color colorFor(String symbol) {
    final upper = symbol.toUpperCase();
    if (upper.contains('USDT')) return const Color(0xFF26A17B);
    if (upper.contains('USDC')) return const Color(0xFF2775CA);
    if (upper.contains('BNB')) return const Color(0xFFF0B90B);
    if (upper.contains('POL') || upper.contains('MATIC')) {
      return const Color(0xFF8247E5);
    }
    if (upper.contains('ETH')) return const Color(0xFF627EEA);
    return const Color(0xFF5B4BDB);
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(symbol);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      child: Text(
        symbol.isEmpty ? '?' : symbol.characters.first.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
