# Feature Specification: Processamento Batch de Pagamentos

**Feature Branch**: `001-pagamentos-batch`

**Created**: 2026-11-17

**Status**: Draft

**Input**: User description: "Processamento Batch de Pagamentos: ler sequencialmente um
arquivo de pagamentos, validar cada registro (única regra: valor maior que zero), gravar
os válidos em um arquivo de aprovados e os inválidos em um arquivo de rejeitados. Gerar
posteriormente programa COBOL, copybook e JCL. Programa principal: SDDP0001."

## Clarifications

### Session 2026-11-17

- Q: Com qual código de retorno o processamento deve terminar? → A: RC 0 sem rejeitados,
  RC 4 se houver ao menos um rejeitado; erro de arquivo encerra com RC 12.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Separar pagamentos aprovados e rejeitados (Priority: P1)

A área de operação recebe um arquivo de pagamentos e precisa separá-los: os pagamentos
com valor maior que zero seguem como aprovados; os demais ficam em um arquivo de
rejeitados, com o código do motivo, para análise.

**Why this priority**: é o objetivo central do processamento.

**Independent Test**: processar um arquivo com pagamentos de valor positivo, zero,
negativo e não numérico e conferir em qual arquivo cada registro foi gravado e, nos
rejeitados, o código do motivo.

**Acceptance Scenarios**:

1. **Given** um pagamento com valor 150,00 (`+000000015000`), **When** o arquivo é processado, **Then** o
   registro é gravado no arquivo de aprovados, idêntico ao de entrada.
2. **Given** um pagamento com valor contendo caracteres não numéricos, **When** o
   arquivo é processado, **Then** o registro é gravado no arquivo de rejeitados com o
   motivo `01`.
3. **Given** um pagamento com valor 0,00 (`+000000000000`), **When** o arquivo é processado, **Then** o
   registro é gravado no arquivo de rejeitados com o motivo `02`.
4. **Given** um pagamento com valor negativo -10,00 (`-000000001000`), **When** o arquivo é processado,
   **Then** o registro é gravado no arquivo de rejeitados com o motivo `02`.
5. **Given** um arquivo com 5 pagamentos, 2 com valor positivo e 3 não, **When** o
   arquivo é processado, **Then** o arquivo de aprovados contém 2 registros e o de
   rejeitados contém 3, na mesma ordem relativa da entrada.

---

### User Story 2 - Contadores de controle (Priority: P2)

Ao fim do processamento, o operador precisa ver quantos registros foram lidos, aprovados
e rejeitados, para conferir o resultado sem abrir os arquivos.

**Why this priority**: é o controle operacional mínimo de um batch, mas depende da
história 1.

**Independent Test**: processar um arquivo com quantidades conhecidas e conferir os
contadores exibidos.

**Acceptance Scenarios**:

1. **Given** o arquivo do cenário 5 da história 1, **When** o processamento termina,
   **Then** são exibidos: lidos = 5, aprovados = 2, rejeitados = 3, e o código de
   retorno é 4.
2. **Given** um arquivo de entrada vazio, **When** o processamento termina, **Then** os
   três contadores são exibidos com valor zero e o código de retorno é 0.

---

### Edge Cases

- Arquivo de entrada vazio: o processamento termina normalmente, os dois arquivos de
  saída ficam vazios e os contadores são zero.
- Todos os pagamentos aprovados (ou todos rejeitados): o outro arquivo de saída fica
  vazio e o processamento termina normalmente.
- Erro ao abrir, ler, gravar ou fechar um arquivo: o processamento é encerrado com código de
  retorno 12 e uma mensagem indicando o arquivo com problema.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O processamento MUST ler todos os registros do arquivo de pagamentos,
  sequencialmente, do primeiro ao último.
- **FR-002**: Regra de negócio única — **RN01**: o pagamento é aprovado se, e somente se,
  o valor do pagamento for numérico e maior que zero.
- **FR-003**: Pagamentos não aprovados pela RN01 MUST receber um código de motivo,
  verificado nesta ordem:

  | Código | Motivo                          |
  |--------|---------------------------------|
  | 01     | Valor não numérico              |
  | 02     | Valor menor ou igual a zero     |

  O valor é considerado numérico quando a posição do sinal contém `+` ou `-` e as 12
  posições seguintes contêm apenas dígitos. Os motivos são mutuamente exclusivos: o
  código 02 só é avaliado para valores numéricos.
- **FR-004**: Pagamentos aprovados MUST ser gravados no arquivo de pagamentos aprovados,
  sem alteração de conteúdo.
