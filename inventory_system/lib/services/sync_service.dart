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
      print('🔄 Iniciando sincronización...');

      // Primero sincronizar datos maestros (sin dependencias)
      await syncStores();
      await syncWarehouses();
      await syncProducts();

      // Luego empleados (necesita tiendas/almacenes)
      await syncEmployees();

      // Finalmente transacciones (necesita todo lo anterior)
      await syncPurchases();
      await syncSales();
      await syncTransfers();

      print('✅ Sincronización completada exitosamente');
    } catch (e) {
      print('❌ Error en sincronización: $e');
      rethrow;
    }
  }

  // ==================== EMPLEADOS ====================

  Future<void> syncEmployees() async {
    try {
      print('📤 Sincronizando empleados...');
      final localEmployees = await database.getAllEmployees();
      final unsyncedEmployees = localEmployees.where((e) => e.syncedAt == null);

      for (final employee in unsyncedEmployees) {
        try {
          if (employee.supabaseId == null) {
            // Obtener UUIDs de tienda y almacén si están asignados
            String? storeSupabaseId;
            String? warehouseSupabaseId;

            if (employee.storeId != null) {
              final stores = await database.getAllStores();
              final store = stores.firstWhere(
                    (s) => s.id == employee.storeId,
                orElse: () => Store(
                  id: 0,
                  supabaseId: null,
                  name: '',
                  address: '',
                  phone: '',
                  isActive: false,
                  createdAt: DateTime.now(),
                  syncedAt: null,
                ),
              );
              if (store.id != 0 && store.supabaseId != null) {
                storeSupabaseId = store.supabaseId;
              } else {
                print('  ⚠ Tienda local ${employee.storeId} no tiene supabaseId, asignando null');
              }
            }

            if (employee.warehouseId != null) {
              final warehouses = await database.getAllWarehouses();
              final warehouse = warehouses.firstWhere(
                    (w) => w.id == employee.warehouseId,
                orElse: () => Warehouse(
                  id: 0,
                  supabaseId: null,
                  name: '',
                  address: '',
                  isActive: false,
                  createdAt: DateTime.now(),
                  syncedAt: null,
                ),
              );
              if (warehouse.id != 0 && warehouse.supabaseId != null) {
                warehouseSupabaseId = warehouse.supabaseId;
              } else {
                print('  ⚠ Almacén local ${employee.warehouseId} no tiene supabaseId, asignando null');
              }
            }

            // Insertar nuevo empleado con UUIDs correctos
            final response = await supabase.from('employees').insert({
              'name': employee.name,
              'email': employee.email,
              'password': employee.password,
              'role': employee.role,
              'store_id': storeSupabaseId,  // UUID o null
              'warehouse_id': warehouseSupabaseId,  // UUID o null
              'is_active': employee.isActive,
            }).select().single();

            await database.updateEmployee(employee.copyWith(
              supabaseId: drift.Value(response['id'].toString()),
              syncedAt: drift.Value(DateTime.now()),
            ));
            print('  ✓ Empleado ${employee.name} sincronizado');
          }
        } catch (e) {
          print('  ⚠ Error sincronizando empleado ${employee.id}: $e');
        }
      }

      // Descargar desde Supabase
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
            // Buscar IDs locales de tienda/almacén si existen
            int? localStoreId;
            int? localWarehouseId;

            if (remote['store_id'] != null) {
              final stores = await database.getAllStores();
              final store = stores.firstWhere(
                    (s) => s.supabaseId == remote['store_id'].toString(),
                orElse: () => Store(
                  id: 0,
                  supabaseId: null,
                  name: '',
                  address: '',
                  phone: '',
                  isActive: false,
                  createdAt: DateTime.now(),
                  syncedAt: null,
                ),
              );
              if (store.id != 0) localStoreId = store.id;
            }

            if (remote['warehouse_id'] != null) {
              final warehouses = await database.getAllWarehouses();
              final warehouse = warehouses.firstWhere(
                    (w) => w.supabaseId == remote['warehouse_id'].toString(),
                orElse: () => Warehouse(
                  id: 0,
                  supabaseId: null,
                  name: '',
                  address: '',
                  isActive: false,
                  createdAt: DateTime.now(),
                  syncedAt: null,
                ),
              );
              if (warehouse.id != 0) localWarehouseId = warehouse.id;
            }

            await database.insertEmployee(EmployeesCompanion(
              supabaseId: drift.Value(remote['id'].toString()),
              name: drift.Value(remote['name']),
              email: drift.Value(remote['email']),
              password: drift.Value(remote['password'] ?? ''),
              role: drift.Value(remote['role']),
              storeId: drift.Value(localStoreId),
              warehouseId: drift.Value(localWarehouseId),
              isActive: drift.Value(remote['is_active'] ?? true),
              syncedAt: drift.Value(DateTime.now()),
            ));
            print('  ✓ Empleado ${remote['name']} descargado desde Supabase');
          }
        }
      } catch (e) {
        print('  ⚠ Error descargando empleados: $e');
      }
    } catch (e) {
      print('  ❌ Error en sincronización de empleados: $e');
    }
  }

  // ==================== TIENDAS ====================

  Future<void> syncStores() async {
    try {
      print('📤 Sincronizando tiendas...');
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
            print('  ✓ Tienda ${store.name} sincronizada');
          }
        } catch (e) {
          print('  ⚠ Error sincronizando tienda ${store.id}: $e');
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
            print('  ✓ Tienda ${remote['name']} descargada desde Supabase');
          }
        }
      } catch (e) {
        print('  ⚠ Error descargando tiendas: $e');
      }
    } catch (e) {
      print('  ❌ Error en sincronización de tiendas: $e');
    }
  }

  // ==================== ALMACENES ====================

  Future<void> syncWarehouses() async {
    try {
      print('📤 Sincronizando almacenes...');
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
            print('  ✓ Almacén ${warehouse.name} sincronizado');
          }
        } catch (e) {
          print('  ⚠ Error sincronizando almacén ${warehouse.id}: $e');
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
            print('  ✓ Almacén ${remote['name']} descargado desde Supabase');
          }
        }
      } catch (e) {
        print('  ⚠ Error descargando almacenes: $e');
      }
    } catch (e) {
      print('  ❌ Error en sincronización de almacenes: $e');
    }
  }

  // ==================== PRODUCTOS ====================

  Future<void> syncProducts() async {
    try {
      print('📤 Sincronizando productos...');
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
            print('  ✓ Producto ${product.name} sincronizado');
          }
        } catch (e) {
          print('  ⚠ Error sincronizando producto ${product.id}: $e');
        }
      }

      try {
        final remoteData = await supabase.from('products').select();

        for (final remote in remoteData) {
          final exists = localProducts.any((p) => p.supabaseId == remote['id'].toString());

          if (!exists) {
            final existsBySku = localProducts.any((p) => p.sku == remote['sku']);
            if (existsBySku) {
              print('  ⚠ Producto con SKU ${remote['sku']} ya existe localmente');
              continue;
            }

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
            print('  ✓ Producto ${remote['name']} descargado desde Supabase');
          }
        }
      } catch (e) {
        print('  ⚠ Error descargando productos: $e');
      }
    } catch (e) {
      print('  ❌ Error en sincronización de productos: $e');
    }
  }

  // ==================== COMPRAS ====================

  Future<void> syncPurchases() async {
    try {
      print('📤 Sincronizando compras...');
      final localPurchases = await database.getAllPurchases();
      final unsyncedPurchases = localPurchases.where((p) => p.syncedAt == null);

      for (final purchase in unsyncedPurchases) {
        try {
          if (purchase.supabaseId == null) {
            final products = await database.getAllProducts();
            final product = products.firstWhere((p) => p.id == purchase.productId);

            if (product.supabaseId == null) {
              print('  ⚠ Producto local ${purchase.productId} no tiene supabaseId, saltando compra');
              continue;
            }

            final warehouses = await database.getAllWarehouses();
            final warehouse = warehouses.firstWhere((w) => w.id == purchase.warehouseId);

            if (warehouse.supabaseId == null) {
              print('  ⚠ Almacén local ${purchase.warehouseId} no tiene supabaseId, saltando compra');
              continue;
            }

            final response = await supabase.from('purchases').insert({
              'product_id': product.supabaseId,
              'warehouse_id': warehouse.supabaseId,
              'quantity': purchase.quantity,
              'unit_price': purchase.unitPrice,
              'total_price': purchase.totalPrice,
              'supplier': purchase.supplier,
              'purchase_date': purchase.purchaseDate.toIso8601String(),
              'employee_id': '1',
            }).select().single();

            await database.update(database.purchases).replace(purchase.copyWith(
              supabaseId: drift.Value(response['id'].toString()),
              syncedAt: drift.Value(DateTime.now()),
            ));
            print('  ✓ Compra sincronizada');
          }
        } catch (e) {
          print('  ⚠ Error sincronizando compra ${purchase.id}: $e');
        }
      }
    } catch (e) {
      print('  ❌ Error en sincronización de compras: $e');
    }
  }

  // ==================== VENTAS ====================

  Future<void> syncSales() async {
    try {
      print('📤 Sincronizando ventas...');
      final localSales = await database.getAllSales();
      final unsyncedSales = localSales.where((s) => s.syncedAt == null);

      for (final sale in unsyncedSales) {
        try {
          if (sale.supabaseId == null) {
            final products = await database.getAllProducts();
            final product = products.firstWhere((p) => p.id == sale.productId);

            if (product.supabaseId == null) {
              print('  ⚠ Producto local ${sale.productId} no tiene supabaseId, saltando venta');
              continue;
            }

            final stores = await database.getAllStores();
            final store = stores.firstWhere((s) => s.id == sale.storeId);

            if (store.supabaseId == null) {
              print('  ⚠ Tienda local ${sale.storeId} no tiene supabaseId, saltando venta');
              continue;
            }

            final response = await supabase.from('sales').insert({
              'product_id': product.supabaseId,
              'store_id': store.supabaseId,
              'quantity': sale.quantity,
              'unit_price': sale.unitPrice,
              'total_price': sale.totalPrice,
              'sale_date': sale.saleDate.toIso8601String(),
              'employee_id': '1',
            }).select().single();

            await database.update(database.sales).replace(sale.copyWith(
              supabaseId: drift.Value(response['id'].toString()),
              syncedAt: drift.Value(DateTime.now()),
            ));
            print('  ✓ Venta sincronizada');
          }
        } catch (e) {
          print('  ⚠ Error sincronizando venta ${sale.id}: $e');
        }
      }
    } catch (e) {
      print('  ❌ Error en sincronización de ventas: $e');
    }
  }

  // ==================== TRANSFERENCIAS ====================

  Future<void> syncTransfers() async {
    try {
      print('📤 Sincronizando transferencias...');
      final localTransfers = await database.getAllTransfers();
      final unsyncedTransfers = localTransfers.where((t) => t.syncedAt == null);

      for (final transfer in unsyncedTransfers) {
        try {
          if (transfer.supabaseId == null) {
            final products = await database.getAllProducts();
            final product = products.firstWhere((p) => p.id == transfer.productId);

            if (product.supabaseId == null) {
              print('  ⚠ Producto local ${transfer.productId} no tiene supabaseId, saltando transferencia');
              continue;
            }

            final response = await supabase.from('transfers').insert({
              'product_id': product.supabaseId,
              'from_store_id': null,
              'from_warehouse_id': null,
              'to_store_id': null,
              'to_warehouse_id': null,
              'quantity': transfer.quantity,
              'transfer_date': transfer.transferDate.toIso8601String(),
              'employee_id': '1',
              'notes': transfer.notes,
            }).select().single();

            await database.update(database.transfers).replace(transfer.copyWith(
              supabaseId: drift.Value(response['id'].toString()),
              syncedAt: drift.Value(DateTime.now()),
            ));
            print('  ✓ Transferencia sincronizada');
          }
        } catch (e) {
          print('  ⚠ Error sincronizando transferencia ${transfer.id}: $e');
        }
      }
    } catch (e) {
      print('  ❌ Error en sincronización de transferencias: $e');
    }
  }

  // ==================== INVENTARIO ====================

  Future<void> syncInventory() async {
    print('📦 Inventario sincronizado indirectamente vía transacciones');
  }
}