import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../services/currency_service.dart';

/// Website-style price typography: big bold fg numerals with the currency
/// unit ("DA") rendered smaller and muted. Falls back to the plain formatted
/// string if the unit suffix can't be split off.
///
/// [gold] applies the myazz-ui GoldShader (champagne gradient) to the
/// NUMERALS only — the unit stays muted. Use with restraint: featured hero,
/// product-details price, order totals. Grid-card prices stay ink.
class PriceText extends StatelessWidget {
  final double price;
  final double fontSize;
  final double? unitSize;
  final Color color;
  final Color unitColor;
  final FontWeight fontWeight;
  final bool gold;

  const PriceText({
    super.key,
    required this.price,
    this.fontSize = 16,
    this.unitSize,
    this.color = AppTheme.fg,
    this.unitColor = AppTheme.dim,
    this.fontWeight = FontWeight.w700,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = CurrencyService.formatPrice(price);
    final symbol = CurrencyService.currentCurrency.symbol;
    final unit = ' $symbol';

    String numerals = formatted;
    String? suffix;
    if (formatted.endsWith(unit)) {
      numerals = formatted.substring(0, formatted.length - unit.length);
      suffix = unit;
    }

    final numeralsStyle = TextStyle(
      // Under the ShaderMask the child color only supplies alpha.
      color: gold ? Colors.white : color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'Inter',
      height: 1.15,
    );
    final suffixStyle = TextStyle(
      color: unitColor,
      fontSize: unitSize ?? fontSize * 0.55,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
    );

    if (gold) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          GoldShader(child: Text(numerals, style: numeralsStyle)),
          if (suffix != null) Text(suffix, style: suffixStyle),
        ],
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: numerals, style: numeralsStyle),
          if (suffix != null) TextSpan(text: suffix, style: suffixStyle),
        ],
      ),
    );
  }
}
