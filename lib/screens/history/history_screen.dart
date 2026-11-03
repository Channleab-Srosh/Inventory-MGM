import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/stock_movement.dart';
import 'widgets/movement_detail_card.dart';
import 'widgets/history_filter_sheet.dart';

class _HistoryUserOption {
  final String id;
  final String name;
  final String roleDisplayName;
  const _HistoryUserOption({
    required this.id,
    required this.name,
    required this.roleDisplayName,
  });
}

/// Stock History Screen with minimalist header and pill filter UI
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  late final ScrollController _scrollCtrl;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stock = context.read<StockProvider>();
      if (stock.allMovements.isEmpty) stock.fetchMovements();
    });
  }

  void _onScroll() {
    if (_scrollCtrl.hasClients &&
        _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<StockProvider>().loadMoreMovements();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    final stock = context.read<StockProvider>();
    final products = context.read<ProductProvider>().allProducts;
    final authUsers = context.read<AuthProvider>().users;

    // Collect distinct users from both AuthProvider and stock movements
    final userMap = <String, _HistoryUserOption>{};
    for (final u in authUsers) {
      userMap[u.id.toString()] = _HistoryUserOption(
        id: u.id.toString(),
        name: u.name,
        roleDisplayName: u.roleDisplayName,
      );
    }
    for (final m in stock.allMovements) {
      if (m.userId.isNotEmpty && !userMap.containsKey(m.userId)) {
        userMap[m.userId] = _HistoryUserOption(
          id: m.userId,
          name: m.userName,
          roleDisplayName: 'User',
        );
      }
    }

    HistoryFilterSheet.show(
      context: context,
      currentType: stock.typeFilter,
      currentStart: stock.startDate,
      currentEnd: stock.endDate,
      currentProduct: stock.productFilter,
      currentUser: stock.userFilter,
      products: products,
      users: userMap.values.toList(),
      onApply: (type, start, end, productId, userId) {
        stock.applyFilters(
          type: type,
          start: start,
          end: end,
          productId: productId,
          userId: userId,
        );
        Navigator.pop(context);
      },
      onClear: () {
        stock.clearFilters();
        _searchCtrl.clear();
        Navigator.pop(context);
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();
    final filtered = stock.filteredMovements;
    final hasActiveFilters = stock.typeFilter != null ||
        stock.startDate != null ||
        stock.endDate != null ||
        stock.productFilter != null ||
        stock.userFilter != null;
    final hasSearch = stock.search.trim().isNotEmpty;
    final isFiltering = hasActiveFilters || hasSearch;

    int totalUnits = 0;
    int stockInUnits = 0;
    int stockOutUnits = 0;
    for (final m in filtered) {
      totalUnits += m.quantity;
      if (m.isStockIn) {
        stockInUnits += m.quantity;
      } else {
        stockOutUnits += m.quantity;
      }
    }
    final netUnits = stockInUnits - stockOutUnits;

    final distinctProductIds = filtered
        .map((m) => m.productId.isNotEmpty ? m.productId : m.productName)
        .where((id) => id.isNotEmpty)
        .toSet();
    final totalItems = distinctProductIds.length;

    String? activeProductName;
    if (stock.productFilter != null) {
      final products = context.read<ProductProvider>().allProducts;
      final matchedProduct = products
          .where((p) => p.id.toString() == stock.productFilter)
          .firstOrNull;
      activeProductName = matchedProduct?.name ??
          filtered.firstOrNull?.productName ??
          'Product #${stock.productFilter}';
    }

    String? activeUserName;
    if (stock.userFilter != null) {
      final authUsers = context.read<AuthProvider>().users;
      final matchedUser = authUsers
          .where((u) => u.id.toString() == stock.userFilter)
          .firstOrNull;
      activeUserName = matchedUser?.name ??
          filtered.firstOrNull?.userName ??
          'User #${stock.userFilter}';
    }

    final activeFilterChips = <Map<String, dynamic>>[];
    if (activeProductName != null) {
      activeFilterChips.add({
        'icon': Icons.inventory_2_outlined,
        'label': 'Item: $activeProductName',
        'onRemove': () => stock.setProductFilter(null),
      });
    }
    if (stock.typeFilter != null) {
      activeFilterChips.add({
        'icon': Icons.swap_vert_rounded,
        'label': stock.typeFilter == MovementType.stockIn ? 'Stock In' : 'Stock Out',
        'onRemove': () => stock.setTypeFilter(null),
      });
    }
    if (activeUserName != null) {
      activeFilterChips.add({
        'icon': Icons.person_outline,
        'label': 'User: $activeUserName',
        'onRemove': () => stock.setUserFilter(null),
      });
    }
    if (stock.startDate != null || stock.endDate != null) {
      final sStr = stock.startDate != null
          ? DateFormat('dd/MM/yy').format(stock.startDate!)
          : 'Start';
      final eStr = stock.endDate != null
          ? DateFormat('dd/MM/yy').format(stock.endDate!)
          : 'End';
      activeFilterChips.add({
        'icon': Icons.calendar_today_outlined,
        'label': '$sStr - $eStr',
        'onRemove': () => stock.setDateRange(null, null),
      });
    }
    if (hasSearch) {
      activeFilterChips.add({
        'icon': Icons.search_rounded,
        'label': '"${stock.search.trim()}"',
        'onRemove': () {
          stock.setSearch('');
          _searchCtrl.clear();
        },
      });
    }

    final grouped = <String, List<StockMovement>>{};
    for (final m in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(m.date);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final hPad = AppResponsive.screenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: AppResponsive.contentMaxWidth(context)),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                  child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
                        ),
                      ),
                    ),
                  const Expanded(
                    child: Text(
                      'Stock History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  // Search circle button
                  GestureDetector(
                    onTap: () => setState(() => _showSearch = !_showSearch),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _showSearch ? AppColors.primaryActive : AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _showSearch
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: _showSearch ? AppColors.primaryDark : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter circle button with badge dot
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      GestureDetector(
                        onTap: () => _showFilterSheet(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: hasActiveFilters ? AppColors.primaryActive : AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: hasActiveFilters
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: hasActiveFilters ? AppColors.primaryDark : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.outOfStockText,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Inline search field
            if (_showSearch) ...[
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: SearchField(
                  controller: _searchCtrl,
                  hint: 'Search product, user, or reference...',
                  onChanged: stock.setSearch,
                ),
              ),
            ],

            // Filter / Search Active Summary Card
            if (isFiltering)
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 2),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Icon + Result Count + Clear Button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryActive,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filtered Results ($totalItems item${totalItems == 1 ? "" : "s"} · ${filtered.length} transaction${filtered.length == 1 ? "" : "s"})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              stock.clearFilters();
                              _searchCtrl.clear();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryActive,
                                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close_rounded, size: 12, color: AppColors.primaryDark),
                                  SizedBox(width: 4),
                                  Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (activeFilterChips.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: activeFilterChips.map((chip) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(chip['icon'] as IconData, size: 11, color: AppColors.secondaryText),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 160),
                                    child: Text(
                                      chip['label'] as String,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: chip['onRemove'] as VoidCallback,
                                    child: const Icon(Icons.close_rounded, size: 12, color: AppColors.secondaryText),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Stats Row 1: Total Items, Total Units
                      Row(
                        children: [
                          Expanded(
                            child: _FilterMetricTile(
                              label: 'Total Items',
                              value: AppUtils.formatNumber(totalItems),
                              color: const Color(0xFF1D4ED8),
                              bgColor: const Color(0xFFEFF6FF),
                              icon: Icons.category_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterMetricTile(
                              label: 'Total Units',
                              value: AppUtils.formatNumber(totalUnits),
                              color: AppColors.primaryDark,
                              bgColor: AppColors.primaryActive,
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stats Row 2: Stock In, Stock Out
                      Row(
                        children: [
                          Expanded(
                            child: _FilterMetricTile(
                              label: 'Stock In',
                              value: '+${AppUtils.formatNumber(stockInUnits)}',
                              color: AppColors.chartIn,
                              bgColor: AppColors.inStockBg,
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _FilterMetricTile(
                              label: 'Stock Out',
                              value: '-${AppUtils.formatNumber(stockOutUnits)}',
                              color: AppColors.chartOut,
                              bgColor: AppColors.outOfStockBg,
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                        ],
                      ),
                      if (stockInUnits > 0 && stockOutUnits > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.secondaryText),
                                  SizedBox(width: 4),
                                  Text(
                                    'Net Stock Change',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${netUnits >= 0 ? "+" : ""}${AppUtils.formatNumber(netUnits)} units',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: netUnits >= 0 ? AppColors.chartIn : AppColors.chartOut,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: stock.isLoading && stock.allMovements.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDark,
                        strokeWidth: 3,
                      ),
                    )
                  : stock.error != null && stock.allMovements.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: AppColors.outOfStockBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.error_outline_rounded,
                                      size: 32,
                                      color: AppColors.outOfStockText,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  stock.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () => stock.fetchMovements(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryActive,
                                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                    ),
                                    child: const Text(
                                      'Retry',
                                      style: TextStyle(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => stock.fetchMovements(),
                          color: AppColors.primaryDark,
                          child: filtered.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 80),
                                    EmptyState(
                                      message: 'No transaction history found',
                                      icon: Icons.history,
                                      subtitle:
                                          'Try adjusting your search terms or filter criteria',
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  controller: _scrollCtrl,
                                  padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 88),
                                  itemCount: sortedKeys.length +
                                      (stock.isLoadingMore ? 1 : 0),
                                  itemBuilder: (_, dayIdx) {
                                    if (dayIdx == sortedKeys.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    }
                                    final key = sortedKeys[dayIdx];
                                    final movements = grouped[key]!;
                                    final date = DateTime.parse(key);
                                    final dayUnits = movements.fold<int>(0, (sum, m) => sum + m.quantity);
                                    final dayItems = movements
                                        .map((m) => m.productId.isNotEmpty ? m.productId : m.productName)
                                        .where((id) => id.isNotEmpty)
                                        .toSet()
                                        .length;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Date header pill
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryActive,
                                                  borderRadius: BorderRadius.circular(
                                                      AppTheme.pillRadius),
                                                ),
                                                child: Text(
                                                  _formatDateHeader(date),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primaryDark,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Divider(
                                                  color: AppColors.border,
                                                  thickness: 1,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '$dayItems item${dayItems == 1 ? "" : "s"} · ${movements.length} record${movements.length > 1 ? "s" : ""} · ${AppUtils.formatNumber(dayUnits)} units',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.secondaryText,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ...movements.map(
                                          (m) => MovementDetailCard(movement: m),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class _FilterMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _FilterMetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
