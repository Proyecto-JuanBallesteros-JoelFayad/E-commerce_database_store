SET GLOBAL event_scheduler = ON;

-- tablas de apoyo que necesitan algunos eventos

CREATE TABLE IF NOT EXISTS reporte_ventas_semanal (
    id_reporte INT AUTO_INCREMENT PRIMARY KEY,
    semana_inicio DATE,
    semana_fin DATE,
    total_ventas INT,
    ingresos_totales DECIMAL(12,2),
    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS resumen_ventas_diario (
    id_resumen INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE,
    total_ordenes INT,
    ingresos DECIMAL(12,2),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS log_tamano_bd (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    tamano_mb DECIMAL(10,2),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ranking_productos (
    id_ranking INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT,
    nombre_producto VARCHAR(50),
    unidades_vendidas_mes INT,
    posicion INT,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS kpis_mensuales (
    id_kpi INT AUTO_INCREMENT PRIMARY KEY,
    anio INT,
    mes INT,
    total_ventas INT,
    ingresos_totales DECIMAL(12,2),
    ticket_promedio DECIMAL(10,2),
    nuevos_clientes INT,
    fecha_calculo TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 1) evt_generate_weekly_sales_report: Genera un reporte de ventas semanal.

CREATE EVENT IF NOT EXISTS evt_generate_weekly_sales_report
ON SCHEDULE EVERY 1 WEEK
STARTS '2026-01-05 00:00:00'
DO
    INSERT INTO reporte_ventas_semanal(semana_inicio, semana_fin, total_ventas, ingresos_totales)
    SELECT
        DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY) AS semana_inicio,
        DATE_ADD(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 6 DAY) AS semana_fin,
        COUNT(*),
        COALESCE(SUM(total), 0)
    FROM ventas
    WHERE fecha_venta >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    AND estado != 'Cancelado';


-- 2) evt_cleanup_temp_tables_daily: Borra tablas temporales diariamente.

CREATE EVENT IF NOT EXISTS evt_cleanup_temp_tables_daily
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
    DELETE FROM alertas_stock
    WHERE revisada = TRUE
    AND fecha_alerta < DATE_SUB(CURDATE(), INTERVAL 7 DAY);


-- 3) evt_archive_old_logs_monthly: Archiva logs de mas de 6 meses.

CREATE EVENT IF NOT EXISTS evt_archive_old_logs_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
    DELETE FROM log_precios_productos
    WHERE fecha_cambio < DATE_SUB(CURDATE(), INTERVAL 6 MONTH);


-- 4) evt_deactivate_expired_promotions_hourly: Desactiva codigos de descuento que han expirado.

-- PENDIENTE - requiere tabla promociones/cupones
-- CREATE TABLE promociones (id_promo INT, codigo VARCHAR(50), descuento DECIMAL, fecha_expiracion DATE, activa BOOLEAN)
/*
CREATE EVENT IF NOT EXISTS evt_deactivate_expired_promotions_hourly
ON SCHEDULE EVERY 1 HOUR
DO
    UPDATE promociones
    SET activa = FALSE
    WHERE fecha_expiracion < CURDATE() AND activa = TRUE;
*/


-- 5) evt_recalculate_customer_loyalty_tiers_nightly: Recalcula el nivel de lealtad de los clientes cada noche.

ALTER TABLE clientes
ADD COLUMN IF NOT EXISTS nivel_lealtad VARCHAR(20) DEFAULT 'Bronce';

CREATE EVENT IF NOT EXISTS evt_recalculate_customer_loyalty_tiers_nightly
ON SCHEDULE EVERY 1 DAY
STARTS '2026-01-01 02:00:00'
DO
    UPDATE clientes
    SET nivel_lealtad = fn_DeterminarEstadoLealtad2(id_cliente);


-- 6) evt_generate_reorder_list_daily: Crea una lista de productos que necesitan reabastecimiento.

CREATE TABLE IF NOT EXISTS lista_reabastecimiento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT,
    nombre_producto VARCHAR(50),
    stock_actual INT,
    stock_minimo INT,
    fecha_generacion DATE
);

CREATE EVENT IF NOT EXISTS evt_generate_reorder_list_daily
ON SCHEDULE EVERY 1 DAY
STARTS '2026-01-01 06:00:00'
DO BEGIN
    DELETE FROM lista_reabastecimiento WHERE fecha_generacion = CURDATE();

    INSERT INTO lista_reabastecimiento(id_producto, nombre_producto, stock_actual, stock_minimo, fecha_generacion)
    SELECT id_producto, nombre, stock, stock_minimo, CURDATE()
    FROM productos
    WHERE stock <= stock_minimo AND activo = TRUE;
END;


-- 7) evt_rebuild_indexes_weekly: Reconstruye los indices de las tablas mas usadas para optimizar el rendimiento.

CREATE EVENT IF NOT EXISTS evt_rebuild_indexes_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS '2026-01-01 03:00:00'
DO BEGIN
    OPTIMIZE TABLE productos;
    OPTIMIZE TABLE ventas;
    OPTIMIZE TABLE detalle_ventas;
    OPTIMIZE TABLE clientes;
