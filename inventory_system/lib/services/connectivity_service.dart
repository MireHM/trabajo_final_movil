import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  // Stream de estado de conectividad - COMPATIBLE CON AMBAS VERSIONES
  Stream<bool> get connectivityStream async* {
    try {
      // Verificar estado inicial
      final initialResult = await _connectivity.checkConnectivity();
      yield _hasConnection(initialResult);

      // Escuchar cambios - compatible con ambas versiones
      await for (final result in _connectivity.onConnectivityChanged) {
        yield _hasConnection(result);
      }
    } catch (e) {
      print('Error en connectivity stream: $e');
      yield false;
    }
  }

  // Verificar si hay conexión - COMPATIBLE CON AMBAS VERSIONES
  bool _hasConnection(dynamic results) {
    // Si es List<ConnectivityResult> (versión nueva)
    if (results is List) {
      return results.any((result) =>
      result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet
      );
    }

    // Si es ConnectivityResult (versión antigua)
    if (results is ConnectivityResult) {
      return results == ConnectivityResult.mobile ||
          results == ConnectivityResult.wifi ||
          results == ConnectivityResult.ethernet;
    }

    // Fallback
    return false;
  }

  // Verificar estado actual una sola vez
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _hasConnection(result);
    } catch (e) {
      print('Error al verificar conectividad: $e');
      return false;
    }
  }

  // Limpiar recursos
  void dispose() {
    _subscription?.cancel();
  }
}

// Widget de banner de conectividad
class ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onSyncPressed;

  const ConnectivityBanner({
    super.key,
    required this.isOnline,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isOnline ? 0 : 50,
      child: AnimatedOpacity(
        opacity: isOnline ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sin conexión - Modo offline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget flotante de estado de conectividad
class ConnectivityIndicator extends StatelessWidget {
  final bool isOnline;
  final bool showAlways;

  const ConnectivityIndicator({
    super.key,
    required this.isOnline,
    this.showAlways = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showAlways && isOnline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.shade700 : Colors.orange.shade700,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Snackbar de cambio de conectividad
class ConnectivitySnackBar {
  static void show(BuildContext context, bool isOnline) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOnline ? 'Conexión restaurada' : 'Sin conexión a internet',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isOnline
                        ? 'Ya puedes sincronizar tus datos'
                        : 'La app funciona en modo offline',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isOnline ? Colors.green.shade700 : Colors.orange.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// Dialog informativo sobre conectividad
class ConnectivityInfoDialog extends StatelessWidget {
  final bool isOnline;

  const ConnectivityInfoDialog({
    super.key,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: isOnline ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Text(isOnline ? 'Modo Online' : 'Modo Offline'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isOnline
                  ? 'Estás conectado a internet'
                  : 'Sin conexión a internet',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (isOnline) ...[
              _buildFeatureItem(
                icon: Icons.sync,
                title: 'Sincronización disponible',
                description: 'Puedes sincronizar tus datos con el servidor',
                color: Colors.green,
              ),
              _buildFeatureItem(
                icon: Icons.cloud_upload,
                title: 'Subida de datos',
                description: 'Los cambios locales se pueden subir a Supabase',
                color: Colors.blue,
              ),
              _buildFeatureItem(
                icon: Icons.cloud_download,
                title: 'Descarga de datos',
                description: 'Puedes obtener datos actualizados del servidor',
                color: Colors.purple,
              ),
            ] else ...[
              _buildFeatureItem(
                icon: Icons.check_circle,
                title: 'Todas las funciones disponibles',
                description: 'Crear, editar y ver datos localmente',
                color: Colors.green,
              ),
              _buildFeatureItem(
                icon: Icons.storage,
                title: 'Base de datos local',
                description: 'Todos tus datos están guardados en el dispositivo',
                color: Colors.blue,
              ),
              _buildFeatureItem(
                icon: Icons.sync_disabled,
                title: 'Sincronización pendiente',
                description: 'Los cambios se sincronizarán cuando haya conexión',
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context, bool isOnline) {
    showDialog(
      context: context,
      builder: (context) => ConnectivityInfoDialog(isOnline: isOnline),
    );
  }
}