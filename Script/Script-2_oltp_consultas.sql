
-- SISGESC – SCRIPT: OPERAÇÕES OLTP E TRANSAÇÕES
-- Finalidade : SELECTs simples e Subselects avançados (com agregação/correlação) que cobrem os módulos Acadêmico, Financeiro e RH.


USE SisGESC; -- Se precisar



-- BLOCO A – CONSULTAS SIMPLES (SELECT direto em tabelas/views)

-- A1. Lista completa de alunos com nome, série e turno matriculados em 2025
SELECT
    a.pk_rgm,
    CONCAT(a.primeiro_nome,' ',a.sobrenome) AS aluno,
    m.fk_serie  AS serie,
    m.fk_turno  AS turno,
    m.status    AS status_matricula
FROM tb_alunos a
JOIN tb_matriculas m ON m.fk_rgm = a.pk_rgm
WHERE m.fk_ano_letivo = 2025
ORDER BY m.fk_serie, aluno;



-- A2. Boletim completo de um aluno (via VIEW vw_boletim_aluno)
SELECT
    fk_rgm,
    fk_serie,
    fk_nome_disciplina AS disciplina,
    fk_bimestre        AS bimestre,
    media_bimestral,
    status_bimestre
FROM vw_boletim_aluno
WHERE fk_rgm = '2025001'
ORDER BY fk_nome_disciplina, fk_bimestre;



-- A3. Frequência de todos os alunos (via VIEW vw_frequencia_aluno)
SELECT
    fk_rgm,
    fk_nome_disciplina AS disciplina,
    total_aulas,
    aulas_presentes,
    percentual_frequencia,
    situacao
FROM vw_frequencia_aluno
WHERE fk_ano_letivo = 2025
ORDER BY fk_rgm, disciplina;



-- A4. Holerite de janeiro 2025 (via VIEW vw_folha_pagamento)
SELECT
    fk_cpf_funcionario                               AS cpf,
    mes_referencia                                   AS mes,
    salario_base,
    abono_ferias,
    inss,
    irrf,
    vale_transporte,
    vale_refeicao,
    total_proventos,
    total_descontos,
    salario_liquido
FROM vw_folha_pagamento
WHERE mes_referencia = 1 AND ano_referencia = 2025
ORDER BY cpf;



-- A5. Mensalidades em aberto (via VIEW vw_mensalidades)
SELECT
    fk_rgm_aluno,
    mes_referencia,
    data_vencimento,
    valor_mensalidade,
    status,
    dias_atraso,
    multa,
    juros,
    valor_total
FROM vw_mensalidades
WHERE status IN ('Pendente','Atrasado')
ORDER BY fk_rgm_aluno, mes_referencia;



-- A6. Fluxo de caixa mensal (via VIEW vw_fluxo_caixa_mensal)
SELECT ano, mes, total_receitas, total_despesas, saldo_mensal
FROM vw_fluxo_caixa_mensal
ORDER BY ano, mes;



-- A7. Grade horária – professor e suas turmas
SELECT
    f.primeiro_nome                                  AS professor,
    g.fk_nome_disciplina                             AS disciplina,
    g.fk_serie                                       AS serie,
    g.fk_turno                                       AS turno,
    g.dia_semana,
    g.numero_aula,
    g.carga_horaria_semanal
FROM tb_grade_horaria g
JOIN tb_funcionarios f ON f.pk_cpf = g.fk_cpf_professor
WHERE g.data_fim IS NULL
ORDER BY professor, g.dia_semana, g.numero_aula;



-- A8. Contratos com valores calculados (via VIEW vw_contrato_escolar)
SELECT
    fk_rgm_aluno,
    fk_serie,
    bolsa,
    valor_mensalidade,
    valor_desconto,
    valor_final,
    valor_rematricula,
    status
FROM vw_contrato_escolar
ORDER BY fk_rgm_aluno;



-- A9. Férias detalhadas (via VIEW vw_ferias_detalhada)
SELECT
    fk_cpf_funcionario,
    ano,
    data_inicio,
    data_fim,
    data_retorno,
    valor_abono_ferias,
    status
FROM vw_ferias_detalhada
ORDER BY ano, data_inicio;




