import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/database.dart';
import '../providers/app_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _reportType = 'daily_sales'; // daily_sales, sales_by_store, purchases, transfers
  DateTime _selectedDate = DateTime.now();
  Store? _selectedStore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: Colors.pink.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Selector de tipo de reporte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de Reporte:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _reportType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'daily_sales',
                      child: Text('Ventas del Día'),
                    ),
                    DropdownMenuItem(
                      value: 'sales_by_store',
                      child: Text('Ventas por Tienda'),
                    ),
                    DropdownMenuItem(
                      value: 'purchases',
                      child: Text('Compras'),
                    ),
                    DropdownMenuItem(
                      value: 'transfers',
                      child: Text('Transferencias'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _reportType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filtros adicionales
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                      ),
                    ),
                    if (_reportType == 'sales_by_store') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final storesAsync = ref.watch(storesProvider);
                            return storesAsync.when(
                              data: (stores) => DropdownButtonFormField<Store>(
                                decoration: const InputDecoration(
                                  labelText: 'Tienda',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                value: _selectedStore,
                                items: stores
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.name),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedStore = value);
                                },
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (error, stack) => Text('Error: $error'),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Contenido del reporte
          Expanded(
            child: _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_reportType) {
      case 'daily_sales':
        return _buildDailySalesReport();
      case 'sales_by_store':
        return _buildSalesByStoreReport();
      case 'purchases':
        return _buildPurchasesReport();
      case 'transfers':
        return _buildTransfersReport();
      default:
        return const Center(child: Text('Seleccione un tipo de reporte'));
    }
  }

  Widget _buildDailySalesReport() {
    final salesAsync = ref.watch(salesByDateProvider(_selectedDate));

    return salesAsync.when(
      data: (sales) {
        if (sales.isEmpty) {
          return const Center(
            child: Text('No hay ventas en la fecha seleccionada'),
          );
        }

        final totalRevenue = sales.fold<double>(
          0.0,
          (sum, sale) => sum + sale.totalPrice,
        );
        final totalQuantity = sales.fold<int>(
          0,
          (sum, sale) => sum + sale.quantity,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(
                'Resumen del Día',
                [
                  _buildSummaryStat('Total Ventas', '${sales.length}', Colors.blue),
                  _buildSummaryStat(
                    'Ingresos Totales',
                    '\$${totalRevenue.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                  _buildSummaryStat(
                    'Unidades Vendidas',
                    '$totalQuantity',
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Detalle de Ventas:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sales.map((sale) => _buildSaleCard(sale)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildSalesByStoreReport() {
    if (_selectedStore == null) {
      return const Center(
        child: Text('Seleccione una tienda para ver el reporte'),
      );
    }

    final salesAsync = ref.watch(salesByStoreProvider(_selectedStore!.id));

    return salesAsync.when(
      data: (sales) {
        if (sales.isEmpty) {
          return const Center(
            child: Text('No hay ventas en esta tienda'),
          );
        }

        final totalRevenue = sales.fold<double>(
          0.0,
          (sum, sale) => sum + sale.totalPrice,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(
                'Tienda: ${_selectedStore!.name}',
                [
                  _buildSummaryStat('Total Ventas', '${sales.length}', Colors.blue),
                  _buildSummaryStat(
                    'Ingresos Totales',
                    '\$${totalRevenue.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Ventas Recientes:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sales.take(20).map((sale) => _buildSaleCard(sale)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildPurchasesReport() {
    final purchasesAsync = ref.watch(purchasesProvider);

    return purchasesAsync.when(
      data: (purchases) {
        if (purchases.isEmpty) {
          return const Center(child: Text('No hay compras registradas'));
        }

        final totalSpent = purchases.fold<double>(
          0.0,
          (sum, purchase) => sum + purchase.totalPrice,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(
                'Resumen de Compras',
                [
                  _buildSummaryStat('Total Compras', '${purchases.length}', Colors.blue),
                  _buildSummaryStat(
                    'Gasto Total',
                    '\$${totalSpent.toStringAsFixed(2)}',
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Compras Recientes:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...purchases.take(20).map((purchase) => _buildPurchaseCard(purchase)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildTransfersReport() {
    final transfersAsync = ref.watch(transfersProvider);

    return transfersAsync.when(
      data: (transfers) {
        if (transfers.isEmpty) {
          return const Center(child: Text('No hay transferencias registradas'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(
                'Resumen de Transferencias',
                [
                  _buildSummaryStat(
                    'Total Transferencias',
                    '${transfers.length}',
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Transferencias Recientes:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...transfers.take(20).map((transfer) => _buildTransferCard(transfer)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: stats,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) {
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

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(product.name),
            subtitle: Text(
              'Cantidad: ${sale.quantity} | ${DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate)}',
            ),
            trailing: Text(
              '\$${sale.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
      loading: () => const Card(child: LinearProgressIndicator()),
      error: (error, stack) => Card(child: Text('Error: $error')),
    );
  }

  Widget _buildPurchaseCard(Purchase purchase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(purchase.supplier),
        subtitle: Text(
          'Cantidad: ${purchase.quantity} | ${DateFormat('dd/MM/yyyy HH:mm').format(purchase.purchaseDate)}',
        ),
        trailing: Text(
          '\$${purchase.totalPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildTransferCard(Transfer transfer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Cantidad: ${transfer.quantity}'),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy HH:mm').format(transfer.transferDate)}\n'
          '${transfer.notes ?? "Sin notas"}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
