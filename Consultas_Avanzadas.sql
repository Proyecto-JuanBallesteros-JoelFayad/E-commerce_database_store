/*1 Top 10 Productos Más Vendidos: Generar un ranking con los 10 productos que han generado más ingresos.*/

SELECT p.id_producto, p.nombre, SUM(dv.cantidad * dv.precio_unitario_congelado) as Total_generado
FROM productos p
JOIN detalle_ventas dv on p.id_producto = dv.id_producto
JOIN ventas v on v.id_venta = dv.id_venta
WHERE v.estado ='Entregado'
GROUP BY p.id_producto, p.nombre
ORDER BY Total_generado DESC
LIMIT 10;


/*3 Clientes VIP: Listar los 5 clientes con el mayor valor de vida (LTV), basado en su gasto total histórico.*/
SELECT c.id_cliente,CONCAT(c.nombre, ' ', c.apellido) AS cliente, c.email, SUM(v.total) AS total_historico
FROM clientes c
JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.estado != 'Cancelado'
GROUP BY c.id_cliente, c.nombre, c.apellido, c.email
ORDER BY total_historico DESC
LIMIT 5;

/*4 Análisis de Ventas Mensuales: Mostrar las ventas totales agrupadas por mes y año*/

SELECT YEAR(fecha_venta) AS anio, MONTH(fecha_venta) AS mes, COUNT(id_venta) AS total_pedidos, SUM(total) AS ingresos_mensuales
FROM ventas
WHERE estado != 'Cancelado'
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY anio DESC, mes DESC;

/*5 Crecimiento de Clientes: Calcular el número de nuevos clientes registrados por trimestre. */

SELECT YEAR(fecha_registro) AS anio, QUARTER(fecha_registro) AS trimestre, COUNT(id_cliente) AS nuevos_clientes
FROM clientes
GROUP BY YEAR(fecha_registro), QUARTER(fecha_registro)
ORDER BY anio DESC, trimestre DESC;

/*6 Tasa de Compra Repetida: Determinar qué porcentaje de clientes ha realizado más de una compra.*/
WITH VentasPorCliente AS (
SELECT id_cliente, COUNT(id_venta) AS total_compras
FROM ventas
WHERE estado != 'Cancelado'
GROUP BY id_cliente
)
SELECT COUNT(CASE WHEN total_compras > 1 THEN 1 END) AS clientes_recurrentes,COUNT(*) AS total_clientes_compradores,
CONCAT(ROUND((COUNT(CASE WHEN total_compras > 1 THEN 1 END) / COUNT(*)) * 100, 2),'%') AS tasa_compra_repetida_porcentaje
FROM VentasPorCliente;

/*7 Productos Comprados Juntos Frecuentemente: Identificar pares de productos que a menudo se compran en la misma transacción.*/

SELECT p1.nombre AS producto_a, p2.nombre AS producto_b,  COUNT(*) AS veces_comprados_juntos
FROM detalle_ventas dv1
JOIN detalle_ventas dv2 ON dv1.id_venta = dv2.id_venta AND dv1.id_producto < dv2.id_producto
JOIN productos p1 ON dv1.id_producto = p1.id_producto
JOIN productos p2 ON dv2.id_producto = p2.id_producto
GROUP BY p1.nombre, p2.nombre
ORDER BY veces_comprados_juntos DESC;

/*9 Productos que Necesitan Reabastecimiento: Listar productos cuyo stock actual está por debajo de su umbral mínimo.*/

SELECT id_producto, nombre, sku, stock, stock_minimo 
FROM productos 
WHERE stock <= stock_minimo;

/*10 Análisis de Carrito Abandonado (Simulado): Identificar clientes que agregaron productos pero no completaron una venta en un período determinado.*/

