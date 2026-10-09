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
    if (upper.contains('ETH') || upper.contains('SEP')) {
      return const Color(0xFF627EEA);
    }
    return const Color(0xFFF5C400);
  }

  static String? assetFor(String symbol) {
    final upper = symbol.toUpperCase();
    if (upper.contains('USDT')) return 'assets/tokens/usdt.png';
    if (upper.contains('BNB')) return 'assets/tokens/bnb.png';
    if (upper.contains('POL') || upper.contains('MATIC')) {
      return 'assets/tokens/pol.png';
    }
    if (upper.contains('ETH') || upper.contains('SEP')) {
      return 'assets/tokens/eth.png';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(symbol);
    final asset = assetFor(symbol);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? Text(
              symbol.isEmpty ? '?' : symbol.characters.first.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
              ),
            )
          : Padding(
              padding: EdgeInsets.all(size * 0.12),
              child: Image.asset(
                asset,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Text(
                  symbol.characters.first.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }
}
