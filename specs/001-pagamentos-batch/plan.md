# Implementation Plan: Processamento Batch de Pagamentos

**Branch**: `001-pagamentos-batch` | **Date**: 2026-11-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-pagamentos-batch/spec.md`

## Summary

Um programa COBOL batch (`SDDP0001`) lê sequencialmente o arquivo de pagamentos, aplica
a RN01 (valor numérico e maior que zero) e grava cada registro no arquivo de aprovados
ou no de rejeitados (com motivo `01` ou `02`). Ao final exibe os contadores e devolve
RC 0, 4 ou 12. A execução é feita por uma procedure JCL (`PSDDE001`), chamada por um job
submetido sob demanda, e documentada em `DSDDE001`. O layout dos registros fica em um
único copybook (`SDDC0001`).

## Technical Context

**Language/Version**: COBOL tradicional (COBOL-85, compatível com IBM Enterprise COBOL),
formato fixo de colunas; JCL z/OS tradicional.

**Primary Dependencies**: nenhuma. Sem utilitários, sem funções intrínsecas, sem chamadas
a outros programas.

**Storage**: três arquivos sequenciais (QSAM), `RECFM=FB`: entrada e aprovados com
`LRECL=30`, rejeitados com `LRECL=32`.

**Testing**: revisão de mesa (desk check) com a massa descrita em
[quickstart.md](quickstart.md). Compilação e execução não são exigidas (Constitution).

**Target Platform**: z/OS batch.

**Project Type**: programa batch único + copybook + JCL + documento operacional.

**Performance Goals**: não aplicável (demonstração).

**Constraints**: código até a coluna 72 (COBOL) e 71 (JCL); documento `DSDDE001` com
linhas de até 72 posições; nomes com até 8 caracteres;
sem acentos em nomes e literais de código.

**Scale/Scope**: 1 programa, 1 copybook, 1 procedure, 1 job, 1 documento.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio / Seção                 | Verificação no plano                                              | Status |
|-----------------------------------|-------------------------------------------------------------------|--------|
| I. Simplicidade Demonstrativa     | Um programa, sem subprogramas nem utilitários                     | OK     |
| II. COBOL em Formato Fixo         | Colunas 1–6/7/8–11/12–72; maiúsculas; sem formato livre           | OK     |
| III. Código Legível e Organizado  | Parágrafos numerados com `PERFORM`, sem `GO TO`; RN01 isolada em `2100-VALIDAR-PAGAMENTO` | OK |
| IV. Copybook como Contrato        | Layouts só em `SDDC0001`; FDs com registro genérico `PIC X(n)` + `READ INTO`/`WRITE FROM` (ver research D2) | OK |
| V. JCL Tradicional                | JOB + PROC + `EXEC PGM=` + DDs; `LRECL` igual ao copybook; `RECFM=FB` | OK |
| VI. Nomenclatura e Documentação   | `SDDP0001`, `PSDDE001` (E = eventual, coerente com FR-009), `DSDDE001` com os itens mínimos e linhas de até 72 posições | OK |
| Restrições Técnicas               | Sem DB2/CICS/VSAM; validação por revisão                           | OK     |

Re-check pós-design (Phase 1): **OK**, sem violações. Complexity Tracking não se aplica.

## Project Structure

### Documentation (this feature)

```text
specs/001-pagamentos-batch/
├── plan.md                        # Este arquivo
├── research.md                    # Decisões técnicas (Phase 0)
├── data-model.md                  # Layouts e regras (Phase 1)
├── quickstart.md                  # Roteiro de validação por revisão (Phase 1)
├── contracts/
│   └── interface-execucao.md      # Mensagens no SYSOUT (Phase 1)
└── tasks.md                       # Gerado por /speckit-tasks
```

### Source Code (repository root)

```text
src/
├── cobol/
│   └── SDDP0001.cbl     # Programa de processamento
├── copy/
│   └── SDDC0001.cpy     # Copybook com os layouts de pagamento e de rejeitado
└── jcl/
    ├── PSDDE001.jcl     # Procedure de execução
    └── JSDDE001.jcl     # Job que executa a procedure (submissão manual)
