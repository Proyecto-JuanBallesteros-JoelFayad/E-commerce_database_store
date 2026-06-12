-- FUNCION PARA VER EL PUNTAJ DEL CLIENTE RESPECTO A EL NUMERO DE VENTAS

CREATE FUNCTION fn_ContarVentasCliente3(
    p_id_cliente INT
)
RETURNS INT

DETERMINISTIC

BEGIN

    DECLARE ventasNum INT;
   	DECLARE score INT;

    SELECT COUNT(*) 
    INTO ventasNum
    FROM  ventas v
    WHERE id_cliente = p_id_cliente;
   
   	IF ventasNum <= 2 THEN
        SET score = 1;
    ELSEIF ventasNum <= 5 THEN
        SET score = 2;
    ELSEIF ventasNum <= 10 THEN
        SET score = 3;
    ELSE
        SET score = 4;
    END IF;

    RETURN score;

END;

SELECT fn_ContarVentasCliente3(1);


-- FUNCION PARA VER EL PUNTAJ DEL CLIENTE RESPECTO A SUS DIAS DESPUES DE LA ULTIMA COMPRA

CREATE FUNCTION fn_CalcularDiasDesdeUltimaCompra5(
    p_id_cliente INT
)
RETURNS INT

DETERMINISTIC

BEGIN

    DECLARE fechaCompra INT;
   	DECLARE score INT;

    SELECT TIMESTAMPDIFF(
    	DAY,
    	MAX(v.fecha_venta),
    	CURDATE()
	)
    INTO fechaCompra
    FROM  ventas v
    WHERE v.id_cliente = p_id_cliente;
   
   	IF fechaCompra <= 10 THEN
        SET score = 4;
    ELSEIF fechaCompra <= 20 THEN
        SET score = 3;
    ELSEIF fechaCompra <= 40 THEN
        SET score = 2;
    ELSE
        SET score = 1;
    END IF;

    RETURN score;

END;

SELECT fn_CalcularDiasDesdeUltimaCompra5(2);

-- FUNCION PARA VER EL PUNTAJ DEL CLIENTE RESPECTO A SU NUMERO DE COMPRAS

CREATE FUNCTION totalClienteHistorico2(
    p_id_cliente INT
)
RETURNS INT

DETERMINISTIC

BEGIN

    DECLARE gastoHistorico DECIMAL;
   	DECLARE score INT;

    SELECT COALESCE(SUM(v.total), 0)
    INTO gastoHistorico
    FROM  ventas v
    WHERE v.id_cliente = p_id_cliente
    GROUP BY v.id_cliente;
   
   	IF gastoHistorico <= 60000 THEN
        SET score = 1;
    ELSEIF gastoHistorico <= 100000 THEN
        SET score = 2;
    ELSEIF gastoHistorico <= 200000 THEN
        SET score = 3;
    ELSE
        SET score = 4;
    END IF;

    RETURN score;

END;


SELECT totalClienteHistorico2(1);

-- FUNCION QUE CALUCLA EL PROMEDIO Y DA EL NIVEL DEL CLIENTE

CREATE FUNCTION RFM(
    p_id_cliente INT
)
RETURNS VARCHAR(100)

DETERMINISTIC

BEGIN
	
	DECLARE puntaje DECIMAL(10,2);
    DECLARE LealtadNIvel VARCHAR(100);
   
   	SET puntaje = (fn_ContarVentasCliente3(p_id_cliente) + fn_CalcularDiasDesdeUltimaCompra5(p_id_cliente) + totalClienteHistorico2(p_id_cliente)) / 3;
   	
   	IF puntaje <= 1 THEN
        SET LealtadNIvel = "cliente malo";
    ELSEIF puntaje <= 2 THEN
        SET LealtadNIvel = "un bien cliente";
    ELSEIF puntaje <= 3 THEN
        SET LealtadNIvel = "es cliente genial";
    ELSE
        SET LealtadNIvel = "el mejor cliente del mundo mundial";
    END IF;

    RETURN LealtadNIvel;

END;

-- CONSULA FINAL PARA MEDIR A UN CLIENTE
SELECT RFM(1);