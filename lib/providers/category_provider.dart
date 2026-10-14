import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../data/mock_data.dart';

/// Manages category list
class CategoryProvider extends ChangeNotifier {
  final List<Category> _categories = List.from(MockData.categories);

  List<Category> get categories => List.unmodifiable(_categories);

  /// Find category by id, returns null if not found
  Category? findById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void addCategory(Category category) {
    _categories.add(category);
    notifyListeners();
  }

  void updateCategory(Category updated) {
    final idx = _categories.indexWhere((c) => c.id == updated.id);
    if (idx >= 0) {
      _categories[idx] = updated;
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Generate a simple unique id
  String generateId() => 'cat${DateTime.now().millisecondsSinceEpoch}';
}
