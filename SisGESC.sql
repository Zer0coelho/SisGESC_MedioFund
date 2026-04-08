
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
  nome_completo   VARCHAR(255)  NOT NULL,
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
  nome_completo          VARCHAR(255)  NOT NULL,
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
  nome_completo VARCHAR(255)  NOT NULL,
  email         VARCHAR(255)  NOT NULL,
  status        ENUM('Ativo','Afastado','Desligado') NOT NULL DEFAULT 'Ativo',
  data_admissao DATE          NOT NULL,
  data_cadastro TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pk_cpf),
  UNIQUE KEY uq_func_email (email)
);



-- tb_vinculos registra cargo, departamento e salário de cada funcionário.
-- Um funcionário pode ter mais de um vínculo (ex.: professor e coordenador).
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



-- tb_atestados atestados médicos de alunos OU funcionários.
-- Apenas um dos dois campos (fk_rgm_aluno, fk_cpf_funcionario) será preenchido
-- por registro — o outro permanece NULL (decisão de design intencional).
CREATE TABLE tb_atestados (
  fk_rgm_aluno       VARCHAR(10)   NULL,
  fk_cpf_funcionario CHAR(11)      NULL,
  data_inicio        DATE          NOT NULL,
  data_fim           DATE          NOT NULL,
  nome_medico        VARCHAR(255)  NOT NULL,
  crm_medico         VARCHAR(20)   NOT NULL,
  atestado_url       VARCHAR(500)  NOT NULL,
  data_entrega       DATE          NOT NULL,
  data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (fk_rgm_aluno, fk_cpf_funcionario, data_inicio),
  CONSTRAINT fk_atest_aluno FOREIGN KEY (fk_rgm_aluno)
    REFERENCES tb_alunos      (pk_rgm),
  CONSTRAINT fk_atest_func  FOREIGN KEY (fk_cpf_funcionario)
    REFERENCES tb_funcionarios (pk_cpf)
);



-- tb_contrato_escolar vínculo financeiro entre responsável e aluno para um ano letivo.
-- Trigger calcular_bolsa_rematricula calcula desconto, valor_final e rematrícula.
-- Trigger cancelar_mensalidades cancela parcelas futuras quando contrato encerra.
CREATE TABLE tb_contrato_escolar (
  fk_cpf_responsavel CHAR(11)      NOT NULL,
  fk_rgm_aluno       VARCHAR(10)   NOT NULL,
  fk_serie           ENUM('6','7','8','9','1EM','2EM','3EM') NOT NULL,
  fk_ano_letivo      INT           NOT NULL,
  fk_turno           ENUM('Manha','Tarde') NOT NULL,
  data_inicio        DATE          NOT NULL,
  data_fim           DATE          NOT NULL,
  valor_mensalidade  DECIMAL(10,2) NOT NULL,
  bolsa              ENUM('Sem_Bolsa','Bolsa_25','Bolsa_50','Bolsa_75') NOT NULL DEFAULT 'Sem_Bolsa',
  valor_desconto     DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_final        DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_rematricula  DECIMAL(10,2) NOT NULL DEFAULT 0,
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



-- tb_mensalidades 12 parcelas geradas automaticamente por trigger ao criar o contrato.
-- Mensalidade de janeiro inclui rematrícula. Atraso gera multa e juros via trigger.
CREATE TABLE tb_mensalidades (
  fk_cpf_responsavel CHAR(11)      NOT NULL,
  fk_rgm_aluno       VARCHAR(10)   NOT NULL,
  fk_ano_letivo      INT           NOT NULL,
  mes_referencia     INT           NOT NULL,
  data_vencimento    DATE          NOT NULL,
  data_atraso        DATE          NULL,
  valor_mensalidade  DECIMAL(10,2) NOT NULL,
  inclui_rematricula BOOLEAN       NOT NULL DEFAULT FALSE,
  multa              DECIMAL(10,2) NOT NULL DEFAULT 0,
  juros              DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_total        DECIMAL(10,2) NOT NULL,
  status             ENUM('Pendente','Pago','Atrasado','Cancelado') NOT NULL DEFAULT 'Pendente',
  data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo, mes_referencia),
  CONSTRAINT fk_mens_contrato FOREIGN KEY (fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo)
    REFERENCES tb_contrato_escolar (fk_cpf_responsavel, fk_rgm_aluno, fk_ano_letivo)
);



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



