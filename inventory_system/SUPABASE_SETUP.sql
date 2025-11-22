-- =====================================================
-- SCRIPT DE CONFIGURACIÓN DE SUPABASE
-- Sistema de Inventario - Base de Datos
-- =====================================================

-- IMPORTANTE: Ejecutar este script en el SQL Editor de Supabase

-- =====================================================
-- 1. CREAR TABLAS
-- =====================================================

-- Tabla de Empleados
CREATE TABLE IF NOT EXISTS employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'store_manager', 'warehouse_manager')),
    store_id UUID REFERENCES stores(id),
    warehouse_id UUID REFERENCES warehouses(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de Tiendas
CREATE TABLE IF NOT EXISTS stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    phone TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de Almacenes
CREATE TABLE IF NOT EXISTS warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de Productos
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('smartphones', 'laptops', 'tablets', 'accessories')),
    sku TEXT UNIQUE NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de Inventario
CREATE TABLE IF NOT EXISTS inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
    warehouse_id UUID REFERENCES warehouses(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (
        (store_id IS NOT NULL AND warehouse_id IS NULL) OR
        (store_id IS NULL AND warehouse_id IS NOT NULL)
    )
);

-- Tabla de Compras
CREATE TABLE IF NOT EXISTS purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    supplier TEXT NOT NULL,
    purchase_date TIMESTAMPTZ DEFAULT NOW(),
    employee_id UUID NOT NULL REFERENCES employees(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de Ventas
CREATE TABLE IF NOT EXISTS sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    sale_date TIMESTAMPTZ DEFAULT NOW(),
    employee_id UUID NOT NULL REFERENCES employees(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de Transferencias
CREATE TABLE IF NOT EXISTS transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    from_store_id UUID REFERENCES stores(id),
    from_warehouse_id UUID REFERENCES warehouses(id),
    to_store_id UUID REFERENCES stores(id),
    to_warehouse_id UUID REFERENCES warehouses(id),
    quantity INTEGER NOT NULL,
    transfer_date TIMESTAMPTZ DEFAULT NOW(),
    employee_id UUID NOT NULL REFERENCES employees(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (
        (from_store_id IS NOT NULL OR from_warehouse_id IS NOT NULL) AND
        (to_store_id IS NOT NULL OR to_warehouse_id IS NOT NULL) AND
        (from_store_id IS NULL OR from_warehouse_id IS NULL) AND
        (to_store_id IS NULL OR to_warehouse_id IS NULL)
    )
);

-- =====================================================
-- 2. CREAR ÍNDICES
-- =====================================================

CREATE INDEX idx_employees_email ON employees(email);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_store ON inventory(store_id);
CREATE INDEX idx_inventory_warehouse ON inventory(warehouse_id);
CREATE INDEX idx_purchases_product ON purchases(product_id);
CREATE INDEX idx_purchases_warehouse ON purchases(warehouse_id);
CREATE INDEX idx_purchases_date ON purchases(purchase_date);
CREATE INDEX idx_sales_product ON sales(product_id);
CREATE INDEX idx_sales_store ON sales(store_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_transfers_product ON transfers(product_id);
CREATE INDEX idx_transfers_date ON transfers(transfer_date);

-- =====================================================
-- 3. HABILITAR ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE transfers ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. POLÍTICAS DE SEGURIDAD (RLS POLICIES)
-- =====================================================

-- Políticas para empleados (solo lectura para autenticados)
CREATE POLICY "Empleados: lectura para autenticados"
    ON employees FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Empleados: inserción para autenticados"
    ON employees FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Empleados: actualización para autenticados"
    ON employees FOR UPDATE
    USING (auth.role() = 'authenticated');

-- Políticas para tiendas
CREATE POLICY "Tiendas: lectura para todos"
    ON stores FOR SELECT
    USING (true);

CREATE POLICY "Tiendas: escritura para autenticados"
    ON stores FOR ALL
    USING (auth.role() = 'authenticated');

-- Políticas para almacenes
CREATE POLICY "Almacenes: lectura para todos"
    ON warehouses FOR SELECT
    USING (true);

CREATE POLICY "Almacenes: escritura para autenticados"
    ON warehouses FOR ALL
    USING (auth.role() = 'authenticated');

-- Políticas para productos
CREATE POLICY "Productos: lectura para todos"
    ON products FOR SELECT
    USING (true);

CREATE POLICY "Productos: escritura para autenticados"
    ON products FOR ALL
    USING (auth.role() = 'authenticated');

-- Políticas para inventario
CREATE POLICY "Inventario: lectura para todos"
    ON inventory FOR SELECT
    USING (true);

CREATE POLICY "Inventario: escritura para autenticados"
    ON inventory FOR ALL
    USING (auth.role() = 'authenticated');

-- Políticas para compras
CREATE POLICY "Compras: lectura para todos"
    ON purchases FOR SELECT
    USING (true);

CREATE POLICY "Compras: escritura para autenticados"
    ON purchases FOR ALL
    USING (auth.role() = 'authenticated');

-- Políticas para ventas
CREATE POLICY "Ventas: lectura para todos"
    ON sales FOR SELECT
    USING (true);

CREATE POLICY "Ventas: escritura para autenticados"
    ON sales FOR ALL
    USING (auth.role() = 'authenticated');

-- Políticas para transferencias
CREATE POLICY "Transferencias: lectura para todos"
    ON transfers FOR SELECT
    USING (true);

CREATE POLICY "Transferencias: escritura para autenticados"
    ON transfers FOR ALL
    USING (auth.role() = 'authenticated');

-- =====================================================
-- 5. TRIGGERS PARA UPDATED_AT
-- =====================================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para todas las tablas
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_stores_updated_at BEFORE UPDATE ON stores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_warehouses_updated_at BEFORE UPDATE ON warehouses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 6. DATOS DE PRUEBA (OPCIONAL)
-- =====================================================

-- Insertar tiendas de ejemplo
INSERT INTO stores (name, address, phone) VALUES
    ('Tienda Centro', 'Av. Principal 123', '2-2345678'),
    ('Tienda Norte', 'Zona Norte, Calle 45', '2-7654321')
ON CONFLICT DO NOTHING;

-- Insertar almacén de ejemplo
INSERT INTO warehouses (name, address) VALUES
    ('Almacén Central', 'Zona Industrial, Mz. 5')
ON CONFLICT DO NOTHING;

-- Insertar productos de ejemplo
INSERT INTO products (name, description, category, sku, price) VALUES
    ('iPhone 15 Pro', 'Smartphone Apple última generación', 'smartphones', 'IPH15PRO', 1299.99),
    ('Samsung Galaxy S24', 'Smartphone Samsung flagship', 'smartphones', 'SAMS24', 999.99),
    ('MacBook Pro M3', 'Laptop Apple con chip M3', 'laptops', 'MBPM3', 2499.99),
    ('iPad Air', 'Tablet Apple iPad Air', 'tablets', 'IPADAIR', 699.99),
    ('AirPods Pro', 'Auriculares inalámbricos Apple', 'accessories', 'AIRPODSP', 249.99)
ON CONFLICT (sku) DO NOTHING;

-- =====================================================
-- 7. FUNCIONES ÚTILES
-- =====================================================

-- Función para obtener inventario global
CREATE OR REPLACE FUNCTION get_global_inventory()
RETURNS TABLE (
    product_id UUID,
    product_name TEXT,
    total_quantity BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        COALESCE(SUM(i.quantity), 0) as total_quantity
    FROM products p
    LEFT JOIN inventory i ON p.id = i.product_id
    WHERE p.is_active = TRUE
    GROUP BY p.id, p.name
    ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener reporte de ventas diarias
CREATE OR REPLACE FUNCTION get_daily_sales_report(report_date DATE)
RETURNS TABLE (
    total_sales BIGINT,
    total_revenue DECIMAL,
    total_quantity BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_sales,
        COALESCE(SUM(total_price), 0) as total_revenue,
        COALESCE(SUM(quantity), 0)::BIGINT as total_quantity
    FROM sales
    WHERE DATE(sale_date) = report_date;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================

-- Para verificar que todo se creó correctamente:
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
