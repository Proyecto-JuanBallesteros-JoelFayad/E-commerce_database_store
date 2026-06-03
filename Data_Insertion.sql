-- =============================================================================
-- 1. INSERTAR CATEGORÍAS
-- =============================================================================
INSERT INTO categorias (nombre, descripcion) VALUES
('Electrónica', 'Dispositivos tecnológicos, gadgets y accesorios de computación.'),
('Ropa y Calzado', 'Prendas de vestir, zapatos y accesorios de moda para todas las edades.'),
('Hogar y Cocina', 'Muebles, electrodomésticos y utensilios para el hogar.'),
('Deportes', 'Equipamiento deportivo, ropa fitness y accesorios para exterior.'),
('Videojuegos', 'Consolas, juegos físicos, componentes de PC gaming y periféricos.');

-- =============================================================================
-- 2. INSERTAR PROVEEDORES
-- =============================================================================
INSERT INTO proveedores (nombre, email_contacto, telefono_contacto) VALUES
('TechDistribuidora SAS', 'contacto@techdistribuidora.com', '+573151234567'),
('Moda Global Co', 'ventas@modaglobal.com', '+573009876543'),
('Hogar Estilo Limitada', 'info@hogarestilo.co', '+576076345678'),
('SportGlow Colombia', 'proveedores@sportglow.com', '+573112223334'),
('Gaming Zone Imports', 'mayoreo@gamingzone.com', '+573205556667');

-- =============================================================================
-- 3. INSERTAR PRODUCTOS
-- (Nota la coherencia: precio > costo, stock >= 0, sku único)
-- =============================================================================
INSERT INTO productos (id_categoria, id_proveedor, nombre, descripcion, precio, costo, stock, sku, activo) VALUES
-- Electrónica (id_categoria: 1, id_proveedor: 1)
(1, 1, 'Mouse Inalámbrico Ergonómico', 'Mouse recargable con conexión 2.4GHz y Bluetooth.', 120000.00, 65000.00, 45, 'MOU-TECH-001', TRUE),
(1, 1, 'Teclado Mecánico RGB', 'Teclado switch red, formato TKL, distribución en español.', 280000.00, 140000.00, 20, 'KEY-TECH-002', TRUE),
-- Ropa y Calzado (id_categoria: 2, id_proveedor: 2)
(2, 2, 'Camiseta Algodón Premium Black', 'Camiseta 100% algodón pesado unisex, color negro.', 65000.00, 25000.00, 100, 'CAM-MODA-001', TRUE),
(2, 2, 'Tenis Urbanos Blancos', 'Zapatillas de cuero sintético con suela de alta resistencia.', 180000.00, 85000.00, 35, 'ZAP-MODA-002', TRUE),
-- Hogar y Cocina (id_categoria: 3, id_proveedor: 3)
(3, 3, 'Cafetera de Goteo Programable', 'Capacidad para 12 tazas, filtro permanente y temporizador.', 220000.00, 115000.00, 15, 'CAF-HOGAR-001', TRUE),
(3, 3, 'Juego de Cuchillos de Cocina', 'Set de 6 piezas de acero inoxidable con base de madera.', 140000.00, 70000.00, 0, 'CUC-HOGAR-002', TRUE), -- Producto sin stock temporal
-- Deportes (id_categoria: 4, id_proveedor: 4)
(4, 4, 'Termo Deportivo Inoxidable 1L', 'Mantiene bebidas frías por 24 horas y calientes por 12.', 85000.00, 38000.00, 60, 'TER-SPOR-001', TRUE),
(4, 4, 'Tapete de Yoga Antideslizante', 'Espesor de 6mm, material ecológico TPE con guía de posturas.', 95000.00, 42000.00, 25, 'TAP-SPOR-002', TRUE),
-- Videojuegos (id_categoria: 5, id_proveedor: 5)
(5, 5, 'Control Inalámbrico Pro-Gaming', 'Compatible con PC y consolas, palancas con efecto Hall.', 240000.00, 130000.00, 18, 'CTR-GAME-001', TRUE),
(5, 5, 'Audífonos Gamer 7.1 Surround', 'Cancelación pasiva de ruido, micrófono extraíble, luces LED.', 310000.00, 165000.00, 12, 'AUD-GAME-002', FALSE); -- Descontinuado / Inactivo

