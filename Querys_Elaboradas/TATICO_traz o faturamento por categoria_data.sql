-- Script para trazer as informações de volume faturado por mês e ano



-- Essa primeira query traz todo os valores
SELECT
    t.mes || '/' || t.ano  AS  MES_ANO,
    f.sk_localizacao_adm,
    f.sk_localizacao_eng,
    f.sk_tempo,
    f.sk_produto,
    p.ds_cd_categoria_uso,
    f.sk_sujeito,
    f.sk_fatura,
    f.sk_leitura,
    f.sm_volume_agua,
    f.sm_volume_esgoto,
    f.sm_volume_end,
    f.dt_inclusao
FROM
    ora_dw_tat.ft_volume_faturado f
left join ora_dw_tat.dm_produto p on f.sk_produto = p.sk_produto
left join ora_dw_tat.dm_tempo t on f.sk_tempo = t.sk_tempo
where f.sk_tempo in(
/* INSERIR O CÓDIGO DA TABELA DM_TEMPO REFERENTE AO MÊS E ANO A SER FEITA A BUSCA*/
);    


-- Essa variação traz os dados separados por categoria
SELECT
    t.mes || '/' || t.ano AS mes_ano,
    NVL(p.ds_cd_categoria_uso, 'SEM CATEGORIA') AS categoria,
    SUM(f.sm_volume_agua) AS total_sm_volume_agua
FROM ora_dw_tat.ft_volume_faturado f
LEFT JOIN ora_dw_tat.dm_produto p ON f.sk_produto = p.sk_produto
LEFT JOIN ora_dw_tat.dm_tempo   t ON f.sk_tempo   = t.sk_tempo
WHERE f.sk_tempo IN (
/* INSERIR O CÓDIGO DA TABELA DM_TEMPO REFERENTE AO MÊS E ANO A SER FEITA A BUSCA*/
)
GROUP BY
    t.mes || '/' || t.ano,
    NVL(p.ds_cd_categoria_uso, 'SEM CATEGORIA')
ORDER BY
    mes_ano, categoria;

