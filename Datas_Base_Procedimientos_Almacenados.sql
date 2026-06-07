-- 1) sp_RealizarNuevaVenta: Procesa una nueva venta de forma transaccional.

CREATE PROCEDURE sp_RealizarNuevaVenta(
    IN p_id_cliente INT,
    IN p_id_producto INT,
    IN p_cantidad INT
)
BEGIN
    DECLARE precioActual DECIMAL(10,2);
    DECLARE stockActual INT;
    DECLARE nuevaVentaId INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error al procesar la venta, se revirtieron los cambios' AS mensaje;
    END;

    START TRANSACTION;

        SELECT precio, stock INTO precioActual, stockActual
        FROM productos WHERE id_producto = p_id_producto FOR UPDATE;

        IF stockActual < p_cantidad THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente';
        END IF;

        INSERT INTO ventas(id_cliente, estado, total)
        VALUES(p_id_cliente, 'Procesando', 0);

        SET nuevaVentaId = LAST_INSERT_ID();

        INSERT INTO detalle_ventas(id_venta, id_producto, cantidad, precio_unitario_congelado)
        VALUES(nuevaVentaId, p_id_producto, p_cantidad, precioActual);

        UPDATE ventas
        SET total = p_cantidad * precioActual
        WHERE id_venta = nuevaVentaId;

    COMMIT;

    SELECT nuevaVentaId AS id_venta_creada, 'Venta procesada con exito' AS mensaje;
END;


-- 2) sp_AgregarNuevoProducto: Inserta un nuevo producto y sus atributos iniciales.

CREATE PROCEDURE sp_AgregarNuevoProducto(
    IN p_id_categoria INT,
    IN p_id_proveedor INT,
    IN p_nombre VARCHAR(50),
    IN p_descripcion TEXT,
    IN p_precio DECIMAL(10,2),
    IN p_costo DECIMAL(10,2),
    IN p_sku VARCHAR(20),
    IN p_peso_kg DECIMAL(8,2)
)
BEGIN
    IF p_precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio debe ser mayor a cero';
    END IF;

    IF p_costo < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El costo no puede ser negativo';
    END IF;

    INSERT INTO productos(id_categoria, id_proveedor, nombre, descripcion, precio, costo, sku, activo, peso_kg)
    VALUES(p_id_categoria, p_id_proveedor, p_nombre, p_descripcion, p_precio, p_costo, p_sku, TRUE, p_peso_kg);

    SELECT LAST_INSERT_ID() AS id_producto_creado, 'Producto agregado correctamente' AS mensaje;
END;


-- 3) sp_ActualizarDireccionCliente: Actualiza la direccion de un cliente.

CREATE PROCEDURE sp_ActualizarDireccionCliente(
    IN p_id_cliente INT,
    IN p_nueva_direccion VARCHAR(255)
)
BEGIN
    DECLARE clienteExiste INT;

    SELECT COUNT(*) INTO clienteExiste FROM clientes WHERE id_cliente = p_id_cliente;

    IF clienteExiste = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no existe';
    END IF;

    UPDATE clientes
    SET direccion_envio = p_nueva_direccion
    WHERE id_cliente = p_id_cliente;

    SELECT 'Direccion actualizada correctamente' AS mensaje;
END;


-- 4) sp_ProcesarDevolucion: Gestiona la devolucion de un producto, ajustando el stock y generando un credito.

CREATE PROCEDURE sp_ProcesarDevolucion(
    IN p_id_venta INT,
    IN p_id_producto INT,
    IN p_cantidad_devuelta INT
)
BEGIN
    DECLARE precioCongelado DECIMAL(10,2);
    DECLARE montoCredito DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error al procesar devolucion' AS mensaje;
    END;

    START TRANSACTION;

        SELECT precio_unitario_congelado INTO precioCongelado
        FROM detalle_ventas
        WHERE id_venta = p_id_venta AND id_producto = p_id_producto;

        SET montoCredito = precioCongelado * p_cantidad_devuelta;

        -- devolver stock
        UPDATE productos SET stock = stock + p_cantidad_devuelta
        WHERE id_producto = p_id_producto;

        -- cambiar estado de la venta
        UPDATE ventas SET estado = 'Cancelado' WHERE id_venta = p_id_venta;

        -- aqui deberia insertar el credito en una tabla wallet_clientes pero no existe
        -- INSERT INTO creditos_clientes (...) VALUES (...);  -- PENDIENTE

    COMMIT;

    SELECT montoCredito AS credito_generado, 'Devolucion procesada, stock restaurado' AS mensaje;
END;


-- 5) sp_ObtenerHistorialComprasCliente: Devuelve el historial completo de compras de un cliente.


