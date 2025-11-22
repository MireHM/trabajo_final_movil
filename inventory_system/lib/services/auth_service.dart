import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import '../models/database.dart';

class AuthService {
  final AppDatabase database;
  final SupabaseClient supabase;

  AuthService(this.database, this.supabase);

  // Autenticación local (offline-first)
  Future<Employee?> loginLocal(String email, String password) async {
    final employee = await database.getEmployeeByEmail(email);
    
    if (employee != null && employee.password == password && employee.isActive) {
      return employee;
    }
    
    return null;
  }

  // Autenticación con Supabase (cuando hay internet)
  Future<Employee?> loginWithSupabase(String email, String password) async {
    try {
      // Primero intentar autenticación con Supabase Auth
      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // Buscar empleado en la base de datos
        final response = await supabase
            .from('employees')
            .select()
            .eq('email', email)
            .single();

        // Verificar si existe localmente
        final localEmployee = await database.getEmployeeByEmail(email);
        
        if (localEmployee == null) {
          // Crear empleado localmente
          final id = await database.insertEmployee(EmployeesCompanion.insert(
            supabaseId: drift.Value(response['id'].toString()),
            name: response['name'],
            email: email,
            password: password,
            role: response['role'],
            storeId: drift.Value(response['store_id']),
            warehouseId: drift.Value(response['warehouse_id']),
            isActive: drift.Value(response['is_active'] ?? true),
            syncedAt: drift.Value(DateTime.now()),
          ));

          return await database.select(database.employees)
              .getSingle();
        }

        return localEmployee;
      }
    } catch (e) {
      print('Error en login con Supabase: $e');
      // Si falla, intentar login local
      return await loginLocal(email, password);
    }

    return null;
  }

  // Login principal (intenta Supabase primero, luego local)
  Future<Employee?> login(String email, String password) async {
    try {
      // Intentar con Supabase
      final employee = await loginWithSupabase(email, password);
      if (employee != null) return employee;
    } catch (e) {
      print('Supabase no disponible, usando autenticación local');
    }

    // Si falla, usar local
    return await loginLocal(email, password);
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      print('Error al cerrar sesión en Supabase: $e');
    }
  }

  // Verificar si hay sesión activa
  User? get currentUser => supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
}