-- BLOCO B – SUBSELECTS INTERMEDIÁRIOS / AVANÇADOS

-- B1. Alunos em recuperação em QUALQUER disciplina no BIM1 2025
--     (subquery correlacionada na cláusula WHERE)
SELECT DISTINCT
    a.pk_rgm,
    CONCAT(a.primeiro_nome,' ',a.sobrenome) AS aluno
FROM tb_alunos a
WHERE EXISTS (
    SELECT 1
    FROM vw_boletim_aluno b
    WHERE b.fk_rgm        = a.pk_rgm
      AND b.fk_bimestre   = 'BIM1'
      AND b.fk_ano_letivo = 2025
      AND b.status_bimestre IN ('Recuperacao','Reprovado')
);



-- B2. Responsável com maior valor total de mensalidades em aberto (com encargos)
--     (subquery na cláusula FROM – derived table)
SELECT
    i.fk_cpf_responsavel,
    CONCAT(r.primeiro_nome,' ',r.sobrenome) AS responsavel,
    i.parcelas_atrasadas,
    i.valor_base_devido,
    i.valor_total_com_encargos
FROM vw_inadimplencia i
JOIN tb_responsaveis r ON r.pk_cpf = i.fk_cpf_responsavel
ORDER BY i.valor_total_com_encargos DESC
LIMIT 5;



-- B3. Média geral por disciplina em 2025 (alunos com ao menos um bimestre lançado)
--     (agregação sobre a VIEW vw_boletim_aluno)
SELECT
    fk_nome_disciplina AS disciplina,
    fk_serie           AS serie,
    COUNT(DISTINCT fk_rgm)          AS qtd_alunos,
    ROUND(AVG(media_bimestral), 2)  AS media_turma,
    MIN(media_bimestral)            AS menor_nota,
    MAX(media_bimestral)            AS maior_nota
FROM vw_boletim_aluno
WHERE fk_ano_letivo = 2025
GROUP BY fk_nome_disciplina, fk_serie
ORDER BY fk_serie, disciplina;



-- B4. Professores que estão acima da carga horária de 20 aulas/semana
--     (HAVING com SUM agregado)
SELECT
    g.fk_cpf_professor,
    CONCAT(f.primeiro_nome,' ',f.sobrenome) AS professor,
    SUM(g.carga_horaria_semanal)            AS total_horas_semana
FROM tb_grade_horaria g
JOIN tb_funcionarios f ON f.pk_cpf = g.fk_cpf_professor
WHERE g.data_fim IS NULL
  AND g.fk_ano_letivo = 2025
GROUP BY g.fk_cpf_professor, professor
HAVING SUM(g.carga_horaria_semanal) > 20;



-- B5. Alunos sem nenhum pagamento registrado em 2025
--     (NOT EXISTS correlacionado)
SELECT
    a.pk_rgm,
    CONCAT(a.primeiro_nome,' ',a.sobrenome) AS aluno
FROM tb_alunos a
WHERE NOT EXISTS (
    SELECT 1
    FROM tb_pagamentos p
    WHERE p.fk_rgm_aluno  = a.pk_rgm
      AND p.fk_ano_letivo = 2025
);



-- B6. Receita x Despesa por mês – apenas meses com saldo negativo
SELECT ano, mes, total_receitas, total_despesas, saldo_mensal
FROM vw_fluxo_caixa_mensal
WHERE saldo_mensal < 0
ORDER BY ano, mes;



-- B7. Funcionários com salário acima da média do próprio departamento
--     (subquery correlacionada no WHERE com agregação)
SELECT
    f.pk_cpf,
    CONCAT(f.primeiro_nome,' ',f.sobrenome) AS funcionario,
    v.cargo,
    v.departamento,
    v.salario_base
FROM tb_funcionarios f
JOIN tb_vinculos v ON v.fk_cpf_funcionario = f.pk_cpf
WHERE v.salario_base > (
    SELECT AVG(v2.salario_base)
    FROM tb_vinculos v2
    WHERE v2.departamento = v.departamento
)
ORDER BY v.departamento, v.salario_base DESC;



