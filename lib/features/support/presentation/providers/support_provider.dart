import 'package:flutter/foundation.dart';
import '../../domain/entities/faq_model.dart';

class SupportProvider with ChangeNotifier {
  List<FAQModel> _faqs = [];
  List<FAQModel> _filteredFAQs = [];
  String _searchQuery = '';

  List<FAQModel> get faqs => _filteredFAQs;
  String get searchQuery => _searchQuery;

  SupportProvider() {
    _loadFAQs();
  }

  void _loadFAQs() {
    _faqs = FAQModel.getDummyFAQs();
    _filteredFAQs = _faqs;
  }

  void searchFAQs(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isEmpty) {
      _filteredFAQs = _faqs;
    } else {
      _filteredFAQs = _faqs.where((faq) {
        return faq.question.toLowerCase().contains(_searchQuery) ||
               faq.answer.toLowerCase().contains(_searchQuery) ||
               faq.category.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredFAQs = _faqs;
    notifyListeners();
  }
}
