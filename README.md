# 🛒 E-commerce Database Store

Base de datos relacional diseñada para gestionar el núcleo de una tienda en línea. Incluye manejo de inventario, clientes, ventas y automatización de procesos mediante SQL avanzado.

---

## 👥 Equipo

| Nombre | GitHub |
|---|---|
| Juan Felix Ballesteros Díaz | [@JuanBallesteros](https://github.com/JuanBallesteros) |
| Joel Estiven Fayad Fandiño | [@JoelFayad](https://github.com/JoelFayad) |

---

## 📁 Estructura del Proyecto

| Archivo | Descripción |
|---|---|
| `Data_Base_Creation.sql` | Creación de tablas, relaciones y restricciones |
| `Data_Insertion.sql` | Datos de prueba para todas las entidades |
| `DataBase_Queries.sql` | 20 consultas analíticas de negocio |
| `Data_Base_Funtions.sql` | 20 funciones definidas por el usuario (UDFs) |
| `DataBase_Triggers.sql` | 20 triggers de automatización e integridad |
| `DataBase_StoredProcedures.sql` | 20 procedimientos almacenados |
| `DataBase_Events.sql` | 20 eventos programados de mantenimiento |
| `DataBase_Security.sql` | Roles, usuarios y permisos (RBAC) |

---

## 🗄️ Entidades Principales

- **Productos** — Catálogo con inventario, SKU y costos
- **Categorías** — Clasificación jerárquica de productos
- **Proveedores** — Información de contacto y suministro
- **Clientes** — Usuarios registrados con historial de compras
- **Ventas** — Transacciones con estado y total
- **Detalle de Ventas** — Líneas de orden con precio histórico congelado

---

## ⚙️ Tecnología

- **Motor:** MySQL 8.0+
- **Paradigma:** SQL relacional con lógica de negocio en base de datos

---

## 🚀 Cómo usar

1. Ejecutar `Data_Base_Creation.sql` para crear la base de datos y tablas
2. Ejecutar `Data_Insertion.sql` para cargar los datos de prueba
3. Ejecutar los demás archivos en cualquier orden según lo que se necesite probar