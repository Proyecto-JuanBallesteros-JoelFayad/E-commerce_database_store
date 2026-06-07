-- 1) fn_CalcularTotalVenta: Calcula el monto total de una venta específica.


CREATE FUNCTION	 fn_CalcularTotalVenta(
	p_id_venta INT	
)

RETURNS DECIMAL(10,2)

DETERMINISTIC

BEGIN
	DECLARE	 total  DECIMAL(10,2);
	SELECT SUM(cantidad * precio_unitario_congelado) INTO total FROM detalle_ventas
	WHERE id_venta = p_id_venta;

	RETURN total;
END;

SELECT fn_CalcularTotalVenta(1);

-- 2) fn_VerificarDisponibilidadStock: Valida si hay stock suficiente para un producto.

CREATE FUNCTION fn_VerificarDisponibilidadStock(
    p_id_producto INT,
    cantidad_solicitada INT
)
RETURNS BOOLEAN

DETERMINISTIC

BEGIN

    DECLARE stockDisponible INT;

    SELECT stock
    INTO stockDisponible
    FROM productos
    WHERE id_producto = p_id_producto;

    RETURN stockDisponible >= cantidad_solicitada;

END;

SELECT fn_VerificarDisponibilidadStock(1, 5);

-- 3) fn_ObtenerPrecioProducto: Devuelve el precio actual de un producto.

CREATE FUNCTION fn_ObtenerPrecioProducto(
    p_id_producto INT
)
RETURNS DECIMAL(10,2)

DETERMINISTIC

BEGIN

    DECLARE precioProducto INT;

    SELECT precio
    INTO precioProducto
    FROM productos
    WHERE id_producto = p_id_producto;

    RETURN precioProducto;

END;

SELECT fn_ObtenerPrecioProducto(2)

-- 4) fn_CalcularEdadCliente: Calcula la edad de un cliente a partir de su fecha de nacimiento.

CREATE FUNCTION fn_CalcularEdadCliente2(
    p_id_cliente INT
)
RETURNS INT

DETERMINISTIC

BEGIN

    DECLARE edadCliente INT;

    SELECT TIMESTAMPDIFF(
    	YEAR,
    	fecha_naciminto,
    	CURDATE()
	)
    INTO edadCliente
    FROM clientes c
    WHERE id_cliente = p_id_cliente;

    RETURN edadCliente;

END;

SELECT fn_CalcularEdadCliente2(1);

-- 5) fn_FormatearNombreCompleto: Devuelve el nombre y apellido de un cliente en un formato estandarizado.

CREATE FUNCTION fn_FormatearNombreCompleto(
	p_id_cliente INT
)
RETURNS VARCHAR(100)

DETERMINISTIC

BEGIN

    DECLARE nombreCompleto VARCHAR(100);

    SELECT CONCAT(nombre, " ", apellido)
    INTO nombreCompleto
    FROM clientes c
    WHERE id_cliente = p_id_cliente;

    RETURN nombreCompleto;

END;

SELECT fn_FormatearNombreCompleto(1);

-- 6) fn_EsClienteNuevo: Devuelve VERDADERO si un cliente realizó su primera compra en los últimos 30 días.

CREATE FUNCTION fn_EsClienteNuevo2(
    p_id_cliente INT
)
RETURNS BOOLEAN

DETERMINISTIC

BEGIN

    DECLARE diasCliente INT;

    SELECT TIMESTAMPDIFF(
    	DAY,
    	MIN(fecha_venta) ,
    	CURDATE()
	)
    INTO diasCliente
    FROM  ventas v
    WHERE id_cliente = p_id_cliente;

    RETURN diasCliente <= 30;

END;

SELECT fn_EsClienteNuevo(2);

-- 7) fn_CalcularCostoEnvio: Calcula el costo de envío basado en el peso total de los productos de una venta.

CREATE FUNCTION fn_CalcularCostoEnvio3(
	p_id_venta INT
)
RETURNS DECIMAL(10,2)

DETERMINISTIC

BEGIN
	DECLARE pesoEnvio DECIMAL(10,2);
	DECLARE costoEnvio DECIMAL(10,2);
	
	SELECT
		SUM(dv.cantidad * p.peso_kg) 
	INTO pesoEnvio
	FROM detalle_ventas dv
	inner join productos p on p.id_producto = dv.id_producto
	WHERE dv.id_venta = p_id_venta
	group by id_venta;
	
	IF pesoEnvio <= 1 THEN
    	SET costoEnvio = 10000;
	ELSEIF pesoEnvio <= 5 THEN
    	SET costoEnvio = 20000;
	ELSEIF pesoEnvio <= 10 THEN
    	SET costoEnvio = 35000;
	ELSE
    	SET costoEnvio = 50000;
	END IF;

	RETURN costoEnvio;

END;

SELECT fn_CalcularCostoEnvio3(13)

