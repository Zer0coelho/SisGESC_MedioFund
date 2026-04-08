CREATE TABLE `tb_alunos` (
  `pk_rgm` varchar(10) PRIMARY KEY,
  `nome_completo` varchar(255) NOT NULL,
  `sexo` ENUM ('Masculino', 'Feminino', 'Intersexo', 'Nao_Informado') NOT NULL,
  `cpf` char(11) UNIQUE NOT NULL,
  `data_nascimento` date NOT NULL,
  `email` varchar(255) UNIQUE NOT NULL,
  `rua` varchar(150) NOT NULL,
  `numero` varchar(10) NOT NULL,
  `complemento` varchar(50),
  `bairro` varchar(80) NOT NULL,
  `cidade` varchar(80) NOT NULL,
  `estado` char(2) NOT NULL,
  `cep` char(8) NOT NULL,
  `data_cadastro` timestamp NOT NULL DEFAULT 'now()'
);

CREATE TABLE `tb_responsaveis` (
  `pk_cpf` char(11) PRIMARY KEY,
  `nome_completo` varchar(255) NOT NULL,
  `email` varchar(255) UNIQUE NOT NULL,
  `telefone` varchar(15) NOT NULL,
  `parentesco` ENUM ('Pai', 'Mãe', 'Avo', 'Avoa', 'Tio', 'Tia', 'Tutor_Legal', 'Outro') NOT NULL,
  `responsavel_financeiro` boolean NOT NULL DEFAULT false
);

CREATE TABLE `tb_aluno_responsavel` (
  `fk_rgm` varchar(10) NOT NULL,
  `fk_cpf` char(11) NOT NULL,
  PRIMARY KEY (`fk_rgm`, `fk_cpf`)
);

CREATE TABLE `tb_turmas` (
  `serie` ENUM ('6', '7', '8', '9', '1EM', '2EM', '3EM') NOT NULL,
  `ano_letivo` int NOT NULL,
  `turno` ENUM ('Manha', 'Tarde') NOT NULL,
  PRIMARY KEY (`serie`, `ano_letivo`, `turno`)
);

CREATE TABLE `tb_disciplinas` (
  `pk_nome_disciplina` varchar(100) PRIMARY KEY,
  `nivel` ENUM ('Fundamental', 'Medio', 'Ambos') NOT NULL
);

CREATE TABLE `tb_turma_disciplinas` (
  `fk_serie` ENUM ('6', '7', '8', '9', '1EM', '2EM', '3EM') NOT NULL,
  `fk_ano_letivo` int NOT NULL,
  `fk_turno` ENUM ('Manha', 'Tarde') NOT NULL,
  `fk_nome_disciplina` varchar(100) NOT NULL,
  PRIMARY KEY (`fk_serie`, `fk_ano_letivo`, `fk_turno`, `fk_nome_disciplina`)
);

CREATE TABLE `tb_matriculas` (
  `fk_rgm` varchar(10) NOT NULL,
  `fk_serie` ENUM ('6', '7', '8', '9', '1EM', '2EM', '3EM') NOT NULL,
  `fk_ano_letivo` int NOT NULL,
  `fk_turno` ENUM ('Manha', 'Tarde') NOT NULL,
  `data_matricula` date NOT NULL,
  `status` ENUM ('Ativo', 'Trancado', 'Cancelado', 'Concluido') NOT NULL DEFAULT 'Ativo',
  `data_cadastro` timestamp NOT NULL DEFAULT 'now()',
  PRIMARY KEY (`fk_rgm`, `fk_serie`, `fk_ano_letivo`, `fk_turno`)
);

CREATE TABLE `tb_funcionarios` (
  `pk_cpf` char(11) PRIMARY KEY,
  `nome_completo` varchar(255) NOT NULL,
  `email` varchar(255) UNIQUE NOT NULL,
  `status` ENUM ('Ativo', 'Afastado', 'Desligado') NOT NULL DEFAULT 'Ativo',
  `data_admissao` date NOT NULL,
  `data_cadastro` timestamp NOT NULL DEFAULT 'now()'
);

CREATE TABLE `tb_vinculos` (
  `fk_cpf_funcionario` char(11) NOT NULL,
  `cargo` ENUM ('Diretor', 'Coordenador', 'Professor', 'Secretario', 'Bibliotecario', 'Inspetor', 'Porteiro', 'Aux_Limpeza', 'Aux_Cantina', 'Administrador', 'Contador') NOT NULL,
  `departamento` ENUM ('Pedagogico', 'Administrativo', 'Operacional', 'Financeiro') NOT NULL,
  `salario_base` decimal(10,2) NOT NULL,
  PRIMARY KEY (`fk_cpf_funcionario`, `cargo`, `departamento`)
);

