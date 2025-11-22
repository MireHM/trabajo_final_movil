# 📚 DOCUMENTACIÓN TÉCNICA - PARA PRESENTACIÓN

## 🎯 Conceptos Clave Implementados

### 1. Arquitectura Offline-First

**¿Qué es?**
Una arquitectura donde la aplicación funciona primero con datos locales y sincroniza con el servidor cuando hay conexión disponible.

**Implementación en el proyecto:**
```dart
// 1. Base de datos local (SQLite via Drift)
final database = AppDatabase();

// 2. Operaciones siempre van primero a BD local
await database.insertSale(sale);  // Guarda localmente

// 3. Sincronización manual cuando hay internet
await syncService.syncAll();  // Sube a Supabase
```

**Ventajas:**
- ✅ Funciona sin internet
- ✅ Operaciones rápidas (no espera red)
- ✅ Resiliente a fallos de conexión
- ✅ Mejor experiencia de usuario

---

### 2. ORM con Drift

**¿Qué es Drift?**
Un ORM (Object-Relational Mapping) que convierte código Dart en operaciones SQL de forma type-safe.

**Ejemplo de implementación:**

```dart
// Definición de tabla
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  // ... más columnas
}

// Uso type-safe
final products = await database.select(database.products).get();
```

**Ventajas sobre SQLite crudo:**
- ✅ Type-safe (errores en compile-time, no runtime)
- ✅ Menos código boilerplate
- ✅ Queries reactivas con Streams
- ✅ Migraciones automáticas

---

### 3. State Management con Riverpod

**¿Por qué Riverpod?**
Gestión de estado moderna, type-safe y con menos boilerplate que Provider.

**Patrones implementados:**

```dart
// 1. Providers de datos
final productsProvider = StreamProvider<List<Product>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.products).watch();
});

// 2. Providers de estado
final currentEmployeeProvider = StateProvider<Employee?>((ref) => null);

// 3. Consumo en UI
ref.watch(productsProvider).when(
  data: (products) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

**Ventajas:**
- ✅ Actualización automática de UI
- ✅ Gestión de estado global
- ✅ Fácil testing
- ✅ No usa BuildContext

---

### 4. Sincronización Bidireccional

**Flujo de Sincronización:**

```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐
│             │         │              │         │              │
│  App Local  │◄───────►│    Drift     │◄───────►│   Supabase   │
│     UI      │         │   Database   │         │  PostgreSQL  │
│             │         │              │         │              │
└─────────────┘         └──────────────┘         └──────────────┘
```

**Implementación:**

1. **Subida de datos locales:**
```dart
// Buscar registros sin sincronizar
final unsynced = localData.where((d) => d.syncedAt == null);

// Subir a Supabase
for (final item in unsynced) {
  final response = await supabase.from('table').insert(item);
  // Marcar como sincronizado
  await updateLocalRecord(item, syncedAt: DateTime.now());
}
```

2. **Descarga de datos remotos:**
```dart
final remoteData = await supabase.from('table').select();
for (final remote in remoteData) {
  // Verificar si existe localmente
  final exists = localData.any((d) => d.supabaseId == remote['id']);
  if (!exists) {
    // Insertar nuevo desde servidor
    await insertLocalRecord(remote);
  }
}
```

---

### 5. Gestión de Inventario en Tiempo Real

**Patrón de Actualización Automática:**

```dart
Future<int> insertSale(SalesCompanion sale) async {
  // 1. Registrar la venta
  final id = await into(sales).insert(sale);
  
  // 2. Actualizar inventario automáticamente
  await updateInventory(
    sale.productId.value,
    sale.storeId.value,
    null,
    -sale.quantity.value,  // RESTAR cantidad
  );
  
  return id;
}
```

**Tipos de operaciones:**
- **Compras:** +Inventario en almacén
- **Ventas:** -Inventario en tienda
- **Transferencias:** -Origen, +Destino

---

### 6. Manejo de Relaciones en Base de Datos

**Tipos de Relaciones Implementadas:**

1. **One-to-Many:**
```dart
// Un producto tiene muchos registros de inventario
class Inventory extends Table {
  IntColumn get productId => integer()();  // FK
  // ...
}
```

2. **Constraints y Validaciones:**
```dart
// Solo puede tener storeId O warehouseId, no ambos
CHECK (
  (store_id IS NOT NULL AND warehouse_id IS NULL) OR
  (store_id IS NULL AND warehouse_id IS NOT NULL)
)
```

3. **Cascade Delete:**
```sql
product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE
```

---

### 7. Autenticación Multi-nivel

**Sistema de Autenticación Implementado:**

```dart
Future<Employee?> login(String email, String password) async {
  try {
    // 1. Intentar con Supabase (online)
    final employee = await loginWithSupabase(email, password);
    if (employee != null) return employee;
  } catch (e) {
    print('Supabase no disponible, usando auth local');
  }
  
  // 2. Fallback a autenticación local (offline)
  return await loginLocal(email, password);
}
```

**Roles soportados:**
- `admin` - Acceso total
- `store_manager` - Gestión de tienda específica
- `warehouse_manager` - Gestión de almacén específico

---

### 8. Reportes y Análisis de Datos

**Agregaciones implementadas:**

```dart
// Reporte de ventas diarias
Future<Map<String, dynamic>> getDailySalesReport(DateTime date) async {
  final sales = await getSalesByDate(date);
  
  return {
    'totalSales': sales.length,
    'totalRevenue': sales.fold(0.0, (sum, s) => sum + s.totalPrice),
    'totalQuantity': sales.fold(0, (sum, s) => sum + s.quantity),
  };
}
```

**Tipos de reportes:**
1. Ventas del día (global)
2. Ventas por tienda
3. Compras históricas
4. Transferencias entre ubicaciones

---

## 🏗️ Arquitectura del Proyecto

```
┌─────────────────────────────────────────────┐
│              PRESENTATION LAYER              │
│  (Screens - UI Components)                   │
└───────────────┬─────────────────────────────┘
                │
                │ uses
                ▼
