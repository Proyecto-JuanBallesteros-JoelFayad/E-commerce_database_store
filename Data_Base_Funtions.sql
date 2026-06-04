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