CREATE TABLE `tb_formacoes` (
  `fk_cpf_funcionario` char(11) NOT NULL,
  `curso` varchar(255) NOT NULL,
  `instituicao` varchar(255) NOT NULL,
  `ano_conclusao` int NOT NULL,
  `diploma_url` varchar(500) NOT NULL,
  PRIMARY KEY (`fk_cpf_funcionario`, `curso`)
);

CREATE TABLE `tb_avaliacoes` (
  `fk_cpf_professor` char(11) NOT NULL,
  `fk_serie` ENUM ('6', '7', '8', '9', '1EM', '2EM', '3EM') NOT NULL,
  `fk_ano_letivo` int NOT NULL,
  `fk_turno` ENUM ('Manha', 'Tarde') NOT NULL,
  `fk_nome_disciplina` varchar(100) NOT NULL,
  `titulo` varchar(255) NOT NULL,
  `tipo` ENUM ('Prova', 'Trabalho', 'Seminario', 'Simulado', 'Recuperacao') NOT NULL,
  `bimestre` ENUM ('BIM1', 'BIM2', 'BIM3', 'BIM4') NOT NULL,
  `valor_maximo` decimal(4,2) NOT NULL,
  `data_inicio` timestamp NOT NULL,
  `data_fim` timestamp NOT NULL,
  PRIMARY KEY (`fk_cpf_professor`, `fk_serie`, `fk_ano_letivo`, `fk_turno`, `fk_nome_disciplina`, `bimestre`, `tipo`, `titulo`)
);

CREATE TABLE `tb_notas` (
  `fk_rgm` varchar(10) NOT NULL,
  `fk_cpf_professor` char(11) NOT NULL,
  `fk_serie` ENUM ('6', '7', '8', '9', '1EM', '2EM', '3EM') NOT NULL,
  `fk_ano_letivo` int NOT NULL,
  `fk_turno` ENUM ('Manha', 'Tarde') NOT NULL,
  `fk_nome_disciplina` varchar(100) NOT NULL,
  `fk_bimestre` ENUM ('BIM1', 'BIM2', 'BIM3', 'BIM4') NOT NULL,
  `fk_tipo` ENUM ('Prova', 'Trabalho', 'Seminario', 'Simulado', 'Recuperacao') NOT NULL,
  `fk_titulo` varchar(255) NOT NULL,
  `nota_obtida` decimal(4,2) NOT NULL,
  `status` ENUM ('Aprovado', 'Recuperacao', 'Reprovado') NOT NULL DEFAULT 'Aprovado',
  PRIMARY KEY (`fk_rgm`, `fk_cpf_professor`, `fk_serie`, `fk_ano_letivo`, `fk_turno`, `fk_nome_disciplina`, `fk_bimestre`, `fk_tipo`, `fk_titulo`)
);

CREATE TABLE `tb_grade_horaria` (
  `fk_cpf_professor` char(11) NOT NULL,
  `fk_serie` ENUM ('6', '7', '8', '9', '1EM', '2EM', '3EM') NOT NULL,
  `fk_ano_letivo` int NOT NULL,
  `fk_turno` ENUM ('Manha', 'Tarde') NOT NULL,
  `fk_nome_disciplina` varchar(100) NOT NULL,
  `dia_semana` ENUM ('Segunda', 'Terca', 'Quarta', 'Quinta', 'Sexta') NOT NULL,
  `numero_aula` ENUM ('aula_1', 'aula_2', 'aula_3', 'aula_4', 'aula_5', 'aula_6') NOT NULL,
  `data_inicio` date NOT NULL,
  `data_fim` date,
  `carga_horaria_semanal` int NOT NULL,
  PRIMARY KEY (`fk_cpf_professor`, `fk_serie`, `fk_ano_letivo`, `fk_turno`, `fk_nome_disciplina`, `dia_semana`, `numero_aula`)
);

