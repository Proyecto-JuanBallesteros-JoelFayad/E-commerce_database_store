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


SELECT * FROM productos p

























