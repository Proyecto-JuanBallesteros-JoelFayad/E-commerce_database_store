/*1 Top 10 Productos Más Vendidos: Generar un ranking con los 10 productos que han generado más ingresos.*/

SELECT p.id_producto, p.nombre, SUM(dv.cantidad * dv.precio_unitario_congelado) as Total_generado
FROM productos p
JOIN detalle_ventas dv on p.id_producto = dv.id_producto
JOIN ventas v on v.id_venta = dv.id_venta
WHERE v.estado ='Entregado'
GROUP BY p.id_producto, p.nombre
ORDER BY Total_generado DESC
LIMIT 10;

/*2 Productos con Bajas Ventas: Identificar los productos en el 10% inferior de ventas para considerar su descontinuación.*/
SELECT p.id_producto, p.nombre, COALESCE(SUM(dv.cantidad), 0) as Total_Vendido
FROM productos p
LEFT JOIN detalle_ventas dv on p.id_producto = dv.id_producto
LEFT JOIN ventas v on dv.id_venta = v.id_venta and v.estado = 'Entregado'
GROUP BY p.id_producto, p.nombre
ORDER BY Total_Vendido ASC
LIMIT (SELECT ROUND(COUNT(*) * 0.10, 0) FROM productos);
/*EL 2 ESTÁ INCOMPLETO, Y POSIBLEMENTE MAL*/