docs/
└── DSDDE001.md          # Documentação operacional da procedure
```

**Structure Decision**: uma pasta por tipo de membro, espelhando as bibliotecas
tradicionais (fontes, copybooks, JCL). As extensões existem só para os editores no
repositório; no Mainframe cada arquivo vira um membro de PDS com o nome sem extensão.

### Desenho do programa SDDP0001

Parágrafos da PROCEDURE DIVISION, todos acionados por `PERFORM`:

| Parágrafo                   | Responsabilidade                                                     |
|-----------------------------|----------------------------------------------------------------------|
| `0000-PRINCIPAL`            | Orquestra: inicializar, processar até fim de arquivo, finalizar       |
| `1000-INICIALIZAR`          | Abrir os três arquivos e ler o primeiro registro                      |
| `2000-PROCESSAR`            | Validar, gravar no destino, ler o próximo                             |
| `2100-VALIDAR-PAGAMENTO`    | Aplicar RN01 e definir o motivo (`01`/`02`) — ver data-model          |
| `2200-GRAVAR-APROVADO`      | Gravar no arquivo de aprovados e somar aprovado                       |
| `2300-GRAVAR-REJEITADO`     | Montar registro rejeitado (original + motivo), gravar e somar rejeitado |
| `8000-LER-PAGAMENTO`        | `READ ... INTO`; somar lido; marcar fim de arquivo                    |
| `9000-FINALIZAR`            | Fechar arquivos, exibir contadores, definir RC 0 ou 4                 |
| `9900-ERRO-ARQUIVO`         | Exibir mensagem, fechar só os arquivos abertos, RC 12, encerrar       |

**Tratamento de erro de arquivo**:

- Cada `OPEN`, `READ`, `WRITE` e `CLOSE` testa o FILE STATUS do arquivo; qualquer valor
  diferente de `00` (e de `10` no `READ`, fim de arquivo) aciona `9900-ERRO-ARQUIVO`.
- Cada arquivo tem um indicador de aberto (`S`/`N`): passa a `S` após `OPEN` com
  sucesso e volta a `N` após `CLOSE` com sucesso.
- `9900-ERRO-ARQUIVO` fecha apenas os arquivos com indicador `S`, sem testar o FILE
  STATUS desses fechamentos (evita laço de erro), define RC 12 e encerra com
  `STOP RUN`.

### Desenho do JCL

**`JSDDE001`** (job): cartão `JOB` e um step `EXEC PSDDE001`. Submetido manualmente.

**`PSDDE001`** (procedure): símbolo `HLQ` (padrão `SDD`) e um step `EXEC PGM=SDDP0001`.
As saídas são criadas e catalogadas pelo próprio step:

| DD        | Dataset                   | DISP                 | Alocação (saídas)                              |
|-----------|---------------------------|----------------------|------------------------------------------------|
| `STEPLIB` | `&HLQ..LOADLIB`           | `SHR`                | —                                              |
| `PAGENT`  | `&HLQ..PAGAMENT.ENTRADA`  | `SHR`                | —                                              |
| `PAGAPR`  | `&HLQ..PAGAMENT.APROVADO` | `(NEW,CATLG,DELETE)` | `UNIT=SYSDA`, `SPACE=(TRK,(5,5),RLSE)`, `DCB=(RECFM=FB,LRECL=30,BLKSIZE=0)` |
| `PAGREJ`  | `&HLQ..PAGAMENT.REJEITAD` | `(NEW,CATLG,DELETE)` | `UNIT=SYSDA`, `SPACE=(TRK,(5,5),RLSE)`, `DCB=(RECFM=FB,LRECL=32,BLKSIZE=0)` |
| `SYSOUT`  | `SYSOUT=*`                | —                    | —                                              |

- `DISP=(NEW,CATLG,DELETE)`: cria na execução, cataloga se o step terminar, exclui se
  houver abend. Com RC 12 (término normal com erro) a saída é catalogada; o
  `DSDDE001` orienta a exclusão antes de reexecutar (research D5).
- `BLKSIZE=0`: o sistema calcula o melhor tamanho de bloco.

## Complexity Tracking

Não se aplica: nenhuma violação da Constitution.