SELECT c.id_cliente, CONCAT(c.nombre, ' ', c.apellido) AS cliente, c.email, v.id_venta AS id_orden_abandonada, v.fecha_venta, v.estado, v.total AS monto_abandonado
FROM clientes c
JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.estado IN ('Pendiente de Pago', 'Cancelado') AND NOT EXISTS (
 SELECT 1 
 FROM ventas v2 
 WHERE v2.id_cliente = c.id_cliente 
 AND v2.estado IN ('Procesando', 'Enviado', 'Entregado')
 AND v2.fecha_venta > v.fecha_venta)
ORDER BY v.fecha_venta DESC;

/*11 Rendimiento de Proveedores: Clasificar a los proveedores según el volumen de ventas de sus productos.*/

SELECT prov.id_proveedor, prov.nombre AS proveedor, prov.email_contacto, COUNT(DISTINCT dv.id_producto) AS catalogo_vendido, SUM(dv.cantidad) AS total_unidades_surtidas,
SUM(dv.cantidad * dv.precio_unitario_congelado) AS ingresos_generados
FROM proveedores prov
JOIN productos prod ON prov.id_proveedor = prod.id_proveedor
JOIN detalle_ventas dv ON prod.id_producto = dv.id_producto
JOIN ventas v ON dv.id_venta = v.id_venta
WHERE v.estado != 'Cancelado'
GROUP BY prov.id_proveedor, prov.nombre, prov.email_contacto
ORDER BY ingresos_generados DESC;

/*12 Análisis Geográfico de Ventas: Agrupar las ventas por ciudad o región del cliente.*/

SELECT TRIM(SUBSTRING_INDEX(direccion_envio, ',', -1)) AS ciudad_region, COUNT(DISTINCT c.id_cliente) AS clientes_unicos, COUNT(v.id_venta) AS volumen_pedidos,
SUM(v.total) AS facturacion_total
FROM clientes c
INNER JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.estado != 'Cancelado' AND c.direccion_envio IS NOT NULL
GROUP BY ciudad_region
ORDER BY facturacion_total DESC;

/*13 Ventas por Hora del Día: Determinar las horas pico de compras para optimizar campañas de marketing.*/

SELECT HOUR(fecha_venta) AS hora_del_dia, COUNT(id_venta) AS cantidad_transacciones, SUM(total) AS dinero_recaudado
FROM ventas
WHERE estado != 'Cancelado'
GROUP BY HOUR(fecha_venta)
ORDER BY hora_del_dia ASC;

/*14 Impacto de Promociones: Comparar las ventas de un producto antes, durante y después de una campaña de descuento*/
/*Antes de la promocion*/
SELECT p.nombre AS producto, SUM(CASE WHEN v.fecha_venta < '2026-05-01 00:00:00' THEN dv.cantidad ELSE 0 END) AS unidades_antes,
SUM(CASE WHEN v.fecha_venta < '2026-05-01 00:00:00' THEN dv.cantidad * dv.precio_unitario_congelado ELSE 0 END) AS ingresos_antes,
/*Durante la promocion*/
SUM(CASE WHEN v.fecha_venta BETWEEN '2026-05-01 00:00:00' AND '2026-05-15 23:59:59' THEN dv.cantidad ELSE 0 END) AS unidades_durante,
SUM(CASE WHEN v.fecha_venta BETWEEN '2026-05-01 00:00:00' AND '2026-05-15 23:59:59' THEN dv.cantidad * dv.precio_unitario_congelado ELSE 0 END) AS ingresos_durante,
/*Luego de la promocion*/
SUM(CASE WHEN v.fecha_venta > '2026-05-15 23:59:59' THEN dv.cantidad ELSE 0 END) AS unidades_despues,
SUM(CASE WHEN v.fecha_venta > '2026-05-15 23:59:59' THEN dv.cantidad * dv.precio_unitario_congelado ELSE 0 END) AS ingresos_despues
FROM detalle_ventas dv
INNER JOIN ventas v ON dv.id_venta = v.id_venta
INNER JOIN productos p ON dv.id_producto = p.id_producto
WHERE p.id_producto = 1 /*El valor a la izquierda (El 1) se cambia dependiendo del producto a consultar*/ AND v.estado != 'Cancelado'
GROUP BY p.id_producto, p.nombre;
