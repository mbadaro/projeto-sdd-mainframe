# Contrato de Execução: SDDP0001

DDs: ver [plan.md](../plan.md#desenho-do-jcl). Códigos de retorno: ver FR-010 da
[spec.md](../spec.md).

## Mensagens no SYSOUT

Término concluído:

```text
SDDP0001 - REGISTROS LIDOS......: 0000005
SDDP0001 - REGISTROS APROVADOS..: 0000002
SDDP0001 - REGISTROS REJEITADOS.: 0000003
```

Erro de arquivo (`<DD>` = `PAGENT`, `PAGAPR` ou `PAGREJ`; operação = `OPEN`, `READ`,
`WRITE` ou `CLOSE`):

```text
SDDP0001 - ERRO NO ARQUIVO <DD> - OPERACAO <OPERACAO> - FILE STATUS <FS>
```