CREATE PROCEDURE sp_ObtenerHistorialComprasCliente(
    IN p_id_cliente INT
)
BEGIN
    SELECT v.id_venta, v.fecha_venta, v.estado, v.total,
    p.nombre AS producto,  dv.cantidad, dv.precio_unitario_congelado,
    (dv.cantidad * dv.precio_unitario_congelado) AS subtotal
    FROM ventas v
    INNER JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
    INNER JOIN productos p ON dv.id_producto = p.id_producto
    WHERE v.id_cliente = p_id_cliente
    ORDER BY v.fecha_venta DESC;
END;

CALL sp_ObtenerHistorialComprasCliente(1);


-- 6) sp_AjustarNivelStock: Permite ajustar manualmente el stock de un producto, registrando el motivo.


CREATE PROCEDURE sp_AjustarNivelStock(
    IN p_id_producto INT,
    IN p_nuevo_stock INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    IF p_nuevo_stock < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El stock no puede ser negativo';
    END IF;

    UPDATE productos
    SET stock = p_nuevo_stock
    WHERE id_producto = p_id_producto;

    -- idealmente registrariamos esto en un log de ajustes de inventario
    SELECT CONCAT('Stock ajustado. Motivo: ', p_motivo) AS mensaje;
END;


-- 7) sp_EliminarClienteDeFormaSegura: Anonimiza los datos de un cliente en lugar de borrarlos.


CREATE PROCEDURE sp_EliminarClienteDeFormaSegura(
    IN p_id_cliente INT
)
BEGIN
    UPDATE clientes
    SET
        nombre = 'ANONIMIZADO',
        apellido = 'ANONIMIZADO',
        email = CONCAT('anonimo_', p_id_cliente, '@eliminado.com'),
        password_hash = 'ELIMINADO',
        direccion_envio = NULL
    WHERE id_cliente = p_id_cliente;

    SELECT 'Cliente anonimizado correctamente, historial de ventas intacto' AS mensaje;
END;


-- 8) sp_AplicarDescuentoPorCategoria: Aplica un descuento a todos los productos de una categoria.

CREATE PROCEDURE sp_AplicarDescuentoPorCategoria(
    IN p_id_categoria INT,
    IN p_porcentaje_descuento DECIMAL(5,2)
)
BEGIN
    IF p_porcentaje_descuento <= 0 OR p_porcentaje_descuento >= 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El descuento debe estar entre 0 y 100';
    END IF;

    UPDATE productos
    SET precio = ROUND(precio - (precio * p_porcentaje_descuento / 100), 2)
    WHERE id_categoria = p_id_categoria AND activo = TRUE;

    SELECT ROW_COUNT() AS productos_actualizados, 'Descuento aplicado' AS mensaje;
END;


-- 9) sp_GenerarReporteMensualVentas: Genera un reporte de ventas para un mes y anio dados.

CREATE PROCEDURE sp_GenerarReporteMensualVentas(
    IN p_anio INT,
    IN p_mes INT
)
BEGIN
    SELECT
        p.nombre AS producto,
        c.nombre AS categoria,
        SUM(dv.cantidad) AS unidades_vendidas,
        SUM(dv.cantidad * dv.precio_unitario_congelado) AS ingresos,
        SUM(dv.cantidad * p.costo) AS costo_total,
        SUM(dv.cantidad * (dv.precio_unitario_congelado - p.costo)) AS ganancia
    FROM ventas v
    INNER JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
    INNER JOIN productos p ON dv.id_producto = p.id_producto
    INNER JOIN categorias c ON p.id_categoria = c.id_categoria
    WHERE YEAR(v.fecha_venta) = p_anio
    AND MONTH(v.fecha_venta) = p_mes
    AND v.estado != 'Cancelado'
    GROUP BY p.id_producto, p.nombre, c.nombre
    ORDER BY ingresos DESC;
END;

CALL sp_GenerarReporteMensualVentas(2026, 5);


-- 10) sp_CambiarEstadoPedido: Cambia el estado de un pedido y registra el cambio.

CREATE PROCEDURE sp_CambiarEstadoPedido(
    IN p_id_venta INT,
    IN p_nuevo_estado VARCHAR(50)
)
BEGIN
    DECLARE estadoActual VARCHAR(50);

    SELECT estado INTO estadoActual FROM ventas WHERE id_venta = p_id_venta;

    IF estadoActual IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Venta no encontrada';
    END IF;

    -- no permitir volver atras en el flujo si ya fue entregado
    IF estadoActual = 'Entregado' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede cambiar el estado de un pedido ya entregado';
    END IF;

    UPDATE ventas SET estado = p_nuevo_estado WHERE id_venta = p_id_venta;

    SELECT CONCAT('Estado cambiado de "', estadoActual, '" a "', p_nuevo_estado, '"') AS mensaje;
END;