CREATE TABLE `tb_frequencias` (
  `fk_rgm` varchar(10) NOT NULL,
  `fk_cpf_professor` char(11) NOT NULL,
  `fk_serie` ENUM ('6', '7', '8', '9', '1EM', '2EM', '3EM') NOT NULL,
  `fk_ano_letivo` int NOT NULL,
  `fk_turno` ENUM ('Manha', 'Tarde') NOT NULL,
  `fk_nome_disciplina` varchar(100) NOT NULL,
  `data_aula` date NOT NULL,
  `numero_aula` ENUM ('aula_1', 'aula_2', 'aula_3', 'aula_4', 'aula_5', 'aula_6') NOT NULL,
  `status` ENUM ('Presente', 'Ausente', 'Atestado') NOT NULL,
  PRIMARY KEY (`fk_rgm`, `fk_cpf_professor`, `fk_serie`, `fk_ano_letivo`, `fk_turno`, `fk_nome_disciplina`, `data_aula`, `numero_aula`)
);

CREATE TABLE `tb_atestados` (
  `fk_rgm_aluno` varchar(10),
  `fk_cpf_funcionario` char(11),
  `data_inicio` date NOT NULL,
  `data_fim` date NOT NULL,
  `nome_medico` varchar(255) NOT NULL,
  `crm_medico` varchar(20) NOT NULL,
  `atestado_url` varchar(500) NOT NULL,
  `data_entrega` date NOT NULL,
  `data_cadastro` timestamp NOT NULL DEFAULT 'now()',
  PRIMARY KEY (`fk_rgm_aluno`, `fk_cpf_funcionario`, `data_inicio`)
);

CREATE TABLE `tb_contrato_escolar` (
  `fk_cpf_responsavel` char(11) NOT NULL,
  `fk_rgm_aluno` varchar(10) NOT NULL,
  `fk_serie` ENUM ('6', '7', '8', '9', '1EM', '2EM', '3EM') NOT NULL,
  `fk_ano_letivo` int NOT NULL,
  `fk_turno` ENUM ('Manha', 'Tarde') NOT NULL,
  `data_inicio` date NOT NULL,
  `data_fim` date NOT NULL,
  `valor_mensalidade` decimal(10,2) NOT NULL,
  `bolsa` ENUM ('Sem_Bolsa', 'Bolsa_25', 'Bolsa_50', 'Bolsa_75') NOT NULL DEFAULT 'Sem_Bolsa',
  `valor_desconto` decimal(10,2) NOT NULL DEFAULT 0,
  `valor_final` decimal(10,2) NOT NULL,
  `valor_rematricula` decimal(10,2) NOT NULL,
  `status` ENUM ('Ativo', 'Cancelado', 'Concluido', 'Transferido') NOT NULL DEFAULT 'Ativo',
  `data_cadastro` timestamp NOT NULL DEFAULT 'now()',
  PRIMARY KEY (`fk_cpf_responsavel`, `fk_rgm_aluno`, `fk_ano_letivo`)
);

CREATE TABLE `tb_mensalidades` (
  `fk_cpf_responsavel` char(11) NOT NULL,
  `fk_rgm_aluno` varchar(10) NOT NULL,
  `fk_ano_letivo` int NOT NULL,
  `mes_referencia` int NOT NULL,
  `data_vencimento` date NOT NULL,
  `data_atraso` date,
  `valor_mensalidade` decimal(10,2) NOT NULL,
  `inclui_rematricula` boolean NOT NULL DEFAULT false,
  `multa` decimal(10,2) NOT NULL DEFAULT 0,
  `juros` decimal(10,2) NOT NULL DEFAULT 0,
  `valor_total` decimal(10,2) NOT NULL,
  `status` ENUM ('Pendente', 'Pago', 'Atrasado', 'Cancelado') NOT NULL DEFAULT 'Pendente',
  `data_cadastro` timestamp NOT NULL DEFAULT 'now()',
  PRIMARY KEY (`fk_cpf_responsavel`, `fk_rgm_aluno`, `fk_ano_letivo`, `mes_referencia`)
);

CREATE TABLE `tb_pagamentos` (
  `fk_cpf_responsavel` char(11) NOT NULL,
  `fk_rgm_aluno` varchar(10) NOT NULL,
  `fk_ano_letivo` int NOT NULL,
  `fk_mes_referencia` int NOT NULL,
  `valor_pago` decimal(10,2) NOT NULL,
  `forma_pagamento` ENUM ('Boleto', 'PIX', 'Cartao_Debito', 'Cartao_Credito', 'Dinheiro') NOT NULL,
  `data_pagamento` timestamp NOT NULL DEFAULT 'now()',
  PRIMARY KEY (`fk_cpf_responsavel`, `fk_rgm_aluno`, `fk_ano_letivo`, `fk_mes_referencia`)
);