-- tb_receitas receitas da instituição (mensalidades e outras fontes).
CREATE TABLE tb_receitas (
  fk_cpf_funcionario CHAR(11)      NOT NULL,
  tipo               ENUM('Mensalidade','Outros') NOT NULL,
  descricao          VARCHAR(255)  NOT NULL,
  valor              DECIMAL(10,2) NOT NULL,
  data_receita       DATE          NOT NULL,
  status             ENUM('Pago','Pendente','Cancelado') NOT NULL DEFAULT 'Pendente',
  data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (fk_cpf_funcionario, tipo, data_receita),
  CONSTRAINT fk_rec_func FOREIGN KEY (fk_cpf_funcionario)
    REFERENCES tb_funcionarios (pk_cpf)
);



-- tb_despesas despesas operacionais da instituição (luz, água, aluguel, etc.).
CREATE TABLE tb_despesas (
  fk_cpf_funcionario CHAR(11)      NOT NULL,
  tipo               ENUM('Luz','Agua','Internet','Aluguel','Reforma','Fornecedor_Geral','Outros') NOT NULL,
  descricao          VARCHAR(255)  NOT NULL,
  valor              DECIMAL(10,2) NOT NULL,
  data_despesa       DATE          NOT NULL,
  data_vencimento    DATE          NOT NULL,
  status             ENUM('Pago','Pendente','Cancelado') NOT NULL DEFAULT 'Pendente',
  data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (fk_cpf_funcionario, tipo, data_despesa),
  CONSTRAINT fk_desp_func FOREIGN KEY (fk_cpf_funcionario)
    REFERENCES tb_funcionarios (pk_cpf)
);



-- tb_ferias períodos de férias dos funcionários.
-- Trigger calcular_abono_ferias calcula abono (1/3 salário), data_fim e data_retorno.
CREATE TABLE tb_ferias (
  fk_cpf_funcionario CHAR(11)      NOT NULL,
  ano                INT           NOT NULL,
  data_inicio        DATE          NOT NULL,
  data_fim           DATE          NOT NULL,
  data_retorno       DATE          NOT NULL,
  abono_ferias       DECIMAL(10,2) NOT NULL DEFAULT 0,
  status             ENUM('Agendado','Em_Ferias','Concluido','Cancelado') NOT NULL DEFAULT 'Agendado',
  aprovado_por       CHAR(11)      NOT NULL,
  data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (fk_cpf_funcionario, ano),
  CONSTRAINT fk_fer_func     FOREIGN KEY (fk_cpf_funcionario)
    REFERENCES tb_funcionarios (pk_cpf),
  CONSTRAINT fk_fer_aprovado FOREIGN KEY (aprovado_por)
    REFERENCES tb_funcionarios (pk_cpf)
);



-- tb_folha_pagamento folha mensal de pagamento dos funcionários.
-- Trigger calcular_folha calcula automaticamente INSS, IRRF, benefícios e salário líquido.
CREATE TABLE tb_folha_pagamento (
  fk_cpf_funcionario CHAR(11)      NOT NULL,
  mes_referencia     INT           NOT NULL,
  ano_referencia     INT           NOT NULL,
  salario_base       DECIMAL(10,2) NOT NULL,
  abono_ferias       DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_proventos    DECIMAL(10,2) NOT NULL DEFAULT 0,
  inss               DECIMAL(10,2) NOT NULL DEFAULT 0,
  irrf               DECIMAL(10,2) NOT NULL DEFAULT 0,
  vale_transporte    DECIMAL(10,2) NOT NULL DEFAULT 0,
  vale_refeicao      DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_descontos    DECIMAL(10,2) NOT NULL DEFAULT 0,
  salario_liquido    DECIMAL(10,2) NOT NULL DEFAULT 0,
  data_pagamento     DATE          NOT NULL,
  data_cadastro      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (fk_cpf_funcionario, mes_referencia, ano_referencia),
  CONSTRAINT fk_folha_func FOREIGN KEY (fk_cpf_funcionario)
    REFERENCES tb_funcionarios (pk_cpf)
);



-- TRIGGERS

DELIMITER $$ -- O separador de comandos vai mudar temporariamente de ; para $$, para poder fazer todos os TRIGGERs


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



