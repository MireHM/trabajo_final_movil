import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../models/database.dart';
import '../providers/app_providers.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesProvider);
    final productsAsync = ref.watch(productsProvider);
    final storesAsync = ref.watch(storesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: salesAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const Center(child: Text('No hay ventas registradas'));
          }

          return productsAsync.when(
            data: (products) => storesAsync.when(
              data: (stores) => ListView.builder(
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  final product = products.firstWhere(
                    (p) => p.id == sale.productId,
                    orElse: () => Product(
                      id: 0,
                      supabaseId: null,
                      name: 'Desconocido',
                      description: '',
                      category: '',
                      sku: '',
                      price: 0,
                      isActive: false,
                      createdAt: DateTime.now(),
                      syncedAt: null,
                    ),
                  );
                  final store = stores.firstWhere(
                    (s) => s.id == sale.storeId,
                    orElse: () => Store(
                      id: 0,
                      supabaseId: null,
                      name: 'Desconocida',
                      address: '',
                      phone: '',
                      isActive: false,
                      createdAt: DateTime.now(),
                      syncedAt: null,
                    ),
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade700,
                        child: const Icon(Icons.point_of_sale, color: Colors.white),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        'Tienda: ${store.name}\n'
                        'Cantidad: ${sale.quantity} | Total: \$${sale.totalPrice.toStringAsFixed(2)}\n'
                        '${DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate)}',
                      ),
                      isThreeLine: true,
                      trailing: Icon(
                        sale.syncedAt != null ? Icons.cloud_done : Icons.cloud_off,
                        color: sale.syncedAt != null ? Colors.green : Colors.orange,
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSaleDialog(context, ref),
        backgroundColor: Colors.red.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showSaleDialog(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.read(productsProvider);
    final storesAsync = ref.read(storesProvider);
    final currentEmployee = ref.read(currentEmployeeProvider);

    productsAsync.whenData((products) {
      storesAsync.whenData((stores) {
        if (products.isEmpty || stores.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debe haber productos y tiendas registrados'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        Product? selectedProduct;
        Store? selectedStore;
        final quantityController = TextEditingController();

        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Nueva Venta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Product>(
                      decoration: const InputDecoration(labelText: 'Producto'),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedProduct = value);
                      },
                    ),
                    DropdownButtonFormField<Store>(
                      decoration: const InputDecoration(labelText: 'Tienda'),
                      items: stores
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedStore = value);
                      },
                    ),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                      keyboardType: TextInputType.number,
                    ),
                    if (selectedProduct != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Precio unitario: \$${selectedProduct!.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedProduct == null ||
                        selectedStore == null ||
                        quantityController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete todos los campos'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final quantity = int.parse(quantityController.text);
                    final totalPrice = selectedProduct!.price * quantity;

                    final database = ref.read(databaseProvider);
                    await database.insertSale(SalesCompanion(
                      productId: drift.Value(selectedProduct!.id),
                      storeId: drift.Value(selectedStore!.id),
                      quantity: drift.Value(quantity),
                      unitPrice: drift.Value(selectedProduct!.price),
                      totalPrice: drift.Value(totalPrice),
                      employeeId: drift.Value(currentEmployee?.id ?? 1),
                    ));

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Venta registrada correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
        );
      });
    });
  }
}
