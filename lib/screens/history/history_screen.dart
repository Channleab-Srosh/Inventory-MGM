import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/stock_movement.dart';
import 'package:intl/intl.dart';

/// Stock History with search, filter, grouped by date
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    final stock = context.read<StockProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        currentType: stock.typeFilter,
        currentStart: stock.startDate,
        currentEnd: stock.endDate,
        onApply: (type, start, end) {
          stock.setTypeFilter(type);
          stock.setDateRange(start, end);
          Navigator.pop(context);
        },
        onClear: () {
          stock.clearFilters();
          _searchCtrl.clear();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();
    final filtered = stock.filteredMovements;

    // Group by date
    final grouped = <String, List<StockMovement>>{};
    for (final m in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(m.date);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock History'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context),
              ),
              if (stock.typeFilter != null ||
                  stock.startDate != null ||
                  stock.endDate != null)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                      radius: 5, backgroundColor: AppColors.outOfStock),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search by product name...',
              onChanged: stock.setSearch,
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const EmptyState(
              message: 'No movements found',
              icon: Icons.history,
              subtitle: 'Try adjusting your filters',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: sortedKeys.length,
              itemBuilder: (_, dayIdx) {
                final key = sortedKeys[dayIdx];
                final movements = grouped[key]!;
                final date = DateTime.parse(key);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticky-style date header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatDateHeader(date),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                                color: AppColors.grey200, thickness: 1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${movements.length} records',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                    ...movements.map((m) => _MovementTile(movement: m)),
                  ],
                );
              },
            ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class _MovementTile extends StatelessWidget {
  final StockMovement movement;
  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIn = movement.isStockIn;
    final color = isIn ? AppColors.chartIn : AppColors.chartOut;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                  isIn ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movement.productName,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${movement.userName} · ${AppUtils.formatTime(movement.date)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIn ? '+' : '-'}${movement.quantity}',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                Text(
                  isIn ? 'IN' : 'OUT',
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter bottom sheet
class _FilterSheet extends StatefulWidget {
  final MovementType? currentType;
  final DateTime? currentStart;
  final DateTime? currentEnd;
  final Function(MovementType?, DateTime?, DateTime?) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    this.currentType,
    this.currentStart,
    this.currentEnd,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  MovementType? _type;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _type = widget.currentType;
    _start = widget.currentStart;
    _end = widget.currentEnd;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filter Movements', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            Text('Type', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _type == null,
                  onSelected: (_) => setState(() => _type = null),
                ),
                ChoiceChip(
                  label: const Text('Stock In'),
                  selected: _type == MovementType.stockIn,
                  onSelected: (_) =>
                      setState(() => _type = MovementType.stockIn),
                  selectedColor: AppColors.chartIn.withValues(alpha: 0.2),
                ),
                ChoiceChip(
                  label: const Text('Stock Out'),
                  selected: _type == MovementType.stockOut,
                  onSelected: (_) =>
                      setState(() => _type = MovementType.stockOut),
                  selectedColor: AppColors.chartOut.withValues(alpha: 0.2),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text('Date Range', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(_start == null
                        ? 'Start Date'
                        : AppUtils.formatDate(_start!)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _start ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _start = d);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(_end == null
                        ? 'End Date'
                        : AppUtils.formatDate(_end!)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _end ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _end = d);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClear,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onApply(_type, _start, _end),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
