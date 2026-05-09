
-- SisGESC – RUN_ALL.SQL

-- Como Executar:
--   mysql -u root -p < run_all.sql ou -> SOURCE /caminho/run_all.sql  (dentro do MySQL Workbench)
-- ORDEM:
--   PASSO 1 → Reset completo (DROP de tudo)
--   PASSO 2 → DDL: criação da estrutura (tabelas, views, triggers)
--   PASSO 3 → DML: 1ª carga de dados  + COUNT(*) de validação
--   PASSO 4 → DML: 2ª carga (reexecução) + COUNT(*) para provar idempotência
--   PASSO 5 → OLTP: SELECTs simples e subselects avançados
--   PASSO 6 → OLAP/ETL: Star Schema + carga dimensional + validação OLTP=OLAP
--   PASSO 7 → Performance: índices + EXPLAIN
--   PASSO 8 → Governança: checklist final


-- PASSO 1 – RESET COMPLETO (DROP → prepara ambiente limpo para o DDL)
-- SISGESC – SCRIPT: PERFORMANCE E GOVERNANÇA


USE SisGESC; 
-- se precisar

-- PARTE 1 – SCRIPT DE RESET (DROP → recria estrutura limpa)
-- Execute este bloco ANTES de rodar o DDL novamente durante testes.

-- Desabilita temporariamente a verificação de chaves estrangeiras (FK)
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
-- Remove a procedure de população da dimensão tempo caso já exista,
-- evitando erro de duplicidade na recriação durante o Script4 (OLAP/ETL).
DROP PROCEDURE IF EXISTS sp_popular_dim_tempo;

SET FOREIGN_KEY_CHECKS = 1;




-- PASSO 2 – DDL: CRIAÇÃO DA ESTRUTURA COMPLETA
-- (tabelas, views, triggers, procedures)


CREATE DATABASE IF NOT EXISTS SisGESC
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE SisGESC;

-- !!Aviso!! todos os TRIGGER estão no final do codigo

-- tb_alunos armazena os dados cadastrais de cada aluno da instituição.
-- pk_rgm: identificador único do aluno (RGM já existente).
-- Trigger limpar_dados_aluno remove pontuação de pk_rgm, cpf e cep no INSERT.
CREATE TABLE tb_alunos (
    pk_rgm          VARCHAR(10)   NOT NULL,
    primeiro_nome   VARCHAR(100)  NOT NULL,
    sobrenome       VARCHAR(155)  NOT NULL,
    sexo            ENUM('Masculino','Feminino','Intersexo','Nao_Informado') NOT NULL,
    cpf             CHAR(11)      NOT NULL,
    data_nascimento DATE          NOT NULL,
    email           VARCHAR(255)  NOT NULL,
    rua             VARCHAR(150)  NOT NULL,
    numero          VARCHAR(10)   NOT NULL,
    complemento     VARCHAR(50)   NULL,
    bairro          VARCHAR(80)   NOT NULL,
    cidade          VARCHAR(80)   NOT NULL,
    estado          CHAR(2)       NOT NULL,
    cep             CHAR(8)       NOT NULL,
    data_cadastro   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (pk_rgm),
    UNIQUE KEY uq_alunos_cpf   (cpf),
    UNIQUE KEY uq_alunos_email (email)
);



-- tb_responsaveis armazena os responsáveis dos alunos (pai, mãe, tutor legal, etc.).
-- responsavel_financeiro indica quem assina o contrato e recebe cobranças.
CREATE TABLE tb_responsaveis (
    pk_cpf                 CHAR(11)      NOT NULL,
    primeiro_nome          VARCHAR(100)  NOT NULL,
    sobrenome              VARCHAR(155)  NOT NULL,
    email                  VARCHAR(255)  NOT NULL,
    telefone               VARCHAR(15)   NOT NULL,
    parentesco             ENUM('Pai','Mae','Avo','Avoa','Tio','Tia','Tutor_Legal','Outro') NOT NULL,
    responsavel_financeiro BOOLEAN       NOT NULL DEFAULT FALSE,
    PRIMARY KEY (pk_cpf),
    UNIQUE KEY uq_responsaveis_email (email)
);



-- tb_aluno_responsavel associativa N:N entre alunos e responsáveis.
-- Um aluno pode ter múltiplos responsáveis e vice-versa.
CREATE TABLE tb_aluno_responsavel (
    fk_rgm  VARCHAR(10)  NOT NULL,
    fk_cpf  CHAR(11)     NOT NULL,
    PRIMARY KEY (fk_rgm, fk_cpf),
    CONSTRAINT fk_alresp_rgm FOREIGN KEY (fk_rgm) REFERENCES tb_alunos      (pk_rgm),
    CONSTRAINT fk_alresp_cpf FOREIGN KEY (fk_cpf) REFERENCES tb_responsaveis (pk_cpf)
);



-- tb_turmas representa as turmas ativas por série, turno e ano letivo.
-- Chave composta (serie, ano_letivo, turno) garante unicidade.
CREATE TABLE tb_turmas (
    serie      ENUM('6','7','8','9','1EM','2EM','3EM') NOT NULL,
    ano_letivo INT                                      NOT NULL,
    turno      ENUM('Manha','Tarde')                    NOT NULL,
    PRIMARY KEY (serie, ano_letivo, turno)
);



-- tb_disciplinas catálogo de disciplinas oferecidas pela escola.
-- nivel indica se a disciplina é do Fundamental, Médio ou Ambos.
CREATE TABLE tb_disciplinas (
    pk_nome_disciplina VARCHAR(100) NOT NULL,
    nivel              ENUM('Fundamental','Medio','Ambos') NOT NULL,
    PRIMARY KEY (pk_nome_disciplina)
);



-- tb_turma_disciplinas define quais disciplinas cada turma possui em um determinado ano letivo.
-- Trigger validar_nivel_disciplina impede atribuição incompatível de nível.
CREATE TABLE tb_turma_disciplinas (
    fk_serie           ENUM('6','7','8','9','1EM','2EM','3EM') NOT NULL,
    fk_ano_letivo      INT                                      NOT NULL,
    fk_turno           ENUM('Manha','Tarde')                    NOT NULL,
    fk_nome_disciplina VARCHAR(100)                             NOT NULL,
    PRIMARY KEY (fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina),
    CONSTRAINT fk_turdis_serie  FOREIGN KEY (fk_serie, fk_ano_letivo, fk_turno)
        REFERENCES tb_turmas (serie, ano_letivo, turno),
    CONSTRAINT fk_turdis_disc   FOREIGN KEY (fk_nome_disciplina)
        REFERENCES tb_disciplinas (pk_nome_disciplina)
);



-- tb_matriculas vincula alunos às turmas por ano letivo.
-- data_matricula: data oficial (alterável). data_cadastro: timestamp imutável.
CREATE TABLE tb_matriculas (
    fk_rgm        VARCHAR(10)                              NOT NULL,
    fk_serie      ENUM('6','7','8','9','1EM','2EM','3EM')  NOT NULL,
    fk_ano_letivo INT                                       NOT NULL,
    fk_turno      ENUM('Manha','Tarde')                     NOT NULL,
    data_matricula DATE                                     NOT NULL,
    status         ENUM('Ativo','Trancado','Cancelado','Concluido') NOT NULL DEFAULT 'Ativo',
    data_cadastro  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (fk_rgm, fk_serie, fk_ano_letivo, fk_turno),
    CONSTRAINT fk_mat_rgm   FOREIGN KEY (fk_rgm)
        REFERENCES tb_alunos (pk_rgm),
    CONSTRAINT fk_mat_turma FOREIGN KEY (fk_serie, fk_ano_letivo, fk_turno)
        REFERENCES tb_turmas  (serie, ano_letivo, turno)
);



-- tb_funcionarios
-- Dados cadastrais de todos os profissionais da instituição.
CREATE TABLE tb_funcionarios (
    pk_cpf        CHAR(11)      NOT NULL,
    primeiro_nome VARCHAR(100)  NOT NULL,
    sobrenome     VARCHAR(155)  NOT NULL,
    email         VARCHAR(255)  NOT NULL,
    status        ENUM('Ativo','Afastado','Desligado') NOT NULL DEFAULT 'Ativo',
    data_admissao DATE          NOT NULL,
    data_cadastro TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (pk_cpf),
    UNIQUE KEY uq_func_email (email)
);



-- tb_vinculos registra cargo, departamento e salário de cada funcionário.
-- cada funcionário possui apenas um vínculo CLT ativo por vez.
-- acumulos de função eventuais são registrados via campo 'observacao' na tb_folha_pagamento
-- e resolvidos administrativamente, não geram segundo vínculo no banco.
-- Trigger validar_cargo_departamento garante consistência cargo × departamento.
CREATE TABLE tb_vinculos (
    fk_cpf_funcionario CHAR(11)      NOT NULL,
    cargo              ENUM('Diretor','Coordenador','Professor','Secretario','Bibliotecario',
                            'Inspetor','Porteiro','Aux_Limpeza','Aux_Cantina','Administrador','Contador') NOT NULL,
    departamento       ENUM('Pedagogico','Administrativo','Operacional','Financeiro') NOT NULL,
    salario_base       DECIMAL(10,2) NOT NULL, 
    PRIMARY KEY (fk_cpf_funcionario, cargo, departamento),
    CONSTRAINT fk_vinc_func FOREIGN KEY (fk_cpf_funcionario)
        REFERENCES tb_funcionarios (pk_cpf)
);



-- tb_formacoes
-- Formações acadêmicas dos funcionários. Diploma armazenado como URL.
CREATE TABLE tb_formacoes (
    fk_cpf_funcionario CHAR(11)      NOT NULL,
    curso              VARCHAR(255)  NOT NULL,
    instituicao        VARCHAR(255)  NOT NULL,
    ano_conclusao      INT           NOT NULL,
    diploma_url        VARCHAR(500)  NOT NULL, 
    PRIMARY KEY (fk_cpf_funcionario, curso),
    CONSTRAINT fk_form_func FOREIGN KEY (fk_cpf_funcionario)
        REFERENCES tb_funcionarios (pk_cpf)
);



-- tb_grade_horaria alocação de professores em turmas e disciplinas por dia/aula.
-- data_fim é preenchida quando o professor é desvinculado (afastamento, etc.).
CREATE TABLE tb_grade_horaria (
    fk_cpf_professor      CHAR(11)      NOT NULL,
    fk_serie              ENUM('6','7','8','9','1EM','2EM','3EM') NOT NULL,
    fk_ano_letivo         INT           NOT NULL,
    fk_turno              ENUM('Manha','Tarde') NOT NULL,
    fk_nome_disciplina    VARCHAR(100)  NOT NULL,
    dia_semana            ENUM('Segunda','Terca','Quarta','Quinta','Sexta') NOT NULL,
    numero_aula           ENUM('aula_1','aula_2','aula_3','aula_4','aula_5','aula_6') NOT NULL,
    data_inicio           DATE          NOT NULL,
    data_fim              DATE          NULL,
    carga_horaria_semanal INT           NOT NULL,
    PRIMARY KEY (fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina, dia_semana, numero_aula),
    CONSTRAINT fk_grade_prof  FOREIGN KEY (fk_cpf_professor)
        REFERENCES tb_funcionarios (pk_cpf),
    CONSTRAINT fk_grade_turma FOREIGN KEY (fk_serie, fk_ano_letivo, fk_turno)
        REFERENCES tb_turmas (serie, ano_letivo, turno),
    CONSTRAINT fk_grade_disc  FOREIGN KEY (fk_nome_disciplina)
        REFERENCES tb_disciplinas (pk_nome_disciplina)
);



-- tb_avaliacoes avaliações criadas por professores para turmas/disciplinas específicas.
-- valor_maximo deve estar entre 0 e 10 (constraint CHECK).
CREATE TABLE tb_avaliacoes (
    fk_cpf_professor   CHAR(11)      NOT NULL,
    fk_serie           ENUM('6','7','8','9','1EM','2EM','3EM') NOT NULL,
    fk_ano_letivo      INT           NOT NULL,
    fk_turno           ENUM('Manha','Tarde') NOT NULL,
    fk_nome_disciplina VARCHAR(100)  NOT NULL,
    titulo             VARCHAR(255)  NOT NULL,
    tipo               ENUM('Prova','Trabalho','Seminario','Simulado','Recuperacao') NOT NULL,
    bimestre           ENUM('BIM1','BIM2','BIM3','BIM4') NOT NULL,
    valor_maximo       DECIMAL(4,2)  NOT NULL,
    data_inicio        TIMESTAMP     NOT NULL,
    data_fim           TIMESTAMP     NOT NULL,
    PRIMARY KEY (fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina, bimestre, tipo, titulo),
    CONSTRAINT chk_aval_valor   CHECK (valor_maximo BETWEEN 0 AND 10),
    CONSTRAINT fk_aval_prof     FOREIGN KEY (fk_cpf_professor)
        REFERENCES tb_funcionarios (pk_cpf),
    CONSTRAINT fk_aval_turma    FOREIGN KEY (fk_serie, fk_ano_letivo, fk_turno)
        REFERENCES tb_turmas (serie, ano_letivo, turno),
    CONSTRAINT fk_aval_disc     FOREIGN KEY (fk_nome_disciplina)
        REFERENCES tb_disciplinas (pk_nome_disciplina)
);



-- tb_notas nota individual de cada aluno por avaliação.
-- nota_obtida não pode ser negativa (CHECK) nem superior ao valor_maximo (trigger).
-- status é atualizado automaticamente por trigger (Aprovado/Recuperacao/Reprovado).
-- FK composta referencia a PK inteira de tb_avaliacoes.
CREATE TABLE tb_notas (
    fk_rgm             VARCHAR(10)   NOT NULL,
    fk_cpf_professor   CHAR(11)      NOT NULL,
    fk_serie           ENUM('6','7','8','9','1EM','2EM','3EM') NOT NULL,
    fk_ano_letivo      INT           NOT NULL,
    fk_turno           ENUM('Manha','Tarde') NOT NULL,
    fk_nome_disciplina VARCHAR(100)  NOT NULL,
    fk_bimestre        ENUM('BIM1','BIM2','BIM3','BIM4') NOT NULL,
    fk_tipo            ENUM('Prova','Trabalho','Seminario','Simulado','Recuperacao') NOT NULL,
    fk_titulo          VARCHAR(255)  NOT NULL,
    nota_obtida        DECIMAL(4,2)  NOT NULL,
    status             ENUM('Aprovado','Recuperacao','Reprovado') NOT NULL DEFAULT 'Aprovado',
    PRIMARY KEY (fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina, fk_bimestre, fk_tipo, fk_titulo),
    CONSTRAINT chk_nota_positiva CHECK (nota_obtida >= 0),
    CONSTRAINT fk_nota_aluno     FOREIGN KEY (fk_rgm)
        REFERENCES tb_alunos (pk_rgm),
    -- FK composta garante que a avaliação existe (referencia a PK completa de tb_avaliacoes)
    CONSTRAINT fk_nota_avaliacao FOREIGN KEY (fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina, fk_bimestre, fk_tipo, fk_titulo)
        REFERENCES tb_avaliacoes (fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina, bimestre, tipo, titulo)
);
-- vw_boletim_aluno mostra média bimestral por aluno/disciplina/bimestre.
CREATE VIEW vw_boletim_aluno AS
SELECT
    n.fk_rgm,
    n.fk_serie,
    n.fk_ano_letivo,
    n.fk_nome_disciplina,
    n.fk_bimestre,
    ROUND((SUM(n.nota_obtida) / SUM(a.valor_maximo)) * 10, 2) AS media_bimestral,
    -- CASE com prioridade numérica explícita:
    -- Reprovado(3) > Recuperacao(2) > Aprovado(1)
    -- MAX pega o número mais alto, depois o CASE externo converte de volta pro texto.
    -- Isso elimina a dependência da ordem alfabética e deixa a lógica legível e defensável.
    CASE MAX(
        CASE n.status
            WHEN 'Reprovado'   THEN 3
            WHEN 'Recuperacao' THEN 2
            WHEN 'Aprovado'    THEN 1
        END
    )
        WHEN 3 THEN 'Reprovado'
        WHEN 2 THEN 'Recuperacao'
        WHEN 1 THEN 'Aprovado'
    END AS status_bimestre
FROM tb_notas n
JOIN tb_avaliacoes a
    ON  a.fk_cpf_professor   = n.fk_cpf_professor
    AND a.fk_serie           = n.fk_serie
    AND a.fk_ano_letivo      = n.fk_ano_letivo
    AND a.fk_turno           = n.fk_turno
    AND a.fk_nome_disciplina = n.fk_nome_disciplina
    AND a.bimestre           = n.fk_bimestre
    AND a.tipo               = n.fk_tipo
    AND a.titulo             = n.fk_titulo
GROUP BY
    n.fk_rgm,
    n.fk_serie,
    n.fk_ano_letivo,
    n.fk_nome_disciplina,
    n.fk_bimestre;



