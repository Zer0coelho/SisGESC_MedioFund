
-- SISGESC – SCRIPT: OLAP E ETL
-- Finalidade : Criar o modelo dimensional (Star Schema), executar o processo
--              ETL e validar que os totais do OLAP batem com o OLTP.


USE SisGESC; -- Se precisar



-- PARTE 1 – STAR SCHEMA (Modelo Dimensional)



-- Gerada automaticamente via procedure para o ano de 2025.
CREATE TABLE IF NOT EXISTS dim_tempo (
    sk_tempo      INT          NOT NULL AUTO_INCREMENT,
    data_completa DATE         NOT NULL,
    dia           INT          NOT NULL,
    mes           INT          NOT NULL,
    nome_mes      VARCHAR(20)  NOT NULL,
    trimestre     INT          NOT NULL,
    bimestre      VARCHAR(10)  NOT NULL,  -- BIM1 / BIM2 / BIM3 / BIM4
    ano           INT          NOT NULL,
    dia_semana    VARCHAR(20)  NOT NULL,
    PRIMARY KEY (sk_tempo),
    UNIQUE KEY uq_dim_tempo_data (data_completa)
);


-- Popula dim_tempo com todos os dias de 2025 (se ainda não existirem)
DROP PROCEDURE IF EXISTS sp_popular_dim_tempo;
DELIMITER $$
CREATE PROCEDURE sp_popular_dim_tempo(p_ano INT)
BEGIN
    DECLARE v_data DATE;
    DECLARE v_fim  DATE;
    SET v_data = CONCAT(p_ano, '-01-01');
    SET v_fim  = CONCAT(p_ano, '-12-31');
    WHILE v_data <= v_fim DO
        INSERT IGNORE INTO dim_tempo
        (data_completa, dia, mes, nome_mes, trimestre, bimestre, ano, dia_semana)
        VALUES (
            v_data,
            DAY(v_data),
            MONTH(v_data),
            DATE_FORMAT(v_data,'%M'),
            CEIL(MONTH(v_data)/3),
            CASE
                WHEN MONTH(v_data) BETWEEN 1 AND 2  THEN 'BIM1'
                WHEN MONTH(v_data) BETWEEN 3 AND 4  THEN 'BIM1'
                WHEN MONTH(v_data) BETWEEN 5 AND 6  THEN 'BIM2'
                WHEN MONTH(v_data) BETWEEN 7 AND 8  THEN 'BIM3'
                WHEN MONTH(v_data) BETWEEN 9 AND 10 THEN 'BIM3'
                ELSE 'BIM4'
            END,
            YEAR(v_data),
            DATE_FORMAT(v_data,'%W')
        );
        SET v_data = DATE_ADD(v_data, INTERVAL 1 DAY);
    END WHILE;
END$$
DELIMITER ;

CALL sp_popular_dim_tempo(2025);




-- DIMENSÃO ALUNO

CREATE TABLE IF NOT EXISTS dim_aluno (
    sk_aluno      INT          NOT NULL AUTO_INCREMENT,
    pk_rgm        VARCHAR(10)  NOT NULL,
    nome_completo VARCHAR(255) NOT NULL,
    sexo          VARCHAR(20)  NOT NULL,
    ano_nascimento INT         NOT NULL,
    cidade        VARCHAR(80)  NOT NULL,
    estado        CHAR(2)      NOT NULL,
    PRIMARY KEY (sk_aluno),
    UNIQUE KEY uq_dim_aluno_rgm (pk_rgm)
);



-- DIMENSÃO CURSO (série + turno)

CREATE TABLE IF NOT EXISTS dim_curso (
    sk_curso      INT          NOT NULL AUTO_INCREMENT,
    serie         VARCHAR(10)  NOT NULL,
    turno         VARCHAR(10)  NOT NULL,
    nivel         VARCHAR(20)  NOT NULL,   -- Fundamental / Medio
    PRIMARY KEY (sk_curso),
    UNIQUE KEY uq_dim_curso (serie, turno)
);



-- DIMENSÃO UNIDADE (representada pelo estado/cidade )

CREATE TABLE IF NOT EXISTS dim_unidade (
    sk_unidade    INT          NOT NULL AUTO_INCREMENT,
    nome_escola   VARCHAR(255) NOT NULL,
    cidade        VARCHAR(80)  NOT NULL,
    estado        CHAR(2)      NOT NULL,
    PRIMARY KEY (sk_unidade)
);



