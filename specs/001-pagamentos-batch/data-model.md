# Data Model: Processamento Batch de Pagamentos

## Copybook `SDDC0001`

**`REG-PAGAMENTO`** (30 posições) — entrada e aprovados:

| Nível | Nome                                            | PIC        | Pos.  |
|-------|-------------------------------------------------|------------|-------|
| 05    | `PAG-ID`                                        | `X(10)`    | 1–10  |
| 05    | `PAG-VALOR`                                     | —          | 11–23 |
| 10    | `PAG-VALOR-SINAL`                               | `X(01)`    | 11    |
| 10    | `PAG-VALOR-DIGITOS`                             | `X(12)`    | 12–23 |
| 10    | `PAG-VALOR-NUM` REDEFINES `PAG-VALOR-DIGITOS`   | `9(10)V99` | 12–23 |
| 05    | `FILLER`                                        | `X(07)`    | 24–30 |

**`REG-REJEITADO`** (32 posições) — rejeitados:

| Nível | Nome            | PIC     | Pos.  |
|-------|-----------------|---------|-------|
| 05    | `REJ-PAGAMENTO` | `X(30)` | 1–30  |
| 05    | `REJ-MOTIVO`    | `9(02)` | 31–32 |

## RN01 — ordem de avaliação

| Ordem | Condição                                                              | Resultado    |
|-------|-----------------------------------------------------------------------|--------------|
| 1     | Sinal não é `+` nem `-`, ou `PAG-VALOR-DIGITOS` não é `NUMERIC`       | Motivo `01`  |
| 2     | Sinal = `-`, ou `PAG-VALOR-NUM` = zero                                | Motivo `02`  |
| 3     | Demais casos                                                          | Aprovado     |

## Áreas de trabalho de `SDDP0001`

| Nome                                   | PIC     | Uso                                  |
|----------------------------------------|---------|--------------------------------------|
| `WS-FS-PAGENT`/`-PAGAPR`/`-PAGREJ`     | `X(02)` | FILE STATUS de cada arquivo          |
| `WS-ABERTO-PAGENT`/`-PAGAPR`/`-PAGREJ` | `X(01)` | `S`/`N`: arquivo aberto              |
| `WS-FIM-ARQUIVO`                       | `X(01)` | `S` no fim da entrada                |
| `WS-MOTIVO`                            | `9(02)` | `00` aprovado; `01`/`02` rejeitado   |
| `WS-CONT-LIDOS`/`-APROVADOS`/`-REJEITADOS` | `9(07)` | Contadores                       |