-- 11) sp_RegistrarNuevoCliente: Registra un nuevo cliente validando que el email no exista.

CREATE PROCEDURE sp_RegistrarNuevoCliente(
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_password_hash VARCHAR(255),
    IN p_direccion VARCHAR(255)
)
BEGIN
    DECLARE emailExiste INT;

    SELECT COUNT(*) INTO emailExiste FROM clientes WHERE email = p_email;

    IF emailExiste > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ya existe un cliente registrado con ese email';
    END IF;

    INSERT INTO clientes(nombre, apellido, email, password_hash, direccion_envio)
    VALUES(p_nombre, p_apellido, p_email, p_password_hash, p_direccion);

    SELECT LAST_INSERT_ID() AS id_cliente_creado, 'Cliente registrado con exito' AS mensaje;
END

-- 12) sp_ObtenerDetallesProductoCompleto: Devuelve toda la info de un producto con proveedor y categoria.

CREATE PROCEDURE sp_ObtenerDetallesProductoCompleto(
    IN p_id_producto INT
)
BEGIN
    SELECT p.*, c.nombre AS nombre_categoria, c.descripcion AS descripcion_categoria,
    prov.nombre AS nombre_proveedor, prov.email_contacto, prov.telefono_contacto
    FROM productos p
    LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
    LEFT JOIN proveedores prov ON p.id_proveedor = prov.id_proveedor
    WHERE p.id_producto = p_id_producto;
END;

CALL sp_ObtenerDetallesProductoCompleto(1);


-- 13) sp_FusionarCuentasCliente: Fusiona dos cuentas de cliente duplicadas en una sola.

CREATE PROCEDURE sp_FusionarCuentasCliente(
    IN p_id_cliente_principal INT,
    IN p_id_cliente_duplicado INT
)
BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error al fusionar clientes' AS mensaje;
    END;

    START TRANSACTION;

        -- reasignar todas las ventas del duplicado al principal
        UPDATE ventas
        SET id_cliente = p_id_cliente_principal
        WHERE id_cliente = p_id_cliente_duplicado;

        -- actualizar el total gastado del principal sumando el del duplicado
        UPDATE clientes c1
        JOIN clientes c2 ON c2.id_cliente = p_id_cliente_duplicado
        SET c1.total_gastado = c1.total_gastado + c2.total_gastado
        WHERE c1.id_cliente = p_id_cliente_principal;

        -- anonimizar la cuenta duplicada
        CALL sp_EliminarClienteDeFormaSegura(p_id_cliente_duplicado);

    COMMIT;

    SELECT 'Cuentas fusionadas correctamente' AS mensaje;
END;


-- 14) sp_AsignarProductoAProveedor: Asigna o cambia el proveedor de un producto.

CREATE PROCEDURE sp_AsignarProductoAProveedor(
    IN p_id_producto INT,
    IN p_id_proveedor INT
)
BEGIN
    DECLARE proveedorExiste INT;

    SELECT COUNT(*) INTO proveedorExiste FROM proveedores WHERE id_proveedor = p_id_proveedor;

    IF proveedorExiste = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El proveedor no existe';
    END IF;

    UPDATE productos SET id_proveedor = p_id_proveedor WHERE id_producto = p_id_producto;

    SELECT 'Proveedor asignado correctamente' AS mensaje;
END;


-- 15) sp_BuscarProductos: Realiza una busqueda avanzada de productos con filtros.

CREATE PROCEDURE sp_BuscarProductos(
    IN p_nombre VARCHAR(50),
    IN p_id_categoria INT,
    IN p_precio_min DECIMAL(10,2),
    IN p_precio_max DECIMAL(10,2)
)
BEGIN
    SELECT p.id_producto, p.nombre, p.descripcion, p.precio, p.stock, p.sku,
    c.nombre AS categoria
    FROM productos p
    LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
    WHERE p.activo = TRUE
    AND (p_nombre IS NULL OR p.nombre LIKE CONCAT('%', p_nombre, '%'))
    AND (p_id_categoria IS NULL OR p.id_categoria = p_id_categoria)
    AND (p_precio_min IS NULL OR p.precio >= p_precio_min)
    AND (p_precio_max IS NULL OR p.precio <= p_precio_max)
    ORDER BY p.nombre;
END;

CALL sp_BuscarProductos(NULL, 1, NULL, NULL);


-- 16) sp_ObtenerDashboardAdmin: Devuelve KPIs para un panel de administracion.


