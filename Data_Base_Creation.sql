CREATE DATABASE Ecommerce

USE Ecommerce

CREATE TABLE categorias(
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
);

CREATE TABLE proveedores(
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email_contacto VARCHAR(100) NOT NULL UNIQUE,
    telefono_contacto VARCHAR(20)
);

CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT,
    id_proveedor INT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    costo DECIMAL(10,2) NOT NULL CHECK (costo >= 0),
    stock INT NOT NULL CHECK (stock >= 0) DEFAULT 0,
    sku VARCHAR(20) NOT NULL UNIQUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN NOT NULL,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor)
);

CREATE TABLE clientes(
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    direccion_envio VARCHAR(255),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ventas(
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM(
        'Pendiente de Pago',
        'Procesando',
        'Enviado',
        'Entregado',
        'Cancelado'
    ) NOT NULL,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE detalle_ventas (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario_congelado DECIMAL(10,2) NOT NULL CHECK (precio_unitario_congelado > 0),
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);