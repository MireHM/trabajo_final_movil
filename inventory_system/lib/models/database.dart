import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ==================== TABLAS ====================

// Tabla de Empleados
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get password => text()();
  TextColumn get role => text()(); // admin, store_manager, warehouse_manager
  IntColumn get storeId => integer().nullable()();
  IntColumn get warehouseId => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

// Tabla de Tiendas
class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get phone => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

// Tabla de Almacenes
class Warehouses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

// Tabla de Productos
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get category => text()(); // smartphones, laptops, tablets, accessories
  TextColumn get sku => text().unique()();
  RealColumn get price => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

// Tabla de Inventario
class Inventory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().nullable()();
  IntColumn get productId => integer()();
  IntColumn get storeId => integer().nullable()();
  IntColumn get warehouseId => integer().nullable()();
  IntColumn get quantity => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

// Tabla de Compras
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().nullable()();
  IntColumn get productId => integer()();
  IntColumn get warehouseId => integer()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  TextColumn get supplier => text()();
  DateTimeColumn get purchaseDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get employeeId => integer()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

// Tabla de Ventas
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().nullable()();
  IntColumn get productId => integer()();
  IntColumn get storeId => integer()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  DateTimeColumn get saleDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get employeeId => integer()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

// Tabla de Transferencias
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().nullable()();
  IntColumn get productId => integer()();
  IntColumn get fromStoreId => integer().nullable()();
  IntColumn get fromWarehouseId => integer().nullable()();
  IntColumn get toStoreId => integer().nullable()();
  IntColumn get toWarehouseId => integer().nullable()();
  IntColumn get quantity => integer()();
  DateTimeColumn get transferDate => dateTime().withDefault(currentDateAndTime)();
  IntColumn get employeeId => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

// ==================== BASE DE DATOS ====================

