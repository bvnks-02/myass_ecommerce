// ignore_for_file: prefer_const_declarations

import 'package:flutter/material.dart';

enum Currency {
  usd('USD', '\$', 'US Dollar', 1.0),
  eur('EUR', '€', 'Euro', 0.92),
  dzd('DZD', 'DA', 'Dinar Algérien', 136.0); // Updated rate for better rounding

  const Currency(this.code, this.symbol, this.name, this.rateToUSD);
  
  final String code;
  final String symbol;
  final String name;
  final double rateToUSD;
}

class CurrencyService extends ChangeNotifier {
  static const List<Currency> _supportedCurrencies = Currency.values;
  static Currency _currentCurrency = Currency.usd; // Default to US Dollar
  
  static List<Currency> get supportedCurrencies => _supportedCurrencies;
  static Currency get currentCurrency => _currentCurrency;
  
  static void setCurrency(Currency currency) {
    _currentCurrency = currency;
  }
  
  static String formatPrice(double price, {Currency? currency}) {
    final targetCurrency = currency ?? _currentCurrency;
    
    // Format based on currency
    switch (targetCurrency) {
      case Currency.dzd:
        // Algerian Dinar: price is already in DZD, no conversion needed
        return '${targetCurrency.symbol}${price.round().toString()}';
      case Currency.usd:
        // USD: 2 decimal places
        return '${targetCurrency.symbol}${price.toStringAsFixed(2)}';
      case Currency.eur:
        // EUR: 2 decimal places  
        return '${targetCurrency.symbol}${price.toStringAsFixed(2)}';
    }
  }
  
  static String formatPriceWithCode(double price, {Currency? currency}) {
    final targetCurrency = currency ?? _currentCurrency;
    final formattedPrice = formatPrice(price, currency: currency);
    return '$formattedPrice ${targetCurrency.code}';
  }
  
  static double convertFromUSD(double priceInUSD, {Currency? toCurrency}) {
    final targetCurrency = toCurrency ?? _currentCurrency;
    final convertedPrice = priceInUSD * targetCurrency.rateToUSD;
    // Use precise rounding for DZD to avoid floating point issues
    if (targetCurrency == Currency.dzd) {
      return (convertedPrice * 100).round() / 100;
    }
    return convertedPrice;
  }
  
  static double convertToUSD(double priceInLocal, {Currency? fromCurrency}) {
    final sourceCurrency = fromCurrency ?? _currentCurrency;
    // Use precise calculation for DZD to avoid floating point issues
    if (sourceCurrency == Currency.dzd) {
      return (priceInLocal * 100).round() / (sourceCurrency.rateToUSD * 100);
    }
    return priceInLocal / sourceCurrency.rateToUSD;
  }
}