-- tb_frequencias registro de presença/ausência de cada aluno por aula e disciplina.
-- Trigger verificar_frequencia emite alerta se frequência cair abaixo de 75%.
CREATE TABLE tb_frequencias (
    fk_rgm             VARCHAR(10)   NOT NULL,
    fk_cpf_professor   CHAR(11)      NOT NULL,
    fk_serie           ENUM('6','7','8','9','1EM','2EM','3EM') NOT NULL,
    fk_ano_letivo      INT           NOT NULL,
    fk_turno           ENUM('Manha','Tarde') NOT NULL,
    fk_nome_disciplina VARCHAR(100)  NOT NULL,
    data_aula          DATE          NOT NULL,
    numero_aula        ENUM('aula_1','aula_2','aula_3','aula_4','aula_5','aula_6') NOT NULL,
    status             ENUM('Presente','Ausente','Atestado') NOT NULL,
    PRIMARY KEY (fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina, data_aula, numero_aula),
    CONSTRAINT fk_freq_aluno FOREIGN KEY (fk_rgm)
        REFERENCES tb_alunos (pk_rgm),
    CONSTRAINT fk_freq_prof  FOREIGN KEY (fk_cpf_professor)
        REFERENCES tb_funcionarios (pk_cpf),
    CONSTRAINT fk_freq_turma FOREIGN KEY (fk_serie, fk_ano_letivo, fk_turno)
        REFERENCES tb_turmas (serie, ano_letivo, turno),
    CONSTRAINT fk_freq_disc  FOREIGN KEY (fk_nome_disciplina)
        REFERENCES tb_disciplinas (pk_nome_disciplina)
);
-- vw_frequencia_aluno expõe percentual de presença e a situação de risco por aluno/disciplina.
CREATE VIEW vw_frequencia_aluno AS
SELECT
    fk_rgm,
    fk_serie,
    fk_ano_letivo,
    fk_turno,
    fk_nome_disciplina,
    COUNT(*) AS total_aulas,
    SUM(CASE WHEN status IN ('Presente','Atestado') THEN 1 ELSE 0 END) AS aulas_presentes,
    ROUND(
        SUM(CASE WHEN status IN ('Presente','Atestado') THEN 1 ELSE 0 END) / COUNT(*) * 100
    , 2) AS percentual_frequencia,
    CASE
        WHEN SUM(CASE WHEN status IN ('Presente','Atestado') THEN 1 ELSE 0 END) / COUNT(*) * 100 >= 75
        THEN 'Regular'
        ELSE 'Risco_Reprovacao'
    END AS situacao
FROM tb_frequencias
GROUP BY fk_rgm, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina;


-- tb_atestados atestados médicos de alunos OU funcionários.
-- Apenas um dos dois campos (fk_rgm_aluno, fk_cpf_funcionario) será preenchido
-- por registro — o outro permanece NULL (decisão de design intencional).
CREATE TABLE tb_atestados (
    fk_rgm_aluno       VARCHAR(10)   NULL,
    fk_cpf_funcionario CHAR(11)      NULL,
    data_inicio        DATE          NOT NULL,
    data_fim           DATE          NOT NULL,
    nome_medico        VARCHAR(100)  NOT NULL,
    sobrenome_medico   VARCHAR(150)  NOT NULL,
    crm_medico         VARCHAR(20)   NOT NULL,
    atestado_url       VARCHAR(500)  NOT NULL,
    data_entrega 	   DATETIME 	 NOT NULL,
    data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (crm_medico, data_inicio, data_entrega),
    CONSTRAINT fk_atest_aluno FOREIGN KEY (fk_rgm_aluno) 
        REFERENCES tb_alunos (pk_rgm),
    CONSTRAINT fk_atest_func  FOREIGN KEY (fk_cpf_funcionario) 
        REFERENCES tb_funcionarios (pk_cpf),
    CONSTRAINT chk_atestado_dono_unico -- Garante que o atestado pertença a EXATAMENTE uma pessoa (Aluno ou Funcionario).
        CHECK (                        -- Bloqueia se os dois estiverem preenchidos ou se os dois estiverem vazios.
            (fk_rgm_aluno IS NOT NULL AND fk_cpf_funcionario IS NULL) OR 
            (fk_rgm_aluno IS NULL AND fk_cpf_funcionario IS NOT NULL)
        )
);



-- tb_contrato_escolar vínculo financeiro entre responsável e aluno para um ano letivo.
-- campos como: valor_desconto, valor_final, valor_rematricula, são derivados de valor_mensalidade + bolsa e são expostos
-- no VIEW vw_contrato_escolar
-- Trigger calcular_bolsa_rematricula foi REMOVIDO (não há mais o que calcular aqui).
-- Trigger cancelar_mensalidades cancela parcelas futuras quando contrato encerra.
CREATE TABLE tb_contrato_escolar (  -- colocar bolsa = limite de recuperações aviso yoru
    fk_cpf_responsavel CHAR(11)      NOT NULL,
    fk_rgm_aluno       VARCHAR(10)   NOT NULL,
    fk_serie           ENUM('6','7','8','9','1EM','2EM','3EM') NOT NULL,
    fk_ano_letivo      INT           NOT NULL,
    fk_turno           ENUM('Manha','Tarde') NOT NULL,
    data_inicio        DATE          NOT NULL,
    data_fim           DATE          NOT NULL,
    valor_mensalidade  DECIMAL(10,2) NOT NULL,
    bolsa              ENUM('Sem_Bolsa','Bolsa_25','Bolsa_50','Bolsa_75') NOT NULL DEFAULT 'Sem_Bolsa',
    status             ENUM('Ativo','Cancelado','Concluido','Transferido') NOT NULL DEFAULT 'Ativo',
    data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo),
    CONSTRAINT fk_cont_resp  FOREIGN KEY (fk_cpf_responsavel)
        REFERENCES tb_responsaveis (pk_cpf),
    CONSTRAINT fk_cont_aluno FOREIGN KEY (fk_rgm_aluno)
        REFERENCES tb_alunos (pk_rgm),
    CONSTRAINT fk_cont_turma FOREIGN KEY (fk_serie, fk_ano_letivo, fk_turno)
        REFERENCES tb_turmas (serie, ano_letivo, turno)
);
-- vw_contrato_escolar expõe os valores derivados do contrato (desconto, valor final, rematrícula)
-- calculados em tempo de consulta com base em valor_mensalidade e bolsa.
-- Substitui os campos removidos: valor_desconto, valor_final, valor_rematricula.
CREATE VIEW vw_contrato_escolar AS
SELECT
  c.fk_cpf_responsavel,
  c.fk_rgm_aluno,
  c.fk_serie,
  c.fk_ano_letivo,
  c.fk_turno,
  c.data_inicio,
  c.data_fim,
  c.valor_mensalidade,
  c.bolsa,
  c.status,
  -- Desconto aplicado conforme tipo de bolsa
  CASE c.bolsa
    WHEN 'Bolsa_25' THEN c.valor_mensalidade * 0.25
    WHEN 'Bolsa_50' THEN c.valor_mensalidade * 0.50
    WHEN 'Bolsa_75' THEN c.valor_mensalidade * 0.75
    ELSE 0
  END AS valor_desconto,
  -- Valor final (mensalidade com desconto)
  c.valor_mensalidade - CASE c.bolsa
    WHEN 'Bolsa_25' THEN c.valor_mensalidade * 0.25
    WHEN 'Bolsa_50' THEN c.valor_mensalidade * 0.50
    WHEN 'Bolsa_75' THEN c.valor_mensalidade * 0.75
    ELSE 0
  END AS valor_final,
  -- Rematrícula = 15% do valor final
  (c.valor_mensalidade - CASE c.bolsa
    WHEN 'Bolsa_25' THEN c.valor_mensalidade * 0.25
    WHEN 'Bolsa_50' THEN c.valor_mensalidade * 0.50
    WHEN 'Bolsa_75' THEN c.valor_mensalidade * 0.75
    ELSE 0
  END) * 0.15 AS valor_rematricula
FROM tb_contrato_escolar c; 



-- tb_mensalidades 12 parcelas geradas automaticamente por trigger ao criar o contrato.
-- campos como: multa, juros, valor_total, Atraso são calculados pela VIEW vw_mensalidades.
CREATE TABLE tb_mensalidades (
    fk_cpf_responsavel CHAR(11)      NOT NULL,
    fk_rgm_aluno       VARCHAR(10)   NOT NULL,
    fk_ano_letivo      INT           NOT NULL,
    mes_referencia     INT           NOT NULL,
    data_vencimento    DATE          NOT NULL,
    data_pagamento     DATE          NULL,
    valor_mensalidade  DECIMAL(10,2) NOT NULL, -- armazena o valor_final (após desconto de bolsa) para gerar_mensalidades com trigger
    inclui_rematricula BOOLEAN       NOT NULL DEFAULT FALSE,
    status             ENUM('Pendente','Pago','Atrasado','Cancelado') NOT NULL DEFAULT 'Pendente',
    data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, mes_referencia),
    CONSTRAINT fk_mens_contrato FOREIGN KEY (fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo)
        REFERENCES tb_contrato_escolar (fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo)
);
-- vw_mensalidades expõe os valores derivados de cada parcela (multa, juros, valor total)
-- calculados dinamicamente com base em data_vencimento e CURDATE().
-- Substitui os campos removidos: multa, juros, valor_total, data_atraso.
-- Regras: multa = 2% sobre valor_mensalidade; juros = 0,033% ao dia.
-- Se status = 'Atrasado', calcula penalidades; caso contrário, valor_total = valor_mensalidade.
CREATE VIEW vw_mensalidades AS
SELECT
  m.fk_cpf_responsavel,
  m.fk_rgm_aluno,
  m.fk_ano_letivo,
  m.mes_referencia,
  m.data_vencimento,
  m.data_pagamento,
  m.valor_mensalidade,
  m.inclui_rematricula,
  m.status,
  -- Dias de atraso (somente quando status = 'Atrasado')
  -- CASE garante que, se a conta estiver em dia ou paga, o valor_total seja exatamente o valor_mensalidade
  -- evitando cobranças indevidas.
  CASE
    WHEN m.status = 'Atrasado'
    THEN DATEDIFF(CURDATE(), m.data_vencimento)
    ELSE 0
  END AS dias_atraso,
  -- Data de atraso
  CASE
    WHEN m.status = 'Atrasado'
    THEN m.data_vencimento
    ELSE NULL
  END AS data_atraso,
  -- Multa: 2% sobre o valor da mensalidade
  CASE
    WHEN m.status = 'Atrasado'
    THEN m.valor_mensalidade * 0.02
    ELSE 0
  END AS multa,
  -- Juros: 0,033% por dia de atraso
  CASE
    WHEN m.status = 'Atrasado'
    THEN m.valor_mensalidade * (0.00033 * DATEDIFF(CURDATE(), m.data_vencimento)) -- calcula automaticamente os juros diario
    ELSE 0                                                                        -- se consultar em um dias diferentes, é recalculado os juros automaticamente porque o CURDATE() (data atual) terá mudado.
  END AS juros,
  -- Valor total devido
  CASE
    WHEN m.status = 'Atrasado'
    THEN m.valor_mensalidade
         + (m.valor_mensalidade * 0.02)
         + (m.valor_mensalidade * (0.00033 * DATEDIFF(CURDATE(), m.data_vencimento)))
    ELSE m.valor_mensalidade
  END AS valor_total
FROM tb_mensalidades m; 
-- vw_inadimplencia lista responsáveis com parcelas em atraso e valor total devido com encargos.
CREATE VIEW vw_inadimplencia AS
SELECT
    m.fk_cpf_responsavel,
    m.fk_rgm_aluno,
    m.fk_ano_letivo,
    COUNT(*)                    AS parcelas_atrasadas,
    SUM(m.valor_mensalidade)    AS valor_base_devido,
    SUM(vm.valor_total)         AS valor_total_com_encargos
FROM tb_mensalidades m
JOIN vw_mensalidades vm
    ON  vm.fk_cpf_responsavel = m.fk_cpf_responsavel
    AND vm.fk_rgm_aluno       = m.fk_rgm_aluno
    AND vm.fk_ano_letivo      = m.fk_ano_letivo
    AND vm.mes_referencia     = m.mes_referencia
WHERE m.status IN ('Atrasado', 'Pendente')
GROUP BY m.fk_cpf_responsavel, m.fk_rgm_aluno, m.fk_ano_letivo;



-- tb_pagamentos registros de pagamentos realizados pelos responsáveis.
-- Trigger atualizar_status_mensalidade marca mensalidade como Pago quando quitada.
CREATE TABLE tb_pagamentos (
    fk_cpf_responsavel CHAR(11)      NOT NULL,
    fk_rgm_aluno       VARCHAR(10)   NOT NULL,
    fk_ano_letivo      INT           NOT NULL,
    fk_mes_referencia  INT           NOT NULL,
    valor_pago         DECIMAL(10,2) NOT NULL,
    forma_pagamento    ENUM('Boleto','PIX','Cartao_Debito','Cartao_Credito','Dinheiro') NOT NULL,
    data_pagamento     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, fk_mes_referencia),
    CONSTRAINT fk_pag_resp  FOREIGN KEY (fk_cpf_responsavel)
        REFERENCES tb_responsaveis (pk_cpf),
    CONSTRAINT fk_pag_aluno FOREIGN KEY (fk_rgm_aluno)
        REFERENCES tb_alunos (pk_rgm),
    -- FK composta referencia a PK completa de tb_mensalidades
    CONSTRAINT fk_pag_mens  FOREIGN KEY (fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, fk_mes_referencia)
        REFERENCES tb_mensalidades (fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, mes_referencia)
);



-- tb_receitas receitas da instituição (mensalidades e outras fontes de renda).
CREATE TABLE tb_receitas (
    fk_cpf_funcionario CHAR(11)      NOT NULL, -- funcionário responsável pelo registro da receita(Administrador ou Contador)
    tipo               ENUM('Mensalidade', 'Matricula', 'Rematricula', 'Uniforme', 'Material_Didatico', 'Evento', 'Cantina', 'Outros') NOT NULL,
    descricao          VARCHAR(255)  NOT NULL,
    valor              DECIMAL(10,2) NOT NULL,
    data_hora_receita  DATETIME      NOT NULL, -- armazena o dado como 'AAAA-MM-DD HH:MM:SS'
    status             ENUM('Pago', 'Pendente', 'Cancelado') NOT NULL DEFAULT 'Pendente',
    data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (fk_cpf_funcionario, data_hora_receita), -- Permite ter varis entradas repedidas de receitas no mesmo dia, pois os segundos serão diferentes.
    CONSTRAINT fk_rec_func FOREIGN KEY (fk_cpf_funcionario)
        REFERENCES tb_funcionarios (pk_cpf)
);



-- tb_despesas: Controle de saídas financeiras e custos operacionais.
CREATE TABLE tb_despesas (
    fk_cpf_funcionario CHAR(11)      NOT NULL, -- Operador financeiro (Administrador ou Contador) que registrou a saída
    tipo               ENUM('Luz', 'Agua', 'Internet', 'Aluguel', 'Reforma', 'Limpeza', 'Seguranca', 'Manutencao_TI', 'Papelaria', 'Eventos', 'Outros') NOT NULL,
    descricao          VARCHAR(255)  NOT NULL,
    valor              DECIMAL(10,2) NOT NULL,
    data_hora_despesa  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP, -- armazena o dado como 'AAAA-MM-DD HH:MM:SS'
    data_vencimento    DATE          NOT NULL,
    status             ENUM('Pago', 'Pendente', 'Cancelado') NOT NULL DEFAULT 'Pendente',
    data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (fk_cpf_funcionario, data_hora_despesa),
    CONSTRAINT fk_desp_func FOREIGN KEY (fk_cpf_funcionario)
        REFERENCES tb_funcionarios (pk_cpf)
);
-- vw_fluxo_caixa_mensal consolida receitas e despesas pagas por ano/mês, mostrando saldo.
CREATE VIEW vw_fluxo_caixa_mensal AS
WITH receitas_mes AS (
    SELECT
        YEAR(data_hora_receita)  AS ano,
        MONTH(data_hora_receita) AS mes,
        SUM(valor)               AS total_receitas
    FROM tb_receitas
    WHERE status = 'Pago'
    GROUP BY YEAR(data_hora_receita), MONTH(data_hora_receita)
),
despesas_mes AS (
    SELECT
        YEAR(data_hora_despesa)  AS ano,
        MONTH(data_hora_despesa) AS mes,
        SUM(valor)               AS total_despesas
    FROM tb_despesas
    WHERE status = 'Pago'
    GROUP BY YEAR(data_hora_despesa), MONTH(data_hora_despesa)
)
SELECT
    r.ano,
    r.mes,
    r.total_receitas,
    COALESCE(d.total_despesas, 0) AS total_despesas,
    r.total_receitas - COALESCE(d.total_despesas, 0) AS saldo_mensal
FROM receitas_mes r
LEFT JOIN despesas_mes d
    ON d.ano = r.ano
    AND d.mes = r.mes
ORDER BY r.ano, r.mes;



