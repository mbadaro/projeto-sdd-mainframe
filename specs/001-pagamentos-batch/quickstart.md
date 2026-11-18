# Quickstart: Validação por Revisão

Revisão de mesa (desk check): percorrer `SDDP0001` com a massa abaixo e conferir o
resultado. Compilação e execução não são exigidas.

## Massa (`·` = branco)

| # | Registro de entrada              | Esperado            |
|---|----------------------------------|---------------------|
| 1 | `PAG0000001+000000015000·······` | Aprovado            |
| 2 | `PAG0000002+000000000000·······` | Rejeitado, `02`     |
| 3 | `PAG0000003-000000001000·······` | Rejeitado, `02`     |
| 4 | `PAG0000004+0000000A5000·······` | Rejeitado, `01`     |
| 5 | `PAG0000005+000000200050·······` | Aprovado            |

Contadores: lidos 5, aprovados 2, rejeitados 3. RC 4.

Arquivo vazio: saídas vazias, contadores zerados, RC 0.

## Erro de arquivo

Simular `PAGENT` inexistente: `OPEN` falha, nenhum arquivo é fechado (nenhum estava
aberto), mensagem de erro exibida, RC 12.
