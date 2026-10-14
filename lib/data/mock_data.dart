import '../models/product.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/stock_movement.dart';
import '../models/user_profile.dart';

/// Realistic in-memory mock data for the app
class MockData {
  // ---------- Categories ----------
  static final List<Category> categories = [
    Category(id: 'cat1', name: 'Electronics',   color: '#3B82F6', icon: 'devices'),
    Category(id: 'cat2', name: 'Office Supplies', color: '#8B5CF6', icon: 'work'),
    Category(id: 'cat3', name: 'Furniture',      color: '#F59E0B', icon: 'chair'),
    Category(id: 'cat4', name: 'Food & Beverage',color: '#10B981', icon: 'restaurant'),
    Category(id: 'cat5', name: 'Clothing',       color: '#EF4444', icon: 'checkroom'),
    Category(id: 'cat6', name: 'Tools',          color: '#6B7280', icon: 'build'),
  ];

  // ---------- Suppliers ----------
  static final List<Supplier> suppliers = [
    Supplier(
      id: 'sup1', name: 'TechWorld Inc.',
      phone: '+1-555-0101', email: 'orders@techworld.com',
      contactPerson: 'Sarah Chen', address: '123 Tech Ave, Silicon Valley, CA',
    ),
    Supplier(
      id: 'sup2', name: 'Office Depot Pro',
      phone: '+1-555-0202', email: 'supplies@officedepotpro.com',
      contactPerson: 'Mike Johnson', address: '456 Business Blvd, New York, NY',
    ),
    Supplier(
      id: 'sup3', name: 'FreshMart Wholesale',
      phone: '+1-555-0303', email: 'wholesale@freshmart.com',
      contactPerson: 'Lisa Park', address: '789 Market St, Chicago, IL',
    ),
    Supplier(
      id: 'sup4', name: 'FurniCo Ltd.',
      phone: '+1-555-0404', email: 'b2b@furnico.com',
      contactPerson: 'James Brown', address: '321 Wood Lane, Portland, OR',
    ),
    Supplier(
      id: 'sup5', name: 'ToolMaster Supply',
      phone: '+1-555-0505', email: 'sales@toolmaster.com',
      contactPerson: 'Anna White', address: '654 Industrial Rd, Detroit, MI',
    ),
  ];

  // ---------- Products ----------
  static final List<Product> products = [
    Product(
      id: 'p1', name: 'MacBook Pro 14"', sku: 'MBP-14-M3',
      categoryId: 'cat1', supplierId: 'sup1',
      price: 1999.99, quantity: 25, minStockLevel: 5,
      description: 'Apple MacBook Pro with M3 chip, 16GB RAM, 512GB SSD',
    ),
    Product(
      id: 'p2', name: 'Wireless Mouse', sku: 'WM-001-BLK',
      categoryId: 'cat1', supplierId: 'sup1',
      price: 29.99, quantity: 8, minStockLevel: 10,
      description: 'Ergonomic wireless mouse with USB-C receiver',
    ),
    Product(
      id: 'p3', name: 'A4 Paper Ream', sku: 'PAP-A4-500',
      categoryId: 'cat2', supplierId: 'sup2',
      price: 8.99, quantity: 150, minStockLevel: 20,
      description: '500 sheets of 80gsm A4 white paper',
    ),
    Product(
      id: 'p4', name: 'Standing Desk', sku: 'DESK-STAND-01',
      categoryId: 'cat3', supplierId: 'sup4',
      price: 549.00, quantity: 3, minStockLevel: 2,
      description: 'Height-adjustable standing desk, 140x70cm',
    ),
    Product(
      id: 'p5', name: 'USB-C Hub 7-in-1', sku: 'USB-HUB-7C',
      categoryId: 'cat1', supplierId: 'sup1',
      price: 49.99, quantity: 0, minStockLevel: 5,
      description: '7-port USB-C hub with HDMI, SD card, USB-A ports',
    ),
    Product(
      id: 'p6', name: 'Coffee Beans 1kg', sku: 'COFFEE-1KG-ESP',
      categoryId: 'cat4', supplierId: 'sup3',
      price: 24.99, quantity: 42, minStockLevel: 10,
      description: 'Premium Arabica espresso blend, dark roast',
    ),
    Product(
      id: 'p7', name: 'Ballpoint Pens (Box)', sku: 'PEN-BP-12BLK',
      categoryId: 'cat2', supplierId: 'sup2',
      price: 5.99, quantity: 80, minStockLevel: 15,
      description: 'Box of 12 black ballpoint pens',
    ),
    Product(
      id: 'p8', name: 'Ergonomic Chair', sku: 'CHAIR-ERG-BLK',
      categoryId: 'cat3', supplierId: 'sup4',
      price: 399.00, quantity: 7, minStockLevel: 3,
      description: 'Mesh back ergonomic office chair with lumbar support',
    ),
    Product(
      id: 'p9', name: 'Hand Drill Kit', sku: 'DRILL-KIT-20V',
      categoryId: 'cat6', supplierId: 'sup5',
      price: 89.99, quantity: 12, minStockLevel: 5,
      description: '20V cordless hand drill with 25-piece bit set',
    ),
    Product(
      id: 'p10', name: 'Mechanical Keyboard', sku: 'KB-MECH-TKL',
      categoryId: 'cat1', supplierId: 'sup1',
      price: 129.99, quantity: 5, minStockLevel: 8,
      description: 'TKL mechanical keyboard with Cherry MX Brown switches',
    ),
    Product(
      id: 'p11', name: 'Sticky Notes Pack', sku: 'STICKY-3X3-YLW',
      categoryId: 'cat2', supplierId: 'sup2',
      price: 3.49, quantity: 200, minStockLevel: 30,
      description: 'Pack of 12 pads of yellow 3x3 sticky notes',
    ),
    Product(
      id: 'p12', name: 'Water Bottle 1L', sku: 'BTL-1L-STAINL',
      categoryId: 'cat4', supplierId: 'sup3',
      price: 19.99, quantity: 4, minStockLevel: 10,
      description: 'Stainless steel insulated water bottle',
    ),
  ];

