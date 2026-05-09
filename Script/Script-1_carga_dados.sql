
-- SISGESC – SCRIPT: CARGA DE DADOS (DML)
-- Finalidade : Inserir dados operacionais em todas as tabelas para validar tabelas, VIEWs e TRIGGERs de forma integrada.


USE SisGESC; -- Se precisar


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
