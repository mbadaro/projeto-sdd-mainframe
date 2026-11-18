---

description: "Lista de tarefas da feature 001-pagamentos-batch"
---

# Tasks: Processamento Batch de Pagamentos

**Input**: Documentos de projeto em `/specs/001-pagamentos-batch/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: não há tarefas de teste automatizado (não solicitados; a Constitution dispensa
compilação e execução). A verificação é estática, na fase final.

**Organization**: tarefas agrupadas por User Story da spec.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode ser feita em paralelo (arquivo diferente, sem dependência pendente)
- **[Story]**: User Story atendida (US1, US2)

## Path Conventions

Conforme a estrutura do [plan.md](plan.md): `src/cobol/`, `src/copy/`, `src/jcl/`,
`docs/`. As pastas são criadas junto com o primeiro arquivo de cada uma.

Regras válidas para todas as tarefas de código (Constitution II, III e V): COBOL em
formato fixo até a coluna 72, JCL até a coluna 71, maiúsculas, sem `GO TO`, sem acentos
em nomes e literais.

---

## Phase 1: Foundational (pré-requisito bloqueante)

**Purpose**: o copybook é usado pelo programa e define o `LRECL` do JCL.

- [X] T001 Criar o copybook `SDDC0001` em src/copy/SDDC0001.cpy com os dois layouts do
  [data-model.md](data-model.md): `01 REG-PAGAMENTO` (30 posições: `PAG-ID PIC X(10)`;
  grupo `PAG-VALOR` com `PAG-VALOR-SINAL PIC X(01)`, `PAG-VALOR-DIGITOS PIC X(12)` e
  `PAG-VALOR-NUM REDEFINES PAG-VALOR-DIGITOS PIC 9(10)V99`; `FILLER PIC X(07)`) e
  `01 REG-REJEITADO` (32 posições: `REJ-PAGAMENTO PIC X(30)`, `REJ-MOTIVO PIC 9(02)`)

**Checkpoint**: layouts disponíveis para o programa e para o JCL.

---

## Phase 2: User Story 1 - Separar pagamentos aprovados e rejeitados (Priority: P1) 🎯 MVP

**Goal**: cada pagamento de entrada é gravado em aprovados ou em rejeitados (com motivo
`01`/`02`); erro de arquivo encerra com RC 12.

**Independent Test**: desk check com a massa do [quickstart.md](quickstart.md): registros
1 e 5 em `PAGAPR`; 2 e 3 em `PAGREJ` com `02`; 4 em `PAGREJ` com `01`.

- [X] T002 [US1] Criar a estrutura do programa `SDDP0001` em src/cobol/SDDP0001.cbl:
  IDENTIFICATION DIVISION (`PROGRAM-ID. SDDP0001`); ENVIRONMENT DIVISION com `SELECT`
  para as DDs `PAGENT`, `PAGAPR` e `PAGREJ`, cada uma com `FILE STATUS`; DATA DIVISION
  com FDs de registro genérico (`PIC X(30)`, `PIC X(30)`, `PIC X(32)`), as áreas de
  trabalho do [data-model.md](data-model.md) (exceto contadores, ver T006) e
  `COPY SDDC0001` na WORKING-STORAGE (research D2)
- [X] T003 [US1] Implementar em src/cobol/SDDP0001.cbl os parágrafos `0000-PRINCIPAL`
  (`PERFORM 1000-INICIALIZAR`; `PERFORM 2000-PROCESSAR UNTIL` fim de arquivo;
  `PERFORM 9000-FINALIZAR`; `STOP RUN`),
  `1000-INICIALIZAR` (`OPEN INPUT PAGENT`, `OPEN OUTPUT PAGAPR` e `OPEN OUTPUT PAGREJ`,
  marcando o indicador de aberto `S` a cada sucesso, e leitura antecipada do primeiro
  registro via `PERFORM 8000-LER-PAGAMENTO`), `8000-LER-PAGAMENTO` (`READ PAGENT INTO REG-PAGAMENTO`;
  FILE STATUS `10` marca fim de arquivo) e `9900-ERRO-ARQUIVO` (mensagem no formato de
  [contracts/interface-execucao.md](contracts/interface-execucao.md), `CLOSE` apenas dos
  arquivos com indicador `S` sem testar FILE STATUS, `RETURN-CODE` 12, `STOP RUN`),
  conforme "Tratamento de erro de arquivo" do [plan.md](plan.md)
- [X] T004 [US1] Implementar em src/cobol/SDDP0001.cbl os parágrafos `2000-PROCESSAR`
  (`PERFORM 2100-VALIDAR-PAGAMENTO`; se `WS-MOTIVO` = `00`, `PERFORM 2200-GRAVAR-APROVADO`,
  senão `PERFORM 2300-GRAVAR-REJEITADO`; por último `PERFORM 8000-LER-PAGAMENTO` para o
  próximo registro), `2100-VALIDAR-PAGAMENTO`, `2200-GRAVAR-APROVADO` (`WRITE ... FROM REG-PAGAMENTO`) e
  `2300-GRAVAR-REJEITADO` (`REJ-PAGAMENTO` = registro original, `REJ-MOTIVO` =
  `WS-MOTIVO`, `WRITE ... FROM REG-REJEITADO`). A RN01 segue exatamente a ordem do
  data-model: (1) sinal não é `+` nem `-`, ou `PAG-VALOR-DIGITOS` não é `NUMERIC` →
  motivo `01`; (2) sinal = `-`, ou `PAG-VALOR-NUM` = zero → motivo `02`; (3) demais →
  aprovado. Todo `WRITE` com FILE STATUS diferente de `00` aciona `9900-ERRO-ARQUIVO`.
  Incluir em `2100-VALIDAR-PAGAMENTO` comentário curto citando RN01 (FR-002), os
  motivos `01`/`02` (FR-003) e a spec `001-pagamentos-batch`, para rastreabilidade
  (Constitution III)
- [X] T005 [US1] Implementar em src/cobol/SDDP0001.cbl o parágrafo `9000-FINALIZAR`
  com o `CLOSE` dos três arquivos, voltando o indicador de aberto para `N` a cada
  sucesso; FILE STATUS diferente de `00` aciona `9900-ERRO-ARQUIVO`
- [X] T006 [P] [US1] Criar a procedure `PSDDE001` em src/jcl/PSDDE001.jcl: símbolo
  `HLQ=SDD`, um step `EXEC PGM=SDDP0001` e as DDs `STEPLIB`, `PAGENT`, `PAGAPR`,
  `PAGREJ` e `SYSOUT` com os parâmetros exatos da tabela "Desenho do JCL" do
  [plan.md](plan.md) (`PAGAPR` com `LRECL=30`, `PAGREJ` com `LRECL=32`, ambas
  `DISP=(NEW,CATLG,DELETE)`, `UNIT=SYSDA`, `SPACE=(TRK,(5,5),RLSE)`, `RECFM=FB`,
  `BLKSIZE=0`)
- [X] T007 [P] [US1] Criar o job `JSDDE001` em src/jcl/JSDDE001.jcl: cartão `JOB` e um
  step `EXEC PSDDE001`, com comentário `//*` indicando submissão manual sob demanda

