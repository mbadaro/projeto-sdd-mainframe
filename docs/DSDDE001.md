# DSDDE001 — Documentação Operacional da Procedure PSDDE001

## Identificação e finalidade

- **Procedure:** `PSDDE001`
- **Job:** `JSDDE001`
- **Finalidade:** separar o arquivo de pagamentos em aprovados e
  rejeitados (com motivo), conforme a RN01 da spec
  `001-pagamentos-batch`.

## Local ou ambiente de execução

z/OS, processamento batch. Datasets sob o qualificador `HLQ` da
procedure (padrão `SDD`).

## Periodicidade ou condição de execução

Eventual (`E`): submissão manual do job `JSDDE001`, sob demanda.
Não há agendamento periódico nem monitoramento de chegada de arquivo.

## Horário ou janela prevista

Não se aplica (execução sob demanda).

## Programas executados

| Step     | Programa   | Função                        |
|----------|------------|-------------------------------|
| `STEP01` | `SDDP0001` | Valida e separa os pagamentos |

## Arquivos de entrada e saída

| DD       | Dataset                 | Tipo    | Formato     |
|----------|-------------------------|---------|-------------|
| `PAGENT` | `SDD.PAGAMENT.ENTRADA`  | Entrada | FB, LRECL 30 |
| `PAGAPR` | `SDD.PAGAMENT.APROVADO` | Saída   | FB, LRECL 30 |
| `PAGREJ` | `SDD.PAGAMENT.REJEITAD` | Saída   | FB, LRECL 32 |

As saídas são criadas pelo próprio job. Rejeitados: registro original
+ código do motivo (`01` = valor não numérico; `02` = valor menor ou
igual a zero). Layouts no copybook `SDDC0001`.

## Responsável pela criação

1777-Squad Pagamentos

## Outras informações operacionais

**Códigos de retorno do step `STEP01`:**

| RC | Situação                  | Ação                              |
|----|---------------------------|-----------------------------------|
| 0  | Concluído sem rejeitados  | Nenhuma                           |
| 4  | Concluído com rejeitados  | Analisar `SDD.PAGAMENT.REJEITAD`  |
| 12 | Erro de arquivo (1)       | Ver SYSOUT, corrigir e reexecutar |

(1) Erro ao abrir, ler, gravar ou fechar um arquivo.

**Mensagens no SYSOUT:** contadores de lidos, aprovados e rejeitados
ao final. Em caso de erro, a linha abaixo (`<OP>` = operação):

```
SDDP0001 - ERRO NO ARQUIVO <DD> - OPERACAO <OP> - FILE STATUS <FS>
```

**Reexecução:** os datasets de saída são criados pelo próprio job
(`DISP=NEW`). Antes de reexecutar, excluir `SDD.PAGAMENT.APROVADO` e
`SDD.PAGAMENT.REJEITAD` da execução anterior (inclusive após RC 12,
pois o término é normal e as saídas ficam catalogadas).
