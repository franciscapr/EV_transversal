--===============================
-- Caso 1: Estrategia de seguridad
-- Usuario --> ADMIN
--===============================

-- CREACIÓN DE USUARIO

CREATE USER PRY2205_EFT IDENTIFIED BY "EftCloud2025"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON DATA;

CREATE USER PRY2205_EFT_DES IDENTIFIED BY "DesCloud2025"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON DATA;

CREATE USER PRY2205_EFT_CON IDENTIFIED BY "ConCloud2025"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON DATA;

-- Permitir conexión
GRANT CREATE SESSION TO PRY2205_EFT;
GRANT CREATE SESSION TO PRY2205_EFT_DES;
GRANT CREATE SESSION TO PRY2205_EFT_CON;

-- Privilegios para usuario dueño
GRANT CREATE TABLE TO PRY2205_EFT;
GRANT CREATE VIEW TO PRY2205_EFT;
GRANT CREATE SEQUENCE TO PRY2205_EFT;
GRANT CREATE SYNONYM TO PRY2205_EFT;
GRANT CREATE PUBLIC SYNONYM TO PRY2205_EFT;
GRANT CREATE INDEXTYPE TO PRY2205_EFT;

-- Privilegios para usuario desarrollador
GRANT CREATE VIEW TO PRY2205_EFT_DES;
GRANT CREATE SEQUENCE TO PRY2205_EFT_DES;
GRANT CREATE PROCEDURE TO PRY2205_EFT_DES;
GRANT CREATE SYNONYM TO PRY2205_EFT_DES;

-- Roles solicitados
CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_C;

-- Asignación de roles
GRANT PRY2205_ROL_D TO PRY2205_EFT_DES;
GRANT PRY2205_ROL_C TO PRY2205_EFT_CON;



-- ===================================================
-- ===================================================
-- ===================================================
-- ===================================================
-- ===================================================



--===============================
-- POBLAMIENTO DE DATOS 
-- Usuario --> PRY2205_EFT
--===============================


-- ===================================================
-- ===================================================
-- ===================================================
-- ===================================================
-- ===================================================



-- ===================================================
-- CASO 1: PRIVILEGIOS SOBRE TABLAS Y SINÓNIMOS
-- USUARIO: PRY2205_EFT
-- ===================================================

SHOW USER;

-- Permisos directos al usuario DES
-- Importante: WITH GRANT OPTION porque DES creará una vista
-- y luego dará permiso a CON sobre esa vista.

GRANT SELECT ON DEUDOR TO PRY2205_EFT_DES WITH GRANT OPTION;
GRANT SELECT ON OCUPACION TO PRY2205_EFT_DES WITH GRANT OPTION;
GRANT SELECT ON TARJETA_DEUDOR TO PRY2205_EFT_DES WITH GRANT OPTION;
GRANT SELECT ON CUOTA_TARJETAS TO PRY2205_EFT_DES WITH GRANT OPTION;

-- Permisos mediante rol para DES
GRANT SELECT ON DEUDOR TO PRY2205_ROL_D;
GRANT SELECT ON OCUPACION TO PRY2205_ROL_D;
GRANT SELECT ON TARJETA_DEUDOR TO PRY2205_ROL_D;
GRANT SELECT ON CUOTA_TARJETAS TO PRY2205_ROL_D;

-- Permisos mediante rol para CON
GRANT SELECT ON DEUDOR TO PRY2205_ROL_C;
GRANT SELECT ON OCUPACION TO PRY2205_ROL_C;
GRANT SELECT ON TARJETA_DEUDOR TO PRY2205_ROL_C;
GRANT SELECT ON CUOTA_TARJETAS TO PRY2205_ROL_C;
GRANT SELECT ON TRANSACCION_TARJETA_DEUDOR TO PRY2205_ROL_C;
GRANT SELECT ON SUCURSAL TO PRY2205_ROL_C;

-- Permisos para Caso 3
GRANT SELECT ON TRANSACCION_TARJETA_DEUDOR TO PRY2205_ROL_C;
GRANT SELECT ON SUCURSAL TO PRY2205_ROL_C;


-- SINÓNIMOS PÚBLICOS


CREATE OR REPLACE PUBLIC SYNONYM SYN_DEUDOR FOR PRY2205_EFT.DEUDOR;
CREATE OR REPLACE PUBLIC SYNONYM SYN_OCUPACION FOR PRY2205_EFT.OCUPACION;
CREATE OR REPLACE PUBLIC SYNONYM SYN_TARJETA_DEUDOR FOR PRY2205_EFT.TARJETA_DEUDOR;
CREATE OR REPLACE PUBLIC SYNONYM SYN_CUOTA_TARJETAS FOR PRY2205_EFT.CUOTA_TARJETAS;
CREATE OR REPLACE PUBLIC SYNONYM SYN_TRANSACCION_TARJETA_DEUDOR FOR PRY2205_EFT.TRANSACCION_TARJETA_DEUDOR;
CREATE OR REPLACE PUBLIC SYNONYM SYN_SUCURSAL FOR PRY2205_EFT.SUCURSAL;