**Checkpoint**: separação de aprovados e rejeitados completa e executável via JCL.

---

## Phase 3: User Story 2 - Contadores de controle (Priority: P2)

**Goal**: exibir lidos, aprovados e rejeitados e devolver RC 0 ou 4 (FR-008, FR-010).

**Independent Test**: desk check com a massa do quickstart: lidos 5, aprovados 2,
rejeitados 3, RC 4; arquivo vazio: contadores zerados, RC 0.

- [X] T008 [US2] Em src/cobol/SDDP0001.cbl, declarar `WS-CONT-LIDOS`,
  `WS-CONT-APROVADOS` e `WS-CONT-REJEITADOS` (`PIC 9(07)`, iniciados com zero).
  Incrementos: lidos em `8000-LER-PAGAMENTO`, a cada registro lido (FILE STATUS `00`,
  nunca no fim de arquivo); aprovados em `2200-GRAVAR-APROVADO` e rejeitados em
  `2300-GRAVAR-REJEITADO`, somente após `WRITE` com FILE STATUS `00`. Em
  `9000-FINALIZAR`, depois de todos os `CLOSE` bem-sucedidos, exibir as três linhas no
  formato de [contracts/interface-execucao.md](contracts/interface-execucao.md) e mover
  para `RETURN-CODE` 4 se houver rejeitado, senão 0. Prioridade do RC 12:
  `9900-ERRO-ARQUIVO` sempre move 12 e encerra com `STOP RUN`, sem retornar ao fluxo,
  de modo que RC 0/4 nunca sobrescreve o 12

**Checkpoint**: US1 e US2 completas.

---

## Phase 4: Polish & Cross-Cutting Concerns

- [X] T009 [P] Criar a documentação operacional `DSDDE001` em docs/DSDDE001.md com os
  itens mínimos da Constitution VI: identificação e finalidade; ambiente de execução;
  periodicidade (eventual, submissão manual sob demanda — FR-009); janela (não se
  aplica); programa `SDDP0001`; arquivos de entrada e saída (DDs e datasets do plan);
  responsável pela criação (`1777-Squad Pagamentos`); outras informações: tabela de RC (FR-010) e orientação de
  excluir `&HLQ..PAGAMENT.APROVADO` e `&HLQ..PAGAMENT.REJEITAD` antes de reexecutar
  (research D5). Nenhuma linha do documento acima de 72 posições (Constitution VI)
- [X] T010 Revisar estaticamente todos os artefatos de src/ e docs/ contra a
  Constitution e a Spec: colunas (COBOL até 72, JCL até 71, documento `DSDDE001` até
  72 posições); nomes `SDDP0001`,
  `SDDC0001`, `PSDDE001`, `JSDDE001`, `DSDDE001`; ausência de `GO TO` e de acentos no
  código; `LRECL` igual ao tamanho dos registros do copybook; RN01 e motivos
  localizáveis em `2100-VALIDAR-PAGAMENTO`; desk check com a massa do quickstart.md;
  corrigir divergências encontradas

---

## Dependencies & Execution Order

- **T001** (copybook) bloqueia todas as demais tarefas de código.
- **T002 → T003 → T004 → T005**: mesmo arquivo, em sequência.
- **T006** e **T007** (JCL) dependem só de T001 e podem correr em paralelo com T002–T005.
- **T008** (US2) depende de T005.
- **T009** pode correr em paralelo com qualquer tarefa após T001.
- **T010** é a última: depende de todas.

## Parallel Example: User Story 1

```text
Após T001, em paralelo:
Task: "T002–T005 Programa SDDP0001 em src/cobol/SDDP0001.cbl"
Task: "T006 Procedure PSDDE001 em src/jcl/PSDDE001.jcl"
Task: "T007 Job JSDDE001 em src/jcl/JSDDE001.jcl"
```

## Implementation Strategy

1. T001 (copybook).
2. US1 (T002–T007) → desk check da separação: **MVP demonstrável**.
3. US2 (T008) → desk check dos contadores e do RC.
4. T009 (documentação) e T010 (revisão final).

## Notes

- Cada tarefa cita o documento de origem; em caso de dúvida, vale o data-model.md para
  layouts e o plan.md para parágrafos e JCL.
- Nenhuma tarefa de ambiente, compilação ou execução (fora do escopo pela Constitution).