END;


-- 8) evt_suspend_inactive_accounts_quarterly: Desactiva cuentas sin actividad en mas de un anio.

ALTER TABLE clientes
ADD COLUMN IF NOT EXISTS cuenta_activa BOOLEAN DEFAULT TRUE;

CREATE EVENT IF NOT EXISTS evt_suspend_inactive_accounts_quarterly
ON SCHEDULE EVERY 3 MONTH
STARTS CURRENT_TIMESTAMP
DO
    UPDATE clientes
    SET cuenta_activa = FALSE
    WHERE fecha_ultima_compra < DATE_SUB(CURDATE(), INTERVAL 1 YEAR);


-- 9) evt_aggregate_daily_sales_data: Agrega los datos de ventas del dia en una tabla resumen.

CREATE EVENT IF NOT EXISTS evt_aggregate_daily_sales_data
ON SCHEDULE EVERY 1 DAY
STARTS '2026-01-01 23:59:00'
DO
    INSERT INTO resumen_ventas_diario(fecha, total_ordenes, ingresos)
    SELECT CURDATE(), COUNT(*), COALESCE(SUM(total),0)
    FROM ventas
    WHERE DATE(fecha_venta) = CURDATE() AND estado != 'Cancelado';


-- 10) evt_check_data_consistency_nightly: Busca inconsistencias en los datos.

CREATE TABLE IF NOT EXISTS log_inconsistencias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    descripcion VARCHAR(255),
    cantidad INT,
    fecha_deteccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE EVENT IF NOT EXISTS evt_check_data_consistency_nightly
ON SCHEDULE EVERY 1 DAY
STARTS '2026-01-01 04:00:00'
DO BEGIN
    -- ventas sin detalle
    INSERT INTO log_inconsistencias(descripcion, cantidad)
    SELECT 'Ventas sin lineas de detalle', COUNT(*)
    FROM ventas v
    WHERE NOT EXISTS (SELECT 1 FROM detalle_ventas dv WHERE dv.id_venta = v.id_venta);

    -- productos con precio menor al costo (margen negativo)
    INSERT INTO log_inconsistencias(descripcion, cantidad)
    SELECT 'Productos con precio menor al costo', COUNT(*)
    FROM productos WHERE precio < costo AND activo = TRUE;
END;


-- 11) evt_send_birthday_greetings_daily: Genera lista de clientes que cumplen anios hoy.

CREATE TABLE IF NOT EXISTS lista_cumpleanios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    nombre_completo VARCHAR(200),
    email VARCHAR(100),
    fecha DATE
);

CREATE EVENT IF NOT EXISTS evt_send_birthday_greetings_daily
ON SCHEDULE EVERY 1 DAY
STARTS '2026-01-01 07:00:00'
DO BEGIN
    DELETE FROM lista_cumpleanios WHERE fecha = CURDATE();

    INSERT INTO lista_cumpleanios(id_cliente, nombre_completo, email, fecha)
    SELECT id_cliente, CONCAT(nombre,' ',apellido), email, CURDATE()
    FROM clientes
    WHERE DAY(fecha_nacimiento) = DAY(CURDATE())
    AND MONTH(fecha_nacimiento) = MONTH(CURDATE())
    AND cuenta_activa = TRUE;
END;


-- 12) evt_update_product_rankings_hourly: Actualiza una tabla con el ranking de productos mas populares.

CREATE EVENT IF NOT EXISTS evt_update_product_rankings_hourly
ON SCHEDULE EVERY 1 HOUR
DO BEGIN
    DELETE FROM ranking_productos;

    INSERT INTO ranking_productos(id_producto, nombre_producto, unidades_vendidas_mes, posicion)
    SELECT p.id_producto, p.nombre,
    SUM(dv.cantidad) AS total_vendido,
    RANK() OVER (ORDER BY SUM(dv.cantidad) DESC) AS posicion
    FROM productos p
    JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
    JOIN ventas v ON dv.id_venta = v.id_venta
    WHERE MONTH(v.fecha_venta) = MONTH(CURDATE())
    AND v.estado != 'Cancelado'
    GROUP BY p.id_producto, p.nombre;
END;


-- 13) evt_backup_critical_tables_daily: Realiza un backup logico de las tablas mas importantes.

CREATE TABLE IF NOT EXISTS backup_ventas LIKE ventas;
CREATE TABLE IF NOT EXISTS backup_clientes LIKE clientes;

CREATE EVENT IF NOT EXISTS evt_backup_critical_tables_daily
ON SCHEDULE EVERY 1 DAY
STARTS '2026-01-01 01:00:00'
DO BEGIN
    -- limpiar y volver a llenar las tablas de backup
    DELETE FROM backup_ventas;
    INSERT INTO backup_ventas SELECT * FROM ventas;

    DELETE FROM backup_clientes;
    INSERT INTO backup_clientes SELECT * FROM clientes;
END;


-- 14) evt_clear_abandoned_carts_daily: Vacia los carritos abandonados hace mas de 72 horas.

