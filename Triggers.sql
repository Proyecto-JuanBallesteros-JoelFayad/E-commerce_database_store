--  toco crear tablas nuevas porque si no, no se podia hacer

CREATE TABLE IF NOT EXISTS log_precios_productos (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    precio_anterior DECIMAL(10,2),
    precio_nuevo DECIMAL(10,2),
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100) DEFAULT CURRENT_USER()
);

CREATE TABLE IF NOT EXISTS log_clientes_nuevos (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    nombre_completo VARCHAR(200),
    email VARCHAR(100),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS log_cambios_estado_pedido (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    estado_anterior VARCHAR(50),
    estado_nuevo VARCHAR(50),
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alertas_stock (
    id_alerta INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    stock_actual INT,
    mensaje VARCHAR(255),
    fecha_alerta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revisada BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS ventas_archivadas (
    id_venta INT,
    id_cliente INT,
    fecha_venta DATETIME,
    estado VARCHAR(50),
    total DECIMAL(10,2),
    fecha_archivado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- tambien le agregamos columnas a clientes que algunos triggers necesitan
ALTER TABLE clientes
ADD COLUMN IF NOT EXISTS total_gastado DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS fecha_ultima_compra DATETIME,
ADD COLUMN IF NOT EXISTS fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- y a productos
ALTER TABLE productos
ADD COLUMN IF NOT EXISTS stock_minimo INT DEFAULT 5,
ADD COLUMN IF NOT EXISTS fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- y a categorias
ALTER TABLE categorias
ADD COLUMN IF NOT EXISTS total_productos INT DEFAULT 0;

-- ============================================================
-- TRIGGERS
-- ============================================================


-- 1) trg_audit_precio_producto_after_update: Guarda un log de cambios de precios.


CREATE TRIGGER trg_audit_precio_producto_after_update
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    IF OLD.precio != NEW.precio THEN
        INSERT INTO log_precios_productos(id_producto, precio_anterior, precio_nuevo)
        VALUES (OLD.id_producto, OLD.precio, NEW.precio);
    END IF;
END;


-- 2) trg_check_stock_before_insert_venta: Verifica el stock antes de registrar una venta.

CREATE TRIGGER trg_check_stock_before_insert_venta
BEFORE INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
    DECLARE stockDisponible INT;

    SELECT stock INTO stockDisponible
    FROM productos
    WHERE id_producto = NEW.id_producto;

    IF stockDisponible < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuficiente para completar la venta';
    END IF;
END;


-- 3) trg_update_stock_after_insert_venta: Decrementa el stock despues de una venta.

CREATE TRIGGER trg_update_stock_after_insert_venta
AFTER INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
    UPDATE productos
    SET stock = stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
END;


-- 4) trg_prevent_delete_categoria_with_products: Impide eliminar una categoria si tiene productos asociados.

CREATE TRIGGER trg_prevent_delete_categoria_with_products
BEFORE DELETE ON categorias
FOR EACH ROW
BEGIN
    DECLARE cantProductos INT;

    SELECT COUNT(*) INTO cantProductos
    FROM productos
    WHERE id_categoria = OLD.id_categoria;

    IF cantProductos > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar una categoria que tiene productos asociados';
    END IF;
END;


-- 5) trg_log_new_customer_after_insert: Registra en una tabla de auditoria cada vez que se crea un nuevo cliente.


CREATE TRIGGER trg_log_new_customer_after_insert
AFTER INSERT ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO log_clientes_nuevos(id_cliente, nombre_completo, email)
    VALUES (NEW.id_cliente, CONCAT(NEW.nombre,' ',NEW.apellido), NEW.email);
END;


-- 6) trg_update_total_gastado_cliente: Actualiza un campo total_gastado en la tabla clientes despues de cada compra.

CREATE TRIGGER trg_update_total_gastado_cliente
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
    UPDATE clientes
    SET total_gastado = total_gastado + NEW.total
    WHERE id_cliente = NEW.id_cliente;
END;


-- 7) trg_set_fecha_modificacion_producto: Actualiza automaticamente la fecha de ultima modificacion de un producto.

CREATE TRIGGER trg_set_fecha_modificacion_producto
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
    SET NEW.fecha_modificacion = CURRENT_TIMESTAMP;
END;


-- 8) trg_prevent_negative_stock: Impide que el stock de un producto se actualice a un valor negativo.

CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.stock < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El stock no puede ser negativo';
    END IF;
END;


-- 9) trg_capitalize_nombre_cliente: Convierte a mayuscula la primera letra del nombre y apellido al insertarlo.

CREATE TRIGGER trg_capitalize_nombre_cliente
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    SET NEW.nombre  = CONCAT(UPPER(LEFT(NEW.nombre, 1)), LOWER(SUBSTRING(NEW.nombre, 2)));
    SET NEW.apellido = CONCAT(UPPER(LEFT(NEW.apellido,1)), LOWER(SUBSTRING(NEW.apellido,2)));
    -- problema: si el nombre tiene dos palabras ej "Maria Camila" solo capitaliza la primera
    -- lo dejo asi de momento, para nombre compuesto hay que hacer split y eso es mas complikado
