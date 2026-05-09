
-- SISGESC – SCRIPT: PERFORMANCE E GOVERNANÇA


USE SisGESC; -- se precisar


-- PARTE 1 – SCRIPT DE RESET (DROP → recria estrutura limpa)
-- Execute este bloco ANTES de rodar o DDL novamente durante testes.


SET FOREIGN_KEY_CHECKS = 0;

-- OLAP
DROP TABLE IF EXISTS fato_financeiro;
DROP TABLE IF EXISTS fato_desempenho;
DROP TABLE IF EXISTS dim_disciplina;
DROP TABLE IF EXISTS dim_unidade;
DROP TABLE IF EXISTS dim_curso;
DROP TABLE IF EXISTS dim_aluno;
DROP TABLE IF EXISTS dim_tempo;


-- OLTP (ordem inversa da criação para respeitar FK)
DROP TABLE IF EXISTS tb_folha_pagamento;
DROP TABLE IF EXISTS tb_ferias;
DROP TABLE IF EXISTS tb_despesas;
DROP TABLE IF EXISTS tb_receitas;
DROP TABLE IF EXISTS tb_pagamentos;
DROP TABLE IF EXISTS tb_mensalidades;
DROP TABLE IF EXISTS tb_contrato_escolar;
DROP TABLE IF EXISTS tb_atestados;
DROP TABLE IF EXISTS tb_frequencias;
DROP TABLE IF EXISTS tb_notas;
DROP TABLE IF EXISTS tb_avaliacoes;
DROP TABLE IF EXISTS tb_grade_horaria;
DROP TABLE IF EXISTS tb_formacoes;
DROP TABLE IF EXISTS tb_vinculos;
DROP TABLE IF EXISTS tb_funcionarios;
DROP TABLE IF EXISTS tb_matriculas;
DROP TABLE IF EXISTS tb_aluno_responsavel;
DROP TABLE IF EXISTS tb_responsaveis;
DROP TABLE IF EXISTS tb_alunos;
DROP TABLE IF EXISTS tb_turma_disciplinas;
DROP TABLE IF EXISTS tb_disciplinas;
DROP TABLE IF EXISTS tb_turmas;


-- VIEWS (DROP automático com as tabelas, mas explicitamos para segurança)
DROP VIEW IF EXISTS vw_boletim_aluno;
DROP VIEW IF EXISTS vw_frequencia_aluno;
DROP VIEW IF EXISTS vw_contrato_escolar;
DROP VIEW IF EXISTS vw_mensalidades;
DROP VIEW IF EXISTS vw_inadimplencia;
DROP VIEW IF EXISTS vw_fluxo_caixa_mensal;
DROP VIEW IF EXISTS vw_ferias_detalhada;
DROP VIEW IF EXISTS vw_folha_calculos_base;
DROP VIEW IF EXISTS vw_folha_pagamento;


-- PROCEDURES
DROP PROCEDURE IF EXISTS sp_popular_dim_tempo;

SET FOREIGN_KEY_CHECKS = 1;


-- PARTE 2 – CRIAÇÃO DE ÍNDICES ESTRATÉGICOS
-- Critério: colunas mais usadas em JOINs, WHEREs e ORDER BYs nas VIEWs e nos SELECTs da Fase 3.
-- Padrão: DROP INDEX IF EXISTS antes de cada CREATE INDEX


-- MÓDELO ACADÊMICO

-- Busca de alunos por nome (buscas parciais no front-end da secretaria)
DROP INDEX IF EXISTS idx_alunos_nome ON tb_alunos;
CREATE INDEX idx_alunos_nome
    ON tb_alunos (primeiro_nome, sobrenome);


-- Consulta de matrículas por ano letivo e status
DROP INDEX IF EXISTS idx_matriculas_ano_status ON tb_matriculas;
CREATE INDEX idx_matriculas_ano_status
    ON tb_matriculas (fk_ano_letivo, status);


-- Busca de notas por aluno + disciplina + bimestre (usada na vw_boletim_aluno)
DROP INDEX IF EXISTS idx_notas_aluno_disc_bim ON tb_notas;
CREATE INDEX idx_notas_aluno_disc_bim
    ON tb_notas (fk_rgm, fk_nome_disciplina, fk_bimestre);


