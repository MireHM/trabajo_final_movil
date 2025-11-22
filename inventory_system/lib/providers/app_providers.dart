import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/database.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

// ==================== PROVIDERS BASE ====================

// Provider de la base de datos
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Provider de Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provider del servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  final database = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseProvider);
  return AuthService(database, supabase);
});

// Provider del servicio de sincronización
final syncServiceProvider = Provider<SyncService>((ref) {
  final database = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseProvider);
  return SyncService(database, supabase);
});

// ==================== ESTADO DE AUTENTICACIÓN ====================

// Estado del empleado autenticado
final currentEmployeeProvider = StateProvider<Employee?>((ref) => null);

// Provider para verificar si el usuario está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  final employee = ref.watch(currentEmployeeProvider);
  return employee != null;
});

// ==================== DATOS ====================

// Productos
final productsProvider = StreamProvider<List<Product>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.products).watch();
});

// Tiendas
final storesProvider = StreamProvider<List<Store>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.stores).watch();
});

// Almacenes
final warehousesProvider = StreamProvider<List<Warehouse>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.warehouses).watch();
});

// Empleados
final employeesProvider = StreamProvider<List<Employee>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.employees).watch();
});

// Inventario
final inventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.inventory).watch();
});

// Ventas
final salesProvider = StreamProvider<List<Sale>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.sales).watch();
});

// Compras
final purchasesProvider = StreamProvider<List<Purchase>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.purchases).watch();
});

// Transferencias
final transfersProvider = StreamProvider<List<Transfer>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.transfers).watch();
});

// ==================== PROVIDERS DE DATOS FILTRADOS ====================

// Inventario por tienda
final inventoryByStoreProvider = FutureProvider.family<List<InventoryItem>, int>((ref, storeId) async {
  final database = ref.watch(databaseProvider);
  return database.getInventoryByStore(storeId);
});

// Inventario por almacén
final inventoryByWarehouseProvider = FutureProvider.family<List<InventoryItem>, int>((ref, warehouseId) async {
  final database = ref.watch(databaseProvider);
  return database.getInventoryByWarehouse(warehouseId);
});

// Ventas por tienda
final salesByStoreProvider = FutureProvider.family<List<Sale>, int>((ref, storeId) async {
  final database = ref.watch(databaseProvider);
  return database.getSalesByStore(storeId);
});

// Ventas por fecha
final salesByDateProvider = FutureProvider.family<List<Sale>, DateTime>((ref, date) async {
  final database = ref.watch(databaseProvider);
  return database.getSalesByDate(date);
});

// Reporte de ventas del día
final dailySalesReportProvider = FutureProvider.family<Map<String, dynamic>, DailyReportParams>((ref, params) async {
  final database = ref.watch(databaseProvider);
  return database.getDailySalesReport(params.date, storeId: params.storeId);
});

// ==================== HELPERS ====================

class DailyReportParams {
  final DateTime date;
  final int? storeId;

  DailyReportParams({required this.date, this.storeId});
}

// ==================== SINCRONIZACIÓN ====================

final isSyncingProvider = StateProvider<bool>((ref) => false);

final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);
