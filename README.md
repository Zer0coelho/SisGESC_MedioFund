# 🗄️ SisGESC – Sistema de Gestão Escolar (Banco de Dados)

Projeto acadêmico de **modelagem de banco de dados relacional**, desenvolvido com foco em **estruturação, normalização e integração de dados** para um sistema de gestão escolar completo.

---

## 📌 Objetivo

O SisGESC foi projetado para representar a estrutura de um sistema escolar que atende do **Ensino Fundamental II ao Ensino Médio**, contemplando:

* Gestão acadêmica
* Gestão financeira
* Gestão de recursos humanos

O objetivo principal é garantir **integridade, consistência e rastreabilidade dos dados** em todos os processos da instituição. 

---

## 🧱 Arquitetura do Sistema

O banco foi modelado seguindo o padrão **relacional (RDBMS)**, utilizando:

* Chaves primárias (PK)
* Chaves estrangeiras (FK)
* Normalização até a **3ª Forma Normal (3FN)** 

A estrutura é dividida em **3 módulos principais**:

### 🎓 Acadêmico

* Alunos, turmas, disciplinas
* Matrículas, avaliações, notas
* Frequência e atestados

### 💰 Financeiro

* Contratos escolares
* Mensalidades e pagamentos
* Receitas e despesas

### 🧑‍💼 Recursos Humanos (RH)

* Funcionários
* Vínculos e cargos
* Férias e folha de pagamento

---

## 🔗 Integração entre módulos

O sistema foi projetado com rastreabilidade completa:

```text
Aluno → Matrícula → Turma → Disciplina → Professor → Contrato → Mensalidade → Pagamento
```

Isso permite acompanhar todo o ciclo do aluno, desde o cadastro até o pagamento das mensalidades. 

---

## 🧠 Modelagem e decisões técnicas

### ✔ Normalização

* Aplicação das **1FN, 2FN e 3FN**
* Eliminação de redundâncias
* Separação de entidades para evitar dependências transitivas 

### ✔ Relacionamentos

* Uso de tabelas associativas para relações N:N:

  * aluno ↔ responsável
  * turma ↔ disciplina
  * aluno ↔ avaliação 

### ✔ Integridade referencial

* Uso de chaves estrangeiras para garantir consistência
* Nenhum dado existe sem suas dependências 

---

## ⚙️ Funcionalidades modeladas

O banco suporta funcionalidades como:

* Cadastro completo de alunos e responsáveis
* Matrículas em turmas e disciplinas
* Registro de notas e frequência
* Geração automática de mensalidades
* Controle de pagamentos
* Gestão de funcionários e folha salarial

Além disso, foram utilizados **triggers** para automações como:

* Geração de mensalidades
* Aplicação de bolsas
* Cálculo de juros e multas 

---

## 📊 Estrutura do Banco

* Total de tabelas: **22**
* Uso de ENUMs para padronização de dados
* Campos de auditoria (`data_cadastro`)
* Separação entre dados operacionais e históricos 

---

## 📈 Aplicações futuras (BI e IA)

O banco foi estruturado para análises como:

* 📉 Previsão de inadimplência
* 🎓 Previsão de evasão escolar
* 📊 Análise de comportamento financeiro e acadêmico 

---

## 📷 DER (Diagrama Entidade-Relacionamento)

O DER completo do sistema está disponível em:

📄 `DER/der-sisgesc.pdf`

---

## 🛠️ Como executar

1. Abra o MySQL Workbench (ou outro SGBD compatível)
2. Execute o script:

```sql
schema-mysql.sql
```

3. O banco será criado automaticamente com todas as tabelas e relacionamentos

---

## 📁 Estrutura do repositório

```text
SisGESC/
│
├── DER/
│   └── der-sisgesc.pdf
│
├── SQL/
│   └── schema-mysql.sql
│
├── Documentacao/
│   └── documentacao-banco.pdf
│
└── README.md
```

---

## 📌 Observação

Este projeto tem foco em **engenharia de dados e modelagem relacional**, não incluindo camada de aplicação (backend/frontend).

---

## 🚀 Próximos passos

* Integração com aplicação Java (CRUD)
* Criação de API para acesso ao banco
* Dashboard analítico (BI)
* Interface gráfica para usuários
