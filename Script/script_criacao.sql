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
    SUM(vm.valor_total)         AS valor_total_com_encargos -- inclui multa + juros da vw_mensalidades
FROM tb_mensalidades m
JOIN vw_mensalidades vm
    ON  vm.fk_cpf_responsavel = m.fk_cpf_responsavel
    AND vm.fk_rgm_aluno       = m.fk_rgm_aluno
    AND vm.fk_ano_letivo      = m.fk_ano_letivo
    AND vm.mes_referencia     = m.mes_referencia
WHERE m.status = 'Atrasado'
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