COMMIT;



-- ===================================================
-- ===================================================
-- ===================================================
-- ===================================================
-- ===================================================



-- ===================================================
-- CASO 2: CREACIÓN DE INFORME
-- USUARIO: PRY2205_EFT_DES
-- VISTA: VW_ANALISIS_DEUDORES_PERIODO
-- ===================================================

SHOW USER;

CREATE OR REPLACE VIEW VW_ANALISIS_DEUDORES_PERIODO AS
SELECT
    TO_CHAR(d.numrun, '99G999G999') || '-' || d.dvrun AS rut_deudor,
    INITCAP(d.pnombre || ' ' || d.appaterno || ' ' || d.apmaterno) AS nombre_deudor,
    COUNT(ct.nro_cuota) AS total_cuotas,
    ROUND(AVG(ct.valor_cuota)) AS promedio_valor_cuotas,
    TO_CHAR(MIN(ct.fecha_venc_cuota), 'DD/MM/YYYY') AS fecha_mas_antigua,
    NVL(TO_CHAR(d.fono_contacto), 'Sin Información') AS telefono,
    UPPER(o.nombre_prof_ofic) AS ocupacion,
    td.cupo_disp_compra AS cupo_disp_compra
FROM syn_deudor d
JOIN syn_ocupacion o
    ON d.cod_ocupacion = o.cod_ocupacion
JOIN syn_tarjeta_deudor td
    ON d.numrun = td.numrun
JOIN syn_cuota_tarjetas ct
    ON td.nro_tarjeta = ct.nro_tarjeta
WHERE UPPER(o.nombre_prof_ofic) <> 'INGENIERO'
AND ct.fecha_venc_cuota BETWEEN TRUNC(ADD_MONTHS(SYSDATE, -12), 'YYYY')
                            AND ADD_MONTHS(TRUNC(SYSDATE, 'YYYY'), -1)
GROUP BY
    d.numrun,
    d.dvrun,
    d.pnombre,
    d.appaterno,
    d.apmaterno,
    d.fono_contacto,
    o.nombre_prof_ofic,
    td.cupo_disp_compra
HAVING ROUND(AVG(ct.valor_cuota)) < (
    SELECT MAX(promedio_general)
    FROM (
        SELECT AVG(valor_cuota) AS promedio_general
        FROM syn_cuota_tarjetas
        GROUP BY nro_tarjeta
    )
);

-- Permiso para que el usuario consultor pueda ver la vista
GRANT SELECT ON VW_ANALISIS_DEUDORES_PERIODO TO PRY2205_EFT_CON;


-- Probamos la vista
SELECT *
FROM VW_ANALISIS_DEUDORES_PERIODO
ORDER BY total_cuotas ASC, cupo_disp_compra ASC;



-- ===================================================
-- ===================================================
-- ===================================================
-- ===================================================
-- ===================================================


-- ===================================================
-- CASO 3: INFORME + OPTIMIZACIÓN
-- USUARIO: PRY2205_EFT
-- ===================================================

SHOW USER;


-- LIMPIEZA

DELETE FROM T_ANALISIS_TARJETAS;
COMMIT;

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_T_ANALISIS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX IDX_SUCURSAL_DIRECCION';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX IDX_TRANSA_SUC_MONTO';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ===================================================
-- SECUENCIA
-- ===================================================

CREATE SEQUENCE SEQ_T_ANALISIS
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- PLAN ANTES DEL ÍNDICE


EXPLAIN PLAN FOR
INSERT INTO T_ANALISIS_TARJETAS (
    num_analisis,
    nro_tarjeta,
    total_cuotas,
    monto_total_transa,
    fecha_transaccion,
    direccion,
    monto_reajustado
)
SELECT
    SEQ_T_ANALISIS.NEXTVAL,
    q.nro_tarjeta,
    q.total_cuotas,
    q.monto_total_transa,
    q.fecha_transaccion,
    q.direccion,
    q.monto_reajustado
FROM (
    SELECT
        tt.nro_tarjeta AS nro_tarjeta,
        tt.total_cuotas_transaccion AS total_cuotas,
        tt.monto_total_transaccion AS monto_total_transa,
        TO_CHAR(tt.fecha_transaccion, 'DD/MM/YYYY') AS fecha_transaccion,
        INITCAP(s.direccion) AS direccion,
        ROUND(
            tt.monto_total_transaccion +
            CASE
                WHEN tt.monto_total_transaccion BETWEEN 200000 AND 300000 THEN tt.monto_total_transaccion * 0.05
                WHEN tt.monto_total_transaccion BETWEEN 300001 AND 500000 THEN tt.monto_total_transaccion * 0.07
                ELSE 0
            END
        ) AS monto_reajustado
    FROM syn_transaccion_tarjeta_deudor tt
    JOIN syn_sucursal s
        ON tt.id_sucursal = s.id_sucursal
    WHERE s.direccion LIKE 'A%'
    AND tt.monto_total_transaccion >= 200000
    ORDER BY
        tt.nro_tarjeta ASC,
        monto_reajustado DESC
) q;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);

