/// App-wide constants
class AppConstants {
  // App info
  static const appName = 'Inventory Manager';
  static const appVersion = '1.0.0';

  // Default low stock threshold
  static const defaultLowStockThreshold = 10;

  // Currency
  static const defaultCurrency = 'USD';
  static const defaultCurrencySymbol = '\$';

  // Route names (used by go_router)
  static const routeLogin = '/login';
  static const routeDashboard = '/dashboard';
  static const routeProducts = '/products';
  static const routeProductDetail = '/products/:id';
  static const routeAddProduct = '/products/add';
  static const routeStock = '/stock';
  static const routeReports = '/reports';
  static const routeProfile = '/profile';
  static const routeHistory = '/history';
  static const routeMore = '/more';
  static const routeCategories = '/more/categories';
  static const routeSuppliers = '/more/suppliers';
  static const routeSettings = '/more/settings';

  // Mock user
  static const mockEmail = 'admin@inventory.com';
  static const mockPassword = 'password123';
  static const mockUserName = 'Alex Johnson';
  static const mockUserRole = 'Admin';
}