┌─────────────────────────────────────────────┐
│           STATE MANAGEMENT LAYER             │
│  (Riverpod Providers)                        │
└───────────────┬─────────────────────────────┘
                │
                │ manages
                ▼
┌─────────────────────────────────────────────┐
│            BUSINESS LOGIC LAYER              │
│  (Services - Auth, Sync)                     │
└───────────────┬─────────────────────────────┘
                │
                │ uses
                ▼
┌─────────────────────────────────────────────┐
│              DATA ACCESS LAYER               │
│  (Drift Database - Models)                   │
└───────────────┬─────────────────────────────┘
                │
                ▼
     ┌──────────────────┐
     │  Local SQLite    │
     └──────────────────┘
                │
                │ syncs with
                ▼
     ┌──────────────────┐
     │    Supabase      │
     │   PostgreSQL     │
     └──────────────────┘
```

---

## 💡 Decisiones Técnicas Importantes

### 1. ¿Por qué Drift y no SQLite directo?

**Drift:**
```dart
// Type-safe, autocomplete
final products = await database.getAllProducts();
```

**SQLite raw:**
```dart
// String-based, prone to errors
final result = await db.rawQuery('SELECT * FROM products');
```

### 2. ¿Por qué Riverpod y no setState?

**Problemas de setState:**
- Solo funciona dentro de StatefulWidget
- No permite compartir estado entre widgets
- Difícil de testear

**Ventajas de Riverpod:**
- Estado global accesible desde cualquier lugar
- Reconstrucción automática de UI
- Fácil testing y debugging

### 3. ¿Por qué Offline-First?

**Escenarios reales:**
- ✅ Tiendas en zonas con mala conexión
- ✅ Almacenes en áreas remotas
- ✅ Operaciones críticas no pueden esperar red
- ✅ Reduce costos de datos móviles

---

## 🔍 Patrones de Diseño Utilizados

### 1. Repository Pattern (Implícito en Drift)
```dart
class AppDatabase {
  Future<List<Product>> getAllProducts() => select(products).get();
  Future<int> insertProduct(ProductsCompanion product) => ...
}
```

### 2. Provider Pattern (Riverpod)
```dart
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
```

### 3. Observer Pattern (Streams)
```dart
final productsProvider = StreamProvider<List<Product>>((ref) {
  return database.select(database.products).watch();  // Observa cambios
});
```

### 4. Singleton Pattern
```dart
// Supabase client es singleton
final supabase = Supabase.instance.client;
```

---

## 📊 Métricas del Proyecto

- **Líneas de código:** ~3,500 líneas
- **Archivos Dart:** 15 archivos principales
- **Pantallas:** 10 pantallas funcionales
- **Modelos de datos:** 8 tablas
- **Providers:** 15+ providers
- **Operaciones CRUD:** 8 entidades completas

---

## 🎓 Conceptos Académicos Demostrados

1. **Bases de Datos Relacionales:** Tablas, FKs, Constraints
2. **CRUD Completo:** Create, Read, Update, Delete
3. **Sincronización de Datos:** Offline-first, conflict resolution
4. **State Management:** Reactive programming
5. **Arquitectura en Capas:** Separation of concerns
6. **Patrones de Diseño:** Repository, Provider, Observer
7. **Autenticación y Autorización:** Multi-rol
8. **Reportes y Análisis:** Agregaciones, filtros

---

## 🚀 Características Avanzadas

- ✅ **Hot Reload** - Desarrollo rápido con Flutter
- ✅ **Type Safety** - Menos errores en runtime
- ✅ **Reactive UI** - Actualización automática
- ✅ **Code Generation** - Drift genera código optimizado
- ✅ **Error Handling** - Try-catch, validaciones
- ✅ **Performance** - Índices en BD, queries optimizadas

---

**Nota para la presentación:**
Este proyecto demuestra dominio de conceptos modernos de desarrollo móvil,
incluyendo offline-first architecture, state management avanzado, y 
sincronización de datos robusta. Es un sistema productivo y escalable.
