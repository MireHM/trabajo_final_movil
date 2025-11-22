# 🚀 GUÍA RÁPIDA DE INSTALACIÓN

## Pasos Rápidos para Ejecutar el Proyecto

### 1️⃣ Instalar Dependencias
```bash
cd inventory_system
flutter pub get
```

### 2️⃣ Generar Código de Drift
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3️⃣ Ejecutar la App
```bash
flutter run
```

### 4️⃣ Iniciar Sesión
```
Email: admin@tienda.com
Password: admin123
```

---

## ⚙️ Configuración Opcional de Supabase

Si quieres habilitar la sincronización con backend:

### 1. Crear Proyecto en Supabase
- Ve a https://supabase.com
- Crea un nuevo proyecto
- Guarda la URL y Anon Key

### 2. Ejecutar Script SQL
- En Supabase, ve a SQL Editor
- Copia y pega todo el contenido de `SUPABASE_SETUP.sql`
- Ejecuta el script

### 3. Configurar Variables de Entorno
Edita el archivo `.env`:
```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
```

### 4. Reiniciar la App
```bash
flutter run
```

---

## ✅ La app funciona 100% offline sin Supabase

Si no configuras Supabase, la aplicación funcionará perfectamente en modo offline.
Todas las funcionalidades están disponibles localmente.

---

## 📱 Funcionalidades Principales

1. **Dashboard** - Acceso a todos los módulos
2. **Productos** - Gestión de catálogo
3. **Tiendas** - Gestión de sucursales
4. **Almacenes** - Gestión de bodegas
5. **Inventario** - Consulta de stock (global, por tienda, por almacén)
6. **Compras** - Registro de compras (actualiza inventario automáticamente)
7. **Ventas** - Registro de ventas (descuenta inventario automáticamente)
8. **Transferencias** - Movimiento entre ubicaciones
9. **Reportes** - Ventas del día, por tienda, compras, transferencias
10. **Sincronización** - Botón de sync en dashboard (si Supabase está configurado)

---

## 🐛 Problemas Comunes

### Error: "No se puede generar código"
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "Supabase no conecta"
- Verifica las credenciales en `.env`
- La app funciona sin Supabase en modo offline

### Error: "Base de datos corrupta"
- Desinstala y reinstala la app
- Los datos de prueba se recrean automáticamente

---

## 📊 Datos de Prueba Incluidos

La app crea automáticamente:
- ✅ 1 usuario administrador
- ✅ 2 tiendas
- ✅ 1 almacén
- ✅ 5 productos (iPhone, Samsung, MacBook, iPad, AirPods)
- ✅ Compras, ventas y transferencias de ejemplo

---

## 📖 Documentación Completa

Lee el archivo `README.md` para documentación completa y detallada.

---

**¡Listo para usar! 🎉**
