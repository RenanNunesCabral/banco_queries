/*

Script para trazer as faturas emitidas separadas por mês/ano definidos no range de data 

*/

WITH parametros_periodo AS ( 

    SELECT 

        DATE '2024-01-01' AS dt_inicio, 

        DATE '2025-01-01' AS dt_fim 

    FROM dual 

), 

faturas_filtradas AS ( 

    SELECT FATURA.* 

    FROM ORA_DW.MOV_FATURA FATURA 

    CROSS JOIN parametros_periodo p 

    WHERE FATURA.CD_SECCIONAL IN ('SOR', 'SOF') 

      AND FATURA.ID_FATURA NOT IN (SELECT ID_FATURA_DESTINO FROM ORA_DW.MOV_REFATURAMENTO) 

      AND FATURA.DT_EMISSAO_FATURA >= p.dt_inicio 

      AND FATURA.DT_EMISSAO_FATURA <  p.dt_fim 

), 

base AS ( 

    SELECT 

        NVL(CATEGORIA.DS_CD_CATEGORIA_USO, '-1') AS DS_CD_CATEGORIA_USO, 

        TO_CHAR(TRUNC(FATURA.DT_EMISSAO_FATURA, 'MM'), 'YYYY-MM') AS mes_label, 

        FATURA.ID_FATURA 

    FROM faturas_filtradas FATURA 

    LEFT JOIN ORA_DW.CAD_FORNECIMENTO FORN 

        ON FORN.ID_FORNECIMENTO = FATURA.ID_FORNECIMENTO 

       AND (FATURA.DT_EMISSAO_FATURA BETWEEN FORN.DT_INI AND FORN.DT_FIM OR FORN.DT_FIM IS NULL) 

    LEFT JOIN ORA_DW.TBA_CD_CATEGORIA_USO CATEGORIA 

        ON CATEGORIA.CD_CATEGORIA_USO = FORN.CD_CATEGORIA_USO 

    LEFT JOIN ORA_DW_TAT.HIERARQUIA_COMERCIAL HC 

        ON HC.CD_ATC = FATURA.CD_ATC 

    WHERE 1=1 

) 

SELECT * 

FROM ( 

    SELECT DS_CD_CATEGORIA_USO, mes_label, ID_FATURA 

    FROM base 

) 

PIVOT ( 

    COUNT(ID_FATURA)  

    FOR mes_label IN ( 

        '2024-01' AS QTDE_2024_01, 

        '2024-02' AS QTDE_2024_02, 

        '2024-03' AS QTDE_2024_03, 

        '2024-04' AS QTDE_2024_04, 

        '2024-05' AS QTDE_2024_05, 

        '2024-06' AS QTDE_2024_06, 

        '2024-07' AS QTDE_2024_07,  

        '2024-08' AS QTDE_2024_08, 

        '2024-09' AS QTDE_2024_09,  

        '2024-10' AS QTDE_2024_10, 

        '2024-11' AS QTDE_2024_11, 

        '2024-12' AS QTDE_2024_12) 

    ) 

ORDER BY DS_CD_CATEGORIA_USO; 