-- Filtro de frequências por aluno e disciplina (usada na vw_frequencia_aluno)
DROP INDEX IF EXISTS idx_freq_aluno_disc ON tb_frequencias;
CREATE INDEX idx_freq_aluno_disc
    ON tb_frequencias (fk_rgm, fk_nome_disciplina, fk_ano_letivo);


-- Grade horária – busca por professor e ano (trigger validar_conflito_grade)
DROP INDEX IF EXISTS idx_grade_prof_ano ON tb_grade_horaria;
CREATE INDEX idx_grade_prof_ano
    ON tb_grade_horaria (fk_cpf_professor, fk_ano_letivo, dia_semana, numero_aula);



-- MÓDELO FINANCEIRO

-- Mensalidades por responsável + status (relatório de inadimplência)
DROP INDEX IF EXISTS idx_mensalidades_status ON tb_mensalidades;
CREATE INDEX idx_mensalidades_status
    ON tb_mensalidades (fk_cpf_responsavel, fk_ano_letivo, status);


-- Mensalidades por aluno + mês (trigger atualizar_status_mensalidade)
DROP INDEX IF EXISTS idx_mensalidades_aluno_mes ON tb_mensalidades;
CREATE INDEX idx_mensalidades_aluno_mes
    ON tb_mensalidades (fk_rgm_aluno, fk_ano_letivo, mes_referencia);


-- Pagamentos por aluno + mês (lookup no trigger)
DROP INDEX IF EXISTS idx_pagamentos_aluno_mes ON tb_pagamentos;
CREATE INDEX idx_pagamentos_aluno_mes
    ON tb_pagamentos (fk_rgm_aluno, fk_ano_letivo, fk_mes_referencia);


-- Receitas por data (vw_fluxo_caixa_mensal agrega por ano/mês)
DROP INDEX IF EXISTS idx_receitas_data ON tb_receitas;
CREATE INDEX idx_receitas_data
    ON tb_receitas (data_hora_receita, status);


-- Despesas por data
DROP INDEX IF EXISTS idx_despesas_data ON tb_despesas;
CREATE INDEX idx_despesas_data
    ON tb_despesas (data_hora_despesa, status);


-- MÓDELO RH

-- Vínculo por CPF + cargo (trigger validar_professor_disciplina)
DROP INDEX IF EXISTS idx_vinculos_cargo ON tb_vinculos;
CREATE INDEX idx_vinculos_cargo
    ON tb_vinculos (fk_cpf_funcionario, cargo);


-- Folha por funcionário + mês + ano (lookup no trigger calcular_folha)
DROP INDEX IF EXISTS idx_folha_func_mes ON tb_folha_pagamento;
CREATE INDEX idx_folha_func_mes
    ON tb_folha_pagamento (fk_cpf_funcionario, mes_referencia, ano_referencia);


-- Férias por funcionário + ano (vw_ferias_detalhada e trigger calcular_folha)
DROP INDEX IF EXISTS idx_ferias_func_ano ON tb_ferias;
CREATE INDEX idx_ferias_func_ano
    ON tb_ferias (fk_cpf_funcionario, ano);


-- OLAP 

-- fato_desempenho: drill-down por série (dim_curso) e bimestre
DROP INDEX IF EXISTS idx_fato_desemp_curso_bim ON fato_desempenho;
CREATE INDEX idx_fato_desemp_curso_bim
    ON fato_desempenho (fk_curso, bimestre, ano_letivo);


-- fato_financeiro: análise mensal
DROP INDEX IF EXISTS idx_fato_fin_tempo ON fato_financeiro;
CREATE INDEX idx_fato_fin_tempo
    ON fato_financeiro (fk_tempo, ano_letivo, status_pagamento);



-- PARTE 3 – DEMONSTRAÇÃO DE GANHO DE PERFORMANCE (EXPLAIN)
-- Execute cada EXPLAIN e observe a coluna "key" 
-- deve mostrar o nome do índice sendo utilizado, e "rows" deve ser baixo.


