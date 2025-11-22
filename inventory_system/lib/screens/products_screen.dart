import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../models/database.dart';
import '../providers/app_providers.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text('No hay productos registrados'),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade700,
                    child: const Icon(Icons.inventory_2, color: Colors.white),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.category} | SKU: ${product.sku}\n\$${product.price.toStringAsFixed(2)}',
                  ),
                  isThreeLine: true,
                  trailing: Icon(
                    product.isActive ? Icons.check_circle : Icons.cancel,
                    color: product.isActive ? Colors.green : Colors.red,
                  ),
                  onTap: () => _showProductDialog(context, product),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(context, null),
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showProductDialog(BuildContext context, Product? product) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final skuController = TextEditingController(text: product?.sku ?? '');
    final priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    String category = product?.category ?? 'smartphones';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Nuevo Producto' : 'Editar Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: const [
                  DropdownMenuItem(value: 'smartphones', child: Text('Smartphones')),
                  DropdownMenuItem(value: 'laptops', child: Text('Laptops')),
                  DropdownMenuItem(value: 'tablets', child: Text('Tablets')),
                  DropdownMenuItem(value: 'accessories', child: Text('Accesorios')),
                ],
                onChanged: (value) => category = value!,
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
              final database = ref.read(databaseProvider);

              if (product == null) {
                await database.insertProduct(ProductsCompanion(
                  name: drift.Value(nameController.text),
                  description: drift.Value(descController.text),
                  category: drift.Value(category),
                  sku: drift.Value(skuController.text),
                  price: drift.Value(double.parse(priceController.text)),
                ));
              } else {
                await database.updateProduct(product.copyWith(
                  name: nameController.text,
                  description: descController.text,
                  category: category,
                  sku: skuController.text,
                  price: double.parse(priceController.text),
                  syncedAt: const drift.Value(null),
                ));
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