- **FR-005**: Pagamentos rejeitados MUST ser gravados no arquivo de pagamentos
  rejeitados, com o registro original sem alteração seguido do código do motivo.
- **FR-006**: Cada registro de entrada MUST ser gravado em exatamente um arquivo de
  saída, na mesma ordem relativa da entrada.
- **FR-007**: Um registro rejeitado MUST NOT interromper o processamento dos demais.
- **FR-008**: Ao final, o processamento MUST exibir os contadores de registros lidos,
  aprovados e rejeitados.
- **FR-009**: A procedure é executada sob demanda (execução eventual), por submissão
  manual, sem agendamento periódico nem monitoramento de chegada de arquivo.
- **FR-010**: O processamento MUST terminar com o código de retorno:

  | RC | Situação                                               |
  |----|--------------------------------------------------------|
  | 0  | Concluído sem nenhum pagamento rejeitado               |
  | 4  | Concluído com ao menos um pagamento rejeitado          |
  | 12 | Encerrado por erro ao abrir, ler, gravar ou fechar um arquivo |

### Arquivos e Layouts

Os três arquivos são sequenciais, com registros de tamanho fixo.

| Arquivo               | Papel   | Tamanho | Conteúdo                                   |
|-----------------------|---------|---------|--------------------------------------------|
| Pagamentos            | Entrada | 30      | Pagamentos a processar                     |
| Pagamentos Aprovados  | Saída   | 30      | Pagamentos que atendem à RN01              |
| Pagamentos Rejeitados | Saída   | 32      | Pagamento original + código do motivo      |

**Layout do registro de pagamento (30 posições)** — usado na entrada e nos aprovados:

| Campo                       | Início | Tamanho | Tipo         | Descrição                                         |
|-----------------------------|--------|---------|--------------|---------------------------------------------------|
| Identificador do pagamento  | 1      | 10      | Alfanumérico | Identifica o pagamento                            |
| Valor do pagamento          | 11     | 13      | Alfanumérico | Sinal (1) + inteiros (10) + centavos (2), sem separador decimal |
| Reservado                   | 24     | 7       | Alfanumérico | Uso futuro; preenchido com brancos                |

O valor é lido como alfanumérico para que caracteres inválidos sejam identificados
(motivo `01`) antes de qualquer conversão numérica. Exemplo: 150,00 = `+000000015000`.

**Layout do registro de pagamento rejeitado (32 posições)**:

| Campo                       | Início | Tamanho | Tipo         | Descrição                               |
|-----------------------------|--------|---------|--------------|-----------------------------------------|
| Registro de pagamento       | 1      | 30      | —            | Cópia integral do registro de entrada   |
| Código do motivo            | 31     | 2       | Numérico     | `01` ou `02`, conforme FR-003           |

### Artefatos e Nomes

Nomes conforme o princípio VI da Constitution:

| Artefato                               | Nome       |
|----------------------------------------|------------|
| Programa de processamento              | `SDDP0001` |
| Procedure de execução (eventual)       | `PSDDE001` |
| Documentação operacional da procedure  | `DSDDE001` |
| Layouts dos registros                  | Copybook único com os dois layouts (nome definido no Plan) |

### Key Entities

- **Pagamento**: identificador e valor.
- **Pagamento rejeitado**: o pagamento original acrescido do código do motivo.
- **Contadores de controle**: quantidades de lidos, aprovados e rejeitados de uma
  execução.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos registros de entrada aparecem em exatamente um dos dois arquivos
  de saída.
- **SC-002**: 100% dos registros aprovados têm valor numérico maior que zero, e 100% dos
  rejeitados trazem o código de motivo correto (`01` ou `02`).
- **SC-003**: Os contadores exibidos fecham: lidos = aprovados + rejeitados, e cada um
  coincide com a quantidade de registros do arquivo correspondente.
- **SC-004**: A RN01, os códigos de motivo, os layouts e os nomes de artefatos desta spec
  podem ser localizados nos artefatos gerados, sem divergência.

## Assumptions

- Não há registros de cabeçalho ou trailer; todos os registros do arquivo são
  pagamentos.
- Não há validação do identificador do pagamento nem de outros campos (escopo limitado
  à RN01).
- Valores em reais, sem conversão de moeda.
- Compilação e execução reais não são exigidas (Constitution, Restrições Técnicas).
- O nome do job que executa a procedure, os nomes de datasets e o nome do copybook
  ficam para o Plan, pois a Constitution não define convenção para eles.