CREATE TABLE `tb_ferias` (
  `fk_cpf_funcionario` char(11) NOT NULL,
  `ano` int NOT NULL,
  `data_inicio` date NOT NULL,
  `data_fim` date NOT NULL,
  `data_retorno` date NOT NULL,
  `abono_ferias` decimal(10,2) NOT NULL,
  `status` ENUM ('Agendado', 'Em_Ferias', 'Concluido', 'Cancelado') NOT NULL DEFAULT 'Agendado',
  `aprovado_por` char(11) NOT NULL,
  `data_cadastro` timestamp NOT NULL DEFAULT 'now()',
  PRIMARY KEY (`fk_cpf_funcionario`, `ano`)
);

CREATE TABLE `tb_folha_pagamento` (
  `fk_cpf_funcionario` char(11) NOT NULL,
  `mes_referencia` int NOT NULL,
  `ano_referencia` int NOT NULL,
  `salario_base` decimal(10,2) NOT NULL,
  `abono_ferias` decimal(10,2) NOT NULL DEFAULT 0,
  `total_proventos` decimal(10,2) NOT NULL,
  `inss` decimal(10,2) NOT NULL DEFAULT 0,
  `irrf` decimal(10,2) NOT NULL DEFAULT 0,
  `vale_transporte` decimal(10,2) NOT NULL DEFAULT 0,
  `vale_refeicao` decimal(10,2) NOT NULL DEFAULT 0,
  `total_descontos` decimal(10,2) NOT NULL,
  `salario_liquido` decimal(10,2) NOT NULL,
  `data_pagamento` date NOT NULL,
  `data_cadastro` timestamp NOT NULL DEFAULT 'now()',
  PRIMARY KEY (`fk_cpf_funcionario`, `mes_referencia`, `ano_referencia`)
);

CREATE TABLE `tb_receitas` (
  `fk_cpf_funcionario` char(11) NOT NULL,
  `tipo` ENUM ('Mensalidade', 'Outros') NOT NULL,
  `descricao` varchar(255) NOT NULL,
  `valor` decimal(10,2) NOT NULL,
  `data_receita` date NOT NULL,
  `status` ENUM ('Pago', 'Pendente', 'Cancelado') NOT NULL DEFAULT 'Pendente',
  `data_cadastro` timestamp NOT NULL DEFAULT 'now()',
  PRIMARY KEY (`fk_cpf_funcionario`, `tipo`, `data_receita`)
);

CREATE TABLE `tb_despesas` (
  `fk_cpf_funcionario` char(11) NOT NULL,
  `tipo` ENUM ('Luz', 'Agua', 'Internet', 'Aluguel', 'Reforma', 'Fornecedor_Geral', 'Outros') NOT NULL,
  `descricao` varchar(255) NOT NULL,
  `valor` decimal(10,2) NOT NULL,
  `data_despesa` date NOT NULL,
  `data_vencimento` date NOT NULL,
  `status` ENUM ('Pago', 'Pendente', 'Cancelado') NOT NULL DEFAULT 'Pendente',
  `data_cadastro` timestamp NOT NULL DEFAULT 'now()',
  PRIMARY KEY (`fk_cpf_funcionario`, `tipo`, `data_despesa`)
);

ALTER TABLE `tb_avaliacoes` COMMENT = 'CHECK (valor_maximo BETWEEN 0 AND 10)';

ALTER TABLE `tb_notas` COMMENT = 'CHECK: nota_obtida >= 0';

ALTER TABLE `tb_aluno_responsavel` ADD FOREIGN KEY (`fk_rgm`) REFERENCES `tb_alunos` (`pk_rgm`);

ALTER TABLE `tb_aluno_responsavel` ADD FOREIGN KEY (`fk_cpf`) REFERENCES `tb_responsaveis` (`pk_cpf`);

ALTER TABLE `tb_turma_disciplinas` ADD FOREIGN KEY (`fk_serie`) REFERENCES `tb_turmas` (`serie`);

ALTER TABLE `tb_turma_disciplinas` ADD FOREIGN KEY (`fk_ano_letivo`) REFERENCES `tb_turmas` (`ano_letivo`);