-- B8. Alunos com percentual de frequência abaixo de 75% em alguma disciplina
--     (subquery com IN / derived table)
SELECT
    a.pk_rgm,
    CONCAT(a.primeiro_nome,' ',a.sobrenome) AS aluno,
    fr.fk_nome_disciplina                   AS disciplina,
    fr.percentual_frequencia,
    fr.situacao
FROM tb_alunos a
JOIN vw_frequencia_aluno fr ON fr.fk_rgm = a.pk_rgm
WHERE fr.situacao = 'Risco_Reprovacao'
  AND fr.fk_ano_letivo = 2025
ORDER BY a.pk_rgm, disciplina;



-- B9. Top 3 disciplinas com maior taxa de recuperação no BIM1
SELECT
    fk_nome_disciplina                                              AS disciplina,
    COUNT(*)                                                        AS total_alunos_avaliados,
    SUM(CASE WHEN status_bimestre IN ('Recuperacao','Reprovado')
             THEN 1 ELSE 0 END)                                     AS em_recuperacao,
    ROUND(
        SUM(CASE WHEN status_bimestre IN ('Recuperacao','Reprovado')
                 THEN 1 ELSE 0 END) / COUNT(*) * 100
    , 1)                                                            AS pct_recuperacao
FROM vw_boletim_aluno
WHERE fk_bimestre = 'BIM1' AND fk_ano_letivo = 2025
GROUP BY fk_nome_disciplina
ORDER BY pct_recuperacao DESC
LIMIT 3;



-- BLOCO C – TESTES EXPLÍCITOS DE TRIGGERS

-- C1. Teste trigger validar_nivel_disciplina

-- Tentativa de inserir disciplina 'Biologia' (Médio) na turma de 6° (Fundamental)
-- Deve retornar ERRO: Disciplina exclusiva do Medio nao e permitida para o Fundamental!
-- INSERT INTO tb_turma_disciplinas VALUES ('6',2025,'Manha','Biologia');


-- C2. Teste trigger validar_cargo_departamento

-- Tentativa de inserir 'Porteiro' no departamento 'Pedagogico' deve retornar ERRO
-- INSERT INTO tb_vinculos VALUES ('10000000007','Porteiro','Pedagogico',2500.00);


-- C3. Teste trigger validar_nota_maxima

-- Tentativa de inserir nota 11 em avaliação de valor_maximo = 10
-- Deve retornar ERRO: Nota superior ao valor maximo da avaliacao!
-- INSERT INTO tb_notas (fk_rgm,fk_cpf_professor,fk_serie,fk_ano_letivo,fk_turno,
--   fk_nome_disciplina,fk_bimestre,fk_tipo,fk_titulo,nota_obtida)
-- VALUES ('2025001','10000000003','6',2025,'Manha','Matematica','BIM1','Prova','Prova BIM1 Mat',11.00);


-- C4. Verificar status de recuperação calculado automaticamente pelo trigger
SELECT fk_rgm, fk_nome_disciplina, fk_bimestre, nota_obtida, status
FROM tb_notas
WHERE fk_rgm IN ('2025001','2025002')
  AND fk_nome_disciplina = 'Matematica'
  AND fk_bimestre = 'BIM1'
ORDER BY fk_rgm, fk_titulo;


-- C5. Confirmar que o trigger gerar_mensalidades criou 12 parcelas por contrato
SELECT fk_rgm_aluno, COUNT(*) AS total_parcelas, MIN(mes_referencia) AS primeiro_mes,
       MAX(mes_referencia) AS ultimo_mes, SUM(valor_mensalidade) AS total_anual
FROM tb_mensalidades
GROUP BY fk_rgm_aluno
ORDER BY fk_rgm_aluno;


-- C6. Confirmar que o trigger atualizar_status_mensalidade marcou parcelas como 'Pago'
SELECT fk_rgm_aluno, mes_referencia, valor_mensalidade, data_pagamento, status
FROM tb_mensalidades
WHERE fk_rgm_aluno IN ('2025001','2025004')
ORDER BY fk_rgm_aluno, mes_referencia;


-- C7. SHOW WARNINGS – deve exibir o aviso gerado pelo trigger verificar_frequencia
-- para o aluno 2025002 (frequência abaixo de 75%)
SHOW WARNINGS;
