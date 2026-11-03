import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management/models/stock_movement.dart';
import 'package:inventory_management/screens/history/widgets/movement_detail_card.dart';

void main() {
  group('StockMovement Unit Cost parsing', () {
    test('parses unitCost directly from json field', () {
      final json = {
        'id': '101',
        'productId': '1',
        'productName': 'Test Widget',
        'transactionType': 'STOCK_IN',
        'quantity': 5,
        'unitOfMeasure': 'PCS',
        'unitCost': 14.75,
        'quantityBefore': 10,
        'quantityAfter': 15,
        'supplierId': '2',
        'supplierName': 'Acme Corp',
        'createdByUsername': 'admin',
        'createdAt': '2026-11-02T10:00:00Z',
      };

      final movement = StockMovement.fromJson(json);
      expect(movement.unitCost, 14.75);
      expect(movement.isStockIn, isTrue);
      expect(movement.displayNote, isNull);
    });

    test('extracts unitCost fallback from note and provides clean displayNote', () {
      final json = {
        'id': '102',
        'productId': '1',
        'productName': 'Test Widget',
        'transactionType': 'STOCK_IN',
        'quantity': 10,
        'note': 'Ref: PO-9988 - Unit Cost: \$22.50 - Quality check passed',
        'createdByUsername': 'admin',
        'createdAt': '2026-11-02T10:00:00Z',
      };

      final movement = StockMovement.fromJson(json);
      expect(movement.unitCost, 22.50);
      expect(movement.displayNote, 'Ref: PO-9988 - Quality check passed');
    });

    test('handles note with only Unit Cost tag', () {
      final json = {
        'id': '103',
        'productId': '1',
        'productName': 'Test Widget',
        'transactionType': 'STOCK_IN',
        'quantity': 3,
        'note': 'Unit Cost: \$50.00',
        'createdByUsername': 'admin',
        'createdAt': '2026-11-02T10:00:00Z',
      };

      final movement = StockMovement.fromJson(json);
      expect(movement.unitCost, 50.0);
      expect(movement.displayNote, isNull);
    });

    test('leaves unitCost null when not input', () {
      final json = {
        'id': '104',
        'productId': '1',
        'productName': 'Test Widget',
        'transactionType': 'STOCK_IN',
        'quantity': 2,
        'note': 'Standard stock arrival',
        'createdByUsername': 'admin',
        'createdAt': '2026-11-02T10:00:00Z',
      };

      final movement = StockMovement.fromJson(json);
      expect(movement.unitCost, isNull);
      expect(movement.displayNote, 'Standard stock arrival');
    });
  });

  group('MovementDetailCard Unit Cost UI Tests', () {
    testWidgets('displays Unit Cost and Total Cost in txn detail sheet when stock in has unit cost',
        (WidgetTester tester) async {
      final movement = StockMovement(
        id: '1',
        productId: '10',
        productName: 'Gaming Mouse',
        type: MovementType.stockIn,
        quantity: 5,
        unit: 'pcs',
        stockBefore: 10,
        stockAfter: 15,
        unitCost: 25.00,
        supplierName: 'Logitech Dist',
        userId: '1',
        userName: 'staff1',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovementDetailCard(movement: movement),
          ),
        ),
      );

      // Card body shows unit cost
      expect(find.textContaining('Unit Cost:'), findsOneWidget);
      expect(find.textContaining('\$25.00'), findsOneWidget);

      // Tap card to open txn detail sheet
      await tester.tap(find.byType(MovementDetailCard));
      await tester.pumpAndSettle();

      // Transaction detail sheet displays Unit Cost and Total Cost rows
      expect(find.text('Unit Cost'), findsOneWidget);
      expect(find.text('Total Cost'), findsOneWidget);
      expect(find.text('\$25.00'), findsWidgets);
      expect(find.text('\$125.00'), findsOneWidget); // 5 * 25.00
    });

    testWidgets('does not display Unit Cost in txn detail when stock in does not have unit cost',
        (WidgetTester tester) async {
      final movement = StockMovement(
        id: '2',
        productId: '10',
        productName: 'Gaming Mouse',
        type: MovementType.stockIn,
        quantity: 5,
        unit: 'pcs',
        stockBefore: 10,
        stockAfter: 15,
        unitCost: null, // No unit cost
        supplierName: 'Logitech Dist',
        userId: '1',
        userName: 'staff1',
        date: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovementDetailCard(movement: movement),
          ),
        ),
      );

      // Card body does not show unit cost
      expect(find.textContaining('Unit Cost:'), findsNothing);

      // Tap card to open txn detail sheet
      await tester.tap(find.byType(MovementDetailCard));
      await tester.pumpAndSettle();

      // Transaction detail sheet does not show Unit Cost or Total Cost
      expect(find.text('Unit Cost'), findsNothing);
      expect(find.text('Total Cost'), findsNothing);
    });
  });
}
