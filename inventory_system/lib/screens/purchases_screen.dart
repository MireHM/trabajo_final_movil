import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../models/database.dart';
import '../providers/app_providers.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: purchasesAsync.when(
        data: (purchases) {
          if (purchases.isEmpty) {
            return const Center(child: Text('No hay compras registradas'));
          }

          return ListView.builder(
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade700,
                    child: const Icon(Icons.shopping_cart, color: Colors.white),
                  ),
                  title: Text(purchase.supplier),
                  subtitle: Text(
                    'Cantidad: ${purchase.quantity} | Total: \$${purchase.totalPrice.toStringAsFixed(2)}\n'
                    '${DateFormat('dd/MM/yyyy HH:mm').format(purchase.purchaseDate)}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPurchaseDialog(context, ref),
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.read(productsProvider);
    final warehousesAsync = ref.read(warehousesProvider);
    final currentEmployee = ref.read(currentEmployeeProvider);

    productsAsync.whenData((products) {
      warehousesAsync.whenData((warehouses) {
        if (products.isEmpty || warehouses.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debe haber productos y almacenes registrados'),
            ),
          );
          return;
        }

        Product? selectedProduct;
        Warehouse? selectedWarehouse;
        final quantityController = TextEditingController();
        final supplierController = TextEditingController();

        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Nueva Compra'),
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
                    DropdownButtonFormField<Warehouse>(
                      decoration: const InputDecoration(labelText: 'Almacén'),
                      items: warehouses
                          .map((w) => DropdownMenuItem(
                                value: w,
                                child: Text(w.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedWarehouse = value);
                      },
                    ),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: supplierController,
                      decoration: const InputDecoration(labelText: 'Proveedor'),
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
                        selectedWarehouse == null ||
                        quantityController.text.isEmpty ||
                        supplierController.text.isEmpty) {
                      return;
                    }

                    final quantity = int.parse(quantityController.text);
                    final totalPrice = selectedProduct!.price * quantity;

                    final database = ref.read(databaseProvider);
                    await database.insertPurchase(PurchasesCompanion(
                      productId: drift.Value(selectedProduct!.id),
                      warehouseId: drift.Value(selectedWarehouse!.id),
                      quantity: drift.Value(quantity),
                      unitPrice: drift.Value(selectedProduct!.price),
                      totalPrice: drift.Value(totalPrice),
                      supplier: drift.Value(supplierController.text),
                      employeeId: drift.Value(currentEmployee?.id ?? 1),
                    ));

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Compra registrada correctamente'),
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
