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

  for i in `seq 1 $numRodadas`
  do
    echo "Rodada: $i"
    runSemAtaque $i
    runComAtaque $i
  done

}


##################################################################
# Objetivo: Checar ping com a máquina
# Argumentos:
#   $1 -> Numero de Clientes
#   $2 -> Numero de Slaves)
##################################################################
function pingCheck() {

	NUMCLIENTS="$1"
	NUMSLAVES="$2"

	ping -c1 192.168.0.200 > /dev/null

		if [ $? -eq 0 ]
		 then
			echo "Teste de ping para Atacado com sucesso"
		 else
			echo "Teste de ping para Atacado falhou"
			exit

		fi
	
	ping -c1 192.168.10.201 > /dev/null

		if [ $? -eq 0 ]
		 then
			echo "Teste de ping para Monitorado com sucesso"
		else
			echo "Teste de ping para Monitorado falhou"
			exit
		fi
		
	for i in `seq 1 $NUMCLIENTS`
	do
		ping -c1 192.168.0.$i > /dev/null

			if [ $? -eq 0 ]
		 	then
				echo "Teste de ping para Cliente "$i" com sucesso"
			else
				echo "Teste de ping para Cliente "$i" falhou"
				exit
			fi
	done

	for i in `seq $[NUMCLIENTS+1] $[NUMCLIENTS+NUMSLAVES]`
	do
		ping -c1 192.168.0.$i > /dev/null

			if [ $? -eq 0 ]
		 	then
				echo "Teste de ping para Atacante "$i" com sucesso"
			else
				echo "Teste de ping para Atacante "$i" falhou"
				exit
			fi
	done
}

##################################################################
# Objetivo: Executa o experimento sem ataque (Só clientes)
# Argumentos:
#   $1 -> Numero de Rodadas
##################################################################
function runSemAtaque() {
	numRodadas=$1
	tipoDeExperimento="SemAtaque"

  	echo "Executando sem ataque na rodada $1"
	echo "Executando função em atacado: "
	sshpass -p 'vagrant' ssh root@192.168.0.200 'bash /gpcn/atacado/scripts/jarbas '$numRodadas $tipoDeExperimento
	
}

##################################################################
# Objetivo: Executa o experimento com ataque (Clientes e atacantes)
# Argumentos:
#   $1 -> Message
#   $2 -> Exit status (optional)
##################################################################
function runComAtaque() {
  	numRodadas=$1
  	echo "Executando com ataque na rodada $1"
}

##################################################################
# Objetivo: Executa o experimento sem ataque (Só clientes)
# Argumentos:
#   $1 -> Numero de Rodadas
#   $2 -> Tipo do experimento
##################################################################
function atacado() {
	echo "Iniciando função em atacado:"
	COUNT=0
	numRodadas="$1"
	tipoDeExperimento="$2"

	collectl -sscmn -P -f /gpcn/atacado/logs/collectl/$tipoDeExperimento_$numRodadas &

	while [ $COUNT != 60 ]
	do
		netstat -taupen | grep 80 | wc -l >> /gpcn/atacado/logs/netstat/socket_$tipoDeExperimento_$numRodadas.log
		sleep 1
		COUNT=$((COUNT+1))
	done

	killall collectl
	killall jarbas
}
