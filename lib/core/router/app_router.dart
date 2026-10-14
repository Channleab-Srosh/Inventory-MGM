import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/products/products_screen.dart';
import '../../screens/products/product_detail_screen.dart';
import '../../screens/products/add_edit_product_screen.dart';
import '../../screens/stock/stock_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/more/more_screen.dart';
import '../../screens/more/categories_screen.dart';
import '../../screens/more/suppliers_screen.dart';
import '../../screens/more/reports_screen.dart';
import '../../screens/more/profile_screen.dart';
import '../../screens/more/settings_screen.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();
  static final _shellKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final isLoggedIn = auth.isAuthenticated;
      final onAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!isLoggedIn && !onAuthPage) return '/login';
      if (isLoggedIn && onAuthPage) return '/dashboard';
      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // Shell with bottom nav
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (_, __) => const ProductsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootKey,
                builder: (_, __) => const AddEditProductScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                parentNavigatorKey: _rootKey,
                builder: (_, state) => AddEditProductScreen(
                  productId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, state) => ProductDetailScreen(
                  productId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/stock',
            builder: (_, __) => const StockScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (_, __) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (_, __) => const MoreScreen(),
          ),
        ],
      ),

      // Route aliases & sub-screens
      GoRoute(
        path: '/more/reports',
        redirect: (_, __) => '/reports',
      ),
      GoRoute(
        path: '/more/profile',
        redirect: (_, __) => '/profile',
      ),
      GoRoute(
        path: '/more/categories',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/more/suppliers',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SuppliersScreen(),
      ),
      GoRoute(
        path: '/more/settings',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
}
