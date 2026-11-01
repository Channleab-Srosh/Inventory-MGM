import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../models/user_profile.dart';
import '../data/api_service.dart';

/// Manages category list with real backend fetching, search, and CRUD support
class CategoryProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Category> _categories = [];
  String _search = '';
  bool _isLoading = false;
  String? _error;
  UserProfile? _currentUser;

  CategoryProvider({UserProfile? currentUser}) : _currentUser = currentUser {
    if (_api.hasToken) {
      fetchCategories();
    }
  }

  void updateUser(UserProfile? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clear() {
    _categories = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  UserProfile? get currentUser => _currentUser;
  List<Category> get categories => _filtered();
  List<Category> get allCategories => List.unmodifiable(_categories);
  String get search => _search;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Category> _filtered() {
    if (_search.trim().isEmpty) return List.unmodifiable(_categories);
    final q = _search.trim().toLowerCase();
    return _categories.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  /// Fetch categories from API
  Future<void> fetchCategories() async {
    if (!_api.hasToken) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.getCategories(size: 100);
      _categories = list.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = (e is ApiException) ? e.message : e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Find category by id, returns null if not found
  Category? findById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add Category via API
  Future<Category?> addCategory(Category category) async {
    if (_currentUser != null && !_currentUser!.canManageCategories) {
      _error = 'Permission denied: Staff accounts cannot add, edit, or delete categories.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createCategory(category.name, category.description);
      final created = Category.fromJson(data);
      _categories.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Update Category via API
  Future<bool> updateCategory(Category updated) async {
    if (_currentUser != null && !_currentUser!.canManageCategories) {
      _error = 'Permission denied: Staff accounts cannot add, edit, or delete categories.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.updateCategory(updated.id, updated.name, updated.description);
      final saved = Category.fromJson(data);
      final idx = _categories.indexWhere((c) => c.id == updated.id);
      if (idx >= 0) {
        _categories[idx] = saved;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Delete Category via API
  Future<bool> deleteCategory(String id) async {
    if (_currentUser != null && !_currentUser!.canManageCategories) {
      _error = 'Permission denied: Staff accounts cannot add, edit, or delete categories.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Soft deactivation: set isActive = false
  void deactivateCategory(String id) {
    if (_currentUser != null && !_currentUser!.canManageCategories) {
      _error = 'Permission denied: Staff accounts cannot add, edit, or delete categories.';
      notifyListeners();
      return;
    }

    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _categories[idx] = _categories[idx].copyWith(isActive: false);
      notifyListeners();
    }
  }

  /// Toggle category active status
  void toggleCategoryStatus(String id) {
    if (_currentUser != null && !_currentUser!.canManageCategories) {
      _error = 'Permission denied: Staff accounts cannot add, edit, or delete categories.';
      notifyListeners();
      return;
    }

    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      final current = _categories[idx];
      _categories[idx] = current.copyWith(isActive: !current.isActive);
      notifyListeners();
    }
  }

  /// Generate a simple unique id
  String generateId() => 'cat${DateTime.now().millisecondsSinceEpoch}';
}
