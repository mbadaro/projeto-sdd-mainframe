       IDENTIFICATION DIVISION.
       PROGRAM-ID. SDDP0001.
       AUTHOR. 1777-SQUAD PAGAMENTOS.
      *----------------------------------------------------------------*
      * SDDP0001 - PROCESSAMENTO BATCH DE PAGAMENTOS
      * LE O ARQUIVO DE PAGAMENTOS, APLICA A RN01 E SEPARA OS
      * REGISTROS EM APROVADOS E REJEITADOS (COM CODIGO DE MOTIVO).
      * ORIGEM: SPEC 001-PAGAMENTOS-BATCH
      * RC 0  = CONCLUIDO SEM REJEITADOS
      * RC 4  = CONCLUIDO COM AO MENOS UM REJEITADO
      * RC 12 = ERRO EM ARQUIVO (OPEN, READ, WRITE OU CLOSE)
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-PAGENT ASSIGN TO PAGENT
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS IS WS-FS-PAGENT.
           SELECT ARQ-PAGAPR ASSIGN TO PAGAPR
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS IS WS-FS-PAGAPR.
           SELECT ARQ-PAGREJ ASSIGN TO PAGREJ
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS IS WS-FS-PAGREJ.

       DATA DIVISION.
       FILE SECTION.
      * REGISTROS GENERICOS: O LAYOUT FICA SOMENTE NO COPYBOOK SDDC0001
       FD  ARQ-PAGENT
           RECORDING MODE IS F.
       01  REG-PAGENT                  PIC X(30).
       FD  ARQ-PAGAPR
           RECORDING MODE IS F.
       01  REG-PAGAPR                  PIC X(30).
       FD  ARQ-PAGREJ
           RECORDING MODE IS F.
       01  REG-PAGREJ                  PIC X(32).

       WORKING-STORAGE SECTION.
      * FILE STATUS DE CADA ARQUIVO
       01  WS-FS-PAGENT                PIC X(02) VALUE SPACES.
       01  WS-FS-PAGAPR                PIC X(02) VALUE SPACES.
       01  WS-FS-PAGREJ                PIC X(02) VALUE SPACES.
      * INDICADORES DE ARQUIVO ABERTO: NO ERRO, FECHA SO O QUE ABRIU
       01  WS-ABERTO-PAGENT            PIC X(01) VALUE 'N'.
       01  WS-ABERTO-PAGAPR            PIC X(01) VALUE 'N'.
       01  WS-ABERTO-PAGREJ            PIC X(01) VALUE 'N'.
      * INDICADOR DE FIM DO ARQUIVO DE ENTRADA
       01  WS-FIM-ARQUIVO              PIC X(01) VALUE 'N'.
           88  FIM-DA-ENTRADA                    VALUE 'S'.
      * RESULTADO DA RN01: 00 = APROVADO, 01 OU 02 = MOTIVO DE REJEICAO
       01  WS-MOTIVO                   PIC 9(02) VALUE ZERO.
      * CONTADORES DE CONTROLE
       01  WS-CONT-LIDOS               PIC 9(07) VALUE ZERO.
       01  WS-CONT-APROVADOS           PIC 9(07) VALUE ZERO.
       01  WS-CONT-REJEITADOS          PIC 9(07) VALUE ZERO.
      * DADOS DA MENSAGEM DE ERRO DE ARQUIVO
       01  WS-ERRO-DD                  PIC X(06) VALUE SPACES.
       01  WS-ERRO-OPERACAO            PIC X(05) VALUE SPACES.
       01  WS-ERRO-FS                  PIC X(02) VALUE SPACES.
      * LAYOUTS DOS REGISTROS (CONTRATO DE DADOS)
           COPY SDDC0001.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * FLUXO PRINCIPAL: LEITURA ANTECIPADA, LACO ATE O FIM DA ENTRADA
      * E FINALIZACAO
      *----------------------------------------------------------------*
       0000-PRINCIPAL.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR UNTIL FIM-DA-ENTRADA
           PERFORM 9000-FINALIZAR
           STOP RUN.

      *----------------------------------------------------------------*
      * ABRE OS TRES ARQUIVOS E LE O PRIMEIRO REGISTRO
      *----------------------------------------------------------------*
       1000-INICIALIZAR.
           OPEN INPUT ARQ-PAGENT
           IF WS-FS-PAGENT = '00'
              MOVE 'S' TO WS-ABERTO-PAGENT
           ELSE
              MOVE 'PAGENT'     TO WS-ERRO-DD
              MOVE 'OPEN'       TO WS-ERRO-OPERACAO
              MOVE WS-FS-PAGENT TO WS-ERRO-FS
              PERFORM 9900-ERRO-ARQUIVO
           END-IF

           OPEN OUTPUT ARQ-PAGAPR
           IF WS-FS-PAGAPR = '00'
              MOVE 'S' TO WS-ABERTO-PAGAPR
           ELSE
              MOVE 'PAGAPR'     TO WS-ERRO-DD
              MOVE 'OPEN'       TO WS-ERRO-OPERACAO
              MOVE WS-FS-PAGAPR TO WS-ERRO-FS
              PERFORM 9900-ERRO-ARQUIVO
           END-IF

           OPEN OUTPUT ARQ-PAGREJ
           IF WS-FS-PAGREJ = '00'
              MOVE 'S' TO WS-ABERTO-PAGREJ
           ELSE
              MOVE 'PAGREJ'     TO WS-ERRO-DD
              MOVE 'OPEN'       TO WS-ERRO-OPERACAO
              MOVE WS-FS-PAGREJ TO WS-ERRO-FS
              PERFORM 9900-ERRO-ARQUIVO
           END-IF

           PERFORM 8000-LER-PAGAMENTO.

      *----------------------------------------------------------------*
      * TRATA O REGISTRO CORRENTE E LE O PROXIMO
      *----------------------------------------------------------------*
       2000-PROCESSAR.
           PERFORM 2100-VALIDAR-PAGAMENTO
           IF WS-MOTIVO = ZERO
              PERFORM 2200-GRAVAR-APROVADO
           ELSE
              PERFORM 2300-GRAVAR-REJEITADO
           END-IF
           PERFORM 8000-LER-PAGAMENTO.

      *----------------------------------------------------------------*
      * RN01 (FR-002) - SPEC 001-PAGAMENTOS-BATCH
      * O PAGAMENTO E APROVADO SE O VALOR FOR NUMERICO E MAIOR QUE
      * ZERO. MOTIVOS DE REJEICAO (FR-003), AVALIADOS NESTA ORDEM:
      *   01 = VALOR NAO NUMERICO (SINAL INVALIDO OU DIGITOS INVALIDOS)
      *   02 = VALOR MENOR OU IGUAL A ZERO
      * A VISAO NUMERICA SO E USADA DEPOIS DO TESTE NUMERIC.
      *----------------------------------------------------------------*
       2100-VALIDAR-PAGAMENTO.
           MOVE ZERO TO WS-MOTIVO
           IF (PAG-VALOR-SINAL NOT = '+' AND
               PAG-VALOR-SINAL NOT = '-')
              OR PAG-VALOR-DIGITOS IS NOT NUMERIC
              MOVE 01 TO WS-MOTIVO
           ELSE
              IF PAG-VALOR-SINAL = '-' OR PAG-VALOR-NUM = ZERO
                 MOVE 02 TO WS-MOTIVO
              END-IF
           END-IF.

      *----------------------------------------------------------------*
      * GRAVA O PAGAMENTO APROVADO, SEM ALTERACAO DE CONTEUDO
      *----------------------------------------------------------------*
       2200-GRAVAR-APROVADO.
           WRITE REG-PAGAPR FROM REG-PAGAMENTO
           IF WS-FS-PAGAPR = '00'
              ADD 1 TO WS-CONT-APROVADOS
           ELSE
              MOVE 'PAGAPR'     TO WS-ERRO-DD
              MOVE 'WRITE'      TO WS-ERRO-OPERACAO
              MOVE WS-FS-PAGAPR TO WS-ERRO-FS
              PERFORM 9900-ERRO-ARQUIVO
           END-IF.

      *----------------------------------------------------------------*
      * GRAVA O PAGAMENTO REJEITADO: REGISTRO ORIGINAL + MOTIVO
      *----------------------------------------------------------------*
       2300-GRAVAR-REJEITADO.
           MOVE REG-PAGAMENTO TO REJ-PAGAMENTO
           MOVE WS-MOTIVO     TO REJ-MOTIVO
           WRITE REG-PAGREJ FROM REG-REJEITADO
           IF WS-FS-PAGREJ = '00'
              ADD 1 TO WS-CONT-REJEITADOS
           ELSE
              MOVE 'PAGREJ'     TO WS-ERRO-DD
              MOVE 'WRITE'      TO WS-ERRO-OPERACAO
              MOVE WS-FS-PAGREJ TO WS-ERRO-FS
              PERFORM 9900-ERRO-ARQUIVO
           END-IF.

      *----------------------------------------------------------------*
      * LE O PROXIMO PAGAMENTO. FILE STATUS 10 = FIM DO ARQUIVO
      *----------------------------------------------------------------*
       8000-LER-PAGAMENTO.
           READ ARQ-PAGENT INTO REG-PAGAMENTO
           EVALUATE WS-FS-PAGENT
              WHEN '00'
                 ADD 1 TO WS-CONT-LIDOS
              WHEN '10'
                 SET FIM-DA-ENTRADA TO TRUE
              WHEN OTHER
                 MOVE 'PAGENT'     TO WS-ERRO-DD
                 MOVE 'READ'       TO WS-ERRO-OPERACAO
                 MOVE WS-FS-PAGENT TO WS-ERRO-FS
                 PERFORM 9900-ERRO-ARQUIVO
           END-EVALUATE.

      *----------------------------------------------------------------*
      * FECHA OS ARQUIVOS, EXIBE OS CONTADORES E DEFINE O RC (0 OU 4).
      * O RC SO E DEFINIDO APOS TODOS OS CLOSE BEM-SUCEDIDOS.
      *----------------------------------------------------------------*
       9000-FINALIZAR.
           CLOSE ARQ-PAGENT
           IF WS-FS-PAGENT = '00'
              MOVE 'N' TO WS-ABERTO-PAGENT
           ELSE
              MOVE 'PAGENT'     TO WS-ERRO-DD
              MOVE 'CLOSE'      TO WS-ERRO-OPERACAO
              MOVE WS-FS-PAGENT TO WS-ERRO-FS
              PERFORM 9900-ERRO-ARQUIVO
           END-IF

           CLOSE ARQ-PAGAPR
           IF WS-FS-PAGAPR = '00'
              MOVE 'N' TO WS-ABERTO-PAGAPR
           ELSE
              MOVE 'PAGAPR'     TO WS-ERRO-DD
              MOVE 'CLOSE'      TO WS-ERRO-OPERACAO
              MOVE WS-FS-PAGAPR TO WS-ERRO-FS
              PERFORM 9900-ERRO-ARQUIVO
           END-IF

           CLOSE ARQ-PAGREJ
           IF WS-FS-PAGREJ = '00'
              MOVE 'N' TO WS-ABERTO-PAGREJ
           ELSE
              MOVE 'PAGREJ'     TO WS-ERRO-DD
              MOVE 'CLOSE'      TO WS-ERRO-OPERACAO
              MOVE WS-FS-PAGREJ TO WS-ERRO-FS
              PERFORM 9900-ERRO-ARQUIVO
           END-IF

           DISPLAY 'SDDP0001 - REGISTROS LIDOS......: '
                   WS-CONT-LIDOS
           DISPLAY 'SDDP0001 - REGISTROS APROVADOS..: '
                   WS-CONT-APROVADOS
           DISPLAY 'SDDP0001 - REGISTROS REJEITADOS.: '
                   WS-CONT-REJEITADOS

           IF WS-CONT-REJEITADOS > ZERO
              MOVE 4 TO RETURN-CODE
           ELSE
              MOVE 0 TO RETURN-CODE
           END-IF.

      *----------------------------------------------------------------*
      * ERRO DE ARQUIVO: EXIBE A MENSAGEM, FECHA SO OS ARQUIVOS ABERTOS
      * (SEM TESTAR O FILE STATUS, PARA NAO ENTRAR EM LACO DE ERRO),
      * DEFINE RC 12 E ENCERRA. NAO RETORNA AO FLUXO, ENTAO O RC 12
      * NUNCA E SOBRESCRITO PELO RC 0 OU 4.
      *----------------------------------------------------------------*
       9900-ERRO-ARQUIVO.
           DISPLAY 'SDDP0001 - ERRO NO ARQUIVO ' WS-ERRO-DD
                   ' - OPERACAO ' WS-ERRO-OPERACAO
                   ' - FILE STATUS ' WS-ERRO-FS
           IF WS-ABERTO-PAGENT = 'S'
              CLOSE ARQ-PAGENT
           END-IF
           IF WS-ABERTO-PAGAPR = 'S'
              CLOSE ARQ-PAGAPR
           END-IF
           IF WS-ABERTO-PAGREJ = 'S'
              CLOSE ARQ-PAGREJ
           END-IF
           MOVE 12 TO RETURN-CODE
           STOP RUN.
