-- Script para trazer os fornecimentos que possuem debito automatico ativo por range de data


WITH fornecimento_debito_ativo AS (
    SELECT
        f.id_fornecimento
    FROM
        ora_dw.cad_fornecimento f
    LEFT JOIN
        ora_dw.cad_fornecimento_debito_automa a
            ON a.id_fornecimento = f.id_fornecimento
           AND a.dt_fim = TO_DATE('31/12/9999', 'DD/MM/YYYY')
    WHERE
        f.dt_fim = TO_DATE('31/12/9999', 'DD/MM/YYYY')
        AND a.dt_revogacao_debito_automatico = TO_DATE('31/12/9999', 'DD/MM/YYYY')
),
faturas_periodo AS (
    SELECT
        DISTINCT f.id_fatura,
                 f.id_fornecimento
    FROM
        ora_dw.mov_fatura f
    LEFT JOIN
        ora_dw.mov_codeline c
            ON c.id_fatura = f.id_fatura
    WHERE
        c.dt_fim = TO_DATE('31/12/9999', 'DD/MM/YYYY')
        AND c.dt_vencimento_codeline >= TO_DATE('01/10/2025', 'DD/MM/YYYY')
        AND c.dt_vencimento_codeline <  TO_DATE('01/11/2025', 'DD/MM/YYYY')
)
SELECT DISTINCT
    fdp.id_fornecimento as "out/25"
FROM
    fornecimento_debito_ativo fdp
INNER JOIN
    faturas_periodo fp
    ON fp.id_fornecimento = fdp.id_fornecimento
ORDER BY
    fdp.id_fornecimento;