-- tb_ferias períodos de férias dos funcionários.
-- Valores calculados foram movidos para uma VIEW.
CREATE TABLE tb_ferias (
    fk_cpf_funcionario CHAR(11)      NOT NULL,
    ano                INT           NOT NULL, -- Ano de referência
    data_inicio        DATE          NOT NULL,
    status             ENUM('Agendado','Em_Ferias','Concluido','Cancelado') NOT NULL DEFAULT 'Agendado',
    aprovado_por       CHAR(11)      NOT NULL, -- CPF do Diretor ou Administrador
    data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (fk_cpf_funcionario, ano),
    CONSTRAINT fk_fer_func     FOREIGN KEY (fk_cpf_funcionario)
        REFERENCES tb_funcionarios (pk_cpf),
    CONSTRAINT fk_fer_aprovado FOREIGN KEY (aprovado_por)
        REFERENCES tb_funcionarios (pk_cpf)
);
-- vw_ferias_detalhada
CREATE VIEW vw_ferias_detalhada AS
SELECT 
    f.fk_cpf_funcionario,
    f.ano,
    f.data_inicio,
    DATE_ADD(f.data_inicio, INTERVAL 29 DAY) AS data_fim,
    DATE_ADD(f.data_inicio, INTERVAL 30 DAY) AS data_retorno,
    v.salario_base / 3 AS valor_abono_ferias,
    f.status,
    f.aprovado_por
FROM tb_ferias f
JOIN tb_vinculos v ON f.fk_cpf_funcionario = v.fk_cpf_funcionario
WHERE v.cargo = (
    SELECT cargo FROM tb_vinculos
    WHERE fk_cpf_funcionario = f.fk_cpf_funcionario
    ORDER BY salario_base DESC
    LIMIT 1
);


-- Armazena apenas o salario base e o Abono de ferias no fim do mes 
-- caso salario mudde no futuro tera os registros anteriores, preservando a integridade
-- calculos de (INSS, IRRF, VT e Líquido) são feitos dinamicamente pelas VIEWs abaixo.
CREATE TABLE tb_folha_pagamento (
    fk_cpf_funcionario CHAR(11)      NOT NULL,
    mes_referencia     INT           NOT NULL,
    ano_referencia     INT           NOT NULL,
    salario_base       DECIMAL(10,2) NOT NULL, -- Valor do salário na data de competência
    abono_ferias       DECIMAL(10,2) NOT NULL DEFAULT 0, -- 1/3 do salário, quando há férias no mês
    observacao         VARCHAR(255)  NULL, -- Para um funcia que foi contratado para uma função mas teve que fazer outra(só descrição e resolver com a escola, não com o banco)
    data_pagamento     DATE          NOT NULL,
    data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (fk_cpf_funcionario, mes_referencia, ano_referencia),
    CONSTRAINT fk_folha_func FOREIGN KEY (fk_cpf_funcionario)
        REFERENCES tb_funcionarios (pk_cpf)
);
-- Primeiro View para tb_folha_pagamento: vw_folha_calculos_base
-- Isola os calculo complexos de INSS e IRRF baseados nas regras basicas, podendo não estar 100% atualizada.
-- caso acha alguma alteração na forma de calcular as alíquotas, a manutenção é feita apenas neste local.
-- disponibilizando as colunas calculadas de impostos para calculo da vw_folha_pagamento.
CREATE VIEW vw_folha_calculos_base AS
SELECT
    f.fk_cpf_funcionario,
    f.mes_referencia,
    f.ano_referencia,
    f.salario_base,
    f.abono_ferias,
    f.data_pagamento,
    -- INSS progressivo (alíquotas pode não estar 100% atualizada)
    ROUND(CASE
        WHEN f.salario_base <= 1518.00 THEN f.salario_base * 0.075
        WHEN f.salario_base <= 2793.88 THEN f.salario_base * 0.09
        WHEN f.salario_base <= 4190.83 THEN f.salario_base * 0.12
        WHEN f.salario_base <= 8157.41 THEN f.salario_base * 0.14
        ELSE 8157.41 * 0.14
    END, 2) AS inss,
    -- Base de cálculo do IRRF = salario_base - INSS
    ROUND(f.salario_base - CASE
        WHEN f.salario_base <= 1518.00 THEN f.salario_base * 0.075
        WHEN f.salario_base <= 2793.88 THEN f.salario_base * 0.09
        WHEN f.salario_base <= 4190.83 THEN f.salario_base * 0.12
        WHEN f.salario_base <= 8157.41 THEN f.salario_base * 0.14
        ELSE 8157.41 * 0.14
    END, 2) AS base_irrf,
    -- IRRF progressivo calculado sobre a base do codigo acima
    ROUND(CASE
        WHEN (f.salario_base - CASE
                WHEN f.salario_base <= 1518.00 THEN f.salario_base * 0.075
                WHEN f.salario_base <= 2793.88 THEN f.salario_base * 0.09
                WHEN f.salario_base <= 4190.83 THEN f.salario_base * 0.12
                WHEN f.salario_base <= 8157.41 THEN f.salario_base * 0.14
                ELSE 8157.41 * 0.14
              END) <= 2259.20 THEN 0
        WHEN (f.salario_base - CASE
                WHEN f.salario_base <= 1518.00 THEN f.salario_base * 0.075
                WHEN f.salario_base <= 2793.88 THEN f.salario_base * 0.09
                WHEN f.salario_base <= 4190.83 THEN f.salario_base * 0.12
                WHEN f.salario_base <= 8157.41 THEN f.salario_base * 0.14
                ELSE 8157.41 * 0.14
              END) <= 2826.65
        THEN (f.salario_base - CASE
                WHEN f.salario_base <= 1518.00 THEN f.salario_base * 0.075
                WHEN f.salario_base <= 2793.88 THEN f.salario_base * 0.09
                WHEN f.salario_base <= 4190.83 THEN f.salario_base * 0.12
                WHEN f.salario_base <= 8157.41 THEN f.salario_base * 0.14
                ELSE 8157.41 * 0.14
              END) * 0.075 - 169.44
        WHEN (f.salario_base - CASE
                WHEN f.salario_base <= 1518.00 THEN f.salario_base * 0.075
                WHEN f.salario_base <= 2793.88 THEN f.salario_base * 0.09
                WHEN f.salario_base <= 4190.83 THEN f.salario_base * 0.12
                WHEN f.salario_base <= 8157.41 THEN f.salario_base * 0.14
                ELSE 8157.41 * 0.14
              END) <= 3751.05
        THEN (f.salario_base - CASE
                WHEN f.salario_base <= 1518.00 THEN f.salario_base * 0.075
                WHEN f.salario_base <= 2793.88 THEN f.salario_base * 0.09
                WHEN f.salario_base <= 4190.83 THEN f.salario_base * 0.12
                WHEN f.salario_base <= 8157.41 THEN f.salario_base * 0.14
                ELSE 8157.41 * 0.14
              END) * 0.15 - 381.44
        WHEN (f.salario_base - CASE
                WHEN f.salario_base <= 1518.00 THEN f.salario_base * 0.075
                WHEN f.salario_base <= 2793.88 THEN f.salario_base * 0.09
                WHEN f.salario_base <= 4190.83 THEN f.salario_base * 0.12
                WHEN f.salario_base <= 8157.41 THEN f.salario_base * 0.14
                ELSE 8157.41 * 0.14
              END) <= 4664.68
        THEN (f.salario_base - CASE
                WHEN f.salario_base <= 1518.00 THEN f.salario_base * 0.075
                WHEN f.salario_base <= 2793.88 THEN f.salario_base * 0.09
                WHEN f.salario_base <= 4190.83 THEN f.salario_base * 0.12
                WHEN f.salario_base <= 8157.41 THEN f.salario_base * 0.14
                ELSE 8157.41 * 0.14
              END) * 0.225 - 662.77
        ELSE (f.salario_base - CASE
                WHEN f.salario_base <= 1518.00 THEN f.salario_base * 0.075
                WHEN f.salario_base <= 2793.88 THEN f.salario_base * 0.09
                WHEN f.salario_base <= 4190.83 THEN f.salario_base * 0.12
                WHEN f.salario_base <= 8157.41 THEN f.salario_base * 0.14
                ELSE 8157.41 * 0.14
              END) * 0.275 - 896.00
    END, 2) AS irrf
FROM tb_folha_pagamento f;
-- Segundo View para tb_folha_pagamento: vw_folha_pagamento (Holerite)
-- consolida os impostos do 1° VIEW com os benefícios (VT/VR)
-- calculando totais de proventos, descontos e valor líquido.
-- gera a visão final do pagamento (Salário Líquido)
-- pronta para ser exibida ao usuario como um Holerite
CREATE VIEW vw_folha_pagamento AS
SELECT
    b.fk_cpf_funcionario,
    b.mes_referencia,
    b.ano_referencia,
    b.salario_base,
    b.abono_ferias,
    b.data_pagamento,
    b.inss,
    b.irrf,
    -- Vale transporte: 6% do salário base
    ROUND(b.salario_base * 0.06, 2)  AS vale_transporte,
    -- Vale refeição: R$25,00 × 22 dias úteis
    ROUND(25.00 * 22, 2)             AS vale_refeicao,
    -- Total de proventos = salário + abono de férias
    ROUND(b.salario_base + b.abono_ferias, 2) AS total_proventos,
    -- Total de descontos = INSS + IRRF + vale transporte + vale refeição
    ROUND(b.inss + b.irrf + (b.salario_base * 0.06) + (25.00 * 22), 2) AS total_descontos,
    -- Salário líquido = total proventos - total descontos
    ROUND(
        (b.salario_base + b.abono_ferias)
        - (b.inss + b.irrf + (b.salario_base * 0.06) + (25.00 * 22))
    , 2) AS salario_liquido
FROM vw_folha_calculos_base b;



-- ------------------------------------------------------------------------------------------------------------------------------------------------------ --
-- TRIGGERS --

DELIMITER $$
-- O separador de comandos vai mudar temporariamente de ; para $$


-- limpar_dados_aluno remove pontuação de pk_rgm, cpf e cep antes do INSERT em tb_alunos.
CREATE TRIGGER limpar_dados_aluno
BEFORE INSERT ON tb_alunos
FOR EACH ROW
BEGIN
  SET NEW.pk_rgm = REGEXP_REPLACE(NEW.pk_rgm, '[^0-9]', '');
  SET NEW.cpf    = REGEXP_REPLACE(NEW.cpf,    '[^0-9]', '');
  SET NEW.cep    = REGEXP_REPLACE(NEW.cep,    '[^0-9]', '');
END$$



-- validar_nivel_disciplina impede que disciplinas exclusivas do Médio sejam atribuídas ao Fundamental
-- e vice-versa. Disciplinas com nivel='Ambos' são permitidas em qualquer turma.
CREATE TRIGGER validar_nivel_disciplina
BEFORE INSERT ON tb_turma_disciplinas
FOR EACH ROW
BEGIN
  DECLARE nivel_disciplina VARCHAR(20);
  SELECT nivel INTO nivel_disciplina
  FROM tb_disciplinas
  WHERE pk_nome_disciplina = NEW.fk_nome_disciplina;
  IF (NEW.fk_serie IN ('6','7','8','9')) AND (nivel_disciplina = 'Medio') THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Erro: Disciplina exclusiva do Medio nao e permitida para o Fundamental!';
  END IF;
  IF (NEW.fk_serie IN ('1EM','2EM','3EM')) AND (nivel_disciplina = 'Fundamental') THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Erro: Disciplina exclusiva do Fundamental nao e permitida para o Medio!';
  END IF;
END$$



-- validar_cargo_departamento garante que o cargo informado pertence ao departamento correto.
CREATE TRIGGER validar_cargo_departamento
BEFORE INSERT ON tb_vinculos
FOR EACH ROW
BEGIN
  IF NEW.departamento = 'Pedagogico'     AND NEW.cargo NOT IN ('Diretor','Coordenador','Professor') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Cargo nao pertence ao departamento Pedagogico!';
  END IF;
  IF NEW.departamento = 'Administrativo' AND NEW.cargo NOT IN ('Secretario','Bibliotecario','Administrador') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Cargo nao pertence ao departamento Administrativo!';
  END IF;
  IF NEW.departamento = 'Operacional'    AND NEW.cargo NOT IN ('Inspetor','Porteiro','Aux_Limpeza','Aux_Cantina') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Cargo nao pertence ao departamento Operacional!';
  END IF;
  IF NEW.departamento = 'Financeiro'     AND NEW.cargo NOT IN ('Contador') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: Cargo nao pertence ao departamento Financeiro!';
  END IF;
END$$



-- validar_nota_maxima verifica se a avaliação existe e se nota_obtida não ultrapassa valor_maximo.
CREATE TRIGGER validar_nota_maxima
BEFORE INSERT ON tb_notas
FOR EACH ROW
BEGIN
  DECLARE max_nota DECIMAL(4,2);
  SELECT valor_maximo INTO max_nota
  FROM tb_avaliacoes
  WHERE fk_cpf_professor   = NEW.fk_cpf_professor
    AND fk_serie           = NEW.fk_serie
    AND fk_ano_letivo      = NEW.fk_ano_letivo
    AND fk_turno           = NEW.fk_turno
    AND fk_nome_disciplina = NEW.fk_nome_disciplina
    AND bimestre           = NEW.fk_bimestre
    AND tipo               = NEW.fk_tipo
    AND titulo             = NEW.fk_titulo;
  IF max_nota IS NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Erro: Avaliacao nao encontrada!';
  END IF;
  IF NEW.nota_obtida > max_nota THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Erro: Nota superior ao valor maximo da avaliacao!';
  END IF;
END$$
-- verificar_recuperacao calcula a média proporcional do aluno no bimestre após cada nota inserida.
-- Se (soma_notas / soma_maxima) * 10 < 6, define status = 'Recuperacao'.
CREATE TRIGGER verificar_recuperacao
BEFORE INSERT ON tb_notas
FOR EACH ROW
BEGIN
  DECLARE soma_notas  DECIMAL(6,2);
  DECLARE soma_maxima DECIMAL(6,2);
  SELECT
    COALESCE(SUM(n.nota_obtida), 0),
    COALESCE(SUM(a.valor_maximo), 0)
  INTO soma_notas, soma_maxima
  FROM tb_notas n
  JOIN tb_avaliacoes a
    ON  a.fk_cpf_professor   = n.fk_cpf_professor
    AND a.fk_serie           = n.fk_serie
    AND a.fk_ano_letivo      = n.fk_ano_letivo
    AND a.fk_turno           = n.fk_turno
    AND a.fk_nome_disciplina = n.fk_nome_disciplina
    AND a.bimestre           = n.fk_bimestre
    AND a.tipo               = n.fk_tipo
    AND a.titulo             = n.fk_titulo
  WHERE n.fk_rgm             = NEW.fk_rgm
    AND n.fk_nome_disciplina = NEW.fk_nome_disciplina
    AND n.fk_bimestre        = NEW.fk_bimestre
    AND n.fk_serie           = NEW.fk_serie
    AND n.fk_ano_letivo      = NEW.fk_ano_letivo
    AND n.fk_turno           = NEW.fk_turno;
  SET soma_notas  = soma_notas  + NEW.nota_obtida;
  SET soma_maxima = soma_maxima + (
    SELECT valor_maximo FROM tb_avaliacoes
    WHERE fk_cpf_professor   = NEW.fk_cpf_professor
      AND fk_serie           = NEW.fk_serie
      AND fk_ano_letivo      = NEW.fk_ano_letivo
      AND fk_turno           = NEW.fk_turno
      AND fk_nome_disciplina = NEW.fk_nome_disciplina
      AND bimestre           = NEW.fk_bimestre
      AND tipo               = NEW.fk_tipo
      AND titulo             = NEW.fk_titulo
  );
  IF soma_maxima > 0 AND (soma_notas / soma_maxima) * 10 < 6 THEN
    SET NEW.status = 'Recuperacao';
  END IF;
END$$
-- validar_nota_maxima_update cobre o caso de correção de nota já lançada via UPDATE.
-- Roda as mesmas validações do BEFORE INSERT
CREATE TRIGGER validar_nota_maxima_update
BEFORE UPDATE ON tb_notas
FOR EACH ROW
BEGIN
  DECLARE max_nota DECIMAL(4,2);
  SELECT valor_maximo INTO max_nota
  FROM tb_avaliacoes
  WHERE fk_cpf_professor   = NEW.fk_cpf_professor
    AND fk_serie           = NEW.fk_serie
    AND fk_ano_letivo      = NEW.fk_ano_letivo
    AND fk_turno           = NEW.fk_turno
    AND fk_nome_disciplina = NEW.fk_nome_disciplina
    AND bimestre           = NEW.fk_bimestre
    AND tipo               = NEW.fk_tipo
    AND titulo             = NEW.fk_titulo;
  IF max_nota IS NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Erro: Avaliacao nao encontrada!';
  END IF;
  IF NEW.nota_obtida > max_nota THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Erro: Nota superior ao valor maximo da avaliacao!';
  END IF;
