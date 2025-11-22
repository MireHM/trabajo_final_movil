import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../models/database.dart';
import '../providers/app_providers.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(child: Text('No hay empleados registrados'));
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade700,
                    child: Text(
                      employee.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(employee.name),
                  subtitle: Text(
                    '${employee.email}\nRol: ${_getRoleName(employee.role)}',
                  ),
                  isThreeLine: true,
                  trailing: Icon(
                    employee.isActive ? Icons.check_circle : Icons.cancel,
                    color: employee.isActive ? Colors.green : Colors.red,
                  ),
                  onTap: () => _showEmployeeDialog(context, ref, employee),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEmployeeDialog(context, ref, null),
        backgroundColor: Colors.indigo.shade700,
        child: const Icon(Icons.add, color: Colors.white),
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

  void _showEmployeeDialog(BuildContext context, WidgetRef ref, Employee? employee) {
    final nameController = TextEditingController(text: employee?.name ?? '');
    final emailController = TextEditingController(text: employee?.email ?? '');
    final passwordController = TextEditingController(text: employee?.password ?? '');
    String selectedRole = employee?.role ?? 'admin';
    bool isActive = employee?.isActive ?? true;
    Store? selectedStore;
    Warehouse? selectedWarehouse;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final storesAsync = ref.watch(storesProvider);
          final warehousesAsync = ref.watch(warehousesProvider);

          return AlertDialog(
            title: Text(employee == null ? 'Nuevo Empleado' : 'Editar Empleado'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Administrador'),
                      ),
                      DropdownMenuItem(
                        value: 'store_manager',
                        child: Text('Encargado de Tienda'),
                      ),
                      DropdownMenuItem(
                        value: 'warehouse_manager',
                        child: Text('Encargado de Almacén'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                        if (selectedRole == 'store_manager') {
                          selectedWarehouse = null;
                        } else if (selectedRole == 'warehouse_manager') {
                          selectedStore = null;
                        } else {
                          selectedStore = null;
                          selectedWarehouse = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mostrar selector de tienda si es encargado de tienda
                  if (selectedRole == 'store_manager')
                    storesAsync.when(
                      data: (stores) => DropdownButtonFormField<Store>(
                        decoration: const InputDecoration(
                          labelText: 'Tienda Asignada',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedStore,
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
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Error: $error'),
                    ),

                  // Mostrar selector de almacén si es encargado de almacén
                  if (selectedRole == 'warehouse_manager')
                    warehousesAsync.when(
                      data: (warehouses) => DropdownButtonFormField<Warehouse>(
                        decoration: const InputDecoration(
                          labelText: 'Almacén Asignado',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedWarehouse,
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
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Error: $error'),
                    ),

                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Activo'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() => isActive = value);
                    },
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
                  if (nameController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor complete todos los campos'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final database = ref.read(databaseProvider);

                  if (employee == null) {
                    // Crear nuevo
                    await database.insertEmployee(EmployeesCompanion(
                      name: drift.Value(nameController.text),
                      email: drift.Value(emailController.text),
                      password: drift.Value(passwordController.text),
                      role: drift.Value(selectedRole),
                      storeId: drift.Value(selectedStore?.id),
                      warehouseId: drift.Value(selectedWarehouse?.id),
                      isActive: drift.Value(isActive),
                    ));
                  } else {
                    // Actualizar existente
                    await database.updateEmployee(employee.copyWith(
                      name: nameController.text,
                      email: emailController.text,
                      password: passwordController.text,
                      role: selectedRole,
                      storeId: drift.Value(selectedStore?.id),
                      warehouseId: drift.Value(selectedWarehouse?.id),
                      isActive: isActive,
                      syncedAt: const drift.Value(null), // Marcar para re-sincronizar
                    ));
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          employee == null
                              ? 'Empleado creado correctamente'
                              : 'Empleado actualizado correctamente',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}