ALTER TABLE `tb_turma_disciplinas` ADD FOREIGN KEY (`fk_turno`) REFERENCES `tb_turmas` (`turno`);

ALTER TABLE `tb_turma_disciplinas` ADD FOREIGN KEY (`fk_nome_disciplina`) REFERENCES `tb_disciplinas` (`pk_nome_disciplina`);

ALTER TABLE `tb_matriculas` ADD FOREIGN KEY (`fk_rgm`) REFERENCES `tb_alunos` (`pk_rgm`);

ALTER TABLE `tb_matriculas` ADD FOREIGN KEY (`fk_serie`) REFERENCES `tb_turmas` (`serie`);

ALTER TABLE `tb_matriculas` ADD FOREIGN KEY (`fk_ano_letivo`) REFERENCES `tb_turmas` (`ano_letivo`);

ALTER TABLE `tb_matriculas` ADD FOREIGN KEY (`fk_turno`) REFERENCES `tb_turmas` (`turno`);

ALTER TABLE `tb_vinculos` ADD FOREIGN KEY (`fk_cpf_funcionario`) REFERENCES `tb_funcionarios` (`pk_cpf`);

ALTER TABLE `tb_formacoes` ADD FOREIGN KEY (`fk_cpf_funcionario`) REFERENCES `tb_funcionarios` (`pk_cpf`);

ALTER TABLE `tb_avaliacoes` ADD FOREIGN KEY (`fk_cpf_professor`) REFERENCES `tb_funcionarios` (`pk_cpf`);

ALTER TABLE `tb_avaliacoes` ADD FOREIGN KEY (`fk_serie`) REFERENCES `tb_turmas` (`serie`);

ALTER TABLE `tb_avaliacoes` ADD FOREIGN KEY (`fk_ano_letivo`) REFERENCES `tb_turmas` (`ano_letivo`);

ALTER TABLE `tb_avaliacoes` ADD FOREIGN KEY (`fk_turno`) REFERENCES `tb_turmas` (`turno`);

ALTER TABLE `tb_avaliacoes` ADD FOREIGN KEY (`fk_nome_disciplina`) REFERENCES `tb_disciplinas` (`pk_nome_disciplina`);

ALTER TABLE `tb_notas` ADD FOREIGN KEY (`fk_rgm`) REFERENCES `tb_alunos` (`pk_rgm`);

ALTER TABLE `tb_notas` ADD FOREIGN KEY (`fk_cpf_professor`) REFERENCES `tb_avaliacoes` (`fk_cpf_professor`);

ALTER TABLE `tb_notas` ADD FOREIGN KEY (`fk_serie`) REFERENCES `tb_avaliacoes` (`fk_serie`);

ALTER TABLE `tb_notas` ADD FOREIGN KEY (`fk_ano_letivo`) REFERENCES `tb_avaliacoes` (`fk_ano_letivo`);

ALTER TABLE `tb_notas` ADD FOREIGN KEY (`fk_turno`) REFERENCES `tb_avaliacoes` (`fk_turno`);

ALTER TABLE `tb_notas` ADD FOREIGN KEY (`fk_nome_disciplina`) REFERENCES `tb_avaliacoes` (`fk_nome_disciplina`);

ALTER TABLE `tb_notas` ADD FOREIGN KEY (`fk_bimestre`) REFERENCES `tb_avaliacoes` (`bimestre`);

ALTER TABLE `tb_notas` ADD FOREIGN KEY (`fk_tipo`) REFERENCES `tb_avaliacoes` (`tipo`);

ALTER TABLE `tb_notas` ADD FOREIGN KEY (`fk_titulo`) REFERENCES `tb_avaliacoes` (`titulo`);

ALTER TABLE `tb_grade_horaria` ADD FOREIGN KEY (`fk_cpf_professor`) REFERENCES `tb_funcionarios` (`pk_cpf`);

ALTER TABLE `tb_grade_horaria` ADD FOREIGN KEY (`fk_serie`) REFERENCES `tb_turmas` (`serie`);

ALTER TABLE `tb_grade_horaria` ADD FOREIGN KEY (`fk_ano_letivo`) REFERENCES `tb_turmas` (`ano_letivo`);

ALTER TABLE `tb_grade_horaria` ADD FOREIGN KEY (`fk_turno`) REFERENCES `tb_turmas` (`turno`);

ALTER TABLE `tb_grade_horaria` ADD FOREIGN KEY (`fk_nome_disciplina`) REFERENCES `tb_disciplinas` (`pk_nome_disciplina`);

