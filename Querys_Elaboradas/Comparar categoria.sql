-- Parâmetros esperados:
-- :mes1  (1-12), :ano1 (YYYY)
-- :mes2  (1-12), :ano2 (YYYY)
/*
Script para comparar em qual categoria o fornecimento estava no mês/ano 1 e onde estava no mês/ano 2 colocando 
o status em uma coluna.


*/
WITH params AS (
  SELECT
    -- início/fim do mês 1
    TO_DATE('01/' || :mes1 || '/' || :ano1, 'DD/MM/YYYY') AS dt_ini1,
    ADD_MONTHS(TO_DATE('01/' || :mes1 || '/' || :ano1, 'DD/MM/YYYY'), 1) AS dt_fim1,
    -- início/fim do mês 2
    TO_DATE('01/' || :mes2 || '/' || :ano2, 'DD/MM/YYYY') AS dt_ini2,
    ADD_MONTHS(TO_DATE('01/' || :mes2 || '/' || :ano2, 'DD/MM/YYYY'), 1) AS dt_fim2
  FROM dual
),
mes1 AS (
  SELECT
    f.id_fornecimento,
    -- Categoria vigente tomando a fatura mais recente no mês
    MAX(cat.ds_cd_categoria_uso)
      KEEP (DENSE_RANK LAST ORDER BY f.dt_emissao_fatura) AS categoria_mes1
  FROM ora_dw.mov_fatura f
  JOIN ora_dw.cad_fornecimento forn
    ON forn.id_fornecimento = f.id_fornecimento
   AND (f.dt_emissao_fatura BETWEEN forn.dt_ini AND NVL(forn.dt_fim, DATE '9999-12-31'))
  JOIN ora_dw.tba_cd_categoria_uso cat
    ON cat.cd_categoria_uso = forn.cd_categoria_uso
  JOIN params p ON 1=1
  WHERE f.dt_emissao_fatura >= p.dt_ini1
    AND f.dt_emissao_fatura <  p.dt_fim1
    AND f.cd_seccional IN ('SOR','SOF')
    -- opcional: excluir refaturamentos se aplicável
    AND f.id_fatura NOT IN (SELECT r.id_fatura_destino FROM ora_dw.mov_refaturamento r)
  GROUP BY f.id_fornecimento
),
mes2 AS (
  SELECT
    f.id_fornecimento,
    MAX(cat.ds_cd_categoria_uso)
      KEEP (DENSE_RANK LAST ORDER BY f.dt_emissao_fatura) AS categoria_mes2
  FROM ora_dw.mov_fatura f
  JOIN ora_dw.cad_fornecimento forn
    ON forn.id_fornecimento = f.id_fornecimento
   AND (f.dt_emissao_fatura BETWEEN forn.dt_ini AND NVL(forn.dt_fim, DATE '9999-12-31'))
  JOIN ora_dw.tba_cd_categoria_uso cat
    ON cat.cd_categoria_uso = forn.cd_categoria_uso
  JOIN params p ON 1=1
  WHERE f.dt_emissao_fatura >= p.dt_ini2
    AND f.dt_emissao_fatura <  p.dt_fim2
    AND f.cd_seccional IN ('SOR','SOF')
    AND f.id_fatura NOT IN (SELECT r.id_fatura_destino FROM ora_dw.mov_refaturamento r)
  GROUP BY f.id_fornecimento
)
SELECT
  COALESCE(m1.id_fornecimento, m2.id_fornecimento) AS id_fornecimento,
  m1.categoria_mes1,
  m2.categoria_mes2,
  CASE
    WHEN m1.categoria_mes1 IS NULL AND m2.categoria_mes2 IS NULL THEN 'SEM DADOS'
    WHEN m1.categoria_mes1 IS NULL OR  m2.categoria_mes2 IS NULL THEN 'INCOMPLETO'
    WHEN m1.categoria_mes1 <> m2.categoria_mes2 THEN 'MUDOU'
    ELSE 'MANTEVE'
  END AS status_categoria
FROM mes1 m1
FULL OUTER JOIN mes2 m2
  ON m2.id_fornecimento = m1.id_fornecimento
  WHERE NVL(m1.categoria_mes1,'-') NOT IN('INEXISTENTE','RESIDENCIAL','PUBLICA','MISTA')--Aqui insere quais categorias NÃO é para entrar na comparação.
ORDER BY id_fornecimento;