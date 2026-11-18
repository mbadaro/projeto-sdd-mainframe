# Research: Processamento Batch de Pagamentos

Decisões que a Spec deixou para o Plan. Detalhes de layout em
[data-model.md](data-model.md); DDs e datasets em [plan.md](plan.md).

## D1. Validação do valor sem aritmética de sinal

- **Decisão**: valor dividido em sinal `X(01)` e dígitos `X(12)`; a visão numérica
  (`REDEFINES`) só é usada após o teste `NUMERIC`.
- **Razão**: valida antes de converter, como pede a Spec, e o sinal decide sozinho se o
  valor é negativo.
- **Descartadas**: `S9(11)V99 SIGN LEADING SEPARATE` (menos legível); `FUNCTION NUMVAL`
  (desnecessária).

## D2. Copybook na WORKING-STORAGE

- **Decisão**: FDs com `PIC X(30)`/`X(32)`; `READ INTO` e `WRITE FROM` sobre o copybook.
- **Razão**: layout definido uma única vez, sem `COPY REPLACING`.

## D3. Nome do copybook: `SDDC0001`

- **Razão**: a Constitution não cobre copybooks; segue a lógica do nome do programa.

## D4. Nome do job: `JSDDE001`

- **Razão**: a Constitution não cobre jobs; liga o job à procedure `PSDDE001`.

## D5. Reexecução sem step de exclusão

- **Decisão**: saídas `NEW`; a exclusão antes de reexecutar fica documentada no
  `DSDDE001`.
- **Descartada**: step `IEFBR14` de exclusão (não exigido pela Spec).

## D6. Contadores e RC

- **Decisão**: contadores `9(07)` exibidos por `DISPLAY` no `SYSOUT`; RC pelo registrador
  especial `RETURN-CODE`.
