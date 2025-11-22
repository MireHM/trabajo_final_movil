import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../models/database.dart';
import '../providers/app_providers.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(transfersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferencias'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: transfersAsync.when(
        data: (transfers) {
          if (transfers.isEmpty) {
            return const Center(child: Text('No hay transferencias registradas'));
          }

          return ListView.builder(
            itemCount: transfers.length,
            itemBuilder: (context, index) {
              final transfer = transfers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade700,
                    child: const Icon(Icons.swap_horiz, color: Colors.white),
                  ),
                  title: Text('Cantidad: ${transfer.quantity}'),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(transfer.transferDate)}\n'
                    '${transfer.notes ?? "Sin notas"}',
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
        onPressed: () => _showTransferDialog(context, ref),
        backgroundColor: Colors.indigo.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showTransferDialog(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.read(productsProvider);
    final storesAsync = ref.read(storesProvider);
    final warehousesAsync = ref.read(warehousesProvider);
    final currentEmployee = ref.read(currentEmployeeProvider);

    productsAsync.whenData((products) {
      storesAsync.whenData((stores) {
        warehousesAsync.whenData((warehouses) {
          if (products.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Debe haber productos registrados')),
            );
            return;
          }

          Product? selectedProduct;
          dynamic fromLocation;
          dynamic toLocation;
          String fromType = 'warehouse';
          String toType = 'store';
          final quantityController = TextEditingController();
          final notesController = TextEditingController();

          showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('Nueva Transferencia'),
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
                      const Divider(height: 32),
                      const Text('Desde:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Almacén'),
                              value: 'warehouse',
                              groupValue: fromType,
                              onChanged: (value) {
                                setState(() {
                                  fromType = value!;
                                  fromLocation = null;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Tienda'),
                              value: 'store',
                              groupValue: fromType,
                              onChanged: (value) {
                                setState(() {
                                  fromType = value!;
                                  fromLocation = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (fromType == 'warehouse')
                        DropdownButtonFormField<Warehouse>(
                          decoration: const InputDecoration(labelText: 'Almacén origen'),
                          items: warehouses
                              .map((w) => DropdownMenuItem(
                                    value: w,
                                    child: Text(w.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => fromLocation = value);
                          },
                        )
                      else
                        DropdownButtonFormField<Store>(
                          decoration: const InputDecoration(labelText: 'Tienda origen'),
                          items: stores
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => fromLocation = value);
                          },
                        ),
                      const Divider(height: 32),
                      const Text('Hacia:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Almacén'),
                              value: 'warehouse',
                              groupValue: toType,
                              onChanged: (value) {
                                setState(() {
                                  toType = value!;
                                  toLocation = null;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Tienda'),
                              value: 'store',
                              groupValue: toType,
                              onChanged: (value) {
                                setState(() {
                                  toType = value!;
                                  toLocation = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (toType == 'warehouse')
                        DropdownButtonFormField<Warehouse>(
                          decoration: const InputDecoration(labelText: 'Almacén destino'),
                          items: warehouses
                              .map((w) => DropdownMenuItem(
                                    value: w,
                                    child: Text(w.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => toLocation = value);
                          },
                        )
                      else
                        DropdownButtonFormField<Store>(
                          decoration: const InputDecoration(labelText: 'Tienda destino'),
                          items: stores
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => toLocation = value);
                          },
                        ),
                      const Divider(height: 32),
                      TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(labelText: 'Cantidad'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'Notas (opcional)'),
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
                          fromLocation == null ||
                          toLocation == null ||
                          quantityController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Complete todos los campos'),
                          ),
                        );
                        return;
                      }

                      final quantity = int.parse(quantityController.text);

                      final database = ref.read(databaseProvider);
                      await database.insertTransfer(TransfersCompanion(
                        productId: drift.Value(selectedProduct!.id),
                        fromStoreId: drift.Value(
                            fromType == 'store' ? fromLocation.id : null),
                        fromWarehouseId: drift.Value(
                            fromType == 'warehouse' ? fromLocation.id : null),
                        toStoreId: drift.Value(
                            toType == 'store' ? toLocation.id : null),
                        toWarehouseId: drift.Value(
                            toType == 'warehouse' ? toLocation.id : null),
                        quantity: drift.Value(quantity),
                        employeeId: drift.Value(currentEmployee?.id ?? 1),
                        notes: drift.Value(notesController.text.isEmpty
                            ? null
                            : notesController.text),
                      ));

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transferencia registrada correctamente'),
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
    });
  }
}
