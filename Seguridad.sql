-- 1) Crear el rol Administrador_Sistema con todos los privilegios.

CREATE ROLE IF NOT EXISTS 'Administrador_Sistema';
GRANT ALL PRIVILEGES ON Ecommerce.* TO 'Administrador_Sistema';


-- 2) Crear el rol Gerente_Marketing con acceso de solo lectura a ventas y clientes.

CREATE ROLE IF NOT EXISTS 'Gerente_Marketing';
GRANT SELECT ON Ecommerce.ventas TO 'Gerente_Marketing';
GRANT SELECT ON Ecommerce.clientes TO 'Gerente_Marketing';
GRANT SELECT ON Ecommerce.detalle_ventas TO 'Gerente_Marketing';

-- 3) Crear el rol Analista_Datos con acceso de solo lectura a todas las tablas excepto auditoria.

CREATE ROLE IF NOT EXISTS 'Analista_Datos';
GRANT SELECT ON Ecommerce.productos TO 'Analista_Datos';
GRANT SELECT ON Ecommerce.categorias TO 'Analista_Datos';
GRANT SELECT ON Ecommerce.proveedores TO 'Analista_Datos';
GRANT SELECT ON Ecommerce.clientes TO 'Analista_Datos';
GRANT SELECT ON Ecommerce.ventas TO 'Analista_Datos';
GRANT SELECT ON Ecommerce.detalle_ventas TO 'Analista_Datos';

-- 4) Crear el rol Empleado_Inventario que solo pueda modificar stock en productos.

CREATE ROLE IF NOT EXISTS 'Empleado_Inventario';
GRANT SELECT ON Ecommerce.productos TO 'Empleado_Inventario';
GRANT UPDATE (stock, stock_minimo) ON Ecommerce.productos TO 'Empleado_Inventario';
-- solo puede ver y editar stock, nada mas


-- 5) Crear el rol Atencion_Cliente que pueda ver clientes y ventas pero no modificar precios.

CREATE ROLE IF NOT EXISTS 'Atencion_Cliente';
GRANT SELECT ON Ecommerce.clientes TO 'Atencion_Cliente';
GRANT SELECT ON Ecommerce.ventas TO 'Atencion_Cliente';
GRANT SELECT ON Ecommerce.detalle_ventas TO 'Atencion_Cliente';
GRANT SELECT ON Ecommerce.v_info_clientes_basica TO 'Atencion_Cliente';

-- 6) Crear el rol Auditor_Financiero con acceso de solo lectura a ventas, productos y logs de precios.

CREATE ROLE IF NOT EXISTS 'Auditor_Financiero';
GRANT SELECT ON Ecommerce.ventas TO 'Auditor_Financiero';
GRANT SELECT ON Ecommerce.detalle_ventas TO 'Auditor_Financiero';
GRANT SELECT ON Ecommerce.productos TO 'Auditor_Financiero';
GRANT SELECT ON Ecommerce.log_precios_productos TO 'Auditor_Financiero';


-- 7) Crear usuario admin_user y asignarle el rol de administrador.

CREATE USER IF NOT EXISTS 'admin_user'@'localhost' IDENTIFIED BY 'Admin@Secure123!';
GRANT 'Administrador_Sistema' TO 'admin_user'@'localhost';
SET DEFAULT ROLE 'Administrador_Sistema' TO 'admin_user'@'localhost';


-- 8) Crear usuario marketing_user y asignarle el rol de marketing.

CREATE USER IF NOT EXISTS 'marketing_user'@'localhost' IDENTIFIED BY 'Mkt@Secure456!';
GRANT 'Gerente_Marketing' TO 'marketing_user'@'localhost';
SET DEFAULT ROLE 'Gerente_Marketing' TO 'marketing_user'@'localhost';


-- 9) Crear usuario inventory_user y asignarle el rol de inventario.

CREATE USER IF NOT EXISTS 'inventory_user'@'localhost' IDENTIFIED BY 'Inv@Secure789!';
GRANT 'Empleado_Inventario' TO 'inventory_user'@'localhost';
SET DEFAULT ROLE 'Empleado_Inventario' TO 'inventory_user'@'localhost';


-- 10) Crear usuario support_user y asignarle el rol de atencion al cliente.

