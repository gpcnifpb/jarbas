#!/bin/bash

##################################################################
# Objetivo: Executa o experimento por completo.
# Argumentos:
#   $1 -> Numero de rodadas
#   $2 -> Exit status (optional)
##################################################################
function run() {
  echo "Executar função com $1 rodadas"
  numRodadas="$1"

  # TODO jarbasCheck

  for i in `seq 1 $numRodadas`
  do
    echo "Rodada: $i"
    runSemAtaque
    runComAtaque
  done

}

##################################################################
# Objetivo: Executa o experimento sem ataque (Só clientes)
# Argumentos:
#   $1 -> Message
#   $2 -> Exit status (optional)
##################################################################
function runSemAtaque() {
  echo "Executando sem ataque"
}

##################################################################
# Objetivo: Executa o experimento com ataque (Clientes e atacantes)
# Argumentos:
#   $1 -> Message
#   $2 -> Exit status (optional)
##################################################################
function runComAtaque() {
  echo "Rodando com ataque"
}
