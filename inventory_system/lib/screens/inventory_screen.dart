import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/database.dart';
import '../providers/app_providers.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _filterType = 'all'; // all, store, warehouse
  dynamic _selectedLocation;

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final productsAsync = ref.watch(productsProvider);
    final storesAsync = ref.watch(storesProvider);
    final warehousesAsync = ref.watch(warehousesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrar por:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('Todo')),
                          ButtonSegment(value: 'store', label: Text('Tienda')),
                          ButtonSegment(
                              value: 'warehouse', label: Text('Almacén')),
                        ],
                        selected: {_filterType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _filterType = newSelection.first;
                            _selectedLocation = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_filterType == 'store')
                  storesAsync.when(
                    data: (stores) => DropdownButtonFormField<Store>(
                      decoration: const InputDecoration(labelText: 'Seleccionar tienda'),
                      items: stores
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedLocation = value);
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Error: $error'),
                  ),
                if (_filterType == 'warehouse')
                  warehousesAsync.when(
                    data: (warehouses) => DropdownButtonFormField<Warehouse>(
                      decoration:
                          const InputDecoration(labelText: 'Seleccionar almacén'),
                      items: warehouses
                          .map((w) => DropdownMenuItem(
                                value: w,
                                child: Text(w.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedLocation = value);
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Error: $error'),
                  ),
              ],
            ),
          ),
          // Lista de inventario
          Expanded(
            child: inventoryAsync.when(
              data: (inventory) {
                final filteredInventory = _filterInventory(inventory);

                if (filteredInventory.isEmpty) {
                  return const Center(
                    child: Text('No hay inventario para mostrar'),
                  );
                }

                return productsAsync.when(
                  data: (products) => ListView.builder(
                    itemCount: filteredInventory.length,
                    itemBuilder: (context, index) {
                      final item = filteredInventory[index];
                      final product = products.firstWhere(
                        (p) => p.id == item.productId,
                        orElse: () => Product(
                          id: 0,
                          supabaseId: null,
                          name: 'Producto Desconocido',
                          description: '',
                          category: '',
                          sku: '',
                          price: 0,
                          isActive: false,
                          createdAt: DateTime.now(),
                          syncedAt: null,
                        ),
                      );

                      final locationInfo = _getLocationInfo(item);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.quantity > 10
                                ? Colors.green
                                : item.quantity > 0
                                    ? Colors.orange
                                    : Colors.red,
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Text(
                            '$locationInfo\n'
                            'SKU: ${product.sku} | \$${product.price.toStringAsFixed(2)}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  List<InventoryData> _filterInventory(List<InventoryData> inventory) {
    if (_filterType == 'all') {
      return inventory;
    } else if (_filterType == 'store' && _selectedLocation != null) {
      return inventory
          .where((i) => i.storeId == _selectedLocation.id)
          .toList();
    } else if (_filterType == 'warehouse' && _selectedLocation != null) {
      return inventory
          .where((i) => i.warehouseId == _selectedLocation.id)
          .toList();
    }
    return [];
  }

  String _getLocationInfo(InventoryData item) {
    final storesAsync = ref.read(storesProvider);
    final warehousesAsync = ref.read(warehousesProvider);

    if (item.storeId != null) {
      return storesAsync.when(
        data: (stores) {
          final store = stores.firstWhere(
            (s) => s.id == item.storeId,
            orElse: () => Store(
              id: 0,
              supabaseId: null,
              name: 'Tienda Desconocida',
              address: '',
              phone: '',
              isActive: false,
              createdAt: DateTime.now(),
              syncedAt: null,
            ),
          );
          return 'Tienda: ${store.name}';
        },
        loading: () => 'Cargando...',
        error: (_, __) => 'Error',
      );
    } else if (item.warehouseId != null) {
      return warehousesAsync.when(
        data: (warehouses) {
          final warehouse = warehouses.firstWhere(
            (w) => w.id == item.warehouseId,
            orElse: () => Warehouse(
              id: 0,
              supabaseId: null,
              name: 'Almacén Desconocido',
              address: '',
              isActive: false,
              createdAt: DateTime.now(),
              syncedAt: null,
            ),
          );
          return 'Almacén: ${warehouse.name}';
        },
        loading: () => 'Cargando...',
        error: (_, __) => 'Error',
      );
    }
    return 'Sin ubicación';
  }
}
