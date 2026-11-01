import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/force_change_password_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/products/products_screen.dart';
import '../../screens/products/product_detail_screen.dart';
import '../../screens/products/add_edit_product_screen.dart';
import '../../screens/stock/stock_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/more/more_screen.dart';
import '../../screens/more/categories_screen.dart';
import '../../screens/more/products_management_screen.dart';
import '../../screens/more/suppliers_screen.dart';
import '../../screens/more/customers_screen.dart';
import '../../screens/more/reports_screen.dart';
import '../../screens/more/profile_screen.dart';
import '../../screens/more/users_screen.dart';
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
      if (isLoggedIn) {
        if (auth.user?.mustChangePassword == true) {
          if (state.matchedLocation != '/force-change-password') {
            return '/force-change-password';
          }
          return null;
        }
        if (onAuthPage || state.matchedLocation == '/force-change-password') {
          return '/dashboard';
        }
      }
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
      GoRoute(
        path: '/force-change-password',
        builder: (_, __) => const ForceChangePasswordScreen(),
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
                redirect: (context, state) {
                  final auth = context.read<AuthProvider>();
                  if (auth.user?.canManageProducts != true) return '/products';
                  return null;
                },
                builder: (_, __) => const AddEditProductScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                parentNavigatorKey: _rootKey,
                redirect: (context, state) {
                  final auth = context.read<AuthProvider>();
                  if (auth.user?.canManageProducts != true) return '/products';
                  return null;
                },
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
            builder: (context, state) {
              final tab = state.uri.queryParameters['tab'];
              final productId = state.uri.queryParameters['productId'];
              final quantityStr = state.uri.queryParameters['quantity'];
              final initialQuantity = int.tryParse(quantityStr ?? '');
              final initialTab = tab == 'out' ? 1 : 0;
              return StockScreen(
                initialTab: initialTab,
                initialProductId: productId,
                initialQuantity: initialQuantity,
              );
            },
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
        path: '/more/history',
        redirect: (_, __) => '/history',
      ),
      GoRoute(
        path: '/more/products',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ProductsManagementScreen(),
      ),
      GoRoute(
        path: '/more/categories',
        parentNavigatorKey: _rootKey,
        redirect: (context, state) {
          final auth = context.read<AuthProvider>();
          if (!auth.isAuthenticated) return '/login';
          if (auth.user?.canViewCategories != true) return '/dashboard';
          return null;
        },
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/more/suppliers',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SuppliersScreen(),
      ),
      GoRoute(
        path: '/more/customers',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CustomersScreen(),
      ),
      GoRoute(
        path: '/more/users',
        parentNavigatorKey: _rootKey,
        redirect: (context, state) {
          final auth = context.read<AuthProvider>();
          if (!auth.isAuthenticated) return '/login';
          if (auth.user?.canManageUsers != true) return '/dashboard';
          return null;
        },
        builder: (_, __) => const UsersScreen(),
      ),
      GoRoute(
        path: '/more/settings',
        parentNavigatorKey: _rootKey,
        redirect: (context, state) {
          final auth = context.read<AuthProvider>();
          if (!auth.isAuthenticated) return '/login';
          if (!auth.user!.isAdmin) return '/dashboard';
          return null;
        },
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
}