CREATE PROCEDURE sp_ObtenerDashboardAdmin()
BEGIN
    -- ventas de hoy
    SELECT COUNT(*) AS ventas_hoy, COALESCE(SUM(total),0) AS ingresos_hoy
    FROM ventas
    WHERE DATE(fecha_venta) = CURDATE() AND estado != 'Cancelado';

    -- nuevos clientes hoy
    SELECT COUNT(*) AS nuevos_clientes_hoy
    FROM clientes
    WHERE DATE(fecha_registro) = CURDATE();

    -- productos con stock bajo
    SELECT COUNT(*) AS productos_stock_bajo
    FROM productos
    WHERE stock <= stock_minimo AND activo = TRUE;

    -- top 3 productos del mes
    SELECT p.nombre, SUM(dv.cantidad) AS vendidos_mes
    FROM detalle_ventas dv
    JOIN ventas v ON dv.id_venta = v.id_venta
    JOIN productos p ON dv.id_producto = p.id_producto
    WHERE MONTH(v.fecha_venta) = MONTH(CURDATE())
    AND v.estado != 'Cancelado'
    GROUP BY p.id_producto, p.nombre
    ORDER BY vendidos_mes DESC
    LIMIT 3;
END;

CALL sp_ObtenerDashboardAdmin();


-- 17) sp_ProcesarPago: Simula el procesamiento de un pago para una venta.

CREATE PROCEDURE sp_ProcesarPago(
    IN p_id_venta INT
)
BEGIN
    DECLARE estadoVenta VARCHAR(50);

    SELECT estado INTO estadoVenta FROM ventas WHERE id_venta = p_id_venta;

    IF estadoVenta != 'Pendiente de Pago' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La venta no esta en estado pendiente de pago';
    END IF;

    -- ERROR: 'Pagado' no existe en el ENUM, esto falla
    UPDATE ventas SET estado = 'Pagado' WHERE id_venta = p_id_venta;

    SELECT 'Pago procesado' AS mensaje;
END;


-- 18) sp_AñadirReseñaProducto: Permite a un cliente añadir una reseña a un producto que ha comprado.


CREATE TABLE IF NOT EXISTS resenas_productos (
    id_resena INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NOT NULL,
    id_cliente INT NOT NULL,
    calificacion TINYINT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    comentario TEXT,
    fecha_resena TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE PROCEDURE sp_AnadirResenaProducto(
    IN p_id_cliente INT,
    IN p_id_producto INT,
    IN p_calificacion TINYINT,
    IN p_comentario TEXT
)
BEGIN
    DECLARE haComprado INT;

    SELECT COUNT(*) INTO haComprado
    FROM ventas v
    INNER JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
    WHERE v.id_cliente = p_id_cliente
    AND dv.id_producto = p_id_producto
    AND v.estado = 'Entregado';

    IF haComprado = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no ha comprado este producto o el pedido no fue entregado';
    END IF;

    IF p_calificacion NOT BETWEEN 1 AND 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La calificacion debe ser entre 1 y 5';
    END IF;

    INSERT INTO resenas_productos(id_producto, id_cliente, calificacion, comentario)
    VALUES(p_id_producto, p_id_cliente, p_calificacion, p_comentario);

    SELECT 'Resena agregada correctamente' AS mensaje;
END;


-- 19) sp_ObtenerProductosRelacionados: Devuelve productos relacionados basandose en compras de otros clientes.

CREATE PROCEDURE sp_ObtenerProductosRelacionados(
    IN p_id_producto INT,
    IN p_limite INT
)
BEGIN
    SELECT p.id_producto, p.nombre, p.precio,
    COUNT(*) AS veces_comprado_junto
    FROM detalle_ventas dv1
    JOIN detalle_ventas dv2 ON dv1.id_venta = dv2.id_venta
        AND dv2.id_producto != p_id_producto
    JOIN productos p ON dv2.id_producto = p.id_producto
    WHERE dv1.id_producto = p_id_producto
    AND p.activo = TRUE
    GROUP BY p.id_producto, p.nombre, p.precio
    ORDER BY veces_comprado_junto DESC
    LIMIT p_limite;
END;

CALL sp_ObtenerProductosRelacionados(1, 5);


-- 20) sp_MoverProductosEntreCategorias: Mueve uno o mas productos de una categoria a otra de forma segura.

CREATE PROCEDURE sp_MoverProductosEntreCategorias(
    IN p_id_categoria_origen INT,
    IN p_id_categoria_destino INT
)
BEGIN
    DECLARE categoriaDestinoExiste INT;
    DECLARE productosMovidos INT;

    SELECT COUNT(*) INTO categoriaDestinoExiste
    FROM categorias WHERE id_categoria = p_id_categoria_destino;

    IF categoriaDestinoExiste = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La categoria destino no existe';
    END IF;

    UPDATE productos
    SET id_categoria = p_id_categoria_destino
    WHERE id_categoria = p_id_categoria_origen;

    SET productosMovidos = ROW_COUNT();

    SELECT productosMovidos AS productos_movidos, 'Productos movidos correctamente' AS mensaje;
END;