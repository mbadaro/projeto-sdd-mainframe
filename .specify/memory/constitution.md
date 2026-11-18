<!--
Sync Impact Report
- Versão: 1.0.0 → 1.1.0 (MINOR: novo princípio) → 1.1.1 (PATCH: sequencial
  dos nomes passa de numérico para alfanumérico A–Z/0–9) → 1.1.2 (PATCH: correção
  da definição do código `I` — intervalos curtos e regulares, não chegada de arquivo)
  → 1.2.0 (MINOR: documento da procedure limitado a 72 posições por linha)
- Princípios modificados: VI (nova regra de 72 posições no documento da procedure)
- Princípios adicionados:
  - VI. Nomenclatura e Documentação Operacional
- Seções modificadas:
  - Fluxo de Desenvolvimento SDD: critério de conclusão passa a incluir a
    documentação operacional de cada procedure
- Seções removidas: nenhuma
- Templates dependentes: não alterados (leem a constitution em tempo de execução)
- TODOs pendentes: nenhum
-->

# Constitution do Projeto SDD Mainframe — Pagamentos Batch

## Core Principles

### I. Simplicidade Demonstrativa

O projeto existe para demonstrar que SDD com agentes de programação funciona em Mainframe.
Toda decisão MUST favorecer a solução mais simples que atenda à especificação.

- O escopo é um único processamento batch: ler pagamentos, validar e separar válidos
  de inválidos.
- MUST NOT haver abstrações, utilitários genéricos, programas auxiliares ou recursos
  não exigidos pela spec.
- Complexidade adicional só entra com justificativa explícita no plano.

**Razão**: a demonstração precisa ser lida e entendida em minutos; excesso de
estrutura esconde o ponto principal — a rastreabilidade spec → código.

### II. COBOL em Formato Fixo

Todo fonte COBOL MUST seguir o formato fixo tradicional de colunas:

| Colunas | Uso                                                    |
|---------|--------------------------------------------------------|
| 1–6     | Área de sequência (pode ficar em branco)               |
| 7       | Indicador (`*` comentário, `-` continuação)            |
| 8–11    | Área A: divisões, seções, parágrafos, níveis 01 e 77   |
| 12–72   | Área B: comandos e demais níveis de dados              |
| 73–80   | Área de identificação (não usada)                      |

- Nenhum código pode ultrapassar a coluna 72.
- Palavras reservadas e nomes em letras maiúsculas.
- MUST NOT usar formato livre nem extensões específicas de compilador.

**Razão**: é a convenção que qualquer profissional de Mainframe reconhece e que os
compiladores tradicionais exigem.

### III. Código Legível e Organizado

- O programa MUST conter as quatro divisões (IDENTIFICATION, ENVIRONMENT, DATA,
  PROCEDURE), na ordem padrão.
- A PROCEDURE DIVISION MUST ser estruturada em parágrafos com nome descritivo e
  prefixo numérico (ex.: `1000-INICIALIZAR`, `2000-PROCESSAR`, `3000-FINALIZAR`),
  executados via `PERFORM`. MUST NOT usar `GO TO`.
- Nomes de dados MUST ser descritivos e em português, com prefixo indicando a origem
  (ex.: `WS-` para WORKING-STORAGE).
- Comentários curtos explicam o *porquê* de cada bloco, não repetem o comando.
- Cada regra de validação MUST ser identificável no código e rastreável até a spec.

**Razão**: legibilidade é o que permite ao leitor conferir que o código implementa
exatamente o que a especificação pede.

### IV. Copybook como Contrato de Dados

- O layout do registro de pagamento MUST ser definido em copybook e incluído nos
  programas via `COPY`.
- Registros MUST ter tamanho fixo, com campos declarados por `PIC` explícito.
- O layout definido no copybook é a fonte única da estrutura do registro; programas
  MUST NOT redefinir o mesmo layout localmente.

**Razão**: o copybook é o contrato de dados tradicional do Mainframe e o ponto natural
de ligação entre a spec (modelo de dados) e o código.

### V. JCL Tradicional

- O JCL MUST seguir a estrutura clássica: cartão `JOB`, passos `EXEC PGM=` e cartões
  `DD` para cada arquivo.
- Instruções iniciam com `//` na coluna 1; comentários com `//*`; conteúdo até a
  coluna 71, com continuação na forma tradicional.
- Nomes de job, step, programa e DD MUST ter até 8 caracteres, em maiúsculas.
- Datasets e parâmetros MUST ser coerentes com o layout do copybook (ex.: `LRECL`
  igual ao tamanho do registro, `RECFM=FB`).