@DriftDatabase(tables: [
  Employees,
  Stores,
  Warehouses,
  Products,
  Inventory,
  Purchases,
  Sales,
  Transfers,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ==================== EMPLEADOS ====================
  
  Future<List<Employee>> getAllEmployees() => select(employees).get();
  Future<Employee?> getEmployeeByEmail(String email) =>
      (select(employees)..where((e) => e.email.equals(email))).getSingleOrNull();
  
  Future<int> insertEmployee(EmployeesCompanion employee) =>
      into(employees).insert(employee);
  
  Future<bool> updateEmployee(Employee employee) =>
      update(employees).replace(employee);

  // ==================== TIENDAS ====================
  
  Future<List<Store>> getAllStores() => 
      (select(stores)..where((s) => s.isActive.equals(true))).get();
  
  Future<int> insertStore(StoresCompanion store) =>
      into(stores).insert(store);

  // ==================== ALMACENES ====================
  
  Future<List<Warehouse>> getAllWarehouses() =>
      (select(warehouses)..where((w) => w.isActive.equals(true))).get();
  
  Future<int> insertWarehouse(WarehousesCompanion warehouse) =>
      into(warehouses).insert(warehouse);

  // ==================== PRODUCTOS ====================
  
  Future<List<Product>> getAllProducts() =>
      (select(products)..where((p) => p.isActive.equals(true))).get();
  
  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product);
  
  Future<bool> updateProduct(Product product) =>
      update(products).replace(product);

  // ==================== INVENTARIO ====================
  
  Future<List<InventoryItem>> getInventoryByStore(int storeId) =>
      (select(inventory)..where((i) => i.storeId.equals(storeId))).get();
  
  Future<List<InventoryItem>> getInventoryByWarehouse(int warehouseId) =>
      (select(inventory)..where((i) => i.warehouseId.equals(warehouseId))).get();
  
  Future<List<InventoryItem>> getAllInventory() => select(inventory).get();
  
  Future<InventoryItem?> getInventoryItem(int productId, int? storeId, int? warehouseId) {
    final query = select(inventory)..where((i) => i.productId.equals(productId));
    if (storeId != null) {
      query.where((i) => i.storeId.equals(storeId));
    }
    if (warehouseId != null) {
      query.where((i) => i.warehouseId.equals(warehouseId));
    }
    return query.getSingleOrNull();
  }
  
  Future<void> updateInventory(int productId, int? storeId, int? warehouseId, int quantityChange) async {
    final existing = await getInventoryItem(productId, storeId, warehouseId);
    
    if (existing != null) {
      final newQuantity = existing.quantity + quantityChange;
      await (update(inventory)..where((i) => i.id.equals(existing.id)))
          .write(InventoryCompanion(
        quantity: Value(newQuantity),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      await into(inventory).insert(InventoryCompanion(
        productId: Value(productId),
        storeId: Value(storeId),
        warehouseId: Value(warehouseId),
        quantity: Value(quantityChange),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  // ==================== COMPRAS ====================
  
  Future<List<Purchase>> getAllPurchases() => select(purchases).get();
  
  Future<List<Purchase>> getPurchasesByWarehouse(int warehouseId) =>
      (select(purchases)..where((p) => p.warehouseId.equals(warehouseId))).get();
  
  Future<int> insertPurchase(PurchasesCompanion purchase) async {
    final id = await into(purchases).insert(purchase);
    
    // Actualizar inventario
    await updateInventory(
      purchase.productId.value,
      null,
      purchase.warehouseId.value,
      purchase.quantity.value,
    );
    
    return id;
  }

  // ==================== VENTAS ====================
  
  Future<List<Sale>> getAllSales() => select(sales).get();
  
  Future<List<Sale>> getSalesByStore(int storeId) =>
      (select(sales)..where((s) => s.storeId.equals(storeId))).get();
  
  Future<List<Sale>> getSalesByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    return (select(sales)
          ..where((s) => s.saleDate.isBiggerOrEqualValue(startOfDay))
          ..where((s) => s.saleDate.isSmallerThanValue(endOfDay)))
        .get();
  }
  
  Future<int> insertSale(SalesCompanion sale) async {
    final id = await into(sales).insert(sale);
    
    // Actualizar inventario (restar)
    await updateInventory(
      sale.productId.value,
      sale.storeId.value,
      null,
      -sale.quantity.value,
    );
    
    return id;
  }

  // ==================== TRANSFERENCIAS ====================
  
  Future<List<Transfer>> getAllTransfers() => select(transfers).get();
  
  Future<int> insertTransfer(TransfersCompanion transfer) async {
    final id = await into(transfers).insert(transfer);
    
    // Actualizar inventario origen (restar)
    if (transfer.fromStoreId.value != null) {
      await updateInventory(
        transfer.productId.value,
        transfer.fromStoreId.value,
        null,
        -transfer.quantity.value,
      );
    } else if (transfer.fromWarehouseId.value != null) {
      await updateInventory(
        transfer.productId.value,
        null,
        transfer.fromWarehouseId.value,
        -transfer.quantity.value,
      );
    }
    
    // Actualizar inventario destino (sumar)
    if (transfer.toStoreId.value != null) {
      await updateInventory(
        transfer.productId.value,
        transfer.toStoreId.value,
        null,
        transfer.quantity.value,
      );
    } else if (transfer.toWarehouseId.value != null) {
      await updateInventory(
        transfer.productId.value,
        null,
        transfer.toWarehouseId.value,
        transfer.quantity.value,
      );
    }
    
    return id;
  }

  // ==================== REPORTES ====================
  
  Future<Map<String, dynamic>> getDailySalesReport(DateTime date, {int? storeId}) async {
    final salesList = await getSalesByDate(date);
    final filteredSales = storeId != null
        ? salesList.where((s) => s.storeId == storeId).toList()
        : salesList;
    
    final totalSales = filteredSales.length;
    final totalRevenue = filteredSales.fold<double>(
      0.0,
      (sum, sale) => sum + sale.totalPrice,
    );
    
    return {
      'date': date,
      'storeId': storeId,
      'totalSales': totalSales,
      'totalRevenue': totalRevenue,
      'sales': filteredSales,
    };
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'inventory_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
