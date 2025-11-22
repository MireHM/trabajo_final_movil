# Sistema de Inventario - Trabajo Final

Sistema de gestión de inventario offline-first para tienda de electrónicos y gadgets.

## 📋 Descripción

Sistema completo de gestión de inventario que permite:
- ✅ Gestión de productos, tiendas, almacenes y empleados
- ✅ Autenticación de usuarios (encargados de tienda/almacén)
- ✅ Registro de compras, ventas y transferencias
- ✅ Inventario actualizado en tiempo real (global, por tienda, por almacén)
- ✅ Reportes de ventas y compras (filtrados por tienda y fecha)
- ✅ Reportes de transferencias entre almacenes y tiendas
- ✅ Reporte de ventas del día (globales y por tienda)
- ✅ Arquitectura **Offline-First** con sincronización a Supabase

## 🛠️ Stack Tecnológico

- **Flutter** - Framework de desarrollo
- **Dart** - Lenguaje de programación
- **Drift** - ORM para base de datos local (SQLite)
- **Riverpod** - Gestión de estado
- **Supabase** - Backend y sincronización (PostgreSQL + Auth)
- **flutter_dotenv** - Gestión de variables de entorno

## 📁 Estructura del Proyecto

```
inventory_system/
├── lib/
│   ├── models/
│   │   └── database.dart          # Modelos Drift y lógica de BD
│   ├── services/
│   │   ├── auth_service.dart      # Autenticación
│   │   └── sync_service.dart      # Sincronización con Supabase
│   ├── providers/
│   │   └── app_providers.dart     # Riverpod providers
│   ├── screens/
│   │   ├── login_screen.dart      # Login
│   │   ├── home_screen.dart       # Dashboard principal
│   │   ├── products_screen.dart   # Gestión de productos
│   │   ├── stores_screen.dart     # Gestión de tiendas
│   │   ├── warehouses_screen.dart # Gestión de almacenes
│   │   ├── inventory_screen.dart  # Consulta de inventario
│   │   ├── purchases_screen.dart  # Registro de compras
│   │   ├── sales_screen.dart      # Registro de ventas
│   │   ├── transfers_screen.dart  # Transferencias
│   │   └── reports_screen.dart    # Reportes y estadísticas
│   └── main.dart                  # Punto de entrada
├── .env                           # Variables de entorno (NO SUBIR A GIT)
├── .gitignore                     # Archivos ignorados
├── pubspec.yaml                   # Dependencias
├── README.md                      # Este archivo
└── SUPABASE_SETUP.sql            # Script SQL para Supabase
```

## 🚀 Instalación y Configuración

### 1. Requisitos Previos

- Flutter SDK 3.0 o superior
- Dart SDK 3.0 o superior
- Android Studio / VS Code
- Cuenta en Supabase (opcional, para sincronización)

### 2. Clonar e Instalar Dependencias

```bash
cd inventory_system
flutter pub get
```

### 3. Generar Código de Drift

El proyecto usa Drift para la base de datos. Debes generar los archivos `.g.dart`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Si necesitas regenerar después de cambios en los modelos:

```bash
flutter pub run build_runner watch
```

### 4. Configurar Variables de Entorno

