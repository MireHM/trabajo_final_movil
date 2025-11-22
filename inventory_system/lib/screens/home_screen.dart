import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/connectivity_service.dart';
import 'products_screen.dart';
import 'stores_screen.dart';
import 'warehouses_screen.dart';
import 'purchases_screen.dart';
import 'sales_screen.dart';
import 'transfers_screen.dart';
import 'reports_screen.dart';
import 'inventory_screen.dart';
import 'employees_screen.dart';
import 'login_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSyncing = false;
  bool? _previousOnlineState;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios de conectividad para mostrar notificaciones
    Future.microtask(() {
      ref.listen<AsyncValue<bool>>(connectivityStreamProvider, (previous, next) {
        next.whenData((isOnline) {
          if (_previousOnlineState != null && _previousOnlineState != isOnline) {
            // Solo mostrar si hubo un cambio real
            if (mounted) {
              ConnectivitySnackBar.show(context, isOnline);
            }
          }
          _previousOnlineState = isOnline;
        });
      });
    });
  }

  Future<void> _syncData() async {
    final isOnline = ref.read(isOnlineProvider);

    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('No hay conexión a internet para sincronizar'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          action: SnackBarAction(
            label: 'INFO',
            textColor: Colors.white,
            onPressed: () {
              ConnectivityInfoDialog.show(context, false);
            },
          ),
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);
    ref.read(isSyncingProvider.notifier).state = true;

    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncAll();

      ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Sincronización completada'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        ref.read(isSyncingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    ref.read(currentEmployeeProvider.notifier).state = null;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmployee = ref.watch(currentEmployeeProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);
    final connectivityAsync = ref.watch(connectivityStreamProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Inventario'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Indicador de conectividad en el AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  ConnectivityInfoDialog.show(context, isOnline);
                },
                child: ConnectivityIndicator(
                  isOnline: isOnline,
                  showAlways: true,
                ),
              ),
            ),
          ),
          // Botón de sincronización
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.sync,
                color: isOnline ? Colors.white : Colors.white70,
              ),
              onPressed: isOnline ? _syncData : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sin conexión para sincronizar'),
                    backgroundColor: Colors.orange.shade700,
                    action: SnackBarAction(
                      label: 'VER',
                      textColor: Colors.white,
                      onPressed: () {
                        ConnectivityInfoDialog.show(context, false);
                      },
                    ),
                  ),
                );
              },
              tooltip: isOnline ? 'Sincronizar' : 'Sin conexión',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de conectividad (solo se muestra cuando está offline)
          ConnectivityBanner(
            isOnline: isOnline,
            onSyncPressed: _syncData,
          ),

          // Información del usuario
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido, ${currentEmployee?.name ?? "Usuario"}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rol: ${_getRoleName(currentEmployee?.role ?? "")}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (lastSync != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Última sincronización: ${_formatTime(lastSync)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Grid de opciones
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMenuItem(
                  context,
                  'Productos',
                  Icons.inventory_2,
                  Colors.blue,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductsScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'Tiendas',
                  Icons.store,
                  Colors.green,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StoresScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'Almacenes',
                  Icons.warehouse,
                  Colors.orange,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WarehousesScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'Empleados',
                  Icons.people,
                  Colors.indigo,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployeesScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'Inventario',
                  Icons.list_alt,
                  Colors.purple,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'Compras',
                  Icons.shopping_cart,
                  Colors.teal,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PurchasesScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'Ventas',
                  Icons.point_of_sale,
                  Colors.red,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'Transferencias',
                  Icons.swap_horiz,
                  Colors.cyan,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransfersScreen()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'Reportes',
                  Icons.assessment,
                  Colors.pink,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'store_manager':
        return 'Encargado de Tienda';
      case 'warehouse_manager':
        return 'Encargado de Almacén';
      default:
        return role;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}