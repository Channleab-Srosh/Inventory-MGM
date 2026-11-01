/// App-wide constants
class AppConstants {
  // App info
  static const appName = 'Inventory Manager';
  static const appVersion = '1.0.0';

  // Backend API Base URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.20.10.10:8080/api/v1',
  );

  static String get defaultBaseUrl => baseUrl;
  static List<String> get candidateBaseUrls => [
    baseUrl,
    'http://localhost:8080/api/v1',
    'http://10.0.2.2:8080/api/v1',
  ];

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
  static const routeCustomers = '/more/customers';
  static const routeUsers = '/more/users';
  static const routeSettings = '/more/settings';

  // Real backend credentials
  static const defaultAdminUsername = 'admin';
  static const defaultAdminPassword = 'Admin@12345';
  static const defaultStaffUsername = 'staff';
  static const defaultStaffPassword = 'Staff@12345';

  // Legacy/Fallback mock credentials
  static const mockEmail = 'admin@inventory.com';
  static const mockPassword = 'password123';
  static const mockUserName = 'System Administrator';
  static const mockUserRole = 'Admin';
}
