import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/database.dart';
import 'package:drift/drift.dart' as drift;

class SyncService {
  final AppDatabase database;
  final SupabaseClient supabase;

  SyncService(this.database, this.supabase);

  // ==================== SINCRONIZACIÓN GENERAL ====================

  Future<void> syncAll() async {
    try {
      await syncEmployees();
      await syncStores();
      await syncWarehouses();
      await syncProducts();
      await syncPurchases();
      await syncSales();
      await syncTransfers();
      await syncInventory();
    } catch (e) {
      print('Error en sincronización: $e');
      rethrow;
    }
  }

  // ==================== EMPLEADOS ====================

  Future<void> syncEmployees() async {
    // Subir datos locales no sincronizados
    final localEmployees = await database.getAllEmployees();
    final unsyncedEmployees = localEmployees.where((e) => e.syncedAt == null);

    for (final employee in unsyncedEmployees) {
      try {
        if (employee.supabaseId == null) {
          // Insertar nuevo
          final response = await supabase.from('employees').insert({
            'name': employee.name,
            'email': employee.email,
            'password': employee.password,
            'role': employee.role,
            'store_id': employee.storeId,
            'warehouse_id': employee.warehouseId,
            'is_active': employee.isActive,
          }).select().single();

          // Actualizar con el ID de Supabase
          await database.updateEmployee(employee.copyWith(
            supabaseId: drift.Value(response['id'].toString()),
            syncedAt: drift.Value(DateTime.now()),
          ));
        } else {
          // Actualizar existente
          await supabase.from('employees').update({
            'name': employee.name,
            'email': employee.email,
            'role': employee.role,
            'store_id': employee.storeId,
            'warehouse_id': employee.warehouseId,
            'is_active': employee.isActive,
          }).eq('id', employee.supabaseId!);

          await database.updateEmployee(employee.copyWith(
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      } catch (e) {
        print('Error sincronizando empleado ${employee.id}: $e');
      }
    }

    // Descargar datos desde Supabase
    try {
      final remoteData = await supabase.from('employees').select();
      
      for (final remote in remoteData) {
        final existingEmployee = localEmployees.firstWhere(
          (e) => e.supabaseId == remote['id'].toString(),
          orElse: () => Employee(
            id: 0,
            supabaseId: null,
            name: '',
            email: '',
            password: '',
            role: '',
            storeId: null,
            warehouseId: null,
            isActive: true,
            createdAt: DateTime.now(),
            syncedAt: null,
          ),
        );

        if (existingEmployee.id == 0) {
          // Insertar nuevo desde Supabase
          await database.insertEmployee(EmployeesCompanion(
            supabaseId: drift.Value(remote['id'].toString()),
            name: drift.Value(remote['name']),
            email: drift.Value(remote['email']),
            password: drift.Value(remote['password'] ?? ''),
            role: drift.Value(remote['role']),
            storeId: drift.Value(remote['store_id']),
            warehouseId: drift.Value(remote['warehouse_id']),
            isActive: drift.Value(remote['is_active'] ?? true),
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      }
    } catch (e) {
      print('Error descargando empleados: $e');
    }
  }

  // ==================== TIENDAS ====================

  Future<void> syncStores() async {
    final localStores = await database.getAllStores();
    final unsyncedStores = localStores.where((s) => s.syncedAt == null);

    for (final store in unsyncedStores) {
      try {
        if (store.supabaseId == null) {
          final response = await supabase.from('stores').insert({
            'name': store.name,
            'address': store.address,
            'phone': store.phone,
            'is_active': store.isActive,
          }).select().single();

          await database.update(database.stores).replace(store.copyWith(
            supabaseId: drift.Value(response['id'].toString()),
            syncedAt: drift.Value(DateTime.now()),
          ));
        } else {
          await supabase.from('stores').update({
            'name': store.name,
            'address': store.address,
            'phone': store.phone,
            'is_active': store.isActive,
          }).eq('id', store.supabaseId!);

          await database.update(database.stores).replace(store.copyWith(
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      } catch (e) {
        print('Error sincronizando tienda ${store.id}: $e');
      }
    }

    // Descargar desde Supabase
    try {
      final remoteData = await supabase.from('stores').select();
      
      for (final remote in remoteData) {
        final exists = localStores.any((s) => s.supabaseId == remote['id'].toString());
        
        if (!exists) {
          await database.insertStore(StoresCompanion(
            supabaseId: drift.Value(remote['id'].toString()),
            name: drift.Value(remote['name']),
            address: drift.Value(remote['address']),
            phone: drift.Value(remote['phone']),
            isActive: drift.Value(remote['is_active'] ?? true),
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      }
    } catch (e) {
      print('Error descargando tiendas: $e');
    }
  }

  // ==================== ALMACENES ====================

  Future<void> syncWarehouses() async {
    final localWarehouses = await database.getAllWarehouses();
    final unsyncedWarehouses = localWarehouses.where((w) => w.syncedAt == null);

    for (final warehouse in unsyncedWarehouses) {
      try {
        if (warehouse.supabaseId == null) {
          final response = await supabase.from('warehouses').insert({
            'name': warehouse.name,
            'address': warehouse.address,
            'is_active': warehouse.isActive,
          }).select().single();

          await database.update(database.warehouses).replace(warehouse.copyWith(
            supabaseId: drift.Value(response['id'].toString()),
            syncedAt: drift.Value(DateTime.now()),
          ));
        } else {
          await supabase.from('warehouses').update({
            'name': warehouse.name,
            'address': warehouse.address,
            'is_active': warehouse.isActive,
          }).eq('id', warehouse.supabaseId!);

          await database.update(database.warehouses).replace(warehouse.copyWith(
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      } catch (e) {
        print('Error sincronizando almacén ${warehouse.id}: $e');
      }
    }

    try {
      final remoteData = await supabase.from('warehouses').select();
      
      for (final remote in remoteData) {
        final exists = localWarehouses.any((w) => w.supabaseId == remote['id'].toString());
        
        if (!exists) {
          await database.insertWarehouse(WarehousesCompanion(
            supabaseId: drift.Value(remote['id'].toString()),
            name: drift.Value(remote['name']),
            address: drift.Value(remote['address']),
            isActive: drift.Value(remote['is_active'] ?? true),
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      }
    } catch (e) {
      print('Error descargando almacenes: $e');
    }
  }

  // ==================== PRODUCTOS ====================

  Future<void> syncProducts() async {
    final localProducts = await database.getAllProducts();
    final unsyncedProducts = localProducts.where((p) => p.syncedAt == null);

    for (final product in unsyncedProducts) {
      try {
        if (product.supabaseId == null) {
          final response = await supabase.from('products').insert({
            'name': product.name,
            'description': product.description,
            'category': product.category,
            'sku': product.sku,
            'price': product.price,
            'is_active': product.isActive,
          }).select().single();

          await database.updateProduct(product.copyWith(
            supabaseId: drift.Value(response['id'].toString()),
            syncedAt: drift.Value(DateTime.now()),
          ));
        } else {
          await supabase.from('products').update({
            'name': product.name,
            'description': product.description,
            'category': product.category,
            'sku': product.sku,
            'price': product.price,
            'is_active': product.isActive,
          }).eq('id', product.supabaseId!);

          await database.updateProduct(product.copyWith(
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      } catch (e) {
        print('Error sincronizando producto ${product.id}: $e');
      }
    }

    try {
      final remoteData = await supabase.from('products').select();
      
      for (final remote in remoteData) {
        final exists = localProducts.any((p) => p.supabaseId == remote['id'].toString());
        
        if (!exists) {
          await database.insertProduct(ProductsCompanion(
            supabaseId: drift.Value(remote['id'].toString()),
            name: drift.Value(remote['name']),
            description: drift.Value(remote['description']),
            category: drift.Value(remote['category']),
            sku: drift.Value(remote['sku']),
            price: drift.Value(remote['price'].toDouble()),
            isActive: drift.Value(remote['is_active'] ?? true),
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      }
    } catch (e) {
      print('Error descargando productos: $e');
    }
  }

  // ==================== COMPRAS ====================

  Future<void> syncPurchases() async {
    final localPurchases = await database.getAllPurchases();
    final unsyncedPurchases = localPurchases.where((p) => p.syncedAt == null);

    for (final purchase in unsyncedPurchases) {
      try {
        if (purchase.supabaseId == null) {
          final response = await supabase.from('purchases').insert({
            'product_id': purchase.productId,
            'warehouse_id': purchase.warehouseId,
            'quantity': purchase.quantity,
            'unit_price': purchase.unitPrice,
            'total_price': purchase.totalPrice,
            'supplier': purchase.supplier,
            'purchase_date': purchase.purchaseDate.toIso8601String(),
            'employee_id': purchase.employeeId,
          }).select().single();

          await database.update(database.purchases).replace(purchase.copyWith(
            supabaseId: drift.Value(response['id'].toString()),
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      } catch (e) {
        print('Error sincronizando compra ${purchase.id}: $e');
      }
    }
  }

  // ==================== VENTAS ====================

  Future<void> syncSales() async {
    final localSales = await database.getAllSales();
    final unsyncedSales = localSales.where((s) => s.syncedAt == null);

    for (final sale in unsyncedSales) {
      try {
        if (sale.supabaseId == null) {
          final response = await supabase.from('sales').insert({
            'product_id': sale.productId,
            'store_id': sale.storeId,
            'quantity': sale.quantity,
            'unit_price': sale.unitPrice,
            'total_price': sale.totalPrice,
            'sale_date': sale.saleDate.toIso8601String(),
            'employee_id': sale.employeeId,
          }).select().single();

          await database.update(database.sales).replace(sale.copyWith(
            supabaseId: drift.Value(response['id'].toString()),
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      } catch (e) {
        print('Error sincronizando venta ${sale.id}: $e');
      }
    }
  }

  // ==================== TRANSFERENCIAS ====================

  Future<void> syncTransfers() async {
    final localTransfers = await database.getAllTransfers();
    final unsyncedTransfers = localTransfers.where((t) => t.syncedAt == null);

    for (final transfer in unsyncedTransfers) {
      try {
        if (transfer.supabaseId == null) {
          final response = await supabase.from('transfers').insert({
            'product_id': transfer.productId,
            'from_store_id': transfer.fromStoreId,
            'from_warehouse_id': transfer.fromWarehouseId,
            'to_store_id': transfer.toStoreId,
            'to_warehouse_id': transfer.toWarehouseId,
            'quantity': transfer.quantity,
            'transfer_date': transfer.transferDate.toIso8601String(),
            'employee_id': transfer.employeeId,
            'notes': transfer.notes,
          }).select().single();

          await database.update(database.transfers).replace(transfer.copyWith(
            supabaseId: drift.Value(response['id'].toString()),
            syncedAt: drift.Value(DateTime.now()),
          ));
        }
      } catch (e) {
        print('Error sincronizando transferencia ${transfer.id}: $e');
      }
    }
  }

  // ==================== INVENTARIO ====================

  Future<void> syncInventory() async {
    // El inventario se calcula desde las transacciones, no se sincroniza directamente
    print('Inventario sincronizado indirectamente vía transacciones');
  }
}