-- DIMENSÃO DISCIPLINA

CREATE TABLE IF NOT EXISTS dim_disciplina (
    sk_disciplina INT          NOT NULL AUTO_INCREMENT,
    nome          VARCHAR(100) NOT NULL,
    nivel         VARCHAR(20)  NOT NULL,
    PRIMARY KEY (sk_disciplina),
    UNIQUE KEY uq_dim_disciplina (nome)
);


-- TABELA FATO – DESEMPENHO ACADÊMICO
-- Granularidade: 1 linha por aluno × disciplina × bimestre × ano letivo
CREATE TABLE IF NOT EXISTS fato_desempenho (
    sk_fato           INT          NOT NULL AUTO_INCREMENT,
    fk_tempo          INT          NOT NULL,   -- referência à dim_tempo (mês de referência do bimestre)
    fk_aluno          INT          NOT NULL,
    fk_curso          INT          NOT NULL,
    fk_unidade        INT          NOT NULL,
    fk_disciplina     INT          NOT NULL,
    ano_letivo        INT          NOT NULL,
    bimestre          VARCHAR(10)  NOT NULL,
    media_bimestral   DECIMAL(5,2) NOT NULL,
    total_aulas       INT          NOT NULL DEFAULT 0,
    aulas_presentes   INT          NOT NULL DEFAULT 0,
    pct_frequencia    DECIMAL(5,2) NOT NULL DEFAULT 0,
    status_desempenho VARCHAR(20)  NOT NULL,   -- Aprovado / Recuperacao / Reprovado
    status_frequencia VARCHAR(20)  NOT NULL,   -- Regular / Risco_Reprovacao
    PRIMARY KEY (sk_fato),
    UNIQUE KEY uq_fato (fk_aluno, fk_disciplina, fk_curso, ano_letivo, bimestre),
    CONSTRAINT fk_fato_tempo       FOREIGN KEY (fk_tempo)      REFERENCES dim_tempo      (sk_tempo),
    CONSTRAINT fk_fato_aluno       FOREIGN KEY (fk_aluno)      REFERENCES dim_aluno      (sk_aluno),
    CONSTRAINT fk_fato_curso       FOREIGN KEY (fk_curso)      REFERENCES dim_curso      (sk_curso),
    CONSTRAINT fk_fato_unidade     FOREIGN KEY (fk_unidade)    REFERENCES dim_unidade    (sk_unidade),
    CONSTRAINT fk_fato_disciplina  FOREIGN KEY (fk_disciplina) REFERENCES dim_disciplina (sk_disciplina)
);



-- TABELA FATO – FINANCEIRO
-- Granularidade: 1 linha por mensalidade / parcela
CREATE TABLE IF NOT EXISTS fato_financeiro (
    sk_fato           INT          NOT NULL AUTO_INCREMENT,
    fk_tempo          INT          NOT NULL,
    fk_aluno          INT          NOT NULL,
    fk_curso          INT          NOT NULL,
    fk_unidade        INT          NOT NULL,
    ano_letivo        INT          NOT NULL,
    mes_referencia    INT          NOT NULL,
    valor_mensalidade DECIMAL(10,2) NOT NULL,
    valor_pago        DECIMAL(10,2) NOT NULL DEFAULT 0,
    inclui_rematricula BOOLEAN     NOT NULL DEFAULT FALSE,
    status_pagamento  VARCHAR(20)  NOT NULL,
    PRIMARY KEY (sk_fato),
    UNIQUE KEY uq_fato_fin (fk_aluno, fk_curso, ano_letivo, mes_referencia),
    CONSTRAINT fk_fatofin_tempo    FOREIGN KEY (fk_tempo)   REFERENCES dim_tempo   (sk_tempo),
    CONSTRAINT fk_fatofin_aluno    FOREIGN KEY (fk_aluno)   REFERENCES dim_aluno   (sk_aluno),
    CONSTRAINT fk_fatofin_curso    FOREIGN KEY (fk_curso)   REFERENCES dim_curso   (sk_curso),
    CONSTRAINT fk_fatofin_unidade  FOREIGN KEY (fk_unidade) REFERENCES dim_unidade (sk_unidade)
);



-- PARTE 2 – PROCESSO ETL (Extração → Transformação → Carga)

