# SisGESC — Sistema de Gestão Escolar
**Grupo MedioFund** | Projeto ERP Escolar — Prof. Clóvis  
Disciplina: Banco de Dados | Entrega Final

---

## Sobre o Projeto

O **SisGESC** é um sistema de gestão escolar desenvolvido em MySQL, cobrindo os módulos **Acadêmico**, **Financeiro** e **RH**. O projeto contempla desde a modelagem relacional (OLTP) até a camada analítica (OLAP/Star Schema), com processo ETL, validação de integridade e otimização de performance.

---

## Estrutura do Repositório

```
SisGESC_MedioFund/
│
├── README.md                        ← este arquivo
│
├── run_all.sql                      ← executa todos os scripts em ordem
│
├── Script/
│   ├── script_criacao.sql                   ← criação das tabelas (DDL) — módulos Acadêmico, Financeiro, RH
│   ├── Script-1_carga_dados.sql                   ← carga de dados operacionais (idempotente)
│   ├── Script-2_oltp_consultas.sql         ← consultas OLTP: SELECTs simples e subselects
│   ├── Script-3_olap_etl.sql              ← Star Schema + processo ETL
│   ├── Script-4_performance_governanca.sql ← índices, EXPLAIN e validação SUM(OLTP) = SUM(OLAP)
│   └── run_all.sql                 ← executa todos os scripts em ordem
│
└── Docs/
    ├── DER-MedioFund-3.0.pdf  ← Diagrama Entidade-Relacionamento (OLTP + OLAP)
    └── SisGESC_DER_MedioFund 4.1.pdf   ← documentação completa: dicionário de dados, prints OLTP e OLAP
```

---

## Como Executar

### Pré-requisitos

- MySQL 8.0 ou superior
- MySQL Workbench ou cliente de linha de comando (`mysql`)

### Execução Completa (recomendado)

Para instalar todo o sistema de uma vez, execute o script único:

```bash
mysql -u seu_usuario -p < run_all.sql
```

Ou, no MySQL Workbench, abra o arquivo `run_all.sql` e execute (`Ctrl+Shift+Enter`).

O `run_all.sql` chama os scripts na seguinte ordem:

| Ordem | Script | O que faz |
|-------|--------|-----------|
| 1 | `01_ddl.sql` | Cria o banco e todas as tabelas com PK e FK |
| 2 | `02_dml.sql` | Insere os dados operacionais |
| 3 | `03_oltp_queries.sql` | Executa as consultas OLTP |
| 4 | `04_olap_etl.sql` | Cria o Star Schema e executa o ETL |
| 5 | `05_performance_governanca.sql` | Cria índices, roda EXPLAINs e valida SUM(OLTP) = SUM(OLAP) |
| 6 | `06_reset.sql` | (opcional) Reseta o banco com DROP/TRUNCATE |

### Execução Individual

Caso queira rodar apenas uma fase:

```bash
mysql -u seu_usuario -p < Scripts/01_ddl.sql
```

### Reset do Banco

Para zerar tudo e recomeçar do zero:

```bash
mysql -u seu_usuario -p < Scripts/06_reset.sql
```

---

## Validações Importantes

### Idempotência da Carga (Fase 2)

O script `02_dml.sql` é **idempotente**: executá-lo mais de uma vez não duplica registros. Para confirmar, rode o `SELECT COUNT(*)` antes e depois da segunda execução — os totais devem ser idênticos.

### Consistência OLTP → OLAP (Fase 5)

O script `05_performance_governanca.sql` inclui uma query de validação que prova:

```
SUM(valores no OLTP) = SUM(valores no OLAP)
```

Se os valores divergirem, o ETL possui falha de integridade.

---

## Módulos do Sistema

| Módulo | Descrição |
|--------|-----------|
| **Acadêmico** | Alunos, matrículas, cursos, turmas, notas e frequência |
| **Financeiro** | Mensalidades, pagamentos e inadimplência |
| **RH** | Professores, funcionários e vínculos |

---

## Modelagem OLAP — Star Schema

A camada analítica segue o modelo **Star Schema** com:

- **Tabela Fato:** `fato_matriculas` (ou equivalente definida no projeto)
- **Dimensões:** `dim_tempo`, `dim_aluno`, `dim_curso`, `dim_unidade`
- **Surrogate Keys** em todas as dimensões
- **Granularidade:** definida por matrícula × período

---

## Documentação

Toda a documentação técnica está em `Docs/`:

- **DER 4.0** (`SisGESC_MediFund_DER.4.0.pdf`) — diagrama atualizado com estrutura OLTP e OLAP
- **Documento do Projeto** (`Documento_Projeto.pdf`) — dicionário de dados completo, prints das queries OLTP e OLAP, e demais evidências

---

## Padrões Adotados

- Nomenclatura: `snake_case` em todos os objetos do banco
- Scripts comentados por seção
- Versionamento: histórico de commits com evolução desde a Entrega 1
- Correções da 1ª entrega aplicadas nesta versão final

---

## Grupo MedioFund

Projeto desenvolvido para a disciplina de Banco de Dados.  
Entrega Final — SisGESC ERP Escolar.