ALTER TABLE `tb_frequencias` ADD FOREIGN KEY (`fk_rgm`) REFERENCES `tb_alunos` (`pk_rgm`);

ALTER TABLE `tb_frequencias` ADD FOREIGN KEY (`fk_cpf_professor`) REFERENCES `tb_funcionarios` (`pk_cpf`);

ALTER TABLE `tb_frequencias` ADD FOREIGN KEY (`fk_serie`) REFERENCES `tb_turmas` (`serie`);

ALTER TABLE `tb_frequencias` ADD FOREIGN KEY (`fk_ano_letivo`) REFERENCES `tb_turmas` (`ano_letivo`);

ALTER TABLE `tb_frequencias` ADD FOREIGN KEY (`fk_turno`) REFERENCES `tb_turmas` (`turno`);

ALTER TABLE `tb_frequencias` ADD FOREIGN KEY (`fk_nome_disciplina`) REFERENCES `tb_disciplinas` (`pk_nome_disciplina`);

ALTER TABLE `tb_atestados` ADD FOREIGN KEY (`fk_rgm_aluno`) REFERENCES `tb_alunos` (`pk_rgm`);

ALTER TABLE `tb_atestados` ADD FOREIGN KEY (`fk_cpf_funcionario`) REFERENCES `tb_funcionarios` (`pk_cpf`);

ALTER TABLE `tb_contrato_escolar` ADD FOREIGN KEY (`fk_cpf_responsavel`) REFERENCES `tb_responsaveis` (`pk_cpf`);

ALTER TABLE `tb_contrato_escolar` ADD FOREIGN KEY (`fk_rgm_aluno`) REFERENCES `tb_alunos` (`pk_rgm`);

ALTER TABLE `tb_contrato_escolar` ADD FOREIGN KEY (`fk_serie`) REFERENCES `tb_turmas` (`serie`);

ALTER TABLE `tb_contrato_escolar` ADD FOREIGN KEY (`fk_ano_letivo`) REFERENCES `tb_turmas` (`ano_letivo`);

ALTER TABLE `tb_contrato_escolar` ADD FOREIGN KEY (`fk_turno`) REFERENCES `tb_turmas` (`turno`);

ALTER TABLE `tb_mensalidades` ADD FOREIGN KEY (`fk_cpf_responsavel`) REFERENCES `tb_contrato_escolar` (`fk_cpf_responsavel`);

ALTER TABLE `tb_mensalidades` ADD FOREIGN KEY (`fk_rgm_aluno`) REFERENCES `tb_contrato_escolar` (`fk_rgm_aluno`);

ALTER TABLE `tb_mensalidades` ADD FOREIGN KEY (`fk_ano_letivo`) REFERENCES `tb_contrato_escolar` (`fk_ano_letivo`);

ALTER TABLE `tb_pagamentos` ADD FOREIGN KEY (`fk_cpf_responsavel`) REFERENCES `tb_responsaveis` (`pk_cpf`);

ALTER TABLE `tb_pagamentos` ADD FOREIGN KEY (`fk_rgm_aluno`) REFERENCES `tb_alunos` (`pk_rgm`);

ALTER TABLE `tb_pagamentos` ADD FOREIGN KEY (`fk_ano_letivo`) REFERENCES `tb_mensalidades` (`fk_ano_letivo`);

ALTER TABLE `tb_pagamentos` ADD FOREIGN KEY (`fk_mes_referencia`) REFERENCES `tb_mensalidades` (`mes_referencia`);

ALTER TABLE `tb_ferias` ADD FOREIGN KEY (`fk_cpf_funcionario`) REFERENCES `tb_funcionarios` (`pk_cpf`);

ALTER TABLE `tb_ferias` ADD FOREIGN KEY (`aprovado_por`) REFERENCES `tb_funcionarios` (`pk_cpf`);

ALTER TABLE `tb_folha_pagamento` ADD FOREIGN KEY (`fk_cpf_funcionario`) REFERENCES `tb_funcionarios` (`pk_cpf`);

ALTER TABLE `tb_receitas` ADD FOREIGN KEY (`fk_cpf_funcionario`) REFERENCES `tb_funcionarios` (`pk_cpf`);

ALTER TABLE `tb_despesas` ADD FOREIGN KEY (`fk_cpf_funcionario`) REFERENCES `tb_funcionarios` (`pk_cpf`);