**Razão**: o JCL é a peça que mostra como o programa roda em produção batch; seguir o
padrão clássico torna a demonstração reconhecível para quem vive o ambiente.

### VI. Nomenclatura e Documentação Operacional

Estas convenções são obrigatórias e permanentes. Todo nome MUST ter no máximo 8
caracteres, em letras maiúsculas.

**Programas COBOL** — formato `SDDPnnnn`:

| Posição | Conteúdo | Significado                     |
|---------|----------|---------------------------------|
| 1–3     | `SDD`    | Identificação do projeto        |
| 4       | `P`      | Programa                        |
| 5–8     | `nnnn`   | Sequencial alfanumérico (4 caracteres A–Z/0–9) |

Exemplo: `SDDP0001`.

**Procedures JCL** — formato `PSDDXnnn`:

| Posição | Conteúdo | Significado                         |
|---------|----------|-------------------------------------|
| 1       | `P`      | Procedure                           |
| 2–4     | `SDD`    | Identificação do projeto            |
| 5       | `X`      | Periodicidade ou modalidade (abaixo) |
| 6–8     | `nnn`    | Sequencial alfanumérico (3 caracteres A–Z/0–9) |

Códigos de periodicidade (posição 5):

- `I` — Intermitente: executada em intervalos curtos e regulares ao longo do dia
  (ex.: a cada 5 minutos).
- `D` — Diária.
- `M` — Mensal.
- `E` — Eventual.
- `A` — Anual.

Nenhum outro código é permitido. Exemplo: `PSDDI900`.

**Documentação das procedures**:

- Toda procedure MUST possuir um documento de referência operacional próprio.
- O nome do documento MUST ser o identificador da procedure com o primeiro caractere
  `P` substituído por `D` (ex.: `PSDDI900` → `DSDDI900`).
- O documento MUST registrar, no mínimo:
  - Identificação e finalidade da procedure.
  - Local ou ambiente de execução.
  - Periodicidade ou condição de execução.
  - Horário ou janela prevista de execução, quando aplicável.
  - Programas executados.
  - Arquivos de entrada e saída.
  - Responsável pela criação.
  - Outras informações operacionais relevantes, quando necessárias.
- O código de periodicidade no nome da procedure MUST ser coerente com a periodicidade
  declarada no documento.
- Nenhuma linha do documento pode ultrapassar 72 posições.

**Verificação**: programas atendem ao padrão `^SDDP[A-Z0-9]{4}$`; procedures, ao padrão
`^PSDD[IDMEA][A-Z0-9]{3}$`; para cada procedure existe o documento correspondente com
todos os itens mínimos preenchidos e linhas de até 72 posições.

**Razão**: o nome identifica de imediato o projeto, o tipo do artefato e, nas
procedures, quando ele roda; a documentação vincula a procedure à operação, como
num ambiente de produção real.

## Restrições Técnicas

- Tecnologias: COBOL, JCL e copybook. Nada além disso.
- Arquivos: sequenciais, de registro fixo — uma entrada (pagamentos) e duas saídas
  (válidos e inválidos).
- Fora de escopo: DB2, CICS, VSAM, IMS, utilitários de terceiros e qualquer integração
  externa.
- Compilação e execução NÃO são condição para concluir o projeto. A validação é feita
  por revisão dos artefatos (formato de colunas, coerência com a spec e com o
  copybook).

## Fluxo de Desenvolvimento SDD

- O fluxo segue a sequência do Spec Kit: Constitution → Spec → Plan → Tasks →
  Implementação.
- Nenhum artefato de código é gerado sem spec e plano aprovados.
- Todo conteúdo (documentos, comentários e nomes de dados) MUST ser escrito em
  português brasileiro, respeitando as limitações de caracteres do COBOL (sem acentos
  em nomes e literais de código).
- Uma entrega é considerada concluída quando os artefatos existem (incluindo a
  documentação operacional de cada procedure), respeitam esta Constitution e cobrem
  todas as regras da spec.

## Governance

- Esta Constitution prevalece sobre qualquer outra orientação do projeto.
- Alterações são feitas via `/speckit-constitution`, com registro no Sync Impact Report
  e versionamento semântico: MAJOR para remoção ou redefinição de princípio, MINOR para
  princípio ou seção nova, PATCH para ajustes de redação.
- A conformidade MUST ser verificada no Constitution Check do plano e na revisão dos
  artefatos gerados.

**Version**: 1.2.0 | **Ratified**: 2026-11-17 | **Last Amended**: 2026-11-17