END$$
-- verificar_recuperacao_update recalcula status de recuperação com a nota nova
CREATE TRIGGER verificar_recuperacao_update
BEFORE UPDATE ON tb_notas
FOR EACH ROW
BEGIN
  DECLARE soma_notas  DECIMAL(6,2);
  DECLARE soma_maxima DECIMAL(6,2);
  -- Soma todas as notas do aluno no bimestre/disciplina EXCETO a que está sendo alterada
  -- Sera substituída pelo valor NEW logo abaixo
  SELECT
    COALESCE(SUM(n.nota_obtida), 0),
    COALESCE(SUM(a.valor_maximo), 0)
  INTO soma_notas, soma_maxima
  FROM tb_notas n
  JOIN tb_avaliacoes a
    ON  a.fk_cpf_professor   = n.fk_cpf_professor
    AND a.fk_serie           = n.fk_serie
    AND a.fk_ano_letivo      = n.fk_ano_letivo
    AND a.fk_turno           = n.fk_turno
    AND a.fk_nome_disciplina = n.fk_nome_disciplina
    AND a.bimestre           = n.fk_bimestre
    AND a.tipo               = n.fk_tipo
    AND a.titulo             = n.fk_titulo
  WHERE n.fk_rgm             = NEW.fk_rgm
    AND n.fk_nome_disciplina = NEW.fk_nome_disciplina
    AND n.fk_bimestre        = NEW.fk_bimestre
    AND n.fk_serie           = NEW.fk_serie
    AND n.fk_ano_letivo      = NEW.fk_ano_letivo
    AND n.fk_turno           = NEW.fk_turno
    AND n.fk_titulo         != OLD.fk_titulo; -- exclui a nota antiga sendo substituída
  -- Add o novo valor que está sendo gravado
  SET soma_notas  = soma_notas  + NEW.nota_obtida;
  SET soma_maxima = soma_maxima + (
    SELECT valor_maximo FROM tb_avaliacoes
    WHERE fk_cpf_professor   = NEW.fk_cpf_professor
      AND fk_serie           = NEW.fk_serie
      AND fk_ano_letivo      = NEW.fk_ano_letivo
      AND fk_turno           = NEW.fk_turno
      AND fk_nome_disciplina = NEW.fk_nome_disciplina
      AND bimestre           = NEW.fk_bimestre
      AND tipo               = NEW.fk_tipo
      AND titulo             = NEW.fk_titulo
  );
  IF soma_maxima > 0 AND (soma_notas / soma_maxima) * 10 < 6 THEN
    SET NEW.status = 'Recuperacao';
  ELSE
    SET NEW.status = 'Aprovado'; -- se nota corrigida tirar o aluno de recuperação, volta pra Aprovado
  END IF;
END$$



-- verificar_frequencia após registrar frequência, calcula o percentual do aluno na disciplina.
-- Emite alerta se cair abaixo de 75% (Presente + Atestado contam como presença).
-- No BEFORE INSERT o NEW ainda não está na tabela, então um SELECT simples não o enxergaria.
-- Somamos manualmente NEW.status ao cálculo para que o percentual reflita exatamente como ficará após o INSERT.
CREATE TRIGGER verificar_frequencia
BEFORE INSERT ON tb_frequencias -- BEFORE INSERT o cálculo acontece antes de salvar, e usando SQLSTATE '01000' -- emite o aviso MAS não cancela o INSERT, registrar e alertar, nunca bloquear.
FOR EACH ROW
BEGIN
  DECLARE total_aulas     INT     DEFAULT 0;
  DECLARE total_presentes INT     DEFAULT 0;
  DECLARE percentual      DECIMAL(5,2);
  -- Busca os registros já existentes na tabela para esse aluno/disciplina/turma/ano
  SELECT
    COUNT(*),
    SUM(CASE WHEN status IN ('Presente', 'Atestado') THEN 1 ELSE 0 END)
  INTO total_aulas, total_presentes
  FROM tb_frequencias
  WHERE fk_rgm             = NEW.fk_rgm
    AND fk_nome_disciplina = NEW.fk_nome_disciplina
    AND fk_serie           = NEW.fk_serie
    AND fk_ano_letivo      = NEW.fk_ano_letivo
    AND fk_turno           = NEW.fk_turno;
  -- Inclui manualmente o registro que está sendo inserido agora (NEW),
  -- pois no BEFORE INSERT ele ainda não consta na tabela física
  SET total_aulas     = total_aulas + 1;
  SET total_presentes = total_presentes
                        + CASE WHEN NEW.status IN ('Presente', 'Atestado') THEN 1 ELSE 0 END;
  -- Calcula o percentual já considerando o novo registro
  SET percentual = (total_presentes / total_aulas) * 100;
  -- Se cair abaixo de 75%, emite WARNING sem cancelar o INSERT
  -- MESSAGE_TEXT fica disponível via SHOW WARNINGS após o INSERT
  IF percentual < 75 THEN
    SIGNAL SQLSTATE '01000'
      SET MESSAGE_TEXT = 'Atencao: Aluno abaixo de 75% de frequencia nesta disciplina!';
  END IF;
END$$



-- gerar_mensalidades gera automaticamente as 12 mensalidades após criar um contrato escolar.
-- calcula valor_final localmente (sem depender de campo armazenado no contrato).
-- Janeiro (mês 1) soma os 15% da rematrícula (também calculados sobre o valor com desconto) ao valor da primeira parcela.
-- Vencimento = dia 06 do mês seguinte ao mês de referência. 
-- Não da para colcoar para o proximo dia util isso não é uma obrigação do banco e sim de um sistema financeiro de banco da escola
CREATE TRIGGER gerar_mensalidades -- Trigger relacionado com a tb_contrato_escolar
AFTER INSERT ON tb_contrato_escolar
FOR EACH ROW
BEGIN
  DECLARE mes          INT DEFAULT 1;
  DECLARE valor_desc   DECIMAL(10,2);
  DECLARE valor_final  DECIMAL(10,2);
  DECLARE valor_remat  DECIMAL(10,2);
  DECLARE valor_mes    DECIMAL(10,2);
  -- Calcula desconto conforme bolsa
  SET valor_desc = CASE NEW.bolsa
    WHEN 'Bolsa_25' THEN NEW.valor_mensalidade * 0.25
    WHEN 'Bolsa_50' THEN NEW.valor_mensalidade * 0.50
    WHEN 'Bolsa_75' THEN NEW.valor_mensalidade * 0.75
    ELSE 0
  END;
  SET valor_final = NEW.valor_mensalidade - valor_desc;
  SET valor_remat = valor_final * 0.15;
  WHILE mes <= 12 DO
    IF mes = 1 THEN
      SET valor_mes = valor_final + valor_remat;
    ELSE
      SET valor_mes = valor_final;
    END IF;
    INSERT INTO tb_mensalidades (
      fk_cpf_responsavel,
      fk_rgm_aluno,
      fk_ano_letivo,
      mes_referencia,
      data_vencimento,
      valor_mensalidade,
      inclui_rematricula,
      status
    ) VALUES (
      NEW.fk_cpf_responsavel,
      NEW.fk_rgm_aluno,
      NEW.fk_ano_letivo,
      mes,
      DATE_ADD(
        LAST_DAY(CONCAT(NEW.fk_ano_letivo, '-', LPAD(mes, 2, '0'), '-01')),
        INTERVAL 6 DAY
      ),
      valor_mes,
      IF(mes = 1, TRUE, FALSE),
      'Pendente'
    );
    SET mes = mes + 1;
  END WHILE;
END$$
-- estornar cobranças futuras em caso de cancelamento.
-- localiza mensalidades pendentes após o mês atual
-- e altera o status para 'Cancelado'
CREATE TRIGGER cancelar_mensalidades -- Trigger relacionado com a tb_contrato_escolar
AFTER UPDATE ON tb_contrato_escolar
FOR EACH ROW
BEGIN
  IF NEW.status IN ('Cancelado','Transferido') AND OLD.status = 'Ativo' THEN
    UPDATE tb_mensalidades
    SET status = 'Cancelado'
    WHERE fk_cpf_responsavel = NEW.fk_cpf_responsavel
      AND fk_rgm_aluno       = NEW.fk_rgm_aluno
      AND fk_ano_letivo      = NEW.fk_ano_letivo
      AND status             = 'Pendente'
      AND mes_referencia     > MONTH(CURDATE());
  END IF;
END$$



-- atualizar_status_mensalidade marca mensalidade como Pago quando o valor pago é >= valor da mensalidade.
-- compara com valor_mensalidade(base) pois valor_total foi removido da tabela física.
-- valores de multa e juros são calculados pela vw_mensalidades para referência
-- quitação é validada pelo sistema de pagamento com o valor correto.
CREATE TRIGGER atualizar_status_mensalidade
AFTER INSERT ON tb_pagamentos
FOR EACH ROW
BEGIN
  DECLARE valor_devido DECIMAL(10,2);
  SELECT valor_mensalidade INTO valor_devido
  FROM tb_mensalidades
  WHERE fk_cpf_responsavel = NEW.fk_cpf_responsavel
    AND fk_rgm_aluno       = NEW.fk_rgm_aluno
    AND fk_ano_letivo      = NEW.fk_ano_letivo
    AND mes_referencia     = NEW.fk_mes_referencia;
  IF NEW.valor_pago >= valor_devido THEN
    UPDATE tb_mensalidades
    SET status       = 'Pago',
        data_pagamento = DATE(NEW.data_pagamento)
    WHERE fk_cpf_responsavel = NEW.fk_cpf_responsavel
      AND fk_rgm_aluno       = NEW.fk_rgm_aluno
      AND fk_ano_letivo      = NEW.fk_ano_letivo
      AND mes_referencia     = NEW.fk_mes_referencia;
  END IF;
END$$



-- Automatizar o preenchimento da folha de pagamento.
-- Pega o salario atual e verifica se há abono de férias antes de salvar registro fisico
-- como faz = busca o salário vigente na "tb_vinculos".
-- consultando a "vw_ferias_detalhada" para verificar se existe 1/3 do salario/ferias pra funcionar neste mês
-- usuario precise informar apenas o CPF e o Mês
CREATE TRIGGER calcular_folha
BEFORE INSERT ON tb_folha_pagamento
FOR EACH ROW
BEGIN
    DECLARE v_salario DECIMAL(10,2);
    DECLARE v_abono   DECIMAL(10,2) DEFAULT 0;
    -- Grava o salário vigente na data de competência
    SELECT salario_base INTO v_salario
	FROM tb_vinculos
	WHERE fk_cpf_funcionario = NEW.fk_cpf_funcionario
	ORDER BY salario_base DESC  
	LIMIT 1;
    SET NEW.salario_base = v_salario;
    -- Grava o abono de férias do mês, se houver
    SELECT COALESCE(valor_abono_ferias, 0) INTO v_abono
    FROM vw_ferias_detalhada
    WHERE fk_cpf_funcionario = NEW.fk_cpf_funcionario
      AND ano                = NEW.ano_referencia
      AND MONTH(data_inicio) = NEW.mes_referencia
    LIMIT 1;
    SET NEW.abono_ferias = v_abono;
END$$ -- rever



-- validar_professor_disciplina garante que apenas funcionários com cargo 'Professor'
-- na tb_vinculos podem ser inseridos na grade horária.
CREATE TRIGGER validar_professor_disciplina
BEFORE INSERT ON tb_grade_horaria
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM tb_vinculos
    WHERE fk_cpf_funcionario = NEW.fk_cpf_professor
      AND cargo = 'Professor'
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Erro: Funcionario nao possui cargo de Professor em tb_vinculos!';
  END IF;
END$$
-- validar_conflito_grade impede que o mesmo professor seja alocado em dois horários idênticos 
-- idênticos ao mesmo tempo, independente da turma ou disciplina.
-- A verificação ignora fk_nome_disciplina intencionalmente: 
-- um professor não pode estar em duas turmas diferentes no mesmo dia + número de aula + ano letivo, mesmo as disciplinas sejam diferentes.
CREATE TRIGGER validar_conflito_grade
BEFORE INSERT ON tb_grade_horaria
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM tb_grade_horaria
    WHERE fk_cpf_professor = NEW.fk_cpf_professor
      AND fk_ano_letivo    = NEW.fk_ano_letivo
      AND dia_semana       = NEW.dia_semana
      AND numero_aula      = NEW.numero_aula
      AND data_fim         IS NULL
      -- Sem filtro de fk_serie, fk_turno ou fk_nome_disciplina:
      -- bloqueia o conflito independente de qual turma ou disciplina for
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Erro: Professor ja esta alocado neste dia e horario em outra turma ou disciplina!';
  END IF;
END$$

DELIMITER ;
-- O separador de comandos volta ;

-- -------------------------------------------------------------------------------------------------

-- PASSO 3 – DML: 1ª CARGA DE DADOS
-- Após a carga, COUNT(*) registra os totais iniciais.
-- Finalidade : Inserir dados operacionais em todas as tabelas para validar tabelas, VIEWs e TRIGGERs de forma integrada.


USE SisGESC; 
-- Se precisar


-- DESABILITAR CHECKS TEMPORARIAMENTE (re-habilitar ao final)
SET FOREIGN_KEY_CHECKS = 0;



-- 1. TURMAS
INSERT IGNORE INTO tb_turmas (serie, ano_letivo, turno) VALUES
('6',   2025, 'Manha'),
('7',   2025, 'Manha'),
('8',   2025, 'Tarde'),
('9',   2025, 'Tarde'),
('1EM', 2025, 'Manha'),
('2EM', 2025, 'Tarde'),
('3EM', 2025, 'Manha');



-- 2. DISCIPLINAS
INSERT IGNORE INTO tb_disciplinas (pk_nome_disciplina, nivel) VALUES
('Matematica',          'Ambos'),
('Portugues',           'Ambos'),
('Historia',            'Ambos'),
('Ciencias',            'Fundamental'),
('Geografia',           'Fundamental'),
('Biologia',            'Medio'),
('Quimica',             'Medio'),
('Fisica',              'Medio'),
('Ed. Fisica',          'Ambos'),
('Arte',                'Fundamental'),
('Filosofia',           'Medio'),
('Sociologia',          'Medio'),
('Ingles',              'Ambos');



-- 3. TURMA_DISCIPLINAS  (trigger validar_nivel_disciplina será testado)
-- Fundamental (6° ao 9°) – somente disciplinas Fundamental ou Ambos
INSERT IGNORE INTO tb_turma_disciplinas VALUES
('6', 2025, 'Manha', 'Matematica'),
('6', 2025, 'Manha', 'Portugues'),
('6', 2025, 'Manha', 'Ciencias'),
('6', 2025, 'Manha', 'Historia'),
('6', 2025, 'Manha', 'Ed. Fisica'),
('7', 2025, 'Manha', 'Matematica'),
('7', 2025, 'Manha', 'Portugues'),
('7', 2025, 'Manha', 'Ciencias'),
('8', 2025, 'Tarde', 'Matematica'),
('8', 2025, 'Tarde', 'Historia'),
('9', 2025, 'Tarde', 'Matematica'),
('9', 2025, 'Tarde', 'Portugues'),
('9', 2025, 'Tarde', 'Geografia');

-- Médio (1EM ao 3EM) – somente disciplinas Médio ou Ambos
INSERT IGNORE INTO tb_turma_disciplinas VALUES
('1EM', 2025, 'Manha', 'Matematica'),
('1EM', 2025, 'Manha', 'Portugues'),
('1EM', 2025, 'Manha', 'Biologia'),
('1EM', 2025, 'Manha', 'Quimica'),
('1EM', 2025, 'Manha', 'Fisica'),
('2EM', 2025, 'Tarde', 'Matematica'),
('2EM', 2025, 'Tarde', 'Biologia'),
('2EM', 2025, 'Tarde', 'Quimica'),
('2EM', 2025, 'Tarde', 'Fisica'),
('2EM', 2025, 'Tarde', 'Filosofia'),
('3EM', 2025, 'Manha', 'Matematica'),
('3EM', 2025, 'Manha', 'Portugues'),
('3EM', 2025, 'Manha', 'Fisica'),
('3EM', 2025, 'Manha', 'Sociologia');



-- 4. ALUNOS  (trigger limpar_dados_aluno remove pontuação de RGM/CPF/CEP)
INSERT IGNORE INTO tb_alunos
(pk_rgm, primeiro_nome, sobrenome, sexo, cpf, data_nascimento, email,
 rua, numero, complemento, bairro, cidade, estado, cep)
VALUES
('2025001', 'Lucas',    'Ferreira',  'Masculino', '123.456.789-01', '2010-03-15',
 'lucas.ferreira@email.com',  'Rua das Flores',  '10', NULL,  'Centro',     'São Paulo', 'SP', '01001-000'),
('2025002', 'Ana',      'Souza',     'Feminino',  '234.567.890-12', '2010-07-22',
 'ana.souza@email.com',       'Av. Paulista',    '200','Apto 3','Bela Vista',  'São Paulo', 'SP', '01310-100'),
('2025003', 'Carlos',   'Lima',      'Masculino', '345.678.901-23', '2009-11-05',
 'carlos.lima@email.com',     'Rua Augusta',     '55', NULL,  'Consolação', 'São Paulo', 'SP', '01305-000'),