-- E1. EXTRAÇÃO E CARGA – dim_unidade (escola única)
INSERT IGNORE INTO dim_unidade (nome_escola, cidade, estado)
VALUES ('SisGESC Escola', 'São Paulo', 'SP');


-- E2. EXTRAÇÃO E CARGA – dim_aluno (a partir de tb_alunos)
INSERT IGNORE INTO dim_aluno (pk_rgm, nome_completo, sexo, ano_nascimento, cidade, estado)
SELECT
    pk_rgm,
    CONCAT(primeiro_nome,' ',sobrenome),
    sexo,
    YEAR(data_nascimento),
    cidade,
    estado
FROM tb_alunos;


-- E3. EXTRAÇÃO E CARGA – dim_curso (a partir de tb_turmas)
INSERT IGNORE INTO dim_curso (serie, turno, nivel)
SELECT DISTINCT
    serie,
    turno,
    CASE WHEN serie IN ('6','7','8','9') THEN 'Fundamental' ELSE 'Medio' END
FROM tb_turmas;


-- E4. EXTRAÇÃO E CARGA – dim_disciplina (a partir de tb_disciplinas)
INSERT IGNORE INTO dim_disciplina (nome, nivel)
SELECT pk_nome_disciplina, nivel
FROM tb_disciplinas;


-- E5. CARGA – fato_desempenho
-- Fonte: vw_boletim_aluno (notas) + vw_frequencia_aluno (presença)
-- O campo fk_tempo aponta para o último dia do bimestre (data de referência analítica)
INSERT IGNORE INTO fato_desempenho
(fk_tempo, fk_aluno, fk_curso, fk_unidade, fk_disciplina,
 ano_letivo, bimestre, media_bimestral,
 total_aulas, aulas_presentes, pct_frequencia,
 status_desempenho, status_frequencia)
SELECT
    dt.sk_tempo,
    da.sk_aluno,
    dc.sk_curso,
    (SELECT sk_unidade FROM dim_unidade LIMIT 1),
    dd.sk_disciplina,
    b.fk_ano_letivo,
    b.fk_bimestre,
    b.media_bimestral,
    COALESCE(fr.total_aulas,      0),
    COALESCE(fr.aulas_presentes,  0),
    COALESCE(fr.percentual_frequencia, 0),
    b.status_bimestre,
    COALESCE(fr.situacao, 'Regular')
FROM vw_boletim_aluno b
-- Dimensão Tempo: aponta para o último dia do bimestre como data analítica de referência
JOIN dim_tempo dt ON dt.data_completa = CASE b.fk_bimestre
    WHEN 'BIM1' THEN CONCAT(b.fk_ano_letivo,'-04-30')
    WHEN 'BIM2' THEN CONCAT(b.fk_ano_letivo,'-06-30')
    WHEN 'BIM3' THEN CONCAT(b.fk_ano_letivo,'-09-30')
    ELSE              CONCAT(b.fk_ano_letivo,'-12-31')
END
JOIN dim_aluno da ON da.pk_rgm = b.fk_rgm
JOIN tb_matriculas m
    ON m.fk_rgm = b.fk_rgm
    AND m.fk_serie = b.fk_serie
    AND m.fk_ano_letivo = b.fk_ano_letivo
JOIN dim_curso dc ON dc.serie = m.fk_serie AND dc.turno = m.fk_turno
JOIN dim_disciplina dd ON dd.nome = b.fk_nome_disciplina
LEFT JOIN vw_frequencia_aluno fr
    ON fr.fk_rgm             = b.fk_rgm
    AND fr.fk_nome_disciplina = b.fk_nome_disciplina
    AND fr.fk_ano_letivo      = b.fk_ano_letivo
    AND fr.fk_serie           = b.fk_serie;


-- E6. CARGA – fato_financeiro
-- Fonte: tb_mensalidades + tb_pagamentos
INSERT IGNORE INTO fato_financeiro
(fk_tempo, fk_aluno, fk_curso, fk_unidade, ano_letivo, mes_referencia,
 valor_mensalidade, valor_pago, inclui_rematricula, status_pagamento)
SELECT
    dt.sk_tempo,
    da.sk_aluno,
    dc.sk_curso,
    (SELECT sk_unidade FROM dim_unidade LIMIT 1),
    m.fk_ano_letivo,
    m.mes_referencia,
    m.valor_mensalidade,
    COALESCE(p.valor_pago, 0),
    m.inclui_rematricula,
    m.status
