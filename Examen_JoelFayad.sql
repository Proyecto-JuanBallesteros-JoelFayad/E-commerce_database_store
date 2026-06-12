/*Trigger - Auditoría de Cambios en Clientes

Por motivos de seguridad y cumplimiento, la empresa necesita un registro detallado de cualquier cambio realizado en la información sensible de los clientes, como el email o la direccion_envio.

**Tarea:** Implementa un trigger llamado trg_audit_cliente_after_update que se dispare después de que se actualice un registro en la tabla Clientes.



1. Primero, crea una tabla de auditoría llamada Auditoria_Clientes con campos como id_auditoria, id_cliente, campo_modificado, valor_antiguo, valor_nuevo y fecha_modificacion.
2. El trigger debe activarse solo si el valor del campo email o direccion_envio ha cambiado.
3. Cuando se dispare, el trigger debe insertar un nuevo registro en la tabla Auditoria_Clientes, almacenando el valor antiguo y el nuevo del campo que fue modificado.



Resultado esperado

- Un repositorio privado en github.
- Un único script .sql que incluya el CREATE TABLE para Auditoria_Clientes y el CREATE TRIGGER para trg_audit_cliente_after_update.
- Comentarios que expliquen la lógica.*/


USE Ecommerce;


CREATE TABLE Auditoria_Clientes(
id_auditoria int auto_increment primary key,
id_cliente int,
campo_modificado VARCHAR(50) NOT NULL,
valor_antiguo VARCHAR(50) NOT NULL,
valor_nuevo VARCHAR(50) NOT NULL,
fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);


CREATE TRIGGER trg_audit_cliente_after_update
AFTER UPDATE ON clientes
FOR EACH ROW
BEGIN 
  
	IF OLD.email != NEW.email THEN
		INSERT INTO Auditoria_Clientes(id_cliente, campo_modificado, valor_antiguo, valor_nuevo)
		VALUES (OLD.id_cliente, 'email', OLD.email, NEW.email);
	
		ELSE IF OLD.direccion_envio != NEW.direccion_envio THEN
			INSERT INTO Auditoria_Clientes(id_cliente, campo_modificado, valor_antiguo, valor_nuevo)
			VALUES (OLD.id_cliente, 'dir_envio', OLD.direccion_envio, NEW.direccion_envio);

		END IF;
	END IF;
END;
