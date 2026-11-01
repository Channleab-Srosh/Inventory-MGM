import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/settings_provider.dart';

import 'data/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  // Lock to portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (_) => CategoryProvider(),
          update: (_, auth, prev) {
            final cp = prev ?? CategoryProvider();
            cp.updateUser(auth.user);
            if (auth.isAuthenticated && cp.allCategories.isEmpty && !cp.isLoading) {
              cp.fetchCategories();
            } else if (!auth.isAuthenticated && cp.allCategories.isNotEmpty) {
              cp.clear();
            }
            return cp;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, SupplierProvider>(
          create: (_) => SupplierProvider(),
          update: (_, auth, prev) {
            final sp = prev ?? SupplierProvider();
            sp.updateUser(auth.user);
            if (auth.isAuthenticated && sp.allSuppliers.isEmpty && !sp.isLoading) {
              sp.fetchSuppliers();
            } else if (!auth.isAuthenticated && sp.allSuppliers.isNotEmpty) {
              sp.clear();
            }
            return sp;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CustomerProvider>(
          create: (_) => CustomerProvider(),
          update: (_, auth, prev) {
            final cp = prev ?? CustomerProvider();
            cp.updateUser(auth.user);
            if (auth.isAuthenticated && cp.allCustomers.isEmpty && !cp.isLoading) {
              cp.fetchCustomers();
            } else if (!auth.isAuthenticated && cp.allCustomers.isNotEmpty) {
              cp.clear();
            }
            return cp;
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, CategoryProvider, ProductProvider>(
          create: (_) => ProductProvider(),
          update: (_, auth, cat, prev) {
            final pp = prev ?? ProductProvider();
            pp.updateUser(auth.user);
            if (auth.isAuthenticated && pp.allProducts.isEmpty && !pp.isLoading) {
              pp.fetchProducts();
            } else if (!auth.isAuthenticated && pp.allProducts.isNotEmpty) {
              pp.clear();
            }
            return pp;
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, ProductProvider, StockProvider>(
          create: (_) => StockProvider(),
          update: (_, auth, prod, prev) {
            final sp = prev ?? StockProvider();
            sp.updateUser(auth.user);
            if (auth.isAuthenticated && sp.allMovements.isEmpty && !sp.isLoading) {
              sp.fetchMovements();
            } else if (!auth.isAuthenticated && sp.allMovements.isNotEmpty) {
              sp.clear();
            }
            return sp;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'Inventory Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}