Edita el archivo `.env` en la raíz del proyecto:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
```

**Nota:** Si no usarás Supabase, la app funcionará en modo 100% offline.

### 5. Configurar Supabase (Opcional)

Si quieres habilitar la sincronización:

1. Crea un proyecto en [Supabase](https://supabase.com)
2. Ejecuta el script SQL en `SUPABASE_SETUP.sql` en el SQL Editor de Supabase
3. Copia las credenciales (URL y Anon Key) al archivo `.env`

### 6. Ejecutar la Aplicación

```bash
flutter run
```

## 👤 Credenciales de Prueba

El sistema crea automáticamente datos de prueba al iniciar:

```
Email: admin@tienda.com
Password: admin123
```

**Datos de prueba incluidos:**
- 1 empleado administrador
- 2 tiendas (Tienda Centro, Tienda Norte)
- 1 almacén (Almacén Central)
- 5 productos (iPhone, Samsung, MacBook, iPad, AirPods)
- Compras, transferencias y ventas de ejemplo

## 📱 Funcionalidades Principales

### 1. Autenticación
- Login con email y contraseña
- Autenticación offline-first (local primero, luego Supabase)
- Roles: admin, store_manager, warehouse_manager

### 2. Gestión de Datos
- **Productos:** CRUD completo con categorías (smartphones, laptops, tablets, accessories)
- **Tiendas:** Registro de tiendas con dirección y teléfono
- **Almacenes:** Gestión de almacenes
- **Empleados:** Gestión de usuarios del sistema

### 3. Operaciones de Inventario
- **Compras:** Registro de compras a proveedores (actualiza inventario automáticamente)
- **Ventas:** Registro de ventas en tiendas (descuenta inventario automáticamente)
- **Transferencias:** Movimiento de productos entre almacenes y tiendas

### 4. Consultas de Inventario
- Inventario global
- Inventario por tienda
- Inventario por almacén
- Indicadores visuales de stock (verde: >10, naranja: 1-10, rojo: 0)

### 5. Reportes
- **Ventas del día:** Total de ventas y revenue del día seleccionado
- **Ventas por tienda:** Ventas filtradas por tienda específica
- **Reporte de compras:** Historial de compras y gasto total
- **Reporte de transferencias:** Movimientos entre ubicaciones

### 6. Sincronización
- Arquitectura **offline-first**
- Sincronización manual mediante botón en el dashboard
- Indicadores visuales de estado de sincronización
- Manejo de conflictos básico (local primero)

## 🔄 Flujo de Sincronización

1. **Offline First:** Todas las operaciones se guardan primero en la BD local (SQLite vía Drift)
2. **Marca de Sincronización:** Registros sin sincronizar tienen `syncedAt = null`
3. **Sincronización Manual:** Presionar botón de sync en el dashboard
4. **Subida de Datos:** Se suben registros locales no sincronizados a Supabase
5. **Descarga de Datos:** Se descargan datos nuevos desde Supabase
6. **Actualización:** Se actualiza la marca `syncedAt` en registros sincronizados

## 📊 Modelo de Datos

### Tablas Principales

1. **employees** - Usuarios del sistema
2. **stores** - Tiendas de venta
3. **warehouses** - Almacenes de productos
4. **products** - Catálogo de productos
5. **inventory** - Stock actual por ubicación
6. **purchases** - Compras a proveedores
7. **sales** - Ventas realizadas
8. **transfers** - Transferencias entre ubicaciones

### Relaciones

- Inventory → Product (many-to-one)
- Inventory → Store/Warehouse (many-to-one)
- Sales → Product, Store, Employee (many-to-one)
- Purchases → Product, Warehouse, Employee (many-to-one)
- Transfers → Product, Locations, Employee (many-to-one)

## 🎨 Características de UI/UX

- Material Design 3
- Tema personalizado con Google Fonts
- Colores diferenciados por módulo
- Indicadores de estado visual
- Formularios con validación
- Feedback visual en operaciones
- Responsive design

## 🔐 Seguridad

- Contraseñas almacenadas en texto plano en SQLite local (para demo)
- Variables de entorno protegidas con `.gitignore`
- Autenticación con Supabase Auth para producción
- Row Level Security (RLS) en Supabase

## 📝 Notas Importantes

### Limitaciones Conocidas

1. **Conflictos de Sincronización:** Implementación básica, prioriza datos locales
2. **Contraseñas:** En producción, usar hash (bcrypt, argon2)
3. **Validaciones:** Validaciones básicas en UI, agregar más validaciones de negocio
4. **Multiusuario:** Sincronización simple, no diseñado para concurrencia alta

### Mejoras Futuras

- [ ] Implementar sincronización automática periódica
- [ ] Agregar resolución avanzada de conflictos
- [ ] Implementar caché de imágenes de productos
- [ ] Agregar gráficos más avanzados en reportes
- [ ] Implementar búsqueda y filtros avanzados
- [ ] Agregar notificaciones push
- [ ] Implementar backup/restore de BD local
- [ ] Agregar exportación de reportes a PDF/Excel

## 🧪 Testing

Para ejecutar tests (cuando estén implementados):

```bash
flutter test
```

## 📦 Build para Producción

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## 🐛 Troubleshooting

### Error: "drift" no genera archivos

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: Supabase no conecta

1. Verifica las credenciales en `.env`
2. Verifica que el proyecto de Supabase esté activo
3. La app funciona 100% offline si Supabase no está disponible

### Error: Base de datos corrupta

Elimina la app y reinstala (los datos de prueba se recrearán)

## 👨‍💻 Desarrollo

Este proyecto fue desarrollado como trabajo final para la materia de Desarrollo Móvil.

**Características implementadas:**
- ✅ Sistema offline-first completo
- ✅ CRUD de todas las entidades
- ✅ Autenticación multi-rol
- ✅ Inventario en tiempo real
- ✅ Reportes con filtros
- ✅ Sincronización con backend
- ✅ UI/UX profesional

## 📄 Licencia

Este proyecto es de uso académico.

---