-- CREACIÓN DE ÍNDICES


CREATE INDEX IDX_SUCURSAL_DIRECCION
ON SUCURSAL(direccion, id_sucursal);

CREATE INDEX IDX_TRANSA_SUC_MONTO
ON TRANSACCION_TARJETA_DEUDOR(id_sucursal, monto_total_transaccion);


-- PLAN DESPUÉS DEL ÍNDICE


EXPLAIN PLAN FOR
INSERT INTO T_ANALISIS_TARJETAS (
    num_analisis,
    nro_tarjeta,
    total_cuotas,
    monto_total_transa,
    fecha_transaccion,
    direccion,
    monto_reajustado
)
SELECT
    SEQ_T_ANALISIS.NEXTVAL,
    q.nro_tarjeta,
    q.total_cuotas,
    q.monto_total_transa,
    q.fecha_transaccion,
    q.direccion,
    q.monto_reajustado
FROM (
    SELECT
        tt.nro_tarjeta AS nro_tarjeta,
        tt.total_cuotas_transaccion AS total_cuotas,
        tt.monto_total_transaccion AS monto_total_transa,
        TO_CHAR(tt.fecha_transaccion, 'DD/MM/YYYY') AS fecha_transaccion,
        INITCAP(s.direccion) AS direccion,
        ROUND(
            tt.monto_total_transaccion +
            CASE
                WHEN tt.monto_total_transaccion BETWEEN 200000 AND 300000 THEN tt.monto_total_transaccion * 0.05
                WHEN tt.monto_total_transaccion BETWEEN 300001 AND 500000 THEN tt.monto_total_transaccion * 0.07
                ELSE 0
            END
        ) AS monto_reajustado
    FROM syn_transaccion_tarjeta_deudor tt
    JOIN syn_sucursal s
        ON tt.id_sucursal = s.id_sucursal
    WHERE s.direccion LIKE 'A%'
    AND tt.monto_total_transaccion >= 200000
    ORDER BY
        tt.nro_tarjeta ASC,
        monto_reajustado DESC
) q;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);

-- INSERT 

INSERT INTO T_ANALISIS_TARJETAS (
    num_analisis,
    nro_tarjeta,
    total_cuotas,
    monto_total_transa,
    fecha_transaccion,
    direccion,
    monto_reajustado
)
SELECT
    SEQ_T_ANALISIS.NEXTVAL,
    q.nro_tarjeta,
    q.total_cuotas,
    q.monto_total_transa,
    q.fecha_transaccion,
    q.direccion,
    q.monto_reajustado
FROM (
    SELECT
        tt.nro_tarjeta AS nro_tarjeta,
        tt.total_cuotas_transaccion AS total_cuotas,
        tt.monto_total_transaccion AS monto_total_transa,
        TO_CHAR(tt.fecha_transaccion, 'DD/MM/YYYY') AS fecha_transaccion,
        INITCAP(s.direccion) AS direccion,
        ROUND(
            tt.monto_total_transaccion +
            CASE
                WHEN tt.monto_total_transaccion BETWEEN 200000 AND 300000 THEN tt.monto_total_transaccion * 0.05
                WHEN tt.monto_total_transaccion BETWEEN 300001 AND 500000 THEN tt.monto_total_transaccion * 0.07
                ELSE 0
            END
        ) AS monto_reajustado
    FROM syn_transaccion_tarjeta_deudor tt
    JOIN syn_sucursal s
        ON tt.id_sucursal = s.id_sucursal
    WHERE s.direccion LIKE 'A%'
    AND tt.monto_total_transaccion >= 200000
    ORDER BY
        tt.nro_tarjeta ASC,
        monto_reajustado DESC
) q;

COMMIT;

-- PERMISO PARA USUARIO CONSULTOR

GRANT SELECT ON T_ANALISIS_TARJETAS TO PRY2205_EFT_CON;

-- CONSULTA FINAL

SELECT *
FROM T_ANALISIS_TARJETAS
ORDER BY nro_tarjeta ASC, monto_reajustado DESC;



-- ===================================================
-- ===================================================
-- ===================================================
-- ===================================================
-- ===================================================



-- ===================================================
-- USUARIO: PRY2205_EFT_CON
-- ===================================================

SHOW USER;

SELECT *
FROM PRY2205_EFT_DES.VW_ANALISIS_DEUDORES_PERIODO
ORDER BY total_cuotas ASC, cupo_disp_compra ASC;

-- ===================================================
-- CASO 3: CONSULTA CON USUARIO CONSULTOR
-- USUARIO: PRY2205_EFT_CON
-- ===================================================

SHOW USER;

SELECT *
FROM PRY2205_EFT.T_ANALISIS_TARJETAS
ORDER BY nro_tarjeta ASC, monto_reajustado DESC;