CREATE EVENT IF NOT EXISTS evt_clear_abandoned_carts_daily
ON SCHEDULE EVERY 1 DAY
STARTS '2026-01-01 05:00:00'
DO
    UPDATE ventas
    SET estado = 'Cancelado'
    WHERE estado = 'Pendiente de Pago'
    AND fecha_venta < DATE_SUB(NOW(), INTERVAL 72 HOUR);


-- 15) evt_calculate_monthly_kpis: Calcula los KPIs del mes y los guarda en una tabla.

CREATE EVENT IF NOT EXISTS evt_calculate_monthly_kpis
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-02-01 00:30:00'
DO
    INSERT INTO kpis_mensuales(anio, mes, total_ventas, ingresos_totales, ticket_promedio, nuevos_clientes)
    SELECT
        YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)),
        MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)),
        COUNT(v.id_venta),
        COALESCE(SUM(v.total), 0),
        COALESCE(AVG(v.total), 0),
        (SELECT COUNT(*) FROM clientes
         WHERE YEAR(fecha_registro) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
         AND MONTH(fecha_registro) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)))
    FROM ventas v
    WHERE YEAR(v.fecha_venta) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
    AND MONTH(v.fecha_venta) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
    AND v.estado != 'Cancelado';


-- 16) evt_refresh_materialized_views_nightly: Actualiza las vistas materializadas.

CREATE EVENT IF NOT EXISTS evt_refresh_materialized_views_nightly
ON SCHEDULE EVERY 1 DAY
STARTS '2026-01-01 02:30:00'
DO BEGIN
    -- refrescar resumen de ventas por categoria
    -- (esto seria la vista materializada)
    DELETE FROM ranking_productos;

    INSERT INTO ranking_productos(id_producto, nombre_producto, unidades_vendidas_mes, posicion)
    SELECT p.id_producto, p.nombre,
    COALESCE(SUM(dv.cantidad), 0),
    RANK() OVER (ORDER BY COALESCE(SUM(dv.cantidad), 0) DESC)
    FROM productos p
    LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
    LEFT JOIN ventas v ON dv.id_venta = v.id_venta AND v.estado != 'Cancelado'
    GROUP BY p.id_producto, p.nombre;
END;


-- 17) evt_log_database_size_weekly: Registra el tamanio de la base de datos para monitorear su crecimiento.

CREATE EVENT IF NOT EXISTS evt_log_database_size_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
    INSERT INTO log_tamano_bd(tamano_mb)
    SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2)
    FROM information_schema.tables
    WHERE table_schema = 'Ecommerce';


-- 18) evt_detect_fraudulent_activity_hourly: Busca patrones de actividad sospechosa.

CREATE TABLE IF NOT EXISTS alertas_fraude (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    descripcion VARCHAR(255),
    cantidad_pedidos INT,
    fecha_deteccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE EVENT IF NOT EXISTS evt_detect_fraudulent_activity_hourly
ON SCHEDULE EVERY 1 HOUR
DO
    INSERT INTO alertas_fraude(id_cliente, descripcion, cantidad_pedidos)
    SELECT id_cliente,
    CONCAT('Posible fraude: mas de 3 pedidos en la ultima hora'),
    COUNT(*)
    FROM ventas
    WHERE fecha_venta >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    GROUP BY id_cliente
    HAVING COUNT(*) > 3; -- umbral muy bajo, en produccion esto generaria falsos positivos


-- 19) evt_generate_supplier_performance_report_monthly: Reporte mensual de rendimiento de proveedores.

CREATE TABLE IF NOT EXISTS reporte_proveedores_mensual (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_proveedor INT,
    nombre_proveedor VARCHAR(100),
    mes INT,
    anio INT,
    productos_vendidos INT,
    ingresos_generados DECIMAL(12,2),
    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE EVENT IF NOT EXISTS evt_generate_supplier_performance_report_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-02-01 01:00:00'
DO
    INSERT INTO reporte_proveedores_mensual(id_proveedor, nombre_proveedor, mes, anio, productos_vendidos, ingresos_generados)
    SELECT prov.id_proveedor, prov.nombre,
    MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)),
    YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)),
    SUM(dv.cantidad),
    SUM(dv.cantidad * dv.precio_unitario_congelado)
    FROM proveedores prov
    JOIN productos p ON prov.id_proveedor = p.id_proveedor
    JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
    JOIN ventas v ON dv.id_venta = v.id_venta
    WHERE MONTH(v.fecha_venta) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
    AND v.estado != 'Cancelado'
    GROUP BY prov.id_proveedor, prov.nombre;


-- 20) evt_purge_soft_deleted_records_weekly: Elimina permanentemente registros marcados para borrado hace mas de 30 dias.

CREATE EVENT IF NOT EXISTS evt_purge_soft_deleted_records_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO BEGIN
    -- purgar ventas archivadas con mas de 30 dias
    DELETE FROM ventas_archivadas
    WHERE fecha_archivado < DATE_SUB(CURDATE(), INTERVAL 30 DAY);

    -- purgar logs de clientes viejos
    DELETE FROM log_clientes_nuevos
    WHERE fecha_registro < DATE_SUB(CURDATE(), INTERVAL 30 DAY);
END;