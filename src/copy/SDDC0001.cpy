      *----------------------------------------------------------------*
      * COPYBOOK SDDC0001 - LAYOUTS DO PROCESSAMENTO DE PAGAMENTOS
      * ORIGEM: SPEC 001-PAGAMENTOS-BATCH (DATA-MODEL)
      *----------------------------------------------------------------*
      * REGISTRO DE PAGAMENTO (30 POSICOES) - ENTRADA E APROVADOS
       01  REG-PAGAMENTO.
           05  PAG-ID                  PIC X(10).
      *    VALOR LIDO COMO ALFANUMERICO PARA SER VALIDADO ANTES DE
      *    QUALQUER CONVERSAO NUMERICA. EX.: 150,00 = +000000015000
           05  PAG-VALOR.
               10  PAG-VALOR-SINAL     PIC X(01).
               10  PAG-VALOR-DIGITOS   PIC X(12).
               10  PAG-VALOR-NUM       REDEFINES PAG-VALOR-DIGITOS
                                       PIC 9(10)V99.
           05  FILLER                  PIC X(07).
      * REGISTRO REJEITADO (32 POSICOES) - ORIGINAL + MOTIVO
       01  REG-REJEITADO.
           05  REJ-PAGAMENTO           PIC X(30).
           05  REJ-MOTIVO              PIC 9(02).