-- 8) fn_AplicarDescuento: Aplica un porcentaje de descuento a un monto dado.

CREATE FUNCTION fn_AplicarDescuento2(
    monto DECIMAL(10,2),
    descuento DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)

DETERMINISTIC

BEGIN

    RETURN monto - (monto * descuento);

END;

SELECT fn_AplicarDescuento2(1000,0.2);

-- 9) fn_ObtenerUltimaFechaCompra: Devuelve la fecha de la última compra de un cliente.

CREATE FUNCTION fn_ObtenerUltimaFechaCompra(
    p_id_cliente INT
)
RETURNS DATETIME

DETERMINISTIC

BEGIN

    DECLARE fechaCompra DATETIME;

    SELECT MAX(v.fecha_venta)
    INTO fechaCompra
    FROM  ventas v
    WHERE id_cliente = p_id_cliente;

    RETURN fechaCompra;

END;

SELECT fn_ObtenerUltimaFechaCompra(1);

-- 10) fn_ValidarFormatoEmail: Comprueba si una cadena de texto tiene un formato de correo electrónico válido.

CREATE FUNCTION	 fn_ValidarFormatoEmail2(
	p_email VARCHAR(100)	
)

RETURNS BOOLEAN

DETERMINISTIC

BEGIN

	RETURN p_email REGEXP
    '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';

END;

SELECT fn_ValidarFormatoEmail2("manuelita@gmail.com");

-- 11) fn_ObtenerNombreCategoria: Devuelve el nombre de la categoría a partir del ID de un producto.

CREATE FUNCTION fn_ObtenerNombreCategoria(
	p_id_producto INT
)
RETURNS VARCHAR(100)

DETERMINISTIC

BEGIN
	DECLARE categoriaName VARCHAR(100);
	
	SELECT
		c.nombre
	INTO categoriaName
	FROM productos p
	INNER JOIN categorias c ON p.id_categoria = c.id_categoria
	WHERE p.id_producto = p_id_producto;

	RETURN categoriaName;

END;

SELECT fn_ObtenerNombreCategoria(2);

-- 12) fn_ContarVentasCliente: Cuenta el número total de compras realizadas por un cliente.

CREATE FUNCTION fn_ContarVentasCliente(
    p_id_cliente INT
)
RETURNS INT

DETERMINISTIC

BEGIN

    DECLARE ventasNum INT;

    SELECT COUNT(*) 
    INTO ventasNum
    FROM  ventas v
    WHERE id_cliente = p_id_cliente;

    RETURN ventasNum;

END;

SELECT fn_ContarVentasCliente(1);

-- 13) fn_CalcularDiasDesdeUltimaCompra: Devuelve el número de días transcurridos desde la última compra de un cliente.

CREATE FUNCTION fn_CalcularDiasDesdeUltimaCompra2(
    p_id_cliente INT
)
RETURNS INT

DETERMINISTIC

BEGIN

    DECLARE fechaCompra INT;

    SELECT TIMESTAMPDIFF(
    	DAY,
    	MAX(v.fecha_venta),
    	CURDATE()
	)
    INTO fechaCompra
    FROM  ventas v
    WHERE v.id_cliente = p_id_cliente;

    RETURN fechaCompra;

END;

SELECT * FROM ventas v

SELECT fn_CalcularDiasDesdeUltimaCompra2(2);

-- 14) fn_DeterminarEstadoLealtad: Asigna un estado de lealtad (Bronce, Plata, Oro) a un cliente según su gasto total.

CREATE FUNCTION fn_DeterminarEstadoLealtad2(
    p_id_cliente INT
)
RETURNS VARCHAR(100)

DETERMINISTIC

BEGIN

    DECLARE gastoTotal DECIMAL(10,2);
    DECLARE estadoLealtad VARCHAR(100);

    SELECT COALESCE(SUM(total),0)
    INTO gastoTotal
    FROM ventas
    WHERE id_cliente = p_id_cliente;

    IF gastoTotal < 500000 THEN
        SET estadoLealtad = 'Bronce';
    ELSEIF gastoTotal < 2000000 THEN
        SET estadoLealtad = 'Plata';
    ELSE
        SET estadoLealtad = 'Oro';
    END IF;

    RETURN estadoLealtad;

END;

SELECT fn_DeterminarEstadoLealtad2(13)

-- 15) fn_GenerarSKU: Genera un código de producto (SKU) único basado en su nombre y categoría.


CREATE FUNCTION fn_GenerarSKU(
    p_id_producto INT
)
RETURNS VARCHAR(20)

DETERMINISTIC