FROM tb_mensalidades m
JOIN dim_tempo dt ON dt.data_completa = LAST_DAY(
        CONCAT(m.fk_ano_letivo,'-',LPAD(m.mes_referencia,2,'0'),'-01'))
JOIN dim_aluno da ON da.pk_rgm = m.fk_rgm_aluno
JOIN tb_matriculas mat
    ON mat.fk_rgm         = m.fk_rgm_aluno
    AND mat.fk_ano_letivo = m.fk_ano_letivo
JOIN dim_curso dc ON dc.serie = mat.fk_serie AND dc.turno = mat.fk_turno
LEFT JOIN tb_pagamentos p
    ON p.fk_cpf_responsavel = m.fk_cpf_responsavel
    AND p.fk_rgm_aluno      = m.fk_rgm_aluno
    AND p.fk_ano_letivo     = m.fk_ano_letivo
    AND p.fk_mes_referencia = m.mes_referencia;



-- PARTE 3 – VALIDAÇÃO: OLTP vs OLAP (totais devem ser idênticos)

-- Comparação 1 – Total de alunos distintos
SELECT 'OLTP – tb_alunos'    AS origem, COUNT(DISTINCT pk_rgm)       AS total_alunos FROM tb_alunos
UNION ALL
SELECT 'OLAP – dim_aluno',              COUNT(DISTINCT pk_rgm)       FROM dim_aluno;


-- Comparação 2 – Soma total de mensalidades no OLTP vs OLAP
SELECT 'OLTP – tb_mensalidades' AS origem, SUM(valor_mensalidade) AS soma_mensalidades
FROM tb_mensalidades WHERE status != 'Cancelado'
UNION ALL
SELECT 'OLAP – fato_financeiro',         SUM(valor_mensalidade)
FROM fato_financeiro WHERE status_pagamento != 'Cancelado';


-- Comparação 3 – Soma de pagamentos realizados
SELECT 'OLTP – tb_pagamentos'   AS origem, SUM(valor_pago) AS total_pago FROM tb_pagamentos
UNION ALL
SELECT 'OLAP – fato_financeiro',           SUM(valor_pago) FROM fato_financeiro WHERE valor_pago > 0;


-- Comparação 4 – Contagem de registros de desempenho (notas × bimestre × disciplina)
SELECT 'OLTP – vw_boletim_aluno' AS origem, COUNT(*) AS linhas FROM vw_boletim_aluno WHERE fk_ano_letivo = 2025
UNION ALL
SELECT 'OLAP – fato_desempenho',           COUNT(*) FROM fato_desempenho WHERE ano_letivo = 2025;



-- PARTE 4 – CONSULTAS ANALÍTICAS (OLAP)

-- OLAP-1. Média geral por série e bimestre (pivot manual)
SELECT
    dc.serie,
    fd.bimestre,
    ROUND(AVG(fd.media_bimestral),2) AS media_geral,
    COUNT(DISTINCT fd.fk_aluno)      AS alunos_avaliados
FROM fato_desempenho fd
JOIN dim_curso dc ON dc.sk_curso = fd.fk_curso
WHERE fd.ano_letivo = 2025
GROUP BY dc.serie, fd.bimestre
ORDER BY dc.serie, fd.bimestre;


-- OLAP-2. Receita mensal consolidada (a partir do OLAP)
SELECT
    dt.ano,
    dt.mes,
    dt.nome_mes,
    SUM(ff.valor_mensalidade) AS receita_prevista,
    SUM(ff.valor_pago)        AS receita_realizada,
    SUM(ff.valor_mensalidade) - SUM(ff.valor_pago) AS inadimplencia
FROM fato_financeiro ff
JOIN dim_tempo dt ON dt.sk_tempo = ff.fk_tempo
WHERE ff.ano_letivo = 2025
GROUP BY dt.ano, dt.mes, dt.nome_mes
ORDER BY dt.ano, dt.mes;


-- OLAP-3. Alunos em risco de reprovação por frequência (< 75%) por série
SELECT
    dc.serie,
    COUNT(*) AS alunos_em_risco
FROM fato_desempenho fd
JOIN dim_curso dc ON dc.sk_curso = fd.fk_curso
WHERE fd.status_frequencia = 'Risco_Reprovacao'
  AND fd.ano_letivo = 2025
GROUP BY dc.serie
ORDER BY dc.serie;