-- verificar_frequencia após registrar frequência, calcula o percentual do aluno na disciplina.
-- Emite alerta se cair abaixo de 75% (Presente + Atestado contam como presença).
CREATE TRIGGER verificar_frequencia
AFTER INSERT ON tb_frequencias
FOR EACH ROW
BEGIN
  DECLARE percentual DECIMAL(5,2);

  SELECT
    (SUM(CASE WHEN status IN ('Presente','Atestado') THEN 1 ELSE 0 END) / COUNT(*)) * 100
  INTO percentual
  FROM tb_frequencias
  WHERE fk_rgm             = NEW.fk_rgm
    AND fk_nome_disciplina = NEW.fk_nome_disciplina
    AND fk_serie           = NEW.fk_serie
    AND fk_ano_letivo      = NEW.fk_ano_letivo
    AND fk_turno           = NEW.fk_turno;

  IF percentual < 75 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Atencao: Aluno abaixo de 75% de frequencia nesta disciplina!';
  END IF;
END$$



-- calcular_bolsa_rematricula calcula automaticamente valor_desconto, valor_final e valor_rematricula
-- com base no tipo de bolsa informado no contrato.
CREATE TRIGGER calcular_bolsa_rematricula
BEFORE INSERT ON tb_contrato_escolar
FOR EACH ROW
BEGIN
  IF NEW.bolsa = 'Bolsa_25' THEN
    SET NEW.valor_desconto = NEW.valor_mensalidade * 0.25;
  ELSEIF NEW.bolsa = 'Bolsa_50' THEN
    SET NEW.valor_desconto = NEW.valor_mensalidade * 0.50;
  ELSEIF NEW.bolsa = 'Bolsa_75' THEN
    SET NEW.valor_desconto = NEW.valor_mensalidade * 0.75;
  ELSE
    SET NEW.valor_desconto = 0;
  END IF;

  SET NEW.valor_final       = NEW.valor_mensalidade - NEW.valor_desconto;
  SET NEW.valor_rematricula = NEW.valor_final * 0.15;
END$$



-- gerar_mensalidades gera automaticamente as 12 mensalidades após criar um contrato escolar.
-- Janeiro inclui rematrícula. Vencimento = dia 06 do mês seguinte.
CREATE TRIGGER gerar_mensalidades
AFTER INSERT ON tb_contrato_escolar
FOR EACH ROW
BEGIN
  DECLARE mes       INT DEFAULT 1;
  DECLARE valor_mes DECIMAL(10,2);

  WHILE mes <= 12 DO
    IF mes = 1 THEN
      SET valor_mes = NEW.valor_final + NEW.valor_rematricula;
    ELSE
      SET valor_mes = NEW.valor_final;
    END IF;

    INSERT INTO tb_mensalidades (
      fk_cpf_responsavel,
      fk_rgm_aluno,
      fk_ano_letivo,
      mes_referencia,
      data_vencimento,
      valor_mensalidade,
      inclui_rematricula,
      multa,
      juros,
      valor_total,
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
      NEW.valor_final,
      IF(mes = 1, TRUE, FALSE),
      0,
      0,
      valor_mes,
      'Pendente'
    );

    SET mes = mes + 1;
  END WHILE;
END$$



-- calcular_multa_juros calcula multa (2%) e juros (0,033%/dia) quando mensalidade muda para Atrasado.
CREATE TRIGGER calcular_multa_juros
BEFORE UPDATE ON tb_mensalidades
FOR EACH ROW
BEGIN
  DECLARE dias_atraso INT;

  IF NEW.status = 'Atrasado' AND OLD.status = 'Pendente' THEN
    SET dias_atraso    = DATEDIFF(CURDATE(), NEW.data_vencimento);
    SET NEW.data_atraso = CURDATE();
    SET NEW.multa       = NEW.valor_total * 0.02;
    SET NEW.juros       = NEW.valor_total * (0.00033 * dias_atraso);
    SET NEW.valor_total = NEW.valor_total + NEW.multa + NEW.juros;
  END IF;
END$$



-- cancelar_mensalidades cancela mensalidades futuras (status=Pendente) quando o contrato é encerrado.
CREATE TRIGGER cancelar_mensalidades
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



