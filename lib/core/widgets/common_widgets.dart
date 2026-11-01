import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

/// A stats summary card matching the Bento aesthetic with generous 24px radius
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isPrimary;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.bentoRadius),
        border: Border.all(
          color: isPrimary ? Colors.transparent : AppColors.border,
          width: 1,
        ),
        boxShadow: isPrimary ? AppColors.lavenderShadow : AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.bentoRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.25)
                            : color.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        icon,
                        color: isPrimary ? Colors.white : color,
                        size: 20,
                      ),
                    ),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.secondaryText,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: isPrimary ? Colors.white : AppColors.text,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Semantic status pill badge: In Stock / Low Stock / Out of Stock
class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final Color? backgroundColor;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.backgroundColor,
  });

  factory StatusChip.inStock() => const StatusChip(
        label: 'In Stock',
        textColor: AppColors.inStockText,
        backgroundColor: AppColors.inStockBg,
      );

  factory StatusChip.lowStock() => const StatusChip(
        label: 'Low Stock',
        textColor: AppColors.lowStockText,
        backgroundColor: AppColors.lowStockBg,
      );

  factory StatusChip.outOfStock() => const StatusChip(
        label: 'Out of Stock',
        textColor: AppColors.outOfStockText,
        backgroundColor: AppColors.outOfStockBg,
      );

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? color ?? AppColors.text;
    final bg = backgroundColor ??
        (color != null
            ? color!.withValues(alpha: 0.12)
            : AppColors.primaryActive);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

/// Search field with pill/rounded aesthetic and clear button
class SearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const SearchField({
    super.key,
    this.hint = 'Search...',
    required this.onChanged,
    this.controller,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x041A1A1A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
          prefixIcon: const Icon(Icons.search,
              size: 20, color: AppColors.secondaryText),
          suffixIcon: ValueListenableBuilder(
            valueListenable: _controller,
            builder: (_, value, __) => value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        size: 18, color: AppColors.secondaryText),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// Generic confirm/alert dialog
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color? confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.confirmColor,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    Color? confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => ConfirmDialog(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            confirmColor: confirmColor ?? AppColors.danger,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.card,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.secondaryText,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondaryText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size(96, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// Empty state with icon and message
class EmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F1F5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Section header with optional trailing widget
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

/// +/- quantity stepper with pill/rounded aesthetic
class QuantityStepper extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 999999,
  });

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()
      ..addListener(() {
        // When user taps away, restore minimum value if left empty or invalid
        if (!_focusNode.hasFocus) {
          final parsed = int.tryParse(_controller.text);
          if (parsed == null || parsed < widget.min) {
            _controller.text = widget.min.toString();
            widget.onChanged(widget.min);
          }
        }
      });
  }

  @override
  void didUpdateWidget(covariant QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync text field when +/- buttons are pressed or form resets _quantity to 1
    if (oldWidget.value != widget.value &&
        _controller.text != widget.value.toString()) {
      _controller.value = TextEditingValue(
        text: widget.value.toString(),
        selection: TextSelection.collapsed(
          offset: widget.value.toString().length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateValue(int newValue) {
    final clamped = newValue.clamp(widget.min, widget.max);
    _controller.text = clamped.toString();
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button (-)
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: widget.value > widget.min
                ? () => _updateValue(widget.value - 1)
                : null,
          ),

          // Direct numeric input field
          SizedBox(
            width: 64,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                if (val.isEmpty) return; // Allow clearing while typing
                final parsed = int.tryParse(val);
                if (parsed != null) {
                  final clamped = parsed.clamp(widget.min, widget.max);
                  widget.onChanged(clamped);
                }
              },
            ),
          ),

          // Increase button (+)
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: widget.value < widget.max
                ? () => _updateValue(widget.value + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