END;


-- 10) trg_recalculate_total_venta_on_detalle_change: Recalcula el total en la tabla ventas si se modifica un detalle_venta.

CREATE TRIGGER trg_recalculate_total_venta_on_detalle_change
AFTER UPDATE ON detalle_ventas
FOR EACH ROW
BEGIN
    UPDATE ventas
    SET total = (
        SELECT SUM(cantidad * precio_unitario_congelado)
        FROM detalle_ventas
        WHERE id_venta = NEW.id_venta
    )
    WHERE id_venta = NEW.id_venta;
END;


-- 11) trg_log_order_status_change: Audita cada cambio de estado en un pedido.

CREATE TRIGGER trg_log_order_status_change
AFTER UPDATE ON ventas
FOR EACH ROW
BEGIN
    IF OLD.estado != NEW.estado THEN
        INSERT INTO log_cambios_estado_pedido(id_venta, estado_anterior, estado_nuevo)
        VALUES (OLD.id_venta, OLD.estado, NEW.estado);
    END IF;
END;


-- 12) trg_prevent_price_zero_or_less: Impide que el precio de un producto se establezca en cero o un valor negativo.

CREATE TRIGGER trg_prevent_price_zero_or_less
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio del producto no puede ser cero ni negativo';
    END IF;
END;


-- 13) trg_send_stock_alert_on_low_stock: Inserta un registro en alertas si el stock baja de un umbral.

CREATE TRIGGER trg_send_stock_alert_on_low_stock
AFTER UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.stock <= NEW.stock_minimo AND OLD.stock > OLD.stock_minimo THEN
        INSERT INTO alertas_stock(id_producto, stock_actual, mensaje)
        VALUES (NEW.id_producto, NEW.stock,
            CONCAT('Alerta: el producto "', NEW.nombre, '" bajo del stock minimo (', NEW.stock_minimo,')'));
    END IF;
END;


-- 14) trg_archive_deleted_venta: Mueve una venta eliminada a una tabla de archivo en lugar de borrarla permanentemente.

CREATE TRIGGER trg_archive_deleted_venta
BEFORE DELETE ON ventas
FOR EACH ROW
BEGIN
    INSERT INTO ventas_archivadas(id_venta, id_cliente, fecha_venta, estado, total)
    VALUES (OLD.id_venta, OLD.id_cliente, OLD.fecha_venta, OLD.estado, OLD.total);
END;


-- 15) trg_validate_email_format_on_customer: Valida el formato del email antes de insertar o actualizar un cliente.

CREATE TRIGGER trg_validate_email_format_on_customer
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    IF NEW.email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'email invalido por favor verifique'; -- falta el trigger para UPDATE
    END IF;
END;


-- 16) trg_update_last_order_date_customer: Actualiza la fecha del ultimo pedido en la tabla clientes.

CREATE TRIGGER trg_update_last_order_date_customer
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
    UPDATE clientes
    SET fecha_ultima_compra = NEW.fecha_venta
    WHERE id_cliente = NEW.id_cliente;
END;


-- 17) trg_prevent_self_referral: Impide que un cliente se referencie a si mismo en un programa de referidos.

-- PENDIENTE - requiere tabla referidos que no esta en el esquema base
-- es de los mas dificiles porque implica cambiar el modelo de datos
/*
DELIMITER $$
CREATE TRIGGER trg_prevent_self_referral
BEFORE INSERT ON referidos
FOR EACH ROW
BEGIN
    IF NEW.id_cliente = NEW.id_cliente_referente THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un cliente no puede referenciarse a si mismo';
    END IF;
END$$
DELIMITER ;
*/


-- 18) trg_log_permission_changes: Audita los cambios en los permisos de los usuarios.

-- 19) trg_assign_default_category_on_null: Asigna una categoria "General" si se inserta un producto sin categoria.

CREATE TRIGGER trg_assign_default_category_on_null
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
    DECLARE categoriaDefault INT;

    IF NEW.id_categoria IS NULL THEN
        SELECT id_categoria INTO categoriaDefault
        FROM categorias
        WHERE nombre = 'General'
        LIMIT 1;

        SET NEW.id_categoria = categoriaDefault; -- si no existe 'General' esto queda en NULL igual
    END IF;
END;


-- 20) trg_update_producto_count_in_categoria: Mantiene un contador de cuantos productos hay en cada categoria.

CREATE TRIGGER trg_update_producto_count_in_categoria
AFTER INSERT ON productos
FOR EACH ROW
BEGIN
    UPDATE categorias
    SET total_productos = total_productos + 1
    WHERE id_categoria = NEW.id_categoria;
END;