  // ---------- Stock Movements ----------
  static List<StockMovement> movements = [
    StockMovement(
      id: 'm1', productId: 'p1', productName: 'MacBook Pro 14"',
      type: MovementType.stockIn, quantity: 10, unitCost: 1800.00,
      supplierId: 'sup1', userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      note: 'Monthly restock',
    ),
    StockMovement(
      id: 'm2', productId: 'p2', productName: 'Wireless Mouse',
      type: MovementType.stockOut, quantity: 3,
      reason: StockOutReason.sale,
      userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      note: 'Customer order #1042',
    ),
    StockMovement(
      id: 'm3', productId: 'p3', productName: 'A4 Paper Ream',
      type: MovementType.stockIn, quantity: 50, unitCost: 7.50,
      supplierId: 'sup2', userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    StockMovement(
      id: 'm4', productId: 'p6', productName: 'Coffee Beans 1kg',
      type: MovementType.stockOut, quantity: 5,
      reason: StockOutReason.sale,
      userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(days: 1)),
      note: 'Break room supply',
    ),
    StockMovement(
      id: 'm5', productId: 'p5', productName: 'USB-C Hub 7-in-1',
      type: MovementType.stockOut, quantity: 2,
      reason: StockOutReason.damaged,
      userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      note: 'Damaged in transit',
    ),
    StockMovement(
      id: 'm6', productId: 'p8', productName: 'Ergonomic Chair',
      type: MovementType.stockIn, quantity: 5, unitCost: 320.00,
      supplierId: 'sup4', userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StockMovement(
      id: 'm7', productId: 'p10', productName: 'Mechanical Keyboard',
      type: MovementType.stockOut, quantity: 1,
      reason: StockOutReason.sale,
      userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
    ),
    StockMovement(
      id: 'm8', productId: 'p9', productName: 'Hand Drill Kit',
      type: MovementType.stockIn, quantity: 8, unitCost: 70.00,
      supplierId: 'sup5', userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    StockMovement(
      id: 'm9', productId: 'p12', productName: 'Water Bottle 1L',
      type: MovementType.stockOut, quantity: 6,
      reason: StockOutReason.sale,
      userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
    ),
    StockMovement(
      id: 'm10', productId: 'p4', productName: 'Standing Desk',
      type: MovementType.stockIn, quantity: 2, unitCost: 420.00,
      supplierId: 'sup4', userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(days: 4)),
    ),
    StockMovement(
      id: 'm11', productId: 'p7', productName: 'Ballpoint Pens (Box)',
      type: MovementType.stockIn, quantity: 30, unitCost: 4.50,
      supplierId: 'sup2', userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    StockMovement(
      id: 'm12', productId: 'p11', productName: 'Sticky Notes Pack',
      type: MovementType.stockOut, quantity: 10,
      reason: StockOutReason.other,
      userId: 'u1', userName: 'Alex Johnson',
      date: DateTime.now().subtract(const Duration(days: 6)),
      note: 'Distributed to teams',
    ),
  ];

  // ---------- User ----------
  static final UserProfile currentUser = UserProfile(
    id: 'u1',
    name: 'Alex Johnson',
    email: 'admin@inventory.com',
    role: 'Admin',
  );

  /// Helper: stock-in totals per day for the last 7 days (for chart)
  static List<double> stockInLast7Days() {
    return _aggregateByDay(MovementType.stockIn);
  }

  /// Helper: stock-out totals per day for the last 7 days (for chart)
  static List<double> stockOutLast7Days() {
    return _aggregateByDay(MovementType.stockOut);
  }

  static List<double> _aggregateByDay(MovementType type) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return movements
          .where((m) =>
              m.type == type &&
              m.date.year == day.year &&
              m.date.month == day.month &&
              m.date.day == day.day)
          .fold<double>(0, (sum, m) => sum + m.quantity);
    });
  }
}