-- =============================================================================
-- 4. INSERTAR CLIENTES
-- =============================================================================
INSERT INTO clientes (nombre, apellido, email, password_hash, direccion_envio) VALUES
('Joel Stiven', 'Fayad Fandiño', 'joel.fayad@ejemplo.com', '$2b$12$K3h8j7H6g5F4d3S2a1Q0eOuYmZtWxVuTsRqPoOnMlKjIhGfEdCbA.', 'Calle 36 #24-15, Bucaramanga'),
('María Camila', 'Rodríguez Gómez', 'camila.rod@ejemplo.com', '$2b$12$L9k8j7H6g5F4d3S2a1Q0eOuYmZtWxVuTsRqPoOnMlKjIhGfEdCbA.', 'Carrera 27 #54-02, Bucaramanga'),
('Carlos Andrés', 'Mendoza Duarte', 'carlos.mendoza@ejemplo.com', '$2b$12$M0j9k8h7g6f5d4s3a2q1w.e.r.t.y.u.i.o.p.a.s.d.f.g.h.j.', 'Anillo Vial Km 2, Floridablanca'),
('Diana Marcela', 'Silva Ortega', 'diana.silva@ejemplo.com', '$2b$12$N1k2j3h4g5f6d7s8a9q0w.e.r.t.y.u.i.o.p.a.s.d.f.g.h.j.', 'Calle 105 #18-40, Bucaramanga'),
('Santiago', 'Alvarez Restrepo', 'santi.alvarez@ejemplo.com', '$2b$12$O2j3k4h5g6f7d8s9a0q1w.e.r.t.y.u.i.o.p.a.s.d.f.g.h.j.', 'Carrera 12 #32-11, Girón');

-- =============================================================================
-- 5. INSERTAR VENTAS (ENCABEZADOS)
-- (Nota: Dejamos el total en 0 inicialmente, simulando que un trigger lo calculará,
-- o lo llenamos directamente con el valor real de la suma del detalle)
-- =============================================================================
INSERT INTO ventas (id_cliente, fecha_venta, estado, total) VALUES
(1, '2026-05-10 14:30:00', 'Entregado', 370000.00), -- Mouse (120k) + Control (240k) + IVA/Ajustes simulados si aplica, aquí suma directa = 360k (Actualizado a 360k abajo en el detalle)
(2, '2026-05-15 09:15:00', 'Entregado', 130000.00),
(3, '2026-05-20 18:45:00', 'Enviado', 280000.00),
(1, '2026-05-25 11:00:00', 'Procesando', 220000.00),
(4, '2026-06-01 16:20:00', 'Pendiente de Pago', 180000.00),
(5, '2026-06-02 20:05:00', 'Cancelado', 95000.00);

-- =============================================================================
-- 6. INSERTAR DETALLE DE VENTAS (LÍNEAS DE ORDEN)
-- (El precio_unitario_congelado coincide con el precio de la tabla productos)
-- =============================================================================
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario_congelado) VALUES
-- Venta 1 (Cliente 1): Compró 1 Mouse (120k) y 1 Control Gaming (240k) -> Total: 360,000.00
(1, 1, 1, 120000.00),
(1, 9, 1, 240000.00),

-- Venta 2 (Cliente 2): Compró 2 Camisetas (65k c/u) -> Total: 130,000.00
(2, 3, 2, 65000.00),

-- Venta 3 (Cliente 3): Compró 1 Teclado Mecánico -> Total: 280,000.00
(3, 2, 1, 280000.00),

-- Venta 4 (Cliente 1): Compró 1 Cafetera -> Total: 220,000.00
(4, 5, 1, 220000.00),

-- Venta 5 (Cliente 4): Compró 1 Tenis Urbanos -> Total: 180,000.00
(5, 4, 1, 180000.00),

-- Venta 6 (Cliente 5): Intentó comprar 1 Tapete de Yoga (Venta Cancelada) -> Total: 95,000.00
(6, 8, 1, 95000.00);