-- EXPLAIN 1 – Busca de notas por aluno e bimestre
EXPLAIN SELECT * FROM tb_notas
WHERE fk_rgm = '2025001'
  AND fk_bimestre = 'BIM1';


-- EXPLAIN 2 – Frequência de um aluno em uma disciplina
EXPLAIN SELECT * FROM tb_frequencias
WHERE fk_rgm = '2025002'
  AND fk_nome_disciplina = 'Matematica'
  AND fk_ano_letivo = 2025;


-- EXPLAIN 3 – Mensalidades em atraso de um responsável
EXPLAIN SELECT * FROM tb_mensalidades
WHERE fk_cpf_responsavel = '11122233344'
  AND fk_ano_letivo = 2025
  AND status = 'Atrasado';


-- EXPLAIN 4 – Conflito de grade horária (mesmo filtro usado no trigger)
EXPLAIN SELECT 1 FROM tb_grade_horaria
WHERE fk_cpf_professor = '10000000003'
  AND fk_ano_letivo    = 2025
  AND dia_semana       = 'Segunda'
  AND numero_aula      = 'aula_1'
  AND data_fim IS NULL;


-- EXPLAIN 5 – JOIN OLAP: fato_desempenho x dim_curso x dim_aluno
EXPLAIN SELECT fd.bimestre, da.nome_completo, fd.media_bimestral
FROM fato_desempenho fd
JOIN dim_aluno da ON da.sk_aluno = fd.fk_aluno
JOIN dim_curso dc ON dc.sk_curso = fd.fk_curso
WHERE fd.ano_letivo = 2025
  AND dc.serie = '6';



-- PARTE 4 – CHECKLIST DE GOVERNANÇA


-- 1. Todas as tabelas criadas (snake_case)
SELECT TABLE_NAME AS tabela
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'SisGESC'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;


-- 2. Todas as views criadas
SELECT TABLE_NAME AS view_name
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'SisGESC'
ORDER BY TABLE_NAME;


-- 3. Todos os triggers criados
SELECT
    TRIGGER_NAME            AS trigger_nome,
    EVENT_MANIPULATION      AS evento,
    EVENT_OBJECT_TABLE      AS tabela,
    ACTION_TIMING           AS momento
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE TRIGGER_SCHEMA = 'SisGESC'
ORDER BY EVENT_OBJECT_TABLE, ACTION_TIMING;


-- 4. Todos os índices criados pelo projeto (exclui PKs automáticas)
SELECT
    TABLE_NAME   AS tabela,
    INDEX_NAME   AS indice,
    COLUMN_NAME  AS coluna,
    SEQ_IN_INDEX AS posicao
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'SisGESC'
  AND INDEX_NAME LIKE 'idx_%'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;


-- 5. Todas as constraints por tabela (PK, FK, CHECK, UNIQUE)
SELECT
    TABLE_NAME        AS tabela,
    CONSTRAINT_NAME   AS constraint_nome,
    CONSTRAINT_TYPE   AS tipo
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'SisGESC'
ORDER BY TABLE_NAME, CONSTRAINT_TYPE;



-- =============================================================================
-- ORDEM DE EXECUÇÃO RECOMENDADA PARA O DIA DA BANCA
-- =============================================================================
-- 1. fase5_6_performance_governanca.sql  → PARTE 1 (reset/drop)
-- 2. fase1_estrutura.sql                 → DDL completo
-- 3. fase2_carga_dados.sql               → 1ª carga → COUNT(*) todas as tabelas
-- 4. fase2_carga_dados.sql               → 2ª carga → COUNT(*) deve ser idêntico
-- 5. fase3_oltp_consultas.sql            → SELECTs + validação de triggers
-- 6. fase4_olap_etl.sql                  → Star Schema + ETL + validação OLTP=OLAP
-- 7. fase5_6_performance_governanca.sql  → PARTES 2 e 3 (índices + EXPLAIN)
-- 8. fase5_6_performance_governanca.sql  → PARTE 4 (checklist de governança)
-- =============================================================================