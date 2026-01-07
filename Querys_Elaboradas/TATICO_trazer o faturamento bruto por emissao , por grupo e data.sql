SELECT
    tmp.mes || '/' || tmp.ano  AS  MES_ANO,
    f.sk_localizacao_adm,
    adm.cd_gr_faturamento,
    f.sk_localizacao_eng,
    f.sk_tempo,
    f.sk_produto,
    p.ds_cd_categoria_uso,
    f.sk_sujeito,
    f.sk_fatura,
    f.sk_leitura,
    f.sm_valor_agua,
    f.sm_valor_esgoto,
    f.sm_valor_end,
    f.sm_valor_servico,
    f.sm_valor_multa_sabesp,
    f.sm_valor_juros_sabesp,
    f.sm_valor_atm_sabesp,
    f.sm_valor_encargo_mun,
    f.sm_valor_taxa_lixo,
    f.sm_valor_multa_lixo,
    f.sm_valor_juros_lixo,
    f.sm_valor_atm_lixo,
    f.sm_valor_trcf,
    f.sm_valor_credito,
    f.sm_valor_debito,
    f.sm_valor_retencao,
    f.sm_valor_outros,
    f.sm_valor_total,
    f.dt_inclusao 
FROM
    ora_dw_tat.ft_faturamento_bruto_emissao f
left join ora_dw_tat.dm_localizacao_adm adm
    on f.sk_localizacao_adm = adm.sk_localizacao_adm
left join ora_dw_tat.dm_produto p
    on f.sk_produto = p.sk_produto
left join ora_dw_tat.dm_tempo tmp
    on f.sk_tempo = tmp.sk_tempo
WHERE f.sk_tempo= '81';