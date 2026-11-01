import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/customer_provider.dart';
import '../../data/api_service.dart';
import '../../models/dashboard_summary.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/transaction_tile.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/dashboard_summary_grid.dart';
import 'widgets/low_stock_horizontal_list.dart';
import 'widgets/dashboard_stock_chart.dart';

/// Dashboard Screen matching Image 1:
/// - Minimalist header: Avatar + "☼ GOOD MORNING! ^-^" + "Mark 👋" (left), "Chat" pill + notification bell with red badge (right)
/// - 2x2 Bento Metric Grid (Lavender Total Stock Value, White Total Stock, Out of Stock, Low Stock)
/// - Stock Flow Chart Card with multi-layered pastel stacked bars and smooth lavender gradient
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final products = context.read<ProductProvider>();
    final stock = context.read<StockProvider>();
    final categories = context.read<CategoryProvider>();
    final suppliers = context.read<SupplierProvider>();
    final customers = context.read<CustomerProvider>();

    try {
      final summaryJson = await ApiService().getDashboardSummary();
      if (mounted) {
        setState(() {
          _summary = DashboardSummary.fromJson(summaryJson);
        });
      }
    } catch (_) {}

    await Future.wait([
      products.fetchProducts(),
      products.loadLowStock(),
      stock.fetchMovements(),
      categories.fetchCategories(),
      suppliers.fetchSuppliers(),
      customers.fetchCustomers(),
    ]);
  }

  String _getGreetingTag() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☼ GOOD MORNING! ^-^';
    if (hour < 17) return '☼ GOOD AFTERNOON! ^-^';
    return '☽ GOOD EVENING! ^-^';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductProvider>();
    final stock = context.watch<StockProvider>();
    final user = auth.user;
    final userName = user?.firstName?.isNotEmpty == true
        ? user!.firstName!
        : (user != null && user.name.isNotEmpty
            ? user.name.split(' ').first
            : 'User');

    final int alertCount = products.lowStockCount + products.outOfStockCount;

    final isDesktop = AppResponsive.isDesktop(context);
    final isWide = AppResponsive.isTabletOrDesktop(context);
    final hPad = AppResponsive.screenPadding(context);

    // ── Header widget (shared between mobile & wide) ──────────────────────────
    final header = Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryActive,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(
              child: Text(
                user?.initials ?? 'M',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreetingTag(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.secondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('👋', style: TextStyle(fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support chat coming soon')),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x041A1A1A),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Chat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(alertCount > 0
                    ? '$alertCount product(s) currently need attention.'
                    : 'All inventory stock levels are healthy!'),
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x041A1A1A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 20,
                    color: AppColors.text,
                  ),
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.outOfStockText,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      '${alertCount > 0 ? alertCount : 2}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // ── Recent transactions list (shared) ─────────────────────────────────────
    final recentTransactions = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Transactions',
          trailing: TextButton(
            onPressed: () => context.push('/history'),
            child: const Text('View All →'),
          ),
        ),
        const SizedBox(height: 8),
        if (stock.recentMovements.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No recent transactions found',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
          )
        else
          ...stock.recentMovements.take(5).map(
            (m) => TransactionTile(movement: m),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryDark,
          child: isWide
              // ── Tablet / Desktop layout ──────────────────────────────────
              ? SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 10),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: AppResponsive.contentMaxWidth(context)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          header,
                          const SizedBox(height: 22),

                          // Summary grid (4 columns on wide screens)
                          DashboardSummaryGrid(
                            products: products,
                            stock: stock,
                            summary: _summary,
                          ),
                          const SizedBox(height: 22),

                          // Wide Desktop: two-column layout; Tablet/Mobile: single-column full width
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: chart + quick actions + low stock
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      DashboardStockChart(
                                        stockIn: stock.stockInLast7Days,
                                        stockOut: stock.stockOutLast7Days,
                                      ),
                                      const SizedBox(height: 20),
                                      const DashboardQuickActions(),
                                      const SizedBox(height: 20),
                                      LowStockHorizontalList(products: products),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Right: recent transactions
                                Expanded(
                                  flex: 4,
                                  child: recentTransactions,
                                ),
                              ],
                            )
                          else ...[
                            DashboardStockChart(
                              stockIn: stock.stockInLast7Days,
                              stockOut: stock.stockOutLast7Days,
                            ),
                            const SizedBox(height: 20),
                            const DashboardQuickActions(),
                            const SizedBox(height: 20),
                            LowStockHorizontalList(products: products),
                            const SizedBox(height: 20),
                            recentTransactions,
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                )
              // ── Mobile layout (original single-column) ───────────────────
              : ListView(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 10),
                  children: [
                    header,
                    const SizedBox(height: 18),
                    DashboardSummaryGrid(
                      products: products,
                      stock: stock,
                      summary: _summary,
                    ),
                    const SizedBox(height: 18),
                    DashboardStockChart(
                      stockIn: stock.stockInLast7Days,
                      stockOut: stock.stockOutLast7Days,
                    ),
                    const SizedBox(height: 20),
                    const DashboardQuickActions(),
                    const SizedBox(height: 20),
                    LowStockHorizontalList(products: products),
                    const SizedBox(height: 20),
                    recentTransactions,
                    const SizedBox(height: 32),
                  ],
                ),
        ),
      ),
    );
  }
}