BEGIN

    DECLARE nombreProducto VARCHAR(50);
    DECLARE nombreCategoria VARCHAR(100);
    DECLARE skuGenerado VARCHAR(20);

    SELECT p.nombre, c.nombre
    INTO nombreProducto, nombreCategoria
    FROM productos p
    INNER JOIN categorias c ON c.id_categoria = p.id_categoria
    WHERE p.id_producto = p_id_producto;

    SET skuGenerado = CONCAT(
        UPPER(LEFT(nombreProducto,3)),
        '-',
        UPPER(LEFT(nombreCategoria,3)),
        '-',
        p_id_producto
    );

    RETURN skuGenerado;

END;

SELECT fn_GenerarSKU(1);

-- 16) fn_CalcularIVA: Calcula el impuesto (IVA) sobre el total de una venta.

CREATE FUNCTION fn_CalcularIVA(
	p_id_venta INT
)
RETURNS DECIMAL(10,2)

DETERMINISTIC

BEGIN
	DECLARE precioTotal DECIMAL(10,2);
	
	SELECT
		SUM(dv.cantidad * p.costo) 
	INTO precioTotal
	FROM detalle_ventas dv
	INNER JOIN productos p ON p.id_producto = dv.id_producto
	WHERE dv.id_venta = p_id_venta
	GROUP BY id_venta;

	RETURN precioTotal + (precioTotal * 0.19);

END;

SELECT fn_CalcularIVA(13);

-- 17) fn_ObtenerStockTotalPorCategoria: Suma el stock de todos los productos de una categoria.

CREATE FUNCTION fn_ObtenerStockTotalPorCategoria(
    p_id_categoria INT
)
RETURNS INT

DETERMINISTIC

BEGIN

    DECLARE stockTotal INT;

    SELECT COALESCE(SUM(stock), 0)
    INTO stockTotal
    FROM productos
    WHERE id_categoria = p_id_categoria;

    RETURN stockTotal;

END;

SELECT fn_ObtenerStockTotalPorCategoria(1);

-- 18) fn_EstimarFechaEntrega: Calcula la fecha estimada de entrega de un pedido segun la ubicacion del cliente.

CREATE FUNCTION fn_EstimarFechaEntrega2(
    p_id_venta INT
)
RETURNS DATE

DETERMINISTIC

BEGIN
    DECLARE diasEntrega INT;
    DECLARE ciudadCliente VARCHAR(100);

    SELECT TRIM(SUBSTRING_INDEX(c.direccion_envio, ',',-1))
    INTO ciudadCliente
    FROM ventas v
    INNER JOIN clientes c ON c.id_cliente = v.id_cliente
    WHERE v.id_venta = p_id_venta;

    IF ciudadCliente LIKE '%Bucaramanga%' THEN
        SET diasEntrega = 2;
    ELSEIF ciudadCliente LIKE '%Bogota%' OR ciudadCliente LIKE '%Bogotá%' THEN
        SET diasEntrega = 3;
    ELSEIF ciudadCliente LIKE '%Medellin%' OR ciudadCliente LIKE '%Medellín%' THEN
        SET diasEntrega = 4;
    ELSE
        SET diasEntrega = 7;
    END IF;

    RETURN DATE_ADD(CURDATE(), INTERVAL diasEntrega DAY);

END;

SELECT fn_EstimarFechaEntrega2(13);

-- 19) fn_ConvertirMoneda: Convierte un monto a otra moneda usando una tasa de cambio fija.

CREATE FUNCTION fn_ConvertirMoneda(
    monto DECIMAL(10,2),
    moneda_destino VARCHAR(10)
)
RETURNS  DECIMAL(10,2)

DETERMINISTIC

BEGIN

    DECLARE tasaCambio  DECIMAL(10,4);

    -- tasas fijas al momento de hacer esto, igual esto deberia venir de una tabla
    IF moneda_destino = 'USD' THEN
        SET tasaCambio = 0.00025;
    ELSEIF moneda_destino = 'EUR' THEN
        SET tasaCambio = 0.00023;
    ELSEIF moneda_destino = 'MXN' THEN
        SET tasaCambio = 0.0042;
    ELSE
        SET tasaCambio = 1; -- si no reconoce la moneda devuelve lo mismo
    END IF;

    RETURN ROUND(monto * tasaCambio, 2);

END;

SELECT fn_ConvertirMoneda(120000, 'USD');

-- 20) fn_ValidarComplejidadContraseña: Verifica si una contraseña cumple con los criterios de seguridad (longitud, caracteres, etc.)

CREATE FUNCTION fn_ValidarComplejidadContrasena(
    p_contrasena VARCHAR(255)
)
RETURNS BOOLEAN

DETERMINISTIC

BEGIN
    DECLARE esValida BOOLEAN DEFAULT FALSE;

    IF LENGTH(p_contrasena) >= 8
        AND p_contrasena REGEXP '[0-9]'
        AND p_contrasena REGEXP '[a-z]'
        AND p_contrasena REGEXP '[A-Z]'
    THEN
        SET esValida = TRUE;
    END IF;

    RETURN esValida;

END;

SELECT fn_ValidarComplejidadContrasena('MiClave123');