('2025004', 'Maria',    'Oliveira',  'Feminino',  '456.789.012-34', '2008-06-18',
 'maria.oliveira@email.com',  'Rua Oscar Freire','320',NULL,  'Jardins',    'São Paulo', 'SP', '01426-001'),
('2025005', 'Pedro',    'Santos',    'Masculino', '567.890.123-45', '2007-02-28',
 'pedro.santos@email.com',    'Rua da Consolação','80',NULL,  'Higienópolis','São Paulo','SP', '01302-000'),
('2025006', 'Julia',    'Costa',     'Feminino',  '678.901.234-56', '2006-09-12',
 'julia.costa@email.com',     'Av. Brasil',      '500',NULL, 'Mooca',      'São Paulo', 'SP', '03203-000'),
('2025007', 'Rafael',   'Alves',     'Masculino', '789.012.345-67', '2005-12-30',
 'rafael.alves@email.com',    'Rua Vergueiro',   '750',NULL, 'Vila Mariana','São Paulo','SP', '04101-000'),
('2025008', 'Beatriz',  'Rodrigues', 'Feminino',  '890.123.456-78', '2005-04-14',
 'beatriz.rodrigues@email.com','Rua Tutoia',     '100',NULL, 'Paraíso',    'São Paulo', 'SP', '04007-000');
SELECT * FROM tb_alunos;


-- 5. RESPONSÁVEIS
INSERT IGNORE INTO tb_responsaveis
(pk_cpf, primeiro_nome, sobrenome, email, telefone, parentesco, responsavel_financeiro)
VALUES
('11122233344', 'Roberto',  'Ferreira', 'roberto.ferreira@email.com', '11999990001', 'Pai',    TRUE),
('22233344455', 'Carla',    'Souza',    'carla.souza@email.com',      '11999990002', 'Mae',    TRUE),
('33344455566', 'José',     'Lima',     'jose.lima@email.com',        '11999990003', 'Pai',    TRUE),
('44455566677', 'Fernanda', 'Oliveira', 'fernanda.oliveira@email.com','11999990004', 'Mae',    TRUE),
('55566677788', 'Antonio',  'Santos',   'antonio.santos@email.com',   '11999990005', 'Pai',    TRUE),
('66677788899', 'Mariana',  'Costa',    'mariana.costa@email.com',    '11999990006', 'Mae',    TRUE),
('77788899900', 'Thiago',   'Alves',    'thiago.alves@email.com',     '11999990007', 'Pai',    TRUE),
('88899900011', 'Patricia', 'Rodrigues','patricia.rodrigues@email.com','11999990008','Mae',    TRUE);
SELECT * FROM tb_responsaveis; 


-- 6. ALUNO_RESPONSAVEL
INSERT IGNORE INTO tb_aluno_responsavel (fk_rgm, fk_cpf) VALUES
('2025001','11122233344'),
('2025002','22233344455'),
('2025003','33344455566'),
('2025004','44455566677'),
('2025005','55566677788'),
('2025006','66677788899'),
('2025007','77788899900'),
('2025008','88899900011');
SELECT * FROM tb_aluno_responsavel; 


-- 7. MATRÍCULAS
INSERT IGNORE INTO tb_matriculas
(fk_rgm, fk_serie, fk_ano_letivo, fk_turno, data_matricula, status)
VALUES
('2025001','6',   2025,'Manha','2025-01-10','Ativo'),
('2025002','6',   2025,'Manha','2025-01-10','Ativo'),
('2025003','7',   2025,'Manha','2025-01-10','Ativo'),
('2025004','8',   2025,'Tarde','2025-01-10','Ativo'),
('2025005','9',   2025,'Tarde','2025-01-10','Ativo'),
('2025006','1EM', 2025,'Manha','2025-01-10','Ativo'),
('2025007','2EM', 2025,'Tarde','2025-01-10','Ativo'),
('2025008','3EM', 2025,'Manha','2025-01-10','Ativo');
SELECT * FROM tb_matriculas; 


-- 8. FUNCIONÁRIOS
INSERT IGNORE INTO tb_funcionarios
(pk_cpf, primeiro_nome, sobrenome, email, status, data_admissao)
VALUES
('10000000001','Marcos',   'Diretor',    'marcos.diretor@sisgesc.com',    'Ativo','2015-02-01'),
('10000000002','Silvia',   'Coordenadora','silvia.coord@sisgesc.com',     'Ativo','2017-03-15'),
('10000000003','Joao',     'Professor',  'joao.mat@sisgesc.com',          'Ativo','2018-07-01'),
('10000000004','Fernanda', 'Professora', 'fernanda.port@sisgesc.com',     'Ativo','2019-01-10'),
('10000000005','Ricardo',  'Professor',  'ricardo.bio@sisgesc.com',       'Ativo','2020-02-20'),
('10000000006','Amanda',   'Secretaria', 'amanda.sec@sisgesc.com',        'Ativo','2021-06-01'),
('10000000007','Paulo',    'Porteiro',   'paulo.port@sisgesc.com',        'Ativo','2022-08-01'),
('10000000008','Lucia',    'Aux_Limpeza','lucia.limp@sisgesc.com',        'Ativo','2023-01-05'),
('10000000009','Carlos',   'Contador',   'carlos.cont@sisgesc.com',       'Ativo','2016-09-01'),
('10000000010','Helena',   'Administradora','helena.adm@sisgesc.com',     'Ativo','2014-04-01');
SELECT * FROM tb_funcionarios;


-- 9. VÍNCULOS  (trigger validar_cargo_departamento será testado)
INSERT IGNORE INTO tb_vinculos (fk_cpf_funcionario, cargo, departamento, salario_base) VALUES
('10000000001','Diretor',       'Pedagogico',    12000.00),
('10000000002','Coordenador',   'Pedagogico',     8000.00),
('10000000003','Professor',     'Pedagogico',     5500.00),
('10000000004','Professor',     'Pedagogico',     5200.00),
('10000000005','Professor',     'Pedagogico',     5800.00),
('10000000006','Secretario',    'Administrativo', 3800.00),
('10000000007','Porteiro',      'Operacional',    2500.00),
('10000000008','Aux_Limpeza',   'Operacional',    2200.00),
('10000000009','Contador',      'Financeiro',     7000.00),
('10000000010','Administrador', 'Administrativo', 9000.00);
SELECT * FROM tb_vinculos;


-- 10. FORMAÇÕES
INSERT IGNORE INTO tb_formacoes
(fk_cpf_funcionario, curso, instituicao, ano_conclusao, diploma_url)
VALUES
('10000000003','Licenciatura em Matematica','USP',        2015,'https://docs.escola.com/diplomas/joao_mat.pdf'),
('10000000004','Licenciatura em Letras',    'UNICAMP',    2017,'https://docs.escola.com/diplomas/fernanda_port.pdf'),
('10000000005','Licenciatura em Biologia',  'UNESP',     2018,'https://docs.escola.com/diplomas/ricardo_bio.pdf'),
('10000000001','Mestrado em Gestão Escolar','PUC-SP',    2010,'https://docs.escola.com/diplomas/marcos_dir.pdf'),
('10000000009','Ciencias Contabeis',        'FGV',       2012,'https://docs.escola.com/diplomas/carlos_cont.pdf');
SELECT * FROM tb_formacoes;


-- 11. GRADE HORÁRIA (triggers: validar_professor_disciplina + validar_conflito_grade)
INSERT IGNORE INTO tb_grade_horaria
(fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 dia_semana, numero_aula, data_inicio, data_fim, carga_horaria_semanal)
VALUES
-- João (Matemática) – 6° manhã
('10000000003','6',2025,'Manha','Matematica','Segunda','aula_1','2025-02-01',NULL,5),
('10000000003','6',2025,'Manha','Matematica','Terca',  'aula_2','2025-02-01',NULL,5),
('10000000003','6',2025,'Manha','Matematica','Quarta', 'aula_3','2025-02-01',NULL,5),
-- João também dá aula para 7° (dia/aula diferente para não conflitar)
('10000000003','7',2025,'Manha','Matematica','Quinta', 'aula_1','2025-02-01',NULL,5),
-- Fernanda (Português) – 6° manhã
('10000000004','6',2025,'Manha','Portugues','Segunda','aula_2','2025-02-01',NULL,5),
('10000000004','6',2025,'Manha','Portugues','Terca',  'aula_1','2025-02-01',NULL,5),
-- Ricardo (Biologia) – 1EM manhã e 2EM tarde
('10000000005','1EM',2025,'Manha','Biologia','Segunda','aula_4','2025-02-01',NULL,4),
('10000000005','2EM',2025,'Tarde','Biologia','Terca',  'aula_1','2025-02-01',NULL,4);
SELECT * FROM tb_grade_horaria;


-- 12. AVALIAÇÕES
INSERT IGNORE INTO tb_avaliacoes
(fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 titulo, tipo, bimestre, valor_maximo, data_inicio, data_fim)
VALUES
-- Matemática – 6° BIM1
('10000000003','6',2025,'Manha','Matematica','Prova BIM1 Mat','Prova','BIM1',10.00,'2025-03-01 08:00:00','2025-03-01 09:00:00'),
('10000000003','6',2025,'Manha','Matematica','Trabalho BIM1 Mat','Trabalho','BIM1',10.00,'2025-03-10 08:00:00','2025-03-20 08:00:00'),
-- Matemática – 6° BIM2
('10000000003','6',2025,'Manha','Matematica','Prova BIM2 Mat','Prova','BIM2',10.00,'2025-05-15 08:00:00','2025-05-15 09:00:00'),
-- Português – 6° BIM1
('10000000004','6',2025,'Manha','Portugues','Prova BIM1 Port','Prova','BIM1',10.00,'2025-03-02 08:00:00','2025-03-02 09:00:00'),
-- Biologia – 1EM BIM1
('10000000005','1EM',2025,'Manha','Biologia','Prova BIM1 Bio','Prova','BIM1',10.00,'2025-03-05 08:00:00','2025-03-05 09:00:00'),
-- Recuperação (tipo Recuperacao) – Matemática 6° BIM1
('10000000003','6',2025,'Manha','Matematica','Recuperacao BIM1 Mat','Recuperacao','BIM1',10.00,'2025-04-01 08:00:00','2025-04-01 09:00:00');
SELECT * FROM tb_avaliacoes;


-- 13. NOTAS (triggers: validar_nota_maxima + verificar_recuperacao)
-- Aluno 2025001 – Matemática – BIM1
-- Notas altas → deve ficar 'Aprovado'
INSERT IGNORE INTO tb_notas
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 fk_bimestre, fk_tipo, fk_titulo, nota_obtida)
VALUES
('2025001','10000000003','6',2025,'Manha','Matematica','BIM1','Prova','Prova BIM1 Mat',8.00),
('2025001','10000000003','6',2025,'Manha','Matematica','BIM1','Trabalho','Trabalho BIM1 Mat',9.00);

-- Aluno 2025002 – Matemática – BIM1 → nota baixa → deve ficar 'Recuperacao'
INSERT IGNORE INTO tb_notas
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 fk_bimestre, fk_tipo, fk_titulo, nota_obtida)
VALUES
('2025002','10000000003','6',2025,'Manha','Matematica','BIM1','Prova','Prova BIM1 Mat',3.00),
('2025002','10000000003','6',2025,'Manha','Matematica','BIM1','Trabalho','Trabalho BIM1 Mat',4.00);

-- Aluno 2025001 – Português – BIM1
INSERT IGNORE INTO tb_notas
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 fk_bimestre, fk_tipo, fk_titulo, nota_obtida)
VALUES
('2025001','10000000004','6',2025,'Manha','Portugues','BIM1','Prova','Prova BIM1 Port',7.50);

-- Aluno 2025006 – Biologia – BIM1
INSERT IGNORE INTO tb_notas
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 fk_bimestre, fk_tipo, fk_titulo, nota_obtida)
VALUES
('2025006','10000000005','1EM',2025,'Manha','Biologia','BIM1','Prova','Prova BIM1 Bio',9.00);

-- Matemática BIM2 – aluno 2025001
INSERT IGNORE INTO tb_notas
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 fk_bimestre, fk_tipo, fk_titulo, nota_obtida)
VALUES
('2025001','10000000003','6',2025,'Manha','Matematica','BIM2','Prova','Prova BIM2 Mat',6.50);
SELECT * FROM tb_notas;


-- 14. FREQUÊNCIAS  (trigger verificar_frequencia emite WARNING se < 75%)
-- Aluno 2025001 – frequência regular (> 75%)
INSERT IGNORE INTO tb_frequencias
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 data_aula, numero_aula, status)
VALUES
('2025001','10000000003','6',2025,'Manha','Matematica','2025-02-03','aula_1','Presente'),
('2025001','10000000003','6',2025,'Manha','Matematica','2025-02-04','aula_2','Presente'),
('2025001','10000000003','6',2025,'Manha','Matematica','2025-02-05','aula_3','Presente'),
('2025001','10000000003','6',2025,'Manha','Matematica','2025-02-10','aula_1','Presente'),
('2025001','10000000003','6',2025,'Manha','Matematica','2025-02-11','aula_2','Ausente');

-- Aluno 2025002 – frequência baixa (< 75%) → deve gerar WARNING
INSERT IGNORE INTO tb_frequencias
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 data_aula, numero_aula, status)
VALUES
('2025002','10000000003','6',2025,'Manha','Matematica','2025-02-03','aula_1','Ausente'),
('2025002','10000000003','6',2025,'Manha','Matematica','2025-02-04','aula_2','Ausente'),
('2025002','10000000003','6',2025,'Manha','Matematica','2025-02-05','aula_3','Presente'),
('2025002','10000000003','6',2025,'Manha','Matematica','2025-02-10','aula_1','Ausente');
SELECT * FROM tb_frequencias;


-- 15. ATESTADOS  (constraint chk_atestado_dono_unico garante exclusividade)

-- Atestado para aluno
INSERT IGNORE INTO tb_atestados
(fk_rgm_aluno, fk_cpf_funcionario, data_inicio, data_fim,
 nome_medico, sobrenome_medico, crm_medico, atestado_url, data_entrega)
VALUES
('2025002', NULL, '2025-02-04', '2025-02-04',
 'João','Silva','CRM-SP-123456',
 'https://docs.escola.com/atestados/2025002_fev.pdf','2025-02-05 09:00:00');

-- Atestado para funcionário
INSERT IGNORE INTO tb_atestados
(fk_rgm_aluno, fk_cpf_funcionario, data_inicio, data_fim,
 nome_medico, sobrenome_medico, crm_medico, atestado_url, data_entrega)
VALUES
(NULL, '10000000008', '2025-03-10', '2025-03-12',
 'Maria','Santos','CRM-SP-654321',
 'https://docs.escola.com/atestados/lucia_mar.pdf','2025-03-13 08:30:00');
SELECT * FROM tb_atestados;


-- 16. CONTRATOS ESCOLARES (trigger gerar_mensalidades criará 12 parcelas automaticamente)
INSERT IGNORE INTO tb_contrato_escolar
(fk_cpf_responsavel, fk_rgm_aluno, fk_serie, fk_ano_letivo, fk_turno,
 data_inicio, data_fim, valor_mensalidade, bolsa, status)
VALUES
('11122233344','2025001','6',  2025,'Manha','2025-01-01','2025-12-31',1200.00,'Sem_Bolsa','Ativo'),
('22233344455','2025002','6',  2025,'Manha','2025-01-01','2025-12-31',1200.00,'Bolsa_25', 'Ativo'),
('33344455566','2025003','7',  2025,'Manha','2025-01-01','2025-12-31',1200.00,'Bolsa_50', 'Ativo'),
('44455566677','2025004','8',  2025,'Tarde','2025-01-01','2025-12-31',1500.00,'Sem_Bolsa','Ativo'),
('55566677788','2025005','9',  2025,'Tarde','2025-01-01','2025-12-31',1500.00,'Sem_Bolsa','Ativo'),
('66677788899','2025006','1EM',2025,'Manha','2025-01-01','2025-12-31',1800.00,'Sem_Bolsa','Ativo'),
('77788899900','2025007','2EM',2025,'Tarde','2025-01-01','2025-12-31',1800.00,'Bolsa_25', 'Ativo'),
('88899900011','2025008','3EM',2025,'Manha','2025-01-01','2025-12-31',1800.00,'Bolsa_50', 'Ativo');
SELECT * FROM tb_contrato_escolar;


-- 17. PAGAMENTOS  (trigger atualizar_status_mensalidade marcará como 'Pago')

-- Aluno 2025001 – paga mês 1 (Janeiro – com rematrícula)
INSERT IGNORE INTO tb_pagamentos
(fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, fk_mes_referencia,
 valor_pago, forma_pagamento, data_pagamento)
VALUES
('11122233344','2025001',2025,1,1380.00,'PIX','2025-01-06 10:00:00');

-- Aluno 2025001 – paga mês 2 (Fevereiro)
INSERT IGNORE INTO tb_pagamentos
(fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, fk_mes_referencia,
 valor_pago, forma_pagamento, data_pagamento)
VALUES
('11122233344','2025001',2025,2,1200.00,'Boleto','2025-02-06 11:00:00');

-- Aluno 2025004 – paga mês 1
INSERT IGNORE INTO tb_pagamentos
(fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, fk_mes_referencia,
 valor_pago, forma_pagamento, data_pagamento)
VALUES
('44455566677','2025004',2025,1,1725.00,'Cartao_Credito','2025-01-07 09:30:00');
SELECT * FROM tb_pagamentos;


-- 18. RECEITAS E DESPESAS
INSERT IGNORE INTO tb_receitas
(fk_cpf_funcionario, tipo, descricao, valor, data_hora_receita, status)
VALUES
('10000000009','Mensalidade',   'Mensalidades Janeiro 2025', 38000.00,'2025-01-31 18:00:00','Pago'),
('10000000009','Mensalidade',   'Mensalidades Fevereiro 2025',37500.00,'2025-02-28 18:00:00','Pago'),
('10000000009','Matricula',     'Matrículas 2025',            5000.00,'2025-01-10 09:00:00','Pago'),
('10000000009','Rematricula',   'Rematrículas 2025',          2800.00,'2025-01-10 09:00:01','Pago'),
('10000000009','Cantina',       'Cantina Janeiro 2025',        800.00,'2025-01-31 18:00:01','Pago'),
('10000000009','Evento',        'Festa Junina 2025',          1200.00,'2025-06-15 20:00:00','Pendente');
SELECT * FROM tb_receitas;

INSERT IGNORE INTO tb_despesas
(fk_cpf_funcionario, tipo, descricao, valor, data_hora_despesa, data_vencimento, status)
VALUES
('10000000010','Luz',       'Conta de luz Janeiro',   1500.00,'2025-01-25 10:00:00','2025-01-30','Pago'),
('10000000010','Agua',      'Conta de água Janeiro',   600.00,'2025-01-25 10:01:00','2025-01-30','Pago'),
('10000000010','Internet',  'Internet Janeiro',        300.00,'2025-01-20 10:00:00','2025-01-25','Pago'),
('10000000010','Aluguel',   'Aluguel Fevereiro',     8000.00,'2025-01-31 10:00:00','2025-02-05','Pago'),
('10000000010','Limpeza',   'Material limpeza',        400.00,'2025-02-10 10:00:00','2025-02-15','Pago'),
('10000000010','Papelaria', 'Materiais didáticos',    1200.00,'2025-02-15 10:00:00','2025-02-28','Pendente');
SELECT * FROM tb_despesas;


-- 19. FÉRIAS  (vw_ferias_detalhada calcula data_fim e abono)
INSERT IGNORE INTO tb_ferias
(fk_cpf_funcionario, ano, data_inicio, status, aprovado_por)
VALUES
('10000000003', 2025, '2025-07-01', 'Agendado',  '10000000001'),
('10000000004', 2025, '2025-07-01', 'Agendado',  '10000000001'),
('10000000007', 2025, '2025-06-01', 'Em_Ferias', '10000000010'),
('10000000008', 2025, '2025-06-01', 'Concluido', '10000000010');
SELECT * FROM tb_ferias;


-- 20. FOLHA DE PAGAMENTOc(trigger calcular_folha preenche salario_base e abono_ferias automaticamente)
-- só informamos fk_cpf_funcionario, mes_referencia, ano_referencia e data_pagamento

INSERT IGNORE INTO tb_folha_pagamento
(fk_cpf_funcionario, mes_referencia, ano_referencia, salario_base, abono_ferias, data_pagamento)
VALUES
('10000000003', 1, 2025, 0, 0, '2025-01-31'),
('10000000004', 1, 2025, 0, 0, '2025-01-31'),
('10000000005', 1, 2025, 0, 0, '2025-01-31'),
('10000000006', 1, 2025, 0, 0, '2025-01-31'),
('10000000007', 1, 2025, 0, 0, '2025-01-31'),
('10000000008', 1, 2025, 0, 0, '2025-01-31'),
('10000000003', 2, 2025, 0, 0, '2025-02-28'),
('10000000004', 2, 2025, 0, 0, '2025-02-28');

-- Mês de Julho (julho=7) para João e Fernanda que têm férias agendadas a partir de 01/07
INSERT IGNORE INTO tb_folha_pagamento
(fk_cpf_funcionario, mes_referencia, ano_referencia, salario_base, abono_ferias, data_pagamento)
VALUES
('10000000003', 7, 2025, 0, 0, '2025-07-31'),
('10000000004', 7, 2025, 0, 0, '2025-07-31');
SELECT * FROM tb_folha_pagamento;


-- RE-HABILITAR CHECKS
SET FOREIGN_KEY_CHECKS = 1;


-- --------------------------------------------------------------------------------------------------------------------------------------
-- VALIDAÇÃO DE IDEMPOTÊNCIA – COUNT em todas as tabelas
-- Execute ANTES e APÓS a segunda execução do script para confirmar que os
-- números são idênticos (INSERT IGNORE descarta duplicatas silenciosamente).

SELECT 'tb_turmas'              AS tabela, COUNT(*) AS total FROM tb_turmas
UNION ALL
SELECT 'tb_disciplinas',                   COUNT(*) FROM tb_disciplinas
UNION ALL
SELECT 'tb_turma_disciplinas',             COUNT(*) FROM tb_turma_disciplinas
UNION ALL
SELECT 'tb_alunos',                        COUNT(*) FROM tb_alunos
UNION ALL
SELECT 'tb_responsaveis',                  COUNT(*) FROM tb_responsaveis
UNION ALL
SELECT 'tb_aluno_responsavel',             COUNT(*) FROM tb_aluno_responsavel
UNION ALL
SELECT 'tb_matriculas',                    COUNT(*) FROM tb_matriculas
UNION ALL
SELECT 'tb_funcionarios',                  COUNT(*) FROM tb_funcionarios
UNION ALL
SELECT 'tb_vinculos',                      COUNT(*) FROM tb_vinculos
UNION ALL
SELECT 'tb_formacoes',                     COUNT(*) FROM tb_formacoes
UNION ALL
SELECT 'tb_grade_horaria',                 COUNT(*) FROM tb_grade_horaria
UNION ALL
SELECT 'tb_avaliacoes',                    COUNT(*) FROM tb_avaliacoes
UNION ALL
SELECT 'tb_notas',                         COUNT(*) FROM tb_notas
UNION ALL
SELECT 'tb_frequencias',                   COUNT(*) FROM tb_frequencias
UNION ALL
SELECT 'tb_atestados',                     COUNT(*) FROM tb_atestados
UNION ALL
SELECT 'tb_contrato_escolar',              COUNT(*) FROM tb_contrato_escolar
UNION ALL
SELECT 'tb_mensalidades',                  COUNT(*) FROM tb_mensalidades
UNION ALL
SELECT 'tb_pagamentos',                    COUNT(*) FROM tb_pagamentos
UNION ALL
SELECT 'tb_receitas',                      COUNT(*) FROM tb_receitas
UNION ALL
SELECT 'tb_despesas',                      COUNT(*) FROM tb_despesas
UNION ALL
SELECT 'tb_ferias',                        COUNT(*) FROM tb_ferias
UNION ALL
SELECT 'tb_folha_pagamento',               COUNT(*) FROM tb_folha_pagamento;



-- VALIDAÇÃO 1ª CARGA – COUNT(*) em todas as tabelas OLTP
-- Anotar estes valores, após a 2ª carga devem ser IDÊNTICOS (idempotência).

SELECT 'tb_turmas'               AS tabela, COUNT(*) AS registros FROM tb_turmas
UNION ALL SELECT 'tb_disciplinas',      COUNT(*) FROM tb_disciplinas
UNION ALL SELECT 'tb_alunos',           COUNT(*) FROM tb_alunos
UNION ALL SELECT 'tb_responsaveis',     COUNT(*) FROM tb_responsaveis
UNION ALL SELECT 'tb_aluno_responsavel',COUNT(*) FROM tb_aluno_responsavel
UNION ALL SELECT 'tb_matriculas',       COUNT(*) FROM tb_matriculas
UNION ALL SELECT 'tb_turma_disciplinas',COUNT(*) FROM tb_turma_disciplinas
UNION ALL SELECT 'tb_funcionarios',     COUNT(*) FROM tb_funcionarios
UNION ALL SELECT 'tb_vinculos',         COUNT(*) FROM tb_vinculos
UNION ALL SELECT 'tb_formacoes',        COUNT(*) FROM tb_formacoes
UNION ALL SELECT 'tb_grade_horaria',    COUNT(*) FROM tb_grade_horaria
UNION ALL SELECT 'tb_avaliacoes',       COUNT(*) FROM tb_avaliacoes
UNION ALL SELECT 'tb_notas',            COUNT(*) FROM tb_notas
UNION ALL SELECT 'tb_frequencias',      COUNT(*) FROM tb_frequencias
UNION ALL SELECT 'tb_atestados',        COUNT(*) FROM tb_atestados
UNION ALL SELECT 'tb_contrato_escolar', COUNT(*) FROM tb_contrato_escolar
UNION ALL SELECT 'tb_mensalidades',     COUNT(*) FROM tb_mensalidades
UNION ALL SELECT 'tb_pagamentos',       COUNT(*) FROM tb_pagamentos
UNION ALL SELECT 'tb_receitas',         COUNT(*) FROM tb_receitas
UNION ALL SELECT 'tb_despesas',         COUNT(*) FROM tb_despesas
UNION ALL SELECT 'tb_ferias',           COUNT(*) FROM tb_ferias
UNION ALL SELECT 'tb_folha_pagamento',  COUNT(*) FROM tb_folha_pagamento;



-- PASSO 4 – DML: 2ª CARGA (reexecução – prova de idempotência)
-- O script é IDÊNTICO ao passo 3. Os registros NÃO devem aumentar.
-- SCRIPT: CARGA DE DADOS (DML)
-- Finalidade : Inserir dados operacionais em todas as tabelas para validar tabelas, VIEWs e TRIGGERs de forma integrada.


-- USE SisGESC; 
-- Se precisar


-- DESABILITAR CHECKS TEMPORARIAMENTE (re-habilitar ao final)
SET FOREIGN_KEY_CHECKS = 0;



-- 1. TURMAS
INSERT IGNORE INTO tb_turmas (serie, ano_letivo, turno) VALUES
('6',   2025, 'Manha'),
('7',   2025, 'Manha'),
('8',   2025, 'Tarde'),
('9',   2025, 'Tarde'),
('1EM', 2025, 'Manha'),
('2EM', 2025, 'Tarde'),
('3EM', 2025, 'Manha');
SELECT * FROM tb_turmas;


-- 2. DISCIPLINAS
INSERT IGNORE INTO tb_disciplinas (pk_nome_disciplina, nivel) VALUES
('Matematica',          'Ambos'),
('Portugues',           'Ambos'),
('Historia',            'Ambos'),
('Ciencias',            'Fundamental'),
('Geografia',           'Fundamental'),
('Biologia',            'Medio'),
('Quimica',             'Medio'),
('Fisica',              'Medio'),
('Ed. Fisica',          'Ambos'),
('Arte',                'Fundamental'),
('Filosofia',           'Medio'),
('Sociologia',          'Medio'),
('Ingles',              'Ambos');



-- 3. TURMA_DISCIPLINAS  (trigger validar_nivel_disciplina será testado)
-- Fundamental (6° ao 9°) – somente disciplinas Fundamental ou Ambos
INSERT IGNORE INTO tb_turma_disciplinas VALUES
('6', 2025, 'Manha', 'Matematica'),
('6', 2025, 'Manha', 'Portugues'),
('6', 2025, 'Manha', 'Ciencias'),
('6', 2025, 'Manha', 'Historia'),
('6', 2025, 'Manha', 'Ed. Fisica'),
('7', 2025, 'Manha', 'Matematica'),
('7', 2025, 'Manha', 'Portugues'),
('7', 2025, 'Manha', 'Ciencias'),
('8', 2025, 'Tarde', 'Matematica'),
('8', 2025, 'Tarde', 'Historia'),
('9', 2025, 'Tarde', 'Matematica'),
('9', 2025, 'Tarde', 'Portugues'),
('9', 2025, 'Tarde', 'Geografia');

-- Médio (1EM ao 3EM) – somente disciplinas Médio ou Ambos
INSERT IGNORE INTO tb_turma_disciplinas VALUES
('1EM', 2025, 'Manha', 'Matematica'),
('1EM', 2025, 'Manha', 'Portugues'),
('1EM', 2025, 'Manha', 'Biologia'),
('1EM', 2025, 'Manha', 'Quimica'),
('1EM', 2025, 'Manha', 'Fisica'),
('2EM', 2025, 'Tarde', 'Matematica'),
('2EM', 2025, 'Tarde', 'Biologia'),
('2EM', 2025, 'Tarde', 'Quimica'),
('2EM', 2025, 'Tarde', 'Fisica'),
('2EM', 2025, 'Tarde', 'Filosofia'),
('3EM', 2025, 'Manha', 'Matematica'),
('3EM', 2025, 'Manha', 'Portugues'),
('3EM', 2025, 'Manha', 'Fisica'),
('3EM', 2025, 'Manha', 'Sociologia');



-- 4. ALUNOS  (trigger limpar_dados_aluno remove pontuação de RGM/CPF/CEP)
INSERT IGNORE INTO tb_alunos
(pk_rgm, primeiro_nome, sobrenome, sexo, cpf, data_nascimento, email,
 rua, numero, complemento, bairro, cidade, estado, cep)
VALUES
('2025001', 'Lucas',    'Ferreira',  'Masculino', '123.456.789-01', '2010-03-15',
 'lucas.ferreira@email.com',  'Rua das Flores',  '10', NULL,  'Centro',     'São Paulo', 'SP', '01001-000'),
('2025002', 'Ana',      'Souza',     'Feminino',  '234.567.890-12', '2010-07-22',
 'ana.souza@email.com',       'Av. Paulista',    '200','Apto 3','Bela Vista',  'São Paulo', 'SP', '01310-100'),
('2025003', 'Carlos',   'Lima',      'Masculino', '345.678.901-23', '2009-11-05',
 'carlos.lima@email.com',     'Rua Augusta',     '55', NULL,  'Consolação', 'São Paulo', 'SP', '01305-000'),
('2025004', 'Maria',    'Oliveira',  'Feminino',  '456.789.012-34', '2008-06-18',
 'maria.oliveira@email.com',  'Rua Oscar Freire','320',NULL,  'Jardins',    'São Paulo', 'SP', '01426-001'),
('2025005', 'Pedro',    'Santos',    'Masculino', '567.890.123-45', '2007-02-28',
 'pedro.santos@email.com',    'Rua da Consolação','80',NULL,  'Higienópolis','São Paulo','SP', '01302-000'),
('2025006', 'Julia',    'Costa',     'Feminino',  '678.901.234-56', '2006-09-12',
 'julia.costa@email.com',     'Av. Brasil',      '500',NULL, 'Mooca',      'São Paulo', 'SP', '03203-000'),
('2025007', 'Rafael',   'Alves',     'Masculino', '789.012.345-67', '2005-12-30',
 'rafael.alves@email.com',    'Rua Vergueiro',   '750',NULL, 'Vila Mariana','São Paulo','SP', '04101-000'),
('2025008', 'Beatriz',  'Rodrigues', 'Feminino',  '890.123.456-78', '2005-04-14',
 'beatriz.rodrigues@email.com','Rua Tutoia',     '100',NULL, 'Paraíso',    'São Paulo', 'SP', '04007-000');



-- 5. RESPONSÁVEIS
INSERT IGNORE INTO tb_responsaveis
(pk_cpf, primeiro_nome, sobrenome, email, telefone, parentesco, responsavel_financeiro)
VALUES
('11122233344', 'Roberto',  'Ferreira', 'roberto.ferreira@email.com', '11999990001', 'Pai',    TRUE),
('22233344455', 'Carla',    'Souza',    'carla.souza@email.com',      '11999990002', 'Mae',    TRUE),
('33344455566', 'José',     'Lima',     'jose.lima@email.com',        '11999990003', 'Pai',    TRUE),
('44455566677', 'Fernanda', 'Oliveira', 'fernanda.oliveira@email.com','11999990004', 'Mae',    TRUE),
('55566677788', 'Antonio',  'Santos',   'antonio.santos@email.com',   '11999990005', 'Pai',    TRUE),
('66677788899', 'Mariana',  'Costa',    'mariana.costa@email.com',    '11999990006', 'Mae',    TRUE),
('77788899900', 'Thiago',   'Alves',    'thiago.alves@email.com',     '11999990007', 'Pai',    TRUE),
('88899900011', 'Patricia', 'Rodrigues','patricia.rodrigues@email.com','11999990008','Mae',    TRUE);



-- 6. ALUNO_RESPONSAVEL
INSERT IGNORE INTO tb_aluno_responsavel (fk_rgm, fk_cpf) VALUES
('2025001','11122233344'),
('2025002','22233344455'),
('2025003','33344455566'),
('2025004','44455566677'),
('2025005','55566677788'),
('2025006','66677788899'),
('2025007','77788899900'),
('2025008','88899900011');



-- 7. MATRÍCULAS
INSERT IGNORE INTO tb_matriculas
(fk_rgm, fk_serie, fk_ano_letivo, fk_turno, data_matricula, status)
VALUES
('2025001','6',   2025,'Manha','2025-01-10','Ativo'),
('2025002','6',   2025,'Manha','2025-01-10','Ativo'),
('2025003','7',   2025,'Manha','2025-01-10','Ativo'),
('2025004','8',   2025,'Tarde','2025-01-10','Ativo'),
('2025005','9',   2025,'Tarde','2025-01-10','Ativo'),
('2025006','1EM', 2025,'Manha','2025-01-10','Ativo'),
('2025007','2EM', 2025,'Tarde','2025-01-10','Ativo'),
('2025008','3EM', 2025,'Manha','2025-01-10','Ativo');



-- 8. FUNCIONÁRIOS
INSERT IGNORE INTO tb_funcionarios
(pk_cpf, primeiro_nome, sobrenome, email, status, data_admissao)
VALUES
('10000000001','Marcos',   'Diretor',    'marcos.diretor@sisgesc.com',    'Ativo','2015-02-01'),
('10000000002','Silvia',   'Coordenadora','silvia.coord@sisgesc.com',     'Ativo','2017-03-15'),
('10000000003','Joao',     'Professor',  'joao.mat@sisgesc.com',          'Ativo','2018-07-01'),
('10000000004','Fernanda', 'Professora', 'fernanda.port@sisgesc.com',     'Ativo','2019-01-10'),
('10000000005','Ricardo',  'Professor',  'ricardo.bio@sisgesc.com',       'Ativo','2020-02-20'),
('10000000006','Amanda',   'Secretaria', 'amanda.sec@sisgesc.com',        'Ativo','2021-06-01'),
('10000000007','Paulo',    'Porteiro',   'paulo.port@sisgesc.com',        'Ativo','2022-08-01'),
('10000000008','Lucia',    'Aux_Limpeza','lucia.limp@sisgesc.com',        'Ativo','2023-01-05'),
('10000000009','Carlos',   'Contador',   'carlos.cont@sisgesc.com',       'Ativo','2016-09-01'),
('10000000010','Helena',   'Administradora','helena.adm@sisgesc.com',     'Ativo','2014-04-01');



-- 9. VÍNCULOS  (trigger validar_cargo_departamento será testado)
INSERT IGNORE INTO tb_vinculos (fk_cpf_funcionario, cargo, departamento, salario_base) VALUES
('10000000001','Diretor',       'Pedagogico',    12000.00),
('10000000002','Coordenador',   'Pedagogico',     8000.00),
('10000000003','Professor',     'Pedagogico',     5500.00),
('10000000004','Professor',     'Pedagogico',     5200.00),
('10000000005','Professor',     'Pedagogico',     5800.00),
('10000000006','Secretario',    'Administrativo', 3800.00),
('10000000007','Porteiro',      'Operacional',    2500.00),
('10000000008','Aux_Limpeza',   'Operacional',    2200.00),
('10000000009','Contador',      'Financeiro',     7000.00),
('10000000010','Administrador', 'Administrativo', 9000.00);



-- 10. FORMAÇÕES
INSERT IGNORE INTO tb_formacoes
(fk_cpf_funcionario, curso, instituicao, ano_conclusao, diploma_url)
VALUES
('10000000003','Licenciatura em Matematica','USP',        2015,'https://docs.escola.com/diplomas/joao_mat.pdf'),
('10000000004','Licenciatura em Letras',    'UNICAMP',    2017,'https://docs.escola.com/diplomas/fernanda_port.pdf'),
('10000000005','Licenciatura em Biologia',  'UNESP',     2018,'https://docs.escola.com/diplomas/ricardo_bio.pdf'),
('10000000001','Mestrado em Gestão Escolar','PUC-SP',    2010,'https://docs.escola.com/diplomas/marcos_dir.pdf'),
('10000000009','Ciencias Contabeis',        'FGV',       2012,'https://docs.escola.com/diplomas/carlos_cont.pdf');



-- 11. GRADE HORÁRIA (triggers: validar_professor_disciplina + validar_conflito_grade)
INSERT IGNORE INTO tb_grade_horaria
(fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 dia_semana, numero_aula, data_inicio, data_fim, carga_horaria_semanal)
VALUES
-- João (Matemática) – 6° manhã
('10000000003','6',2025,'Manha','Matematica','Segunda','aula_1','2025-02-01',NULL,5),
('10000000003','6',2025,'Manha','Matematica','Terca',  'aula_2','2025-02-01',NULL,5),
('10000000003','6',2025,'Manha','Matematica','Quarta', 'aula_3','2025-02-01',NULL,5),
-- João também dá aula para 7° (dia/aula diferente para não conflitar)
('10000000003','7',2025,'Manha','Matematica','Quinta', 'aula_1','2025-02-01',NULL,5),
-- Fernanda (Português) – 6° manhã
('10000000004','6',2025,'Manha','Portugues','Segunda','aula_2','2025-02-01',NULL,5),
('10000000004','6',2025,'Manha','Portugues','Terca',  'aula_1','2025-02-01',NULL,5),
-- Ricardo (Biologia) – 1EM manhã e 2EM tarde
('10000000005','1EM',2025,'Manha','Biologia','Segunda','aula_4','2025-02-01',NULL,4),
('10000000005','2EM',2025,'Tarde','Biologia','Terca',  'aula_1','2025-02-01',NULL,4);



-- 12. AVALIAÇÕES
INSERT IGNORE INTO tb_avaliacoes
(fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 titulo, tipo, bimestre, valor_maximo, data_inicio, data_fim)
VALUES
-- Matemática – 6° BIM1
('10000000003','6',2025,'Manha','Matematica','Prova BIM1 Mat','Prova','BIM1',10.00,'2025-03-01 08:00:00','2025-03-01 09:00:00'),
('10000000003','6',2025,'Manha','Matematica','Trabalho BIM1 Mat','Trabalho','BIM1',10.00,'2025-03-10 08:00:00','2025-03-20 08:00:00'),
-- Matemática – 6° BIM2
('10000000003','6',2025,'Manha','Matematica','Prova BIM2 Mat','Prova','BIM2',10.00,'2025-05-15 08:00:00','2025-05-15 09:00:00'),
-- Português – 6° BIM1
('10000000004','6',2025,'Manha','Portugues','Prova BIM1 Port','Prova','BIM1',10.00,'2025-03-02 08:00:00','2025-03-02 09:00:00'),
-- Biologia – 1EM BIM1
('10000000005','1EM',2025,'Manha','Biologia','Prova BIM1 Bio','Prova','BIM1',10.00,'2025-03-05 08:00:00','2025-03-05 09:00:00'),
-- Recuperação (tipo Recuperacao) – Matemática 6° BIM1
('10000000003','6',2025,'Manha','Matematica','Recuperacao BIM1 Mat','Recuperacao','BIM1',10.00,'2025-04-01 08:00:00','2025-04-01 09:00:00');



-- 13. NOTAS (triggers: validar_nota_maxima + verificar_recuperacao)
-- Aluno 2025001 – Matemática – BIM1
-- Notas altas → deve ficar 'Aprovado'
INSERT IGNORE INTO tb_notas
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 fk_bimestre, fk_tipo, fk_titulo, nota_obtida)
VALUES
('2025001','10000000003','6',2025,'Manha','Matematica','BIM1','Prova','Prova BIM1 Mat',8.00),
('2025001','10000000003','6',2025,'Manha','Matematica','BIM1','Trabalho','Trabalho BIM1 Mat',9.00);

-- Aluno 2025002 – Matemática – BIM1 → nota baixa → deve ficar 'Recuperacao'
INSERT IGNORE INTO tb_notas
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 fk_bimestre, fk_tipo, fk_titulo, nota_obtida)
VALUES
('2025002','10000000003','6',2025,'Manha','Matematica','BIM1','Prova','Prova BIM1 Mat',3.00),
('2025002','10000000003','6',2025,'Manha','Matematica','BIM1','Trabalho','Trabalho BIM1 Mat',4.00);

-- Aluno 2025001 – Português – BIM1
INSERT IGNORE INTO tb_notas
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 fk_bimestre, fk_tipo, fk_titulo, nota_obtida)
VALUES
('2025001','10000000004','6',2025,'Manha','Portugues','BIM1','Prova','Prova BIM1 Port',7.50);

-- Aluno 2025006 – Biologia – BIM1
INSERT IGNORE INTO tb_notas
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 fk_bimestre, fk_tipo, fk_titulo, nota_obtida)
VALUES
('2025006','10000000005','1EM',2025,'Manha','Biologia','BIM1','Prova','Prova BIM1 Bio',9.00);

-- Matemática BIM2 – aluno 2025001
INSERT IGNORE INTO tb_notas
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 fk_bimestre, fk_tipo, fk_titulo, nota_obtida)
VALUES
('2025001','10000000003','6',2025,'Manha','Matematica','BIM2','Prova','Prova BIM2 Mat',6.50);



-- 14. FREQUÊNCIAS  (trigger verificar_frequencia emite WARNING se < 75%)
-- Aluno 2025001 – frequência regular (> 75%)
INSERT IGNORE INTO tb_frequencias
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 data_aula, numero_aula, status)
VALUES
('2025001','10000000003','6',2025,'Manha','Matematica','2025-02-03','aula_1','Presente'),
('2025001','10000000003','6',2025,'Manha','Matematica','2025-02-04','aula_2','Presente'),
('2025001','10000000003','6',2025,'Manha','Matematica','2025-02-05','aula_3','Presente'),
('2025001','10000000003','6',2025,'Manha','Matematica','2025-02-10','aula_1','Presente'),
('2025001','10000000003','6',2025,'Manha','Matematica','2025-02-11','aula_2','Ausente');

-- Aluno 2025002 – frequência baixa (< 75%) → deve gerar WARNING
INSERT IGNORE INTO tb_frequencias
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, fk_nome_disciplina,
 data_aula, numero_aula, status)
VALUES
('2025002','10000000003','6',2025,'Manha','Matematica','2025-02-03','aula_1','Ausente'),
('2025002','10000000003','6',2025,'Manha','Matematica','2025-02-04','aula_2','Ausente'),
('2025002','10000000003','6',2025,'Manha','Matematica','2025-02-05','aula_3','Presente'),
('2025002','10000000003','6',2025,'Manha','Matematica','2025-02-10','aula_1','Ausente');



-- 15. ATESTADOS  (constraint chk_atestado_dono_unico garante exclusividade)

-- Atestado para aluno
INSERT IGNORE INTO tb_atestados
(fk_rgm_aluno, fk_cpf_funcionario, data_inicio, data_fim,
 nome_medico, sobrenome_medico, crm_medico, atestado_url, data_entrega)
VALUES
('2025002', NULL, '2025-02-04', '2025-02-04',
 'João','Silva','CRM-SP-123456',
 'https://docs.escola.com/atestados/2025002_fev.pdf','2025-02-05 09:00:00');

-- Atestado para funcionário
INSERT IGNORE INTO tb_atestados
(fk_rgm_aluno, fk_cpf_funcionario, data_inicio, data_fim,
 nome_medico, sobrenome_medico, crm_medico, atestado_url, data_entrega)
VALUES
(NULL, '10000000008', '2025-03-10', '2025-03-12',
 'Maria','Santos','CRM-SP-654321',
 'https://docs.escola.com/atestados/lucia_mar.pdf','2025-03-13 08:30:00');



-- 16. CONTRATOS ESCOLARES (trigger gerar_mensalidades criará 12 parcelas automaticamente)
INSERT IGNORE INTO tb_contrato_escolar
(fk_cpf_responsavel, fk_rgm_aluno, fk_serie, fk_ano_letivo, fk_turno,
 data_inicio, data_fim, valor_mensalidade, bolsa, status)
VALUES
('11122233344','2025001','6',  2025,'Manha','2025-01-01','2025-12-31',1200.00,'Sem_Bolsa','Ativo'),
('22233344455','2025002','6',  2025,'Manha','2025-01-01','2025-12-31',1200.00,'Bolsa_25', 'Ativo'),
('33344455566','2025003','7',  2025,'Manha','2025-01-01','2025-12-31',1200.00,'Bolsa_50', 'Ativo'),
('44455566677','2025004','8',  2025,'Tarde','2025-01-01','2025-12-31',1500.00,'Sem_Bolsa','Ativo'),
('55566677788','2025005','9',  2025,'Tarde','2025-01-01','2025-12-31',1500.00,'Sem_Bolsa','Ativo'),
('66677788899','2025006','1EM',2025,'Manha','2025-01-01','2025-12-31',1800.00,'Sem_Bolsa','Ativo'),
('77788899900','2025007','2EM',2025,'Tarde','2025-01-01','2025-12-31',1800.00,'Bolsa_25', 'Ativo'),
('88899900011','2025008','3EM',2025,'Manha','2025-01-01','2025-12-31',1800.00,'Bolsa_50', 'Ativo');



-- 17. PAGAMENTOS  (trigger atualizar_status_mensalidade marcará como 'Pago')

-- Aluno 2025001 – paga mês 1 (Janeiro – com rematrícula)
INSERT IGNORE INTO tb_pagamentos
(fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, fk_mes_referencia,
 valor_pago, forma_pagamento, data_pagamento)
VALUES
('11122233344','2025001',2025,1,1380.00,'PIX','2025-01-06 10:00:00');

-- Aluno 2025001 – paga mês 2 (Fevereiro)
INSERT IGNORE INTO tb_pagamentos
(fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, fk_mes_referencia,
 valor_pago, forma_pagamento, data_pagamento)
VALUES
('11122233344','2025001',2025,2,1200.00,'Boleto','2025-02-06 11:00:00');

-- Aluno 2025004 – paga mês 1
INSERT IGNORE INTO tb_pagamentos
(fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, fk_mes_referencia,
 valor_pago, forma_pagamento, data_pagamento)
VALUES
('44455566677','2025004',2025,1,1725.00,'Cartao_Credito','2025-01-07 09:30:00');



-- 18. RECEITAS E DESPESAS
INSERT IGNORE INTO tb_receitas
(fk_cpf_funcionario, tipo, descricao, valor, data_hora_receita, status)
VALUES
('10000000009','Mensalidade',   'Mensalidades Janeiro 2025', 38000.00,'2025-01-31 18:00:00','Pago'),
('10000000009','Mensalidade',   'Mensalidades Fevereiro 2025',37500.00,'2025-02-28 18:00:00','Pago'),
('10000000009','Matricula',     'Matrículas 2025',            5000.00,'2025-01-10 09:00:00','Pago'),
('10000000009','Rematricula',   'Rematrículas 2025',          2800.00,'2025-01-10 09:00:01','Pago'),
('10000000009','Cantina',       'Cantina Janeiro 2025',        800.00,'2025-01-31 18:00:01','Pago'),
('10000000009','Evento',        'Festa Junina 2025',          1200.00,'2025-06-15 20:00:00','Pendente');

INSERT IGNORE INTO tb_despesas
(fk_cpf_funcionario, tipo, descricao, valor, data_hora_despesa, data_vencimento, status)
VALUES
('10000000010','Luz',       'Conta de luz Janeiro',   1500.00,'2025-01-25 10:00:00','2025-01-30','Pago'),
('10000000010','Agua',      'Conta de água Janeiro',   600.00,'2025-01-25 10:01:00','2025-01-30','Pago'),
('10000000010','Internet',  'Internet Janeiro',        300.00,'2025-01-20 10:00:00','2025-01-25','Pago'),
('10000000010','Aluguel',   'Aluguel Fevereiro',     8000.00,'2025-01-31 10:00:00','2025-02-05','Pago'),
('10000000010','Limpeza',   'Material limpeza',        400.00,'2025-02-10 10:00:00','2025-02-15','Pago'),
('10000000010','Papelaria', 'Materiais didáticos',    1200.00,'2025-02-15 10:00:00','2025-02-28','Pendente');



-- 19. FÉRIAS  (vw_ferias_detalhada calcula data_fim e abono)
INSERT IGNORE INTO tb_ferias
(fk_cpf_funcionario, ano, data_inicio, status, aprovado_por)
VALUES
('10000000003', 2025, '2025-07-01', 'Agendado',  '10000000001'),
('10000000004', 2025, '2025-07-01', 'Agendado',  '10000000001'),
('10000000007', 2025, '2025-06-01', 'Em_Ferias', '10000000010'),
('10000000008', 2025, '2025-06-01', 'Concluido', '10000000010');



-- 20. FOLHA DE PAGAMENTOc(trigger calcular_folha preenche salario_base e abono_ferias automaticamente)
-- só informamos fk_cpf_funcionario, mes_referencia, ano_referencia e data_pagamento

INSERT IGNORE INTO tb_folha_pagamento
(fk_cpf_funcionario, mes_referencia, ano_referencia, salario_base, abono_ferias, data_pagamento)
VALUES
('10000000003', 1, 2025, 0, 0, '2025-01-31'),
('10000000004', 1, 2025, 0, 0, '2025-01-31'),
('10000000005', 1, 2025, 0, 0, '2025-01-31'),
('10000000006', 1, 2025, 0, 0, '2025-01-31'),
('10000000007', 1, 2025, 0, 0, '2025-01-31'),
('10000000008', 1, 2025, 0, 0, '2025-01-31'),
('10000000003', 2, 2025, 0, 0, '2025-02-28'),
('10000000004', 2, 2025, 0, 0, '2025-02-28');