CREATE USER IF NOT EXISTS 'support_user'@'localhost' IDENTIFIED BY 'Sup@Secure321!';
GRANT 'Atencion_Cliente' TO 'support_user'@'localhost';
SET DEFAULT ROLE 'Atencion_Cliente' TO 'support_user'@'localhost';


-- 11) Impedir que el rol Analista_Datos pueda ejecutar comandos DELETE o TRUNCATE.

REVOKE DELETE ON Ecommerce.* FROM 'Analista_Datos';

-- 12) Otorgar al rol Gerente_Marketing permiso para ejecutar procedimientos almacenados de reportes.

GRANT EXECUTE ON PROCEDURE Ecommerce.sp_GenerarReporteMensualVentas TO 'Gerente_Marketing';
GRANT EXECUTE ON PROCEDURE Ecommerce.sp_ObtenerDashboardAdmin TO 'Gerente_Marketing';
GRANT EXECUTE ON PROCEDURE Ecommerce.sp_ObtenerHistorialComprasCliente TO 'Gerente_Marketing';


-- 13) Crear vista v_info_clientes_basica que oculte informacion sensible.

CREATE OR REPLACE VIEW v_info_clientes_basica AS
SELECT
    id_cliente,
    nombre,
    apellido,
    email,
    direccion_envio,
    fecha_registro,
    nivel_lealtad
FROM clientes;


-- 14) Revocar el permiso de UPDATE sobre la columna precio al rol Empleado_Inventario.

REVOKE UPDATE ON Ecommerce.productos FROM 'Empleado_Inventario';
GRANT UPDATE (stock, stock_minimo) ON Ecommerce.productos TO 'Empleado_Inventario';


-- 15) Implementar una politica de contrasenas seguras para todos los usuarios.

INSTALL PLUGIN validate_password SONAME 'validate_password.so';

SET GLOBAL validate_password.policy = MEDIUM;
SET GLOBAL validate_password.length = 8;
SET GLOBAL validate_password.mixed_case_count = 1;
SET GLOBAL validate_password.number_count = 1;
SET GLOBAL validate_password.special_char_count = 1;


-- 16) Asegurar que el usuario root no pueda ser usado desde conexiones remotas.


-- verificar que root solo exista en localhost
DELETE FROM mysql.user WHERE User = 'root' AND Host != 'localhost';
FLUSH PRIVILEGES;

-- alternativa mas segura: solo actualizar el host
-- UPDATE mysql.user SET Host = 'localhost' WHERE User = 'root' AND Host = '%';
-- FLUSH PRIVILEGES;


-- 17) Crear un rol Visitante que solo pueda ver la tabla productos.

CREATE ROLE IF NOT EXISTS 'Visitante';
GRANT SELECT ON Ecommerce.productos TO 'Visitante';
CREATE OR REPLACE VIEW v_productos_publicos AS
SELECT id_producto, nombre, descripcion, precio, sku
FROM productos WHERE activo = TRUE;

GRANT SELECT ON Ecommerce.v_productos_publicos TO 'Visitante';


-- 18) Limitar el numero de consultas por hora para el rol Analista_Datos.

CREATE USER IF NOT EXISTS 'analista_user'@'localhost'
IDENTIFIED BY 'Analista@Secure654!'
WITH MAX_QUERIES_PER_HOUR 500
     MAX_CONNECTIONS_PER_HOUR 30
     MAX_USER_CONNECTIONS 5;

GRANT 'Analista_Datos' TO 'analista_user'@'localhost';
SET DEFAULT ROLE 'Analista_Datos' TO 'analista_user'@'localhost';


-- 19) Asegurar que los usuarios solo puedan ver las ventas de la sucursal a la que pertenecen.

ALTER TABLE ventas
ADD COLUMN IF NOT EXISTS id_sucursal INT DEFAULT 1;


-- ejemplo para sucursal 1:
CREATE OR REPLACE VIEW v_ventas_sucursal_1 AS
SELECT * FROM ventas WHERE id_sucursal = 1;



-- 20) Auditar todos los intentos de inicio de sesion fallidos en la base de datos.


-- tabla para registrar intentos manuales si se implementa un sistema de login por app
CREATE TABLE IF NOT EXISTS log_intentos_login (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_intentado VARCHAR(100),
    ip_origen VARCHAR(45),
    exitoso BOOLEAN,
    fecha_intento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


FLUSH PRIVILEGES;