-- atualizar_status_mensalidade marca mensalidade como Pago quando o valor pago é >= valor_total devido.
CREATE TRIGGER atualizar_status_mensalidade
AFTER INSERT ON tb_pagamentos
FOR EACH ROW
BEGIN
  DECLARE valor_devido DECIMAL(10,2);

  SELECT valor_total INTO valor_devido
  FROM tb_mensalidades
  WHERE fk_cpf_responsavel = NEW.fk_cpf_responsavel
    AND fk_rgm_aluno       = NEW.fk_rgm_aluno
    AND fk_ano_letivo      = NEW.fk_ano_letivo
    AND mes_referencia     = NEW.fk_mes_referencia;

  IF NEW.valor_pago >= valor_devido THEN
    UPDATE tb_mensalidades
    SET status = 'Pago'
    WHERE fk_cpf_responsavel = NEW.fk_cpf_responsavel
      AND fk_rgm_aluno       = NEW.fk_rgm_aluno
      AND fk_ano_letivo      = NEW.fk_ano_letivo
      AND mes_referencia     = NEW.fk_mes_referencia;
  END IF;
END$$



-- calcular_abono_ferias calcula abono (1/3 do salário), data_fim e data_retorno no INSERT de férias.
CREATE TRIGGER calcular_abono_ferias
BEFORE INSERT ON tb_ferias
FOR EACH ROW
BEGIN
  DECLARE salario DECIMAL(10,2);

  SELECT salario_base INTO salario
  FROM tb_vinculos
  WHERE fk_cpf_funcionario = NEW.fk_cpf_funcionario
  LIMIT 1;

  SET NEW.abono_ferias  = salario / 3;
  SET NEW.data_fim      = DATE_ADD(NEW.data_inicio, INTERVAL 29 DAY);
  SET NEW.data_retorno  = DATE_ADD(NEW.data_inicio, INTERVAL 30 DAY);
END$$



-- calcular_folha calcula automaticamente INSS progressivo, IRRF progressivo, vale transporte,
-- vale refeição, abono de férias (se aplicável), total de proventos,
-- total de descontos e salário líquido.
CREATE TRIGGER calcular_folha
BEFORE INSERT ON tb_folha_pagamento
FOR EACH ROW
BEGIN
  DECLARE salario    DECIMAL(10,2);
  DECLARE base_irrf  DECIMAL(10,2);
  DECLARE dias_uteis INT DEFAULT 22;

  SELECT salario_base INTO salario
  FROM tb_vinculos
  WHERE fk_cpf_funcionario = NEW.fk_cpf_funcionario
  LIMIT 1;

  SET NEW.salario_base = salario;

  -- INSS progressivo
  IF salario <= 1518.00 THEN
    SET NEW.inss = salario * 0.075;
  ELSEIF salario <= 2793.88 THEN
    SET NEW.inss = salario * 0.09;
  ELSEIF salario <= 4190.83 THEN
    SET NEW.inss = salario * 0.12;
  ELSEIF salario <= 8157.41 THEN
    SET NEW.inss = salario * 0.14;
  ELSE
    SET NEW.inss = 8157.41 * 0.14;
  END IF;

  -- IRRF progressivo (base = salário - INSS)
  SET base_irrf = salario - NEW.inss;

  IF base_irrf <= 2259.20 THEN
    SET NEW.irrf = 0;
  ELSEIF base_irrf <= 2826.65 THEN
    SET NEW.irrf = (base_irrf * 0.075) - 169.44;
  ELSEIF base_irrf <= 3751.05 THEN
    SET NEW.irrf = (base_irrf * 0.15)  - 381.44;
  ELSEIF base_irrf <= 4664.68 THEN
    SET NEW.irrf = (base_irrf * 0.225) - 662.77;
  ELSE
    SET NEW.irrf = (base_irrf * 0.275) - 896.00;
  END IF;

  SET NEW.vale_transporte = salario * 0.06;
  SET NEW.vale_refeicao   = 25.00 * dias_uteis;

  -- Abono de férias se o mês de referência tiver férias agendadas
  IF EXISTS (
    SELECT 1 FROM tb_ferias
    WHERE fk_cpf_funcionario = NEW.fk_cpf_funcionario
      AND ano                = NEW.ano_referencia
      AND MONTH(data_inicio) = NEW.mes_referencia
  ) THEN
    SELECT abono_ferias INTO NEW.abono_ferias
    FROM tb_ferias
    WHERE fk_cpf_funcionario = NEW.fk_cpf_funcionario
      AND ano                = NEW.ano_referencia;
  ELSE
    SET NEW.abono_ferias = 0;
  END IF;

  SET NEW.total_proventos = NEW.salario_base + NEW.abono_ferias;
  SET NEW.total_descontos = NEW.inss + NEW.irrf + NEW.vale_transporte + NEW.vale_refeicao;
  SET NEW.salario_liquido = NEW.total_proventos - NEW.total_descontos;
END$$

DELIMITER ; -- O separador de comandos volta ;