-- Mês de Julho (julho=7) para João e Fernanda que têm férias agendadas a partir de 01/07
INSERT IGNORE INTO tb_folha_pagamento
(fk_cpf_funcionario, mes_referencia, ano_referencia, salario_base, abono_ferias, data_pagamento)
VALUES
('10000000003', 7, 2025, 0, 0, '2025-07-31'),
('10000000004', 7, 2025, 0, 0, '2025-07-31');



-- RE-HABILITAR CHECKS
SET FOREIGN_KEY_CHECKS = 1;


-- VALIDAÇÃO DE IDEMPOTÊNCIA – COUNT em todas as tabelas
-- Execute ANTES e APÓS a segunda execução do script para confirmar que os
-- números são idênticos (INSERT IGNORE descarta duplicatas silenciosamente).
SELECT 'tb_turmas'              AS tabela, COUNT(*) AS total FROM tb_turmas
UNION ALL
SELECT 'tb_disciplinas',                   COUNT(*) FROM tb_disciplinas
UNION ALL
SELECT 'tb_turma_disciplinas',             COUNT(*) FROM tb_turma_disciplinas
UNION ALL
SELECT 'tb_alunos',                        COUNT(*) FROM tb_alunos
UNION ALL
SELECT 'tb_responsaveis',                  COUNT(*) FROM tb_responsaveis
UNION ALL
SELECT 'tb_aluno_responsavel',             COUNT(*) FROM tb_aluno_responsavel
UNION ALL
SELECT 'tb_matriculas',                    COUNT(*) FROM tb_matriculas
UNION ALL
SELECT 'tb_funcionarios',                  COUNT(*) FROM tb_funcionarios
UNION ALL
SELECT 'tb_vinculos',                      COUNT(*) FROM tb_vinculos
UNION ALL
SELECT 'tb_formacoes',                     COUNT(*) FROM tb_formacoes
UNION ALL
SELECT 'tb_grade_horaria',                 COUNT(*) FROM tb_grade_horaria
UNION ALL
SELECT 'tb_avaliacoes',                    COUNT(*) FROM tb_avaliacoes
UNION ALL
SELECT 'tb_notas',                         COUNT(*) FROM tb_notas
UNION ALL
SELECT 'tb_frequencias',                   COUNT(*) FROM tb_frequencias
UNION ALL
SELECT 'tb_atestados',                     COUNT(*) FROM tb_atestados
UNION ALL
SELECT 'tb_contrato_escolar',              COUNT(*) FROM tb_contrato_escolar
UNION ALL
SELECT 'tb_mensalidades',                  COUNT(*) FROM tb_mensalidades
UNION ALL
SELECT 'tb_pagamentos',                    COUNT(*) FROM tb_pagamentos
UNION ALL
SELECT 'tb_receitas',                      COUNT(*) FROM tb_receitas
UNION ALL
SELECT 'tb_despesas',                      COUNT(*) FROM tb_despesas
UNION ALL
SELECT 'tb_ferias',                        COUNT(*) FROM tb_ferias
UNION ALL
SELECT 'tb_folha_pagamento',               COUNT(*) FROM tb_folha_pagamento;



-- VALIDAÇÃO 2ª CARGA – valores devem ser IDÊNTICOS ao passo 3
SELECT 'tb_turmas'               AS tabela, COUNT(*) AS registros FROM tb_turmas
UNION ALL SELECT 'tb_disciplinas',      COUNT(*) FROM tb_disciplinas
UNION ALL SELECT 'tb_alunos',           COUNT(*) FROM tb_alunos
UNION ALL SELECT 'tb_responsaveis',     COUNT(*) FROM tb_responsaveis
UNION ALL SELECT 'tb_aluno_responsavel',COUNT(*) FROM tb_aluno_responsavel
UNION ALL SELECT 'tb_matriculas',       COUNT(*) FROM tb_matriculas
UNION ALL SELECT 'tb_turma_disciplinas',COUNT(*) FROM tb_turma_disciplinas
UNION ALL SELECT 'tb_funcionarios',     COUNT(*) FROM tb_funcionarios
UNION ALL SELECT 'tb_vinculos',         COUNT(*) FROM tb_vinculos
UNION ALL SELECT 'tb_formacoes',        COUNT(*) FROM tb_formacoes
UNION ALL SELECT 'tb_grade_horaria',    COUNT(*) FROM tb_grade_horaria
UNION ALL SELECT 'tb_avaliacoes',       COUNT(*) FROM tb_avaliacoes
UNION ALL SELECT 'tb_notas',            COUNT(*) FROM tb_notas
UNION ALL SELECT 'tb_frequencias',      COUNT(*) FROM tb_frequencias
UNION ALL SELECT 'tb_atestados',        COUNT(*) FROM tb_atestados
UNION ALL SELECT 'tb_contrato_escolar', COUNT(*) FROM tb_contrato_escolar
UNION ALL SELECT 'tb_mensalidades',     COUNT(*) FROM tb_mensalidades
UNION ALL SELECT 'tb_pagamentos',       COUNT(*) FROM tb_pagamentos
UNION ALL SELECT 'tb_receitas',         COUNT(*) FROM tb_receitas
UNION ALL SELECT 'tb_despesas',         COUNT(*) FROM tb_despesas
UNION ALL SELECT 'tb_ferias',           COUNT(*) FROM tb_ferias
UNION ALL SELECT 'tb_folha_pagamento',  COUNT(*) FROM tb_folha_pagamento;

-- FIM DA SEGUNDA CARGA DE DADOS E VERIFICAÇÃO



-- PASSO 5 – OLTP: CONSULTAS SIMPLES E SUBSELECTS AVANÇADOS
-- SCRIPT: OPERAÇÕES OLTP E TRANSAÇÕES
-- Finalidade : SELECTs simples e Subselects avançados (com agregação/correlação) que cobrem os módulos Acadêmico, Financeiro e RH.


-- USE SisGESC; -- se precisar
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
    fk_cpf_funcionario    AS cpf,
    mes_referencia        AS mes,
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
-- B1. Alunos em recuperação em QUALQUER disciplina no BIM1 2025 (subquery correlacionada na cláusula WHERE)
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



-- B2. Responsável com maior valor total de mensalidades em aberto (subquery na cláusula FROM – derived table)
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



-- B3. Média geral por disciplina em 2025 (alunos com ao menos um bimestre lançado) (agregação sobre a VIEW vw_boletim_aluno)
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



-- B4. Professores que estão acima da carga horária de 20 aulas/semana (HAVING com SUM agregado)
SELECT
    g.fk_cpf_professor,
    CONCAT(f.primeiro_nome,' ',f.sobrenome) AS professor,
    SUM(g.carga_horaria_semanal)            AS total_horas_semana
FROM tb_grade_horaria g
JOIN tb_funcionarios f ON f.pk_cpf = g.fk_cpf_professor
WHERE g.data_fim IS NULL
  AND g.fk_ano_letivo = 2025
GROUP BY g.fk_cpf_professor, professor
HAVING SUM(g.carga_horaria_semanal) >= 20;



-- B5. Alunos sem nenhum pagamento registrado em 2025 (NOT EXISTS correlacionado)
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

-- Carga de Dado para demonstrar melhor o resultado do script de cima
INSERT IGNORE INTO tb_receitas
(fk_cpf_funcionario, tipo, descricao, valor, data_hora_receita, status)
VALUES
('10000000009', 'Mensalidade', 'Mensalidades Março 2025', 10000.00, '2025-03-31 18:00:00', 'Pago');



-- B7. Funcionários com salário acima da média do próprio departamento (subquery correlacionada no WHERE com agregação)
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



-- B8. Alunos com percentual de frequência abaixo de 75% em alguma disciplina (subquery com IN / derived table)
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
/*INSERT INTO tb_notas (fk_rgm,fk_cpf_professor,fk_serie,fk_ano_letivo,fk_turno,
   fk_nome_disciplina,fk_bimestre,fk_tipo,fk_titulo,nota_obtida)
 VALUES ('2025001','10000000003','6',2025,'Manha','Matematica','BIM1','Prova','Prova BIM1 Mat',11.00);
*/


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


-- Inserir uma frequência baixa para forçar o trigger disparar
INSERT INTO tb_frequencias 
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, 
 fk_nome_disciplina, data_aula, numero_aula, status)
VALUES 
('2025002','10000000003','6',2025,'Manha','Matematica','2025-05-01','aula_1','Falta');

-- Logo em seguida, sem rodar mais nada: ------------------
SHOW WARNINGS;



INSERT INTO tb_frequencias 
(fk_rgm, fk_cpf_professor, fk_serie, fk_ano_letivo, fk_turno, 
 fk_nome_disciplina, data_aula, numero_aula, status)
VALUES 
('2025002','10000000003','6',2025,'Manha','Matematica','2025-05-01','aula_1','Ausente');

-- Rodar IMEDIATAMENTE depois, sem nenhuma query no meio:
SHOW WARNINGS; 

SELECT 
    fk_rgm,
    fk_nome_disciplina,
    total_aulas,
    aulas_presentes,
    percentual_frequencia,
    situacao
FROM vw_frequencia_aluno
WHERE fk_rgm = '2025002'
  AND fk_nome_disciplina = 'Matematica';



-- PASSO 6 – OLAP / ETL: STAR SCHEMA + CARGA DIMENSIONAL + VALIDAÇÃO
-- SCRIPT: OLAP E ETL
-- Finalidade : Criar o modelo dimensional (Star Schema), executar o processo ETL e validar que os totais do OLAP batem com o OLTP.

-- USE SisGESC; 
-- Se precisar


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



-- PASSO 7 – PERFORMANCE: CRIAÇÃO DE ÍNDICES + EXPLAIN
-- Critério: colunas mais usadas em JOINs, WHEREs e ORDER BYs nas VIEWs e SELECTs do projeto.
-- procedure auxiliar (sp_drop_index) que verifica antes de apagar.


DROP PROCEDURE IF EXISTS sp_drop_index;
DELIMITER $$
CREATE PROCEDURE sp_drop_index(p_tabela VARCHAR(100), p_indice VARCHAR(100))
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = p_tabela
          AND INDEX_NAME   = p_indice
    ) THEN
        SET @sql = CONCAT('DROP INDEX ', p_indice, ' ON ', p_tabela);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;



-- MÓDULO ACADÊMICO

-- Busca de alunos por nome (buscas parciais no front-end da secretaria)
CALL sp_drop_index('tb_alunos', 'idx_alunos_nome');
CREATE INDEX idx_alunos_nome
    ON tb_alunos (primeiro_nome, sobrenome);
SHOW INDEX FROM tb_alunos;

-- Consulta de matrículas por ano letivo e status
CALL sp_drop_index('tb_matriculas', 'idx_matriculas_ano_status');
CREATE INDEX idx_matriculas_ano_status
    ON tb_matriculas (fk_ano_letivo, status);
SHOW INDEX FROM tb_matriculas;

-- Busca de notas por aluno + disciplina + bimestre (usada na vw_boletim_aluno)
CALL sp_drop_index('tb_notas', 'idx_notas_aluno_disc_bim');
CREATE INDEX idx_notas_aluno_disc_bim
    ON tb_notas (fk_rgm, fk_nome_disciplina, fk_bimestre);
SHOW INDEX FROM tb_notas;

-- Filtro de frequências por aluno e disciplina (usada na vw_frequencia_aluno)
CALL sp_drop_index('tb_frequencias', 'idx_freq_aluno_disc');
CREATE INDEX idx_freq_aluno_disc
    ON tb_frequencias (fk_rgm, fk_nome_disciplina, fk_ano_letivo);
SHOW INDEX FROM tb_frequencias;

-- Grade horária – busca por professor e ano (trigger validar_conflito_grade)
CALL sp_drop_index('tb_grade_horaria', 'idx_grade_prof_ano');
CREATE INDEX idx_grade_prof_ano
    ON tb_grade_horaria (fk_cpf_professor, fk_ano_letivo, dia_semana, numero_aula);
SHOW INDEX FROM tb_grade_horaria;


-- MÓDULO FINANCEIRO
-- Mensalidades por responsável + status (relatório de inadimplência)
CALL sp_drop_index('tb_mensalidades', 'idx_mensalidades_status');
CREATE INDEX idx_mensalidades_status
    ON tb_mensalidades (fk_cpf_responsavel, fk_ano_letivo, status);

-- Mensalidades por aluno + mês (trigger atualizar_status_mensalidade)
CALL sp_drop_index('tb_mensalidades', 'idx_mensalidades_aluno_mes');
CREATE INDEX idx_mensalidades_aluno_mes
    ON tb_mensalidades (fk_rgm_aluno, fk_ano_letivo, mes_referencia);
SHOW INDEX FROM tb_mensalidades;

-- Pagamentos por aluno + mês (lookup no trigger)
CALL sp_drop_index('tb_pagamentos', 'idx_pagamentos_aluno_mes');
CREATE INDEX idx_pagamentos_aluno_mes
    ON tb_pagamentos (fk_rgm_aluno, fk_ano_letivo, fk_mes_referencia);
SHOW INDEX FROM tb_pagamentos;

-- Receitas por data (vw_fluxo_caixa_mensal agrega por ano/mês)
CALL sp_drop_index('tb_receitas', 'idx_receitas_data');
CREATE INDEX idx_receitas_data
    ON tb_receitas (data_hora_receita, status);
SHOW INDEX FROM tb_receitas;

-- Despesas por data
CALL sp_drop_index('tb_despesas', 'idx_despesas_data');
CREATE INDEX idx_despesas_data
    ON tb_despesas (data_hora_despesa, status);
SHOW INDEX FROM tb_despesas;



-- MÓDULO RH

-- Vínculo por CPF + cargo (trigger validar_professor_disciplina)
CALL sp_drop_index('tb_vinculos', 'idx_vinculos_cargo');
CREATE INDEX idx_vinculos_cargo
    ON tb_vinculos (fk_cpf_funcionario, cargo);
SHOW INDEX FROM tb_vinculos;

-- Folha por funcionário + mês + ano (lookup no trigger calcular_folha)
CALL sp_drop_index('tb_folha_pagamento', 'idx_folha_func_mes');
CREATE INDEX idx_folha_func_mes
    ON tb_folha_pagamento (fk_cpf_funcionario, mes_referencia, ano_referencia);
SHOW INDEX FROM tb_folha_pagamento;

-- Férias por funcionário + ano (vw_ferias_detalhada e trigger calcular_folha)
CALL sp_drop_index('tb_ferias', 'idx_ferias_func_ano');
CREATE INDEX idx_ferias_func_ano
    ON tb_ferias (fk_cpf_funcionario, ano);
SHOW INDEX FROM tb_ferias;



-- MÓDULO OLAP

-- fato_desempenho: drill-down por série (dim_curso) e bimestre
CALL sp_drop_index('fato_desempenho', 'idx_fato_desemp_curso_bim');
CREATE INDEX idx_fato_desemp_curso_bim
    ON fato_desempenho (fk_curso, bimestre, ano_letivo);
SHOW INDEX FROM fato_desempenho;

-- fato_financeiro: análise mensal
CALL sp_drop_index('fato_financeiro', 'idx_fato_fin_tempo');
CREATE INDEX idx_fato_fin_tempo
    ON fato_financeiro (fk_tempo, ano_letivo, status_pagamento);
SHOW INDEX FROM fato_financeiro;


-- PARTE 3 – DEMONSTRAÇÃO DE GANHO DE PERFORMANCE (EXPLAIN)
-- Observe a coluna "key": deve mostrar o nome do índice sendo usado.
-- Observe a coluna "rows": quanto menor, mais eficiente a busca.

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
  AND status = 'Pendente';

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



-- PASSO 8 – GOVERNANÇA: CHECKLIST FINAL
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




-- ORDEM DE EXECUÇÃO RECOMENDADA PARA O DIA DA BANCA

-- 1. fase5_6_performance_governanca.sql  → PARTE 1 (reset/drop)
-- 2. fase1_estrutura.sql                 → DDL completo
-- 3. fase2_carga_dados.sql               → 1ª carga → COUNT(*) todas as tabelas
-- 4. fase2_carga_dados.sql               → 2ª carga → COUNT(*) deve ser idêntico
-- 5. fase3_oltp_consultas.sql            → SELECTs + validação de triggers
-- 6. fase4_olap_etl.sql                  → Star Schema + ETL + validação OLTP=OLAP
-- 7. fase5_6_performance_governanca.sql  → PARTES 2 e 3 (índices + EXPLAIN)
-- 8. fase5_6_performance_governanca.sql  → PARTE 4 (checklist de governança)



-- FIM DO RUN_ALL.SQL – SisGESC
-- Se todos os passos executaram sem erro: sistema pronto para a banca!

-- SELECT 'RUN_ALL.SQL CONCLUÍDO COM SUCESSO!' AS status_final;