import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'models/database.dart';
import 'providers/app_providers.dart';
import 'package:drift/drift.dart' as drift;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    print('✓ Supabase inicializado correctamente');
  } catch (e) {
    print('⚠ Advertencia: No se pudo inicializar Supabase: $e');
    print('⚠ La app funcionará en modo offline únicamente');
  }

  // Inicializar base de datos y datos de prueba
  await _initializeDatabase();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initializeDatabase() async {
  final database = AppDatabase();

  // Verificar si ya hay datos
  final employees = await database.getAllEmployees();

  if (employees.isEmpty) {
    print('⚠ No hay datos. Creando datos de prueba...');
    await _createSampleData(database);
    print('✓ Datos de prueba creados correctamente');
  } else {
    print('✓ Base de datos ya tiene datos (${employees.length} empleados)');
  }
}

Future<void> _createSampleData(AppDatabase database) async {
  // Crear empleado admin
  await database.insertEmployee(EmployeesCompanion(
    name: const drift.Value('Admin User'),
    email: const drift.Value('admin@tienda.com'),
    password: const drift.Value('admin123'),
    role: const drift.Value('admin'),
    isActive: const drift.Value(true),
  ));

  // Crear tiendas
  final store1 = await database.insertStore(StoresCompanion(
    name: const drift.Value('Tienda Centro'),
    address: const drift.Value('Av. Principal 123'),
    phone: const drift.Value('2-2345678'),
    isActive: const drift.Value(true),
  ));

  final store2 = await database.insertStore(StoresCompanion(
    name: const drift.Value('Tienda Norte'),
    address: const drift.Value('Zona Norte, Calle 45'),
    phone: const drift.Value('2-7654321'),
    isActive: const drift.Value(true),
  ));

  // Crear almacenes
  final warehouse1 = await database.insertWarehouse(WarehousesCompanion(
    name: const drift.Value('Almacén Central'),
    address: const drift.Value('Zona Industrial, Mz. 5'),
    isActive: const drift.Value(true),
  ));

  // Crear productos
  final products = [
    {
      'name': 'iPhone 15 Pro',
      'description': 'Smartphone Apple última generación',
      'category': 'smartphones',
      'sku': 'IPH15PRO',
      'price': 1299.99,
    },
    {
      'name': 'Samsung Galaxy S24',
      'description': 'Smartphone Samsung flagship',
      'category': 'smartphones',
      'sku': 'SAMS24',
      'price': 999.99,
    },
    {
      'name': 'MacBook Pro M3',
      'description': 'Laptop Apple con chip M3',
      'category': 'laptops',
      'sku': 'MBPM3',
      'price': 2499.99,
    },
    {
      'name': 'iPad Air',
      'description': 'Tablet Apple iPad Air',
      'category': 'tablets',
      'sku': 'IPADAIR',
      'price': 699.99,
    },
    {
      'name': 'AirPods Pro',
      'description': 'Auriculares inalámbricos Apple',
      'category': 'accessories',
      'sku': 'AIRPODSP',
      'price': 249.99,
    },
  ];

  final productIds = <int>[];
  for (final productData in products) {
    final id = await database.insertProduct(ProductsCompanion(
      name: drift.Value(productData['name'] as String),
      description: drift.Value(productData['description'] as String),
      category: drift.Value(productData['category'] as String),
      sku: drift.Value(productData['sku'] as String),
      price: drift.Value(productData['price'] as double),
      isActive: const drift.Value(true),
    ));
    productIds.add(id);
  }

  // Crear algunas compras de ejemplo
  for (int i = 0; i < productIds.length; i++) {
    await database.insertPurchase(PurchasesCompanion(
      productId: drift.Value(productIds[i]),
      warehouseId: drift.Value(warehouse1),
      quantity: drift.Value(50 + i * 10),
      unitPrice: drift.Value(products[i]['price'] as double),
      totalPrice: drift.Value(
        (products[i]['price'] as double) * (50 + i * 10),
      ),
      supplier: drift.Value('Proveedor ${i + 1}'),
      employeeId: const drift.Value(1),
    ));
  }

  // Crear algunas transferencias
  for (int i = 0; i < 2; i++) {
    await database.insertTransfer(TransfersCompanion(
      productId: drift.Value(productIds[i]),
      fromWarehouseId: drift.Value(warehouse1),
      toStoreId: drift.Value(store1),
      quantity: drift.Value(10 + i * 5),
      employeeId: const drift.Value(1),
      notes: drift.Value('Transferencia inicial a tienda ${i + 1}'),
    ));
  }

  // Crear algunas ventas
  for (int i = 0; i < 3; i++) {
    await database.insertSale(SalesCompanion(
      productId: drift.Value(productIds[i]),
      storeId: drift.Value(store1),
      quantity: drift.Value(2 + i),
      unitPrice: drift.Value(products[i]['price'] as double),
      totalPrice: drift.Value(
        (products[i]['price'] as double) * (2 + i),
      ),
      employeeId: const drift.Value(1),
    ));
  }

  print('✓ Datos de prueba creados:');
  print('  - 1 empleado (admin@tienda.com / admin123)');
  print('  - 2 tiendas');
  print('  - 1 almacén');
  print('  - ${products.length} productos');
  print('  - ${products.length} compras');
  print('  - 2 transferencias');
  print('  - 3 ventas